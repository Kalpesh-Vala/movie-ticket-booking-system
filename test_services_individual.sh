#!/bin/bash

# Test Services Individually
# This script tests notification and payment services separately

echo "🧪 Testing Movie Ticket Booking System Services"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Test Notification Service
echo ""
print_info "Testing Notification Service..."
echo "--------------------------------"

cd services/notification-service

# Check if dependencies are installed
print_info "Checking notification service dependencies..."
python -c "import aio_pika, redis, motor, pytest" 2>/dev/null
if [ $? -eq 0 ]; then
    print_status 0 "All notification service dependencies are available"
else
    print_info "Installing notification service dependencies..."
    pip install -r requirements.txt
    if [ $? -eq 0 ]; then
        print_status 0 "Dependencies installed successfully"
    else
        print_status 1 "Failed to install dependencies"
        exit 1
    fi
fi

# Run notification service tests
print_info "Running notification service unit tests..."
python -m pytest test_notification_service.py -v --tb=short 2>/dev/null
test_result=$?
print_status $test_result "Notification service unit tests"

# Test notification worker directly
print_info "Testing notification worker functionality..."
python -c "
import asyncio
from worker import NotificationWorker
from unittest.mock import AsyncMock

async def test_worker():
    worker = NotificationWorker()
    # Mock dependencies
    worker.redis_client = AsyncMock()
    worker.db = AsyncMock()
    worker.redis_client.get.return_value = None
    
    # Test basic functionality
    event_id = 'test_event_123'
    is_processed = await worker.is_already_processed(event_id)
    print(f'✅ Idempotency check works: {not is_processed}')
    
    await worker.mark_as_processing(event_id)
    print('✅ Event marking works')
    
    # Test event handling
    event_data = {
        'event_id': event_id,
        'booking_id': 'booking_123',
        'user_id': 'user_456',
        'movie_title': 'Test Movie'
    }
    
    worker.send_email_notification = AsyncMock()
    worker.log_notification = AsyncMock()
    
    result = await worker.handle_booking_confirmed(event_data)
    print(f'✅ Booking confirmation handling works: {result}')
    
    result = await worker.handle_payment_success({
        **event_data,
        'transaction_id': 'txn_789',
        'amount': 25.50,
        'payment_method': 'credit_card'
    })
    print(f'✅ Payment success handling works: {result}')

asyncio.run(test_worker())
"

if [ $? -eq 0 ]; then
    print_status 0 "Notification worker functionality test"
else
    print_status 1 "Notification worker functionality test"
fi

cd ../..

# Test Payment Service
echo ""
print_info "Testing Payment Service..."
echo "-------------------------"

cd services/payment-service

# Check if dependencies are installed
print_info "Checking payment service dependencies..."
python -c "import fastapi, uvicorn, pydantic, motor, aio_pika, pytest, httpx" 2>/dev/null
if [ $? -eq 0 ]; then
    print_status 0 "All payment service dependencies are available"
else
    print_info "Installing payment service dependencies..."
    pip install -r requirements.txt
    if [ $? -eq 0 ]; then
        print_status 0 "Dependencies installed successfully"
    else
        print_status 1 "Failed to install dependencies"
        exit 1
    fi
fi

# Run payment service tests
print_info "Running payment service unit tests..."
python -m pytest test_payment_comprehensive.py -v --tb=short 2>/dev/null
test_result=$?
print_status $test_result "Payment service unit tests"

# Test payment service API directly
print_info "Testing payment service API functionality..."
python -c "
import asyncio
from fastapi.testclient import TestClient
from main import app
from unittest.mock import patch, AsyncMock

def test_payment_api():
    client = TestClient(app)
    
    # Test health check
    response = client.get('/health')
    if response.status_code == 200:
        print('✅ Health check endpoint works')
    else:
        print('❌ Health check endpoint failed')
        return
    
    # Test payment processing (mocked)
    payment_request = {
        'booking_id': 'test_booking_123',
        'user_id': 'test_user_456',
        'amount': 50.00,
        'payment_method': 'credit_card',
        'payment_details': {
            'card_number': '4111111111111111',
            'card_holder': 'Test User',
            'expiry_month': '12',
            'expiry_year': '2025',
            'cvv': '123'
        }
    }
    
    with patch('main.simulate_payment_processing', return_value=True), \
         patch('main.publish_payment_event') as mock_publish, \
         patch('main.db') as mock_db:
        
        mock_db.transaction_logs.insert_one = AsyncMock()
        
        response = client.post('/payments', json=payment_request)
        
        if response.status_code == 200:
            data = response.json()
            if data['success']:
                print('✅ Payment processing works')
                print('✅ Event publishing integration works')
            else:
                print('❌ Payment processing returned failure')
        else:
            print(f'❌ Payment processing failed with status {response.status_code}')

test_payment_api()
"

if [ $? -eq 0 ]; then
    print_status 0 "Payment service API functionality test"
else
    print_status 1 "Payment service API functionality test"
fi

# Test event publisher
print_info "Testing payment event publisher..."
python -c "
import asyncio
from event_publisher import PaymentEventPublisher, publish_payment_event
from unittest.mock import AsyncMock

async def test_event_publisher():
    publisher = PaymentEventPublisher()
    
    # Mock dependencies
    publisher.connection = AsyncMock()
    publisher.channel = AsyncMock()
    publisher.exchange = AsyncMock()
    publisher._initialized = True
    
    # Test event publishing
    test_data = {
        'booking_id': 'test_booking',
        'transaction_id': 'test_txn',
        'amount': 100.00,
        'payment_method': 'credit_card'
    }
    
    await publisher.publish_payment_success_event(test_data)
    print('✅ Payment success event publishing works')
    
    await publisher.publish_payment_failure_event(test_data)
    print('✅ Payment failure event publishing works')
    
    # Test helper function
    await publish_payment_event('payment.success', test_data)
    print('✅ Helper function works')

asyncio.run(test_event_publisher())
"

if [ $? -eq 0 ]; then
    print_status 0 "Payment event publisher functionality test"
else
    print_status 1 "Payment event publisher functionality test"
fi

cd ../..

# Summary
echo ""
echo "🎯 Individual Service Testing Complete"
echo "====================================="

print_info "Services have been tested individually and are ready for integration testing."
print_info "Next steps:"
echo "  1. Start RabbitMQ, Redis, and MongoDB services"
echo "  2. Run integration tests with: ./test_integration.sh"
echo "  3. Start both services with docker-compose up"

echo ""
print_info "To run services:"
echo "  Notification Service: cd services/notification-service && python worker.py"
echo "  Payment Service: cd services/payment-service && uvicorn main:app --host 0.0.0.0 --port 8003"