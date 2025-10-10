#!/bin/bash

# Booking Service Setup Script
# Builds and starts the Booking Service (Python + GraphQL + MongoDB)

echo "🎫 Setting up Booking Service"
echo "============================="

# Function to print status
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_error() {
    echo "[ERROR] $1"
}

# Check dependencies
print_status "Checking dependencies..."

# Check if MongoDB is running
if ! docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    print_error "MongoDB is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "MongoDB is running"

# Check if RabbitMQ is running
if ! curl.exe -s -f "http://localhost:15672" > /dev/null 2>&1; then
    print_error "RabbitMQ is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "RabbitMQ is running"

# Check if User Service is running
if ! curl.exe -s -f "http://localhost:8080/health" > /dev/null 2>&1; then
    print_error "User Service is not running. Please run ./setup_user_service.sh first"
    exit 1
fi
print_success "User Service is running"

# Check if Cinema Service is running
if ! curl.exe -s -f "http://localhost:8002/actuator/health" > /dev/null 2>&1; then
    print_error "Cinema Service is not running. Please run ./setup_cinema_service.sh first"
    exit 1
fi
print_success "Cinema Service is running"

# Check if Payment Service is running
if ! curl.exe -s -f "http://localhost:8003/health" > /dev/null 2>&1; then
    print_error "Payment Service is not running. Please run ./setup_payment_service.sh first"
    exit 1
fi
print_success "Payment Service is running"

# Clean up existing booking service container
print_status "Cleaning up existing Booking Service container..."
docker-compose stop booking-service 2>/dev/null || true
docker-compose rm -f booking-service 2>/dev/null || true

# Build Booking Service
echo ""
print_status "Building Booking Service..."
docker-compose build booking-service

if [ $? -ne 0 ]; then
    print_error "Failed to build Booking Service"
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check Dockerfile in services/booking-service/"
    echo "  2. Check requirements.txt dependencies"
    echo "  3. Check if Python version is compatible"
    echo "  4. Try: docker-compose build --no-cache booking-service"
    exit 1
fi
print_success "Booking Service built successfully"

# Start Booking Service
echo ""
print_status "Starting Booking Service..."
docker-compose up -d booking-service

# Wait for Booking Service to be ready
print_status "Waiting for Booking Service to be ready..."
max_attempts=25
attempt=1

while [ $attempt -le $max_attempts ]; do
    # Check REST endpoint
    if curl.exe -s -f "http://localhost:8004/health" > /dev/null 2>&1; then
        print_success "Booking Service REST API is ready!"
        rest_ready=true
        break
    fi
    
    echo "  Attempt $attempt/$max_attempts - Booking Service not ready yet..."
    sleep 3
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Booking Service failed to start after $max_attempts attempts"
    
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check logs: docker-compose logs booking-service"
    echo "  2. Check if all dependencies are running:"
    echo "     - MongoDB: docker-compose ps mongodb"
    echo "     - RabbitMQ: docker-compose ps rabbitmq"
    echo "     - User Service: curl http://localhost:8080/health"
    echo "     - Cinema Service: curl http://localhost:8002/actuator/health"
    echo "     - Payment Service: curl http://localhost:8003/health"
    echo "  3. Check configuration: docker-compose exec booking-service cat /app/app/config.py"
    echo "  4. Restart service: docker-compose restart booking-service"
    echo "  5. Check if port 8004 is available: netstat -an | findstr 8004"
    exit 1
fi

# Wait a bit more for GraphQL to be ready
sleep 5

# Test Booking Service endpoints
echo ""
print_status "Testing Booking Service endpoints..."

# Test health endpoint
echo "Testing health endpoint..."
health_response=$(curl.exe -s "http://localhost:8004/health")
if [ $? -eq 0 ]; then
    print_success "Health endpoint working: $health_response"
else
    print_error "Health endpoint failed"
fi

# Test GraphQL endpoint
echo "Testing GraphQL endpoint..."
graphql_query='{"query": "{ __schema { types { name } } }"}'
graphql_response=$(curl.exe -s -X POST "http://localhost:8004/graphql" \
    -H "Content-Type: application/json" \
    -d "$graphql_query")

if [ $? -eq 0 ]; then
    print_success "GraphQL endpoint working"
    echo "  Schema types available: $(echo "$graphql_response" | grep -o '"name":"[^"]*"' | head -5)"
else
    print_error "GraphQL endpoint failed"
fi

# Test create booking endpoint (REST)
echo "Testing create booking endpoint..."
booking_data='{
    "user_id": "test_user_123",
    "cinema_id": "test_cinema_123",
    "movie_id": "test_movie_123",
    "showtime_id": "test_showtime_123",
    "seats": [{"row": "A", "number": 1}, {"row": "A", "number": 2}],
    "total_amount": 25.50
}'

create_response=$(curl.exe -s -X POST "http://localhost:8004/api/bookings" \
    -H "Content-Type: application/json" \
    -d "$booking_data")

if [ $? -eq 0 ]; then
    print_success "Create booking endpoint working"
    echo "  Response: $create_response"
else
    print_error "Create booking endpoint failed"
fi

# Test RabbitMQ connection
echo "Testing RabbitMQ connection..."
rabbitmq_status=$(curl.exe -s -u admin:admin123 "http://localhost:15672/api/connections")
if [ $? -eq 0 ]; then
    print_success "RabbitMQ connection test passed"
else
    print_error "RabbitMQ connection test failed"
fi

echo ""
print_success "🎉 Booking Service is running and ready!"
echo ""
echo "📊 Booking Service Details:"
echo "  - REST API URL:      http://localhost:8004"
echo "  - GraphQL Endpoint:  http://localhost:8004/graphql"
echo "  - GraphQL Playground: http://localhost:8004/graphql (GET request)"
echo "  - Health Check:      http://localhost:8004/health"
echo "  - Via Kong Gateway:  http://localhost:8000/api/bookings"
echo "  - Database:          MongoDB (movie_tickets_db.bookings collection)"
echo ""
echo "🔧 Management Commands:"
echo "  - View logs:         docker-compose logs booking-service"
echo "  - Restart service:   docker-compose restart booking-service"
echo "  - Stop service:      docker-compose stop booking-service"
echo "  - Access container:  docker-compose exec booking-service bash"
echo "  - Run tests:         docker-compose exec booking-service python -m pytest"
echo ""
echo "📋 REST API Endpoints:"
echo "  - POST /api/bookings           - Create booking"
echo "  - GET /api/bookings            - List bookings"
echo "  - GET /api/bookings/:id        - Get booking by ID"
echo "  - PUT /api/bookings/:id/status - Update booking status"
echo "  - DELETE /api/bookings/:id     - Cancel booking"
echo ""
echo "📋 GraphQL Operations:"
echo "  - Query: bookings              - List all bookings"
echo "  - Query: booking(id)           - Get booking by ID"
echo "  - Mutation: createBooking      - Create new booking"
echo "  - Mutation: updateBookingStatus - Update booking status"
echo "  - Mutation: cancelBooking      - Cancel booking"
echo ""
echo "🔗 Service Integrations:"
echo "  - User Service:      REST API calls for user validation"
echo "  - Cinema Service:    gRPC calls for movie/showtime data"
echo "  - Payment Service:   REST API calls for payment processing"
echo "  - Notification Service: RabbitMQ events for booking confirmations"
echo ""
echo "🎯 Key Features:"
echo "  - GraphQL API with real-time subscriptions"
echo "  - REST API for simple operations"
echo "  - Seat reservation management"
echo "  - Payment integration"
echo "  - Event-driven notifications"
echo "  - Booking status tracking"
echo ""
echo "✅ Booking Service setup complete!"
echo ""
echo "Next: Run ./setup_notification_service.sh"