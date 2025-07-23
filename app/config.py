import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    STRIPE_API_KEY: str = os.getenv("STRIPE_API_KEY")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@db:5432/stripe_db")
    STRIPE_WEBHOOK_SECRET = os.getenv("STRIPE_WEBHOOK_SECRET")
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")
    REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")


settings = Settings()