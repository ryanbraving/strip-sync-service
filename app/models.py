from sqlalchemy import Column, String, Boolean, Integer, DateTime, JSON
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from sqlalchemy.sql import func
from app.db_base import Base # Use shared Base

class StripePayment(Base):
    __tablename__ = "stripe_payments"

    id = Column(String, primary_key=True, index=True)
    amount = Column(Integer)
    currency = Column(String)
    status = Column(String)
    customer_id = Column(String, nullable=True)
    customer_email = Column(String, nullable=True)
    created_at = Column(DateTime)


class WebhookEvent(Base):
    __tablename__ = "webhook_events"

    id = Column(String, primary_key=True, index=True)
    type = Column(String, nullable=False)
    data = Column(JSONB, nullable=False)
    received_at = Column(DateTime(timezone=True), server_default=func.now())


class WebSocketConnection(Base):
    __tablename__ = "websocket_connections"

    connection_id = Column(String, primary_key=True)
    user_id = Column(String, index=True)
    connected_at = Column(DateTime, default=datetime.utcnow)
    should_broadcast = Column(Boolean, default=False)