from fastapi import APIRouter, Request, Header, HTTPException, Depends
from starlette.responses import JSONResponse
import stripe

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime

from app.config import settings
from app.models import WebhookEvent, StripePayment
from app.database import get_db
from app.websocket_manager import manager

router = APIRouter()

# Stripe setup
stripe.api_key = settings.STRIPE_API_KEY

@router.post("/webhook")
async def webhook(
    request: Request,
    stripe_signature: str = Header(None),
    db: AsyncSession = Depends(get_db)
):
    payload = await request.body()

    # Debug logging for signature troubleshooting
    print("==== Stripe Webhook Debug ====")
    print("Stripe-Signature header:", stripe_signature)
    print("Using webhook secret:", settings.STRIPE_WEBHOOK_SECRET)
    print("Payload (first 200 bytes):", payload[:200])
    print("==============================")

    # Verify webhook signature
    try:
        event = stripe.Webhook.construct_event(
            payload=payload,
            sig_header=stripe_signature,
            secret=settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        print("Invalid payload")
        raise HTTPException(status_code=400, detail="Invalid payload")
    except stripe.error.SignatureVerificationError:
        print("Invalid signature")
        raise HTTPException(status_code=400, detail="Invalid signature")

    event_type = event["type"]
    event_id = event["id"]
    obj = event["data"]["object"]

    print(f"Received Stripe event: {event_type}")
    print(f"Object ID: {obj.get('id')}")

    # Store webhook event for audit (if not already exists)
    exists = await db.execute(select(WebhookEvent).where(WebhookEvent.id == event_id))
    if not exists.scalar():
        db.add(WebhookEvent(
            id=event_id,
            type=event_type,
            data=event
        ))
        await db.commit()

    # Real-time charge syncing (from payment_intent)
    if event_type == "payment_intent.succeeded":
        print("Payment succeeded")
        charge_data = obj.get("charges", {}).get("data", [])
        if charge_data:
            charge = charge_data[0]
            charge_id = charge["id"]
            email = charge.get("billing_details", {}).get("email")
            created_at = datetime.fromtimestamp(charge["created"])

            charge_exists = await db.execute(select(StripePayment).where(StripePayment.id == charge_id))
            if not charge_exists.scalar():
                db.add(StripePayment(
                    id=charge_id,
                    amount=charge["amount"],
                    currency=charge["currency"],
                    status=charge["status"],
                    customer_email=email,
                    created_at=created_at
                ))
                await db.commit()

    elif event_type == "charge.refunded":
        print("Charge refunded")
    elif event_type == "invoice.payment_failed":
        print("Invoice payment failed")

    # Notify WebSocket clients
    await manager.broadcast(f"Stripe event received: {event_type}")

    return JSONResponse(status_code=200, content={"message": "Webhook received"})