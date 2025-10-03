from fastapi import FastAPI, Request, Response
import socket
import base64
import httpx
import os


app = FastAPI()


SLACK_URL = os.getenv("SLACK_WEBHOOK_URL")


@app.get("/")
def index():
    return f"Hello from dockerized fastapi {socket.gethostname()}"


async def pubsub_push(request: Request):
    try:
        envelope = await request.json()
        msg = envelope["message"]["data"]
        decoded = base64.b64decode(msg).decode("utf-8")

        payload = {"text": f"⚠️ CI/CD Event: {decoded}"}
        async with httpx.AsyncClient() as client:
            r = await client.post(SLACK_URL, json=payload)
            r.raise_for_status()

        return {"status": "ok"}
    except Exception as e:
        # log error
        print("Error:", e)
        # Returning non-200 triggers retry
        return Response(status_code=500)
