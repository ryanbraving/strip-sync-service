# app/stripe_client.py
import httpx
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime
from app.models import StripePayment
from app.config import settings

STRIPE_API_URL = "https://api.stripe.com/v1/charges"
STRIPE_CUSTOMER_URL = "https://api.stripe.com/v1/customers"

HEADERS = {
    "Authorization": f"Bearer {settings.STRIPE_API_KEY}"
}

async def fetch_customer_email(customer_id: str, client: httpx.AsyncClient) -> str:
    """Fetch customer email from Stripe by customer ID."""
    try:
        response = await client.get(f"{STRIPE_CUSTOMER_URL}/{customer_id}", headers=HEADERS)
        response.raise_for_status()
        return response.json().get("email")
    except httpx.HTTPStatusError as e:
        print(f"⚠️ Failed to fetch customer {customer_id}: {e}")
        return None


async def fetch_and_store_charges(db: AsyncSession):
    params = {
        "limit": 100  # Max allowed by Stripe
    }

    async with httpx.AsyncClient() as client:
        while True:
            resp = await client.get(STRIPE_API_URL, headers=HEADERS, params=params)
            resp.raise_for_status()
            data = resp.json()

            for charge in data.get("data", []):
                # Basic charge fields
                charge_id = charge["id"]
                amount = charge["amount"]
                currency = charge["currency"]
                status = charge["status"]
                created = datetime.fromtimestamp(charge["created"])

                # Attempt to get customer info
                customer_id = charge.get("customer")
                customer_email = charge.get("billing_details", {}).get("email")

                if not customer_email and customer_id:
                    customer_email = await fetch_customer_email(customer_id, client)

                # Skip if charge already exists
                result = await db.execute(select(StripePayment).where(StripePayment.id == charge_id))
                if result.scalar():
                    continue

                # Store the charge
                payment = StripePayment(
                    id=charge_id,
                    amount=amount,
                    currency=currency,
                    status=status,
                    customer_id=customer_id,
                    customer_email=customer_email,
                    created_at=created
                )
                db.add(payment)

            await db.commit()

            # Handle pagination
            if not data.get("has_more"):
                break

            last_charge_id = data["data"][-1]["id"]
            params["starting_after"] = last_charge_id