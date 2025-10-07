#!/bin/bash

# Booking Service Startup Script

echo "🎬 Starting Movie Ticket Booking Service..."

# Set environment variables if .env file exists
if [ -f .env ]; then
    echo "📝 Loading environment variables from .env"
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check if Python virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo "⚠️  Warning: No virtual environment detected"
    echo "💡 Consider activating your virtual environment first"
fi

# Check if required services are running
echo "🔍 Checking required services..."

# Check MongoDB
if ! nc -z localhost 27017 2>/dev/null; then
    echo "❌ MongoDB is not running on localhost:27017"
    echo "💡 Start MongoDB using: docker-compose up -d mongodb"
fi

# Check RabbitMQ
if ! nc -z localhost 5672 2>/dev/null; then
    echo "❌ RabbitMQ is not running on localhost:5672"
    echo "💡 Start RabbitMQ using: docker-compose up -d rabbitmq"
fi

# Check if Cinema Service is running (gRPC)
if ! nc -z localhost 50051 2>/dev/null; then
    echo "⚠️  Cinema Service is not running on localhost:50051"
    echo "💡 Start Cinema Service first for full functionality"
fi

# Check if User Service is running
if ! curl -s http://localhost:8001/health > /dev/null 2>&1; then
    echo "⚠️  User Service is not running on localhost:8001"
    echo "💡 Start User Service first for full functionality"
fi

# Check if Payment Service is running
if ! curl -s http://localhost:8002/health > /dev/null 2>&1; then
    echo "⚠️  Payment Service is not running on localhost:8002"
    echo "💡 Start Payment Service first for full functionality"
fi

echo ""
echo "🚀 Starting Booking Service..."
echo "📡 GraphQL endpoint will be available at: http://localhost:8000/graphql"
echo "🏥 Health check endpoint: http://localhost:8000/health"
echo ""

# Start the service
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload