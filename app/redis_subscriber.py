from app.websocket_manager import manager
from app.redis import redis_client

async def redis_subscriber():
    pubsub = redis_client.pubsub()
    await pubsub.psubscribe("channel:*")
    async for message in pubsub.listen():
        print("RAW MESSAGE:", message)
        if message["type"] == "pmessage":
            channel = message["channel"]
            data = message["data"]
            print(channel, data)
            _, user_id = channel.split(":")
            await manager.broadcast(data, user_id, from_redis=True)