# Dockerfile
FROM python:3.13-slim

# Set working directory
WORKDIR /app
ENV PYTHONUNBUFFERED=1

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY utility ./utility

# Copy Alembic migration files and config
COPY alembic.ini .
COPY migrations ./migrations

# Copy app code
COPY ./app ./app

# Expose port for FastAPI
EXPOSE 8000

# Default command: run FastAPI app
CMD ["sh", "-c", "sleep 3 && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"]