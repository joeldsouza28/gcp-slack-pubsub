FROM python:3.13-slim

WORKDIR /app

COPY fastapi-app/requirements.txt /app/requirements.txt


RUN pip install -r requirements.txt

COPY fastapi-app /app/

EXPOSE 8000

ENTRYPOINT ["/bin/bash", "-c",  "gunicorn -w 4 -b 0.0.0.0:8000 -k uvicorn.workers.UvicornWorker main:app" ]