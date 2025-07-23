from fastapi import FastAPI, Depends, WebSocket, WebSocketDisconnect, HTTPException
from sqlalchemy.exc import OperationalError
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import engine, Base, get_db, init_db
from app.stripe_client import fetch_and_store_charges
from app.stripe_webhook import router as webhook_router
from app.models import WebSocketConnection
from app.websocket_manager import manager
from jose import JWTError, jwt
from jose.exceptions import ExpiredSignatureError
from app.config import settings
from datetime import datetime, timedelta, UTC
from app.database import get_db
from contextlib import asynccontextmanager
from sqlalchemy import select
from app.redis import redis_client
from app.redis_subscriber import redis_subscriber
import asyncio
import json


import logging

logging.basicConfig(level=logging.WARNING)
logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
logging.getLogger("uvicorn.access").setLevel(logging.WARNING)

JWT_SECRET_KEY = settings.JWT_SECRET_KEY  # 🔐 Replace this with a secure value or use SSM
ALGORITHM = "HS256"

# app = FastAPI()
# app.include_router(webhook_router)
#
# @app.on_event("startup")
# async def startup():
#     try:
#         print("Running init_db() to create tables...")
#         await init_db()
#         print("init_db() completed successfully.")
#     except Exception as e:
#         print("Error during init_db():", e)
#         import traceback
#         traceback.print_exc()
#         raise
#     for i in range(10):  # retry up to 10 times
#         try:
#             async with engine.begin() as conn:
#                 await conn.run_sync(Base.metadata.create_all)
#             print("Database is ready")
#             break
#         except OperationalError as e:
#             print(f"⏳ DB not ready yet, retrying... ({i+1}/10)")
#             await asyncio.sleep(2)
#     else:
#         print("Could not connect to DB after 10 tries")
#         raise RuntimeError("DB connection failed")




@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- Startup code (before yield) ---
    asyncio.create_task(redis_subscriber())

    try:
        print("Running init_db() to create tables...")
        await init_db()
        print("init_db() completed successfully.")
    except Exception as e:
        print("Error during init_db():", e)
        import traceback
        traceback.print_exc()
        raise
    for i in range(10):  # retry up to 10 times
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            print("Database is ready")
            break
        except OperationalError as e:
            print(f"⏳ DB not ready yet, retrying... ({i+1}/10)")
            await asyncio.sleep(2)
    else:
        print("Could not connect to DB after 10 tries")
        raise RuntimeError("DB connection failed")
    yield  # App runs here

    # --- Shutdown code (after yield) ---
    # (If you have any shutdown logic, add it here)

app = FastAPI(lifespan=lifespan)
app.include_router(webhook_router)


@app.get("/")
async def root():
    return {"message": "Stripe Sync Service is up"}

@app.get("/sync-payments")
async def sync_payments(db: AsyncSession = Depends(get_db)):
    await fetch_and_store_charges(db)
    return {"status": "sync complete"}

# Track last message timestamps per connection
connection_last_msg_time = {}

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, db: AsyncSession = Depends(get_db)):
    # Extract JWT token and optional broadcast flag from query parameters
    token = websocket.query_params.get("token")
    broadcast_param = websocket.query_params.get("broadcast", "false").lower() == "true"
    print("*"*40)
    client_ip, _ = websocket.client
    print(f"Client IP: {client_ip}")
    print("*"*40)


    if token is None:
        print("❌ No token provided")
        await websocket.close(code=1008)
        return

    try:
        # Decode JWT and extract user ID (sub)
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            print("❌ JWT token does not contain 'sub' (user_id)")
            raise JWTError()
    except ExpiredSignatureError:
        print("❌ Token expired")
        await websocket.close(code=4003)  # Custom error code for expired token
        return
    except JWTError:
        print("❌ Invalid token")
        await websocket.close(code=1008)
        return

    # Accept and register connection
    connection_id = await manager.connect(user_id, websocket, db=db, should_broadcast=broadcast_param)
    if not connection_id:
        return  # Don't continue if connection was rejected

    try:
        while True:
            try:
                # Wait for message with a timeout (keep connection active)
                msg = await asyncio.wait_for(websocket.receive_text(), timeout=30)

                now = datetime.now()
                # 🔄 Rate limit: 1 msg/sec per connection
                last_msg_time = connection_last_msg_time.get(websocket)
                if last_msg_time and now - last_msg_time < timedelta(seconds=1):
                    await websocket.send_text("⚠️ You're sending messages too fast. Slow down.")
                    continue

                connection_last_msg_time[websocket] = now

                print(f"📨 Message from {user_id}: {msg}")

                if manager.has_broadcast_enabled(user_id):
                    # If any connection under this user has broadcast enabled, send to all
                    await manager.broadcast(f"[Broadcasted] {msg}", user_id)
                else:
                    # Otherwise, echo back to this specific client
                    await websocket.send_text(f"[Echo] {msg}")

            except asyncio.TimeoutError:
                # Timeout reached: send periodic heartbeat
                now_utc = datetime.now(UTC).strftime("%Y-%m-%d %H:%M:%S UTC")
                client_ip, _ = websocket.client

                heartbeat_msg = f"💓ping: {user_id} {now_utc} {connection_id}"

                # Update TTL on heartbeat:
                await redis_client.expire(f"ws:{user_id}:{connection_id}", 60)

                if manager.has_broadcast_enabled(user_id):
                    # Only the primary pinger sends the heartbeat to avoid duplication
                    if manager.is_primary_pinger(user_id, websocket):
                        print(f"🔔 Primary heartbeat from {user_id}")
                        await manager.broadcast(heartbeat_msg, user_id)
                else:
                    print(f"🔔 Personal heartbeat to {user_id}")
                    await websocket.send_text(heartbeat_msg)

    except WebSocketDisconnect:
        print(f"🔌 Disconnected: {user_id}")
        await manager.disconnect(user_id, websocket, connection_id=connection_id, db=db)
        connection_last_msg_time.pop(websocket, None)

# @app.get("/admin/websockets")
# async def get_connections(db: AsyncSession = Depends(get_db)):
#     result = await db.execute(select(WebSocketConnection))
#     return result.scalars().all()


@app.get("/admin/websockets")
async def get_connections():
    connections = []
    # SCAN is non-blocking and can safely iterate over large keyspaces in batches
    async for key in redis_client.scan_iter("ws:*"):
        # key format: ws:{user_id}:{connection_id}
        parts = key.split(":")
        if len(parts) == 3:
            _, user_id, connection_id = parts
            ttl = await redis_client.ttl(key)
            values = await redis_client.get(key)
            data = json.loads(values)
            connections.append({
                "user_id": user_id,
                "connection_id": connection_id,
                "hostname": data["hostname"],
                "ttl": ttl,
                "status": data["status"],
                "broadcast": data["broadcast"],
            })
    return connections


async def get_user_connections_from_redis(user_id):
    connection_ids = await redis_client.smembers(f"ws:{user_id}:connections")
    connections = []
    for cid in connection_ids:
        info = await redis_client.get(f"ws:{user_id}:{cid}")
        if info:
            connections.append(json.loads(info))
        else:
            # Stale connection_id, remove from set
            await redis_client.srem(f"ws:{user_id}:connections", cid)
    return connections