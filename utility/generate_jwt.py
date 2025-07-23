'''
You can generate a test token using this script.
Then test with:
wscat -c "wss://your-alb-domain/ws?token=PASTE_TOKEN_HERE"
Or use https://hoppscotch.io/realtime/websocket
'''
import jwt
import boto3
from datetime import datetime, timedelta, UTC
import os

JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY")

# def get_secret_from_ssm(param_name: str, region: str = "us-west-2") -> str:
#     ssm = boto3.client("ssm", region_name=region)
#     response = ssm.get_parameter(Name=param_name, WithDecryption=True)
#     return response["Parameter"]["Value"]
#
# JWT_SECRET_KEY = get_secret_from_ssm("/stripe-sync-service/jwt_secret_key") or None

def generate_token(user_id: str) -> str:
    payload = {
        "sub": user_id,
        "exp": datetime.now(UTC) + timedelta(hours=24),
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm="HS256")

print(generate_token("test-user"))