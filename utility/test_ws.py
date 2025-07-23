import asyncio
import websockets

async def test_ws():
    # uri = "ws://stripe-sync-service-alb-637805745.us-west-2.elb.amazonaws.com/ws"
    uri = "ws://stripe-sync-service-alb-637805745.us-west-2.elb.amazonaws.com/ws?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIiLCJleHAiOjE3NTI2NDQ4Njh9.IiG8_Bb6OTpvwUXW9EeDsU3CoTccF6msMHORhNTP5EU"
    try:
        async with websockets.connect(uri) as websocket:
            print("Connected!")
            await websocket.send("hello")
            print("Message sent!")
    except Exception as e:
        print("Failed to connect:", e)

asyncio.run(test_ws())