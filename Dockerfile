FROM python:3.12-slim

# Set up working directory
WORKDIR /code

# Copy files
COPY requirements.txt .
COPY app/ ./app/
COPY textcat_goemotions/ ./textcat_goemotions/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose FastAPI port
EXPOSE 8080

# Command to run the FastAPI app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
