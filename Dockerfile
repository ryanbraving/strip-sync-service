# Dockerfile
FROM python:3.13-slim

# Set working directory
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app code
COPY ./app ./app
COPY .env .

# Expose port
EXPOSE 8000

# Run FastAPI with uvicorn
#CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
CMD ["sh", "-c", "sleep 2 && uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"]