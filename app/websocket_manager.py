import uuid
import json
from typing import Dict, List, Tuple
from fastapi import WebSocket
from app.models import WebSocketConnection
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import delete
from app.redis import redis_client
import socket



class WebSocketManager:
    MAX_CONNECTIONS_PER_USER = 3
    def __init__(self):
        # Stores active WebSocket connections per user_id.
        # Each connection is stored along with a flag indicating if it wants broadcasting enabled.
        # self.active_connections: Dict[str, List[Tuple[WebSocket, bool, uuid.UUID]]] = {}

        self.local_websockets = {}  # connection_id -> websocket

        # Tracks the "primary pinger" WebSocket per user_id to control single heartbeat broadcasting
        self.primary_pinger: Dict[str, WebSocket] = {}

    async def connect(self, user_id: str, websocket: WebSocket, db: AsyncSession, should_broadcast: bool = False):
        """
        Accepts a new WebSocket connection and tracks it under the given user_id.
        Also records whether this connection wants to enable broadcasting.
        If it's the first broadcast-enabled connection, it becomes the primary pinger.
        """

        # current_count = len(self.active_connections.get(user_id, []))

        # scard returns the number of members in the set, which is efficient and atomic.
        current_count = await redis_client.scard(f"ws:{user_id}:connections")
        if current_count >= self.MAX_CONNECTIONS_PER_USER:
            await websocket.close(code=4004, reason="Too many connections for this user")
            print(f"🚫 User {user_id} exceeded connection limit.")
            return False

        await websocket.accept()

        if should_broadcast and user_id not in self.primary_pinger:
            self.primary_pinger[user_id] = websocket

        connection_id = str(uuid.uuid4())
        # Create and store in DB
        conn = WebSocketConnection(
            connection_id=connection_id,
            user_id=user_id,
            should_broadcast=should_broadcast,
        )
        await db.merge(conn)  # Upsert
        await db.commit()

        # # Save the connection with db UUID
        # self.active_connections.setdefault(user_id, []).append((websocket, should_broadcast, connection_id))

        # keep track of local websockets
        self.local_websockets[connection_id] = websocket



        # Add connection_id to a Redis set for the user
        await redis_client.sadd(f"ws:{user_id}:connections", connection_id)
        await redis_client.expire(f"ws:{user_id}:connections", 259200)  # 3 days

        # Store in Redis
        hostname = socket.gethostname()
        connection_info = json.dumps({"status": "connected", "hostname": hostname, "broadcast": should_broadcast})

        # Store connection details under a separate key
        await redis_client.setex(f"ws:{user_id}:{connection_id}", 60, connection_info)

        # await websocket.send_text(f"Connected to backend: {hostname} with connection_id: {connection_id}. "
        #                           f"Total connections: {len(self.active_connections.get(user_id, []))}")

        current_count = await redis_client.scard(f"ws:{user_id}:connections")

        await websocket.send_text(f"Connected to backend: {hostname} with connection_id: {connection_id}. "
                                  f"Total connections: {current_count}")

        return connection_id

    async def disconnect(self, user_id: str, websocket: WebSocket, connection_id, db: AsyncSession):
        """
        Removes a disconnected WebSocket from the tracked list.
        If it was the primary pinger, also clears the primary_pinger entry.
        Cleans up the user entry if no more connections exist.
        """
        # if user_id in self.active_connections:
        #     self.active_connections[user_id] = [
        #         (ws, flag, conn_id) for ws, flag, conn_id in self.active_connections[user_id] if ws != websocket
        #     ]
        #
        #     if not self.active_connections[user_id]:
        #         self.active_connections.pop(user_id)
        #         self.primary_pinger.pop(user_id, None)
        #
        #     elif self.primary_pinger.get(user_id) == websocket:
        #         self.primary_pinger.pop(user_id, None)

        await redis_client.srem(f"ws:{user_id}:connections", connection_id)
        await redis_client.delete(f"ws:{user_id}:{connection_id}")

        # Remove local websocket
        self.local_websockets.pop(connection_id, None)

        await db.execute(delete(WebSocketConnection).where(WebSocketConnection.connection_id == connection_id))
        await db.commit()

    def has_broadcast_enabled(self, user_id: str) -> bool:
        """
        Returns True if at least one connection for the user_id has requested broadcast support.
        """
        return any(broadcast for _, broadcast, _ in self.active_connections.get(user_id, []))

    def is_primary_pinger(self, user_id: str, websocket: WebSocket) -> bool:
        """
        Checks if the given WebSocket is the assigned primary pinger for this user_id.
        Only the primary pinger is allowed to broadcast heartbeat messages.
        """
        return self.primary_pinger.get(user_id) == websocket


    async def broadcast(self, message: str, user_id: str, from_redis: bool = False):
        """
        Sends the message to all active WebSocket connections for the user.
        Also publishes it to Redis for cross-instance propagation.
        """
        # Local broadcast (for clients connected to this instance)
        # Only send to local clients if this is from Redis
        if from_redis:
            for ws, _, _ in self.active_connections.get(user_id, []):
                await ws.send_text(message)
        else:
        # Publish to Redis so other instances can forward it too
        # Only publish to Redis if this is NOT from Redis
            await redis_client.publish(f"channel:{user_id}", message)


    async def send_personal_message(self, message: str, user_id: str):
        """
        Sends a personal message to all connections for the user_id (no broadcast flag required).
        """
        for ws, _, _ in self.active_connections.get(user_id, []):
            await ws.send_text(message)


    async def get_user_connections_from_redis(user_id):
        """
        Gets all connection_ids from the Redis set.
        Fetches each connection’s metadata and returns as a list.
        """
        connection_ids = await redis_client.smembers(f"ws:{user_id}:connections")
        connections = []
        for cid in connection_ids:
            info = await redis_client.get(f"ws:{user_id}:{cid}")
            if info:
                connections.append(json.loads(info))
        return connections

# Create a global instance of the WebSocketManager
manager = WebSocketManager()