FROM python:3.12-slim

# Set up working directory
WORKDIR /code

# Copy files
COPY requirements.txt .
COPY app/ ./app/
COPY textcat_goemotions/ ./textcat_goemotions/

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Environment variables
# Pass SERVICE_NAME as a build argument and set it as an environment variable
ARG SERVICE_NAME
ENV SERVICE_NAME=${SERVICE_NAME}

# Expose FastAPI port
EXPOSE 80

# Command to run the FastAPI app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "80"]
