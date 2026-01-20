# Use Python base image
FROM python:3.9-slim

# Install system dependencies for building packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libsasl2-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/
COPY models/ ./models/

# Expose port for API
EXPOSE 5000

# Run the app
CMD ["python", "src/app.py"]