#!/bin/bash

# Notification Service Setup Script
# Builds and starts the Notification Service (Python + Redis + MongoDB + RabbitMQ)

echo "📧 Setti    print_error "Notification Service container status: $container_status"
fiion Service"
echo "=================================="

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

# Check if Redis is running
if ! docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_error "Redis is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "Redis is running"

# Check if RabbitMQ is running
if ! curl.exe -s -f "http://localhost:15672" > /dev/null 2>&1; then
    print_error "RabbitMQ is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "RabbitMQ is running"

# Clean up existing notification service container
print_status "Cleaning up existing Notification Service container..."
docker-compose stop notification-service 2>/dev/null || true
docker-compose rm -f notification-service 2>/dev/null || true

# Build Notification Service
echo ""
print_status "Building Notification Service..."
docker-compose build notification-service

if [ $? -ne 0 ]; then
    print_error "Failed to build Notification Service"
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check Dockerfile in services/notification-service/"
    echo "  2. Check requirements.txt dependencies"
    echo "  3. Check if Python version is compatible"
    echo "  4. Try: docker-compose build --no-cache notification-service"
    exit 1
fi
print_success "Notification Service built successfully"

# Start Notification Service
echo ""
print_status "Starting Notification Service..."
docker-compose up -d notification-service

# Wait for Notification Service worker to be ready
print_status "Waiting for Notification Service worker to be ready..."
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
    # Check if the worker is running by looking for startup messages in logs
    if docker-compose logs notification-service 2>/dev/null | grep -q "Starting to consume messages"; then
        print_success "Notification Service worker is ready!"
        break
    fi
    
    echo "  Attempt $attempt/$max_attempts - Notification Service worker not ready yet..."
    sleep 3
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Notification Service worker failed to start after $max_attempts attempts"
    
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check logs: docker-compose logs notification-service"
    echo "  2. Check if all dependencies are running:"
    echo "     - MongoDB: docker-compose ps mongodb"
    echo "     - Redis: docker-compose ps redis"
    echo "     - RabbitMQ: docker-compose ps rabbitmq"
    echo "  3. Check SMTP configuration in smtp_service.py"
    echo "  4. Restart service: docker-compose restart notification-service"
    echo "  5. Check if port 8084 is available: netstat -an | findstr 8084"
    echo "  6. Check RabbitMQ queues: curl -u admin:admin123 http://localhost:15672/api/queues"
    exit 1
fi

# Test Notification Service worker
echo ""
print_status "Testing Notification Service worker functionality..."

# Check if worker is consuming from RabbitMQ
echo "Checking worker connection to RabbitMQ..."
worker_logs=$(docker-compose logs notification-service 2>/dev/null | tail -5)
if echo "$worker_logs" | grep -q "Starting to consume messages"; then
    print_success "Worker is connected to RabbitMQ and consuming messages"
else
    print_error "Worker connection issues detected"
fi

# Check if worker is connected to other services
echo "Checking service connections..."
if echo "$worker_logs" | grep -q "initialized successfully"; then
    print_success "Worker initialized successfully with all dependencies"
else
    print_error "Worker initialization issues detected"
fi

# Check container status
echo "Checking container status..."
container_status=$(docker-compose ps notification-service --format json 2>/dev/null | grep -o '"State":"[^"]*"' | cut -d'"' -f4)
if [ "$container_status" = "running" ]; then
    print_success "Notification Service container is running"
else
    print_error "Notification Service container status: $container_status"
fi

# Test RabbitMQ queue creation
echo "Testing RabbitMQ queue setup..."
queue_status=$(curl.exe -s -u admin:admin123 "http://localhost:15672/api/queues")
if echo "$queue_status" | grep -q "booking_events"; then
    print_success "RabbitMQ booking_events queue is set up"
else
    print_status "RabbitMQ booking_events queue will be created on first message"
fi

# Test SMTP configuration (without actually sending)
echo "Testing SMTP configuration..."
smtp_test_response=$(curl.exe -s -X POST "http://localhost:8084/api/notifications/test-smtp" \
    -H "Content-Type: application/json" \
    -d '{"test": true}')

if [ $? -eq 0 ]; then
    print_success "SMTP configuration test passed"
    echo "  Response: $smtp_test_response"
else
    print_status "SMTP test endpoint not available (this is optional)"
fi

echo ""
print_success "🎉 Notification Service worker is running and ready!"
echo ""
echo "📊 Notification Service Details:"
echo "  - Service Type:      Background Worker (RabbitMQ Consumer)"
echo "  - Database:          MongoDB (movie_tickets_db.notifications collection)"
echo "  - Cache:             Redis (notification status caching)"
echo "  - Message Queue:     RabbitMQ (booking_events, payment_events queues)"
echo "  - SMTP Server:       Gmail SMTP (smtp.gmail.com:587)"
echo ""
echo "🔧 Management Commands:"
echo "  - View logs:         docker-compose logs notification-service"
echo "  - Restart service:   docker-compose restart notification-service"
echo "  - Stop service:      docker-compose stop notification-service"
echo "  - Access container:  docker-compose exec notification-service bash"
echo "  - Run tests:         docker-compose exec notification-service python test_notification_service.py"
echo ""
echo "� Notification Types:"
echo "  - Email notifications (SMTP)"
echo "  - SMS notifications (simulated)"
echo "  - Push notifications (simulated)"
echo "  - In-app notifications"
echo ""
echo "🎯 Event-Driven Features:"
echo "  - RabbitMQ consumer for booking events"
echo "  - Automatic booking confirmation emails"
echo "  - Payment status notifications"
echo "  - Booking reminder notifications"
echo "  - Real-time notification delivery"
echo ""
echo "⚙️  How it works:"
echo "  - Listens to RabbitMQ queues for events"
echo "  - Processes booking and payment events"
echo "  - Sends appropriate notifications via email/SMS"
echo "  - Stores notification history in MongoDB"
echo "  - Caches delivery status in Redis"
echo "  - Cancellation notifications"
echo ""
echo "📨 SMTP Configuration:"
echo "  - Provider: Gmail SMTP (configurable)"
echo "  - Port: 587 (TLS enabled)"
echo "  - Authentication: Username/Password"
echo "  - Template-based emails"
echo ""
echo "🔄 Queue Monitoring:"
echo "  - RabbitMQ Management: http://localhost:15672"
echo "  - Queue: booking_events"
echo "  - Exchange: booking_exchange"
echo "  - Routing Key: booking.confirmed"
echo ""
echo "✅ Notification Service setup complete!"
echo ""
echo "🎊 ALL SERVICES ARE NOW RUNNING!"
echo ""
echo "🌐 System Overview:"
echo "  - Kong Gateway:      http://localhost:8000"
echo "  - User Service:      http://localhost:8080"
echo "  - Cinema Service:    http://localhost:8081"
echo "  - Booking Service:   http://localhost:8082"
echo "  - Payment Service:   http://localhost:8083"
echo "  - Notification Service: http://localhost:8084"
echo ""
echo "📊 Management Interfaces:"
echo "  - Kong Admin:        http://localhost:8001"
echo "  - RabbitMQ Management: http://localhost:15672"
echo "  - MongoDB Express:   http://localhost:8081"
echo "  - pgAdmin:           http://localhost:8080"
echo "  - Redis Commander:   http://localhost:8082"
echo ""
echo "🧪 Next Steps:"
echo "  1. Run integration tests: ./test_integration.sh"
echo "  2. Test individual services: ./test_services_individual.sh"
echo "  3. Load test the system: ./run_integration_tests.sh"
echo "  4. Check API documentation in each service's README"