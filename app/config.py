# app/config.py
import os
from dotenv import load_dotenv

load_dotenv()


class Settings:
    STRIPE_API_KEY: str = os.getenv("STRIPE_API_KEY")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@db:5432/stripe_db")

settings = Settings()