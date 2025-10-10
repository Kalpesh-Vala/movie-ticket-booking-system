# Booking Service Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Generate gRPC code from proto files
RUN mkdir -p ./app/grpc_generated
RUN python -m grpc_tools.protoc \
    --proto_path=. \
    --python_out=./app/grpc_generated \
    --grpc_python_out=./app/grpc_generated \
    cinema.proto

# Expose port
EXPOSE 8004

# Run the application
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8004}"]