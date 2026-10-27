# AION API: FastAPI + SWI-Prolog in one image.
FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends swi-prolog-nox \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY *.pl app.py prolog_bridge.py ./

# Hosts such as Render and Fly.io provide PORT.
ENV PORT=8000
EXPOSE 8000
CMD ["sh", "-c", "uvicorn app:app --host 0.0.0.0 --port ${PORT}"]
