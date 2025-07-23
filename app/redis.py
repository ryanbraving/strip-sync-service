import redis.asyncio as redis
import asyncio
from app.config import settings

print("*"*40)
print("REDIS_URL is:", settings.REDIS_URL)
print("*"*40)

# Redis client
redis_client = redis.Redis.from_url(settings.REDIS_URL, decode_responses=True)
