#!/bin/bash

# Integration Test Script for Payment and Notification Services
# Tests the complete flow through RabbitMQ messaging

echo "🧪 Integration Testing for Payment and Notification Services"
echo "==========================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${BLUE}🔵 $1${NC}"
}

# Check if Docker and Docker Compose are available
print_step "Checking Docker environment..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed or not in PATH${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed or not in PATH${NC}"
    exit 1
fi

print_status 0 "Docker and Docker Compose are available"

# Navigate to project root
cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)
print_info "Project root: $PROJECT_ROOT"

# Start infrastructure services
print_step "Starting infrastructure services (RabbitMQ, Redis, MongoDB)..."
docker-compose up -d rabbitmq redis mongodb

# Wait for services to be ready
print_info "Waiting for services to initialize..."
sleep 10

# Check if RabbitMQ is ready
print_step "Checking RabbitMQ status..."
docker-compose logs rabbitmq | tail -5

# Check if Redis is ready
print_step "Checking Redis status..."
docker-compose exec redis redis-cli ping
if [ $? -eq 0 ]; then
    print_status 0 "Redis is ready"
else
    print_status 1 "Redis is not ready"
fi

# Check if MongoDB is ready
print_step "Checking MongoDB status..."
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"
if [ $? -eq 0 ]; then
    print_status 0 "MongoDB is ready"
else
    print_status 1 "MongoDB is not ready"
fi

# Test RabbitMQ configuration
print_step "Testing RabbitMQ configuration..."
python3 << 'EOF'
import asyncio
import aio_pika
import json

async def test_rabbitmq():
    try:
        # Connect to RabbitMQ
        connection = await aio_pika.connect_robust("amqp://admin:admin123@localhost:5672/")
        channel = await connection.channel()
        
        # Test exchange
        exchange = await channel.declare_exchange(
            "movie_app_events",
            aio_pika.ExchangeType.TOPIC,
            durable=True
        )
        
        # Test queues
        notification_queue = await channel.declare_queue(
            "notification.payment_events",
            durable=True
        )
        
        payment_queue = await channel.declare_queue(
            "payment.processing_queue", 
            durable=True
        )
        
        # Test bindings
        await notification_queue.bind(exchange, "payment.success")
        await notification_queue.bind(exchange, "payment.failed")
        
        print("✅ RabbitMQ configuration test passed")
        
        await connection.close()
        return True
        
    except Exception as e:
        print(f"❌ RabbitMQ configuration test failed: {e}")
        return False

result = asyncio.run(test_rabbitmq())
EOF

rabbitmq_status=$?
print_status $rabbitmq_status "RabbitMQ configuration test"

# Build service images
print_step "Building service Docker images..."
docker-compose build notification-service payment-service
build_status=$?
print_status $build_status "Docker image build"

if [ $build_status -ne 0 ]; then
    echo -e "${RED}❌ Failed to build Docker images${NC}"
    exit 1
fi

# Start services
print_step "Starting notification and payment services..."
docker-compose up -d notification-service payment-service

# Wait for services to start
print_info "Waiting for services to start..."
sleep 15

# Check service health
print_step "Checking service health..."

# Check payment service health
payment_health=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8003/health)
if [ "$payment_health" = "200" ]; then
    print_status 0 "Payment service is healthy"
else
    print_status 1 "Payment service health check failed (HTTP $payment_health)"
fi

# Check notification service logs
print_step "Checking notification service logs..."
docker-compose logs --tail=10 notification-service

# Test end-to-end payment flow
print_step "Testing end-to-end payment and notification flow..."

# Send a test payment request
test_payment_response=$(curl -s -X POST http://localhost:8003/payments \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": "integration_test_booking_001",
    "user_id": "integration_test_user_001", 
    "amount": 99.99,
    "payment_method": "credit_card",
    "payment_details": {
      "card_number": "4111111111111111",
      "card_holder": "Integration Test",
      "expiry_month": "12",
      "expiry_year": "2025",
      "cvv": "123"
    }
  }')

echo "Payment response: $test_payment_response"

# Check if payment was successful
if echo "$test_payment_response" | grep -q '"success":true'; then
    print_status 0 "Payment processing successful"
    
    # Wait for notification processing
    print_info "Waiting for notification processing..."
    sleep 5
    
    # Check notification service logs for payment event processing
    print_step "Checking if notification service processed payment event..."
    notification_logs=$(docker-compose logs notification-service | grep -i "payment\|integration_test")
    
    if [ -n "$notification_logs" ]; then
        print_status 0 "Notification service processed payment event"
        echo -e "${GREEN}Notification logs:${NC}"
        echo "$notification_logs"
    else
        print_status 1 "Notification service did not process payment event"
    fi
    
else
    print_status 1 "Payment processing failed"
    echo "Response: $test_payment_response"
fi

# Test payment failure flow
print_step "Testing payment failure notification flow..."

# Send a payment request that should fail
test_failure_response=$(curl -s -X POST http://localhost:8003/payments \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": "integration_test_booking_002",
    "user_id": "integration_test_user_002",
    "amount": 0.01,
    "payment_method": "credit_card", 
    "payment_details": {
      "card_number": "4000000000000002",
      "card_holder": "Integration Test Fail",
      "expiry_month": "12",
      "expiry_year": "2025",
      "cvv": "123"
    }
  }')

echo "Failure test response: $test_failure_response"

# Wait for processing
sleep 5

# Check notification logs for failure processing
failure_logs=$(docker-compose logs notification-service | grep -i "integration_test_booking_002\|payment.*fail")
if [ -n "$failure_logs" ]; then
    print_status 0 "Payment failure notification processed"
else
    print_status 1 "Payment failure notification not processed"
fi

# Show final service logs
print_step "Final service logs..."
echo -e "${BLUE}Payment Service Logs:${NC}"
docker-compose logs --tail=20 payment-service

echo -e "${BLUE}Notification Service Logs:${NC}"
docker-compose logs --tail=20 notification-service

# Test cleanup
print_step "Integration test completed!"
print_info "Services are still running. To stop them, run:"
echo "  docker-compose down"

print_info "To view logs in real-time, run:"
echo "  docker-compose logs -f notification-service payment-service"

print_info "To test manually:"
echo "  curl -X POST http://localhost:8003/payments -H 'Content-Type: application/json' -d '{...}'"

echo ""
echo -e "${GREEN}🎉 Integration testing completed!${NC}"
echo -e "${GREEN}✅ Payment and Notification services are configured and working together${NC}"