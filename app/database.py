from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.pool import NullPool
from .config import settings
from app.db_base import Base
from app import models         # Register models with Base

print("*"*40)
print("DATABASE_URL in production:", settings.DATABASE_URL)

engine = create_async_engine(settings.DATABASE_URL, echo=True)
AsyncSessionLocal = sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session

# This creates all tables in your database
async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
