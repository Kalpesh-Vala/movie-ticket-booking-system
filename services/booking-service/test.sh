#!/bin/bash

# Simple test script for the booking service

echo "🎬 Testing Movie Ticket Booking Service..."

cd /home/kalpesh/github/movie-ticket-booking-system/services/booking-service

echo "🧪 Running unit tests..."
/home/kalpesh/github/movie-ticket-booking-system/.venv/bin/python -m pytest tests/test_models.py tests/test_grpc_client.py -v

echo ""
echo "📡 Testing API endpoints..."

# Test with mocked dependencies
echo "Starting server with mocked dependencies..."
timeout 3s /home/kalpesh/github/movie-ticket-booking-system/.venv/bin/python -c "
import uvicorn
from unittest.mock import patch, AsyncMock

with patch('app.database.connect_to_mongo'), \
     patch('app.event_publisher.EventPublisher'):
    from app.main import app
    uvicorn.run(app, host='127.0.0.1', port=8000, log_level='error')
" &

SERVER_PID=$!
sleep 2

# Test health endpoint
echo "Testing health endpoint..."
if curl -s http://127.0.0.1:8000/health > /dev/null 2>&1; then
    echo "✅ Health endpoint works!"
    curl -s http://127.0.0.1:8000/health | python3 -m json.tool
else
    echo "❌ Health endpoint failed"
fi

# Test root endpoint
echo ""
echo "Testing root endpoint..."
if curl -s http://127.0.0.1:8000/ > /dev/null 2>&1; then
    echo "✅ Root endpoint works!"
    curl -s http://127.0.0.1:8000/ | python3 -m json.tool
else
    echo "❌ Root endpoint failed"
fi

# Stop the server
kill $SERVER_PID 2>/dev/null

echo ""
echo "🎉 Basic service test completed!"
echo "💡 To run with real dependencies, ensure MongoDB and RabbitMQ are running"
echo "💡 Then use: ./start.sh"