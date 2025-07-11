# app/main.py
from fastapi import FastAPI, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.exc import OperationalError
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import engine, Base, get_db, init_db
from app.stripe_client import fetch_and_store_charges
from app.stripe_webhook import router as webhook_router
from app.websocket_manager import manager
import asyncio


app = FastAPI()
app.include_router(webhook_router)

@app.on_event("startup")
async def startup():
    await init_db()
    for i in range(10):  # retry up to 10 times
        try:
            async with engine.begin() as conn:
                await conn.run_sync(Base.metadata.create_all)
            print("✅ Database is ready")
            break
        except OperationalError as e:
            print(f"⏳ DB not ready yet, retrying... ({i+1}/10)")
            await asyncio.sleep(2)
    else:
        print("❌ Could not connect to DB after 10 tries")
        raise RuntimeError("DB connection failed")

@app.get("/")
async def root():
    return {"message": "Stripe Sync Service is up"}

@app.get("/sync-payments")
async def sync_payments(db: AsyncSession = Depends(get_db)):
    await fetch_and_store_charges(db)
    return {"status": "sync complete"}


@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()  # Keep connection alive
    except WebSocketDisconnect:
        manager.disconnect(websocket)

