#!/bin/bash

# 🚀 Quick Setup and Test Guide
# Run this script to quickly set up and test payment and notification services

echo "🎬 Movie Ticket Booking System - Payment & Notification Services"
echo "================================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if MongoDB is running
    if mongosh --eval "db.runCommand('ping')" --quiet > /dev/null 2>&1; then
        print_success "MongoDB is running"
    else
        print_error "MongoDB is not running. Please start MongoDB first."
        exit 1
    fi
    
    # Check if Redis is running  
    if redis-cli ping > /dev/null 2>&1; then
        print_success "Redis is running"
    else
        print_error "Redis is not running. Please start Redis first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Setup payment service
setup_payment_service() {
    print_status "Setting up Payment Service..."
    
    cd services/payment-service/
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    ./venv/bin/pip install -q -r requirements.txt
    print_success "Payment service setup complete"
    cd ../../
}

# Setup notification service
setup_notification_service() {
    print_status "Setting up Notification Service..."
    
    cd services/notification-service/
    
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    ./venv/bin/pip install -q -r requirements.txt
    print_success "Notification service setup complete"
    cd ../../
}

# Start payment service
start_payment_service() {
    print_status "Starting Payment Service..."
    
    # Kill any existing payment service on port 8003
    existing_pid=$(lsof -ti :8003 2>/dev/null)
    if [ ! -z "$existing_pid" ]; then
        print_warning "Killing existing payment service (PID: $existing_pid)"
        kill $existing_pid 2>/dev/null || true
        sleep 2
    fi
    
    cd services/payment-service/
    PYTHONPATH=./venv/lib/python3.12/site-packages \
    MONGODB_URI=mongodb://localhost:27017 \
    ./venv/bin/python3 main.py > payment_service.log 2>&1 &
    
    PAYMENT_PID=$!
    echo $PAYMENT_PID > payment_service.pid
    cd ../../
    
    # Wait for service to start
    sleep 5
    
    if curl -s http://localhost:8003/health > /dev/null; then
        print_success "Payment Service started (PID: $PAYMENT_PID)"
        return 0
    else
        print_error "Payment Service failed to start. Check payment_service.log"
        return 1
    fi
}

# Run quick tests
run_quick_tests() {
    print_status "Running quick tests..."
    
    echo ""
    print_status "🧪 Testing Payment Service..."
    
    # Test health endpoint
    health_response=$(curl -s http://localhost:8003/health)
    if echo "$health_response" | grep -q "healthy"; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
        return 1
    fi
    
    # Test payment endpoint
    payment_data='{
        "booking_id": "quick_test_'.$(date +%s)'",
        "amount": 99.99,
        "payment_method": "credit_card",
        "payment_details": {
            "card_number": "4111111111111111",
            "cvv": "123",
            "expiry_month": "12",
            "expiry_year": "2025",
            "cardholder_name": "Test User"
        }
    }'
    
    payment_response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payment_data" \
        http://localhost:8003/payments)
    
    if echo "$payment_response" | grep -q '"success"'; then
        print_success "Payment processing test passed"
        
        # Extract transaction ID if available
        transaction_id=$(echo "$payment_response" | grep -o '"transaction_id":"[^"]*"' | cut -d'"' -f4)
        if [ ! -z "$transaction_id" ]; then
            print_status "Transaction ID: $transaction_id"
            
            # Test transaction retrieval
            get_response=$(curl -s http://localhost:8003/payments/$transaction_id)
            if echo "$get_response" | grep -q "$transaction_id"; then
                print_success "Transaction retrieval test passed"
            fi
        fi
    else
        print_error "Payment processing test failed"
        echo "Response: $payment_response"
        return 1
    fi
    
    echo ""
    print_status "🧪 Testing Notification Service..."
    
    cd services/notification-service/
    PYTHONPATH=./venv/lib/python3.12/site-packages ./venv/bin/python3 -c "
import asyncio
from unittest.mock import AsyncMock
import uuid
from worker import NotificationWorker

async def quick_test():
    worker = NotificationWorker()
    worker.redis_client = AsyncMock()
    worker.db = AsyncMock()
    worker.redis_client.get.return_value = None
    worker.redis_client.setex.return_value = True
    worker.db.notification_logs.insert_one = AsyncMock()
    
    emails_sent = []
    async def mock_send_email(to_email, subject, template, data):
        emails_sent.append({'to_email': to_email, 'subject': subject})
    
    worker.send_email_notification = mock_send_email
    
    test_event = {
        'event_id': str(uuid.uuid4()),
        'event_type': 'booking.confirmed',
        'booking_id': 'test_booking_123',
        'user_id': 'test_user_456',
        'showtime_id': 'showtime_789',
        'seats': ['A1', 'A2'],
        'total_amount': 150.00
    }
    
    success = await worker.handle_booking_confirmed(test_event)
    if success and len(emails_sent) == 1:
        print('✅ Notification service test passed')
        return True
    else:
        print('❌ Notification service test failed')
        return False

result = asyncio.run(quick_test())
exit(0 if result else 1)
" 
    
    if [ $? -eq 0 ]; then
        print_success "Notification service test passed"
    else
        print_error "Notification service test failed"
        return 1
    fi
    
    cd ../../
    return 0
}

# Cleanup function
cleanup() {
    print_status "Cleaning up..."
    
    if [ -f services/payment-service/payment_service.pid ]; then
        kill $(cat services/payment-service/payment_service.pid) 2>/dev/null || true
        rm services/payment-service/payment_service.pid
        print_status "Payment service stopped"
    fi
}

# Main execution
main() {
    echo ""
    print_status "Starting setup and testing process..."
    
    # Trap cleanup on exit
    trap cleanup EXIT
    
    # Step 1: Check prerequisites
    check_prerequisites
    
    # Step 2: Setup services
    setup_payment_service
    setup_notification_service
    
    # Step 3: Start payment service
    if ! start_payment_service; then
        print_error "Failed to start payment service"
        exit 1
    fi
    
    # Step 4: Run tests
    if run_quick_tests; then
        echo ""
        print_success "🎉 All tests passed! Services are working correctly."
        echo ""
        echo "📋 Service Information:"
        echo "======================"
        echo "Payment Service: http://localhost:8003"
        echo "Health Check: curl http://localhost:8003/health"
        echo "API Docs: http://localhost:8003/docs"
        echo ""
        echo "📁 Log Files:"
        echo "============="
        echo "Payment Service: services/payment-service/payment_service.log"
        echo ""
        echo "🧪 Run Full Tests:"
        echo "=================="
        echo "Payment Tests: cd services/payment-service && ./run_tests.sh"
        echo "Notification Tests: cd services/notification-service && ./test_notification.sh"
        echo "Integration Tests: ./run_integration_tests.sh"
        echo ""
        echo "📚 Documentation:"
        echo "================="
        echo "Testing Report: TESTING_REPORT.md"
        echo "Architecture: ARCHITECTURE.md"
        echo ""
        
        # Keep service running for manual testing
        print_warning "Payment service is running. Press Ctrl+C to stop."
        echo ""
        echo "🔧 Manual Testing Commands:"
        echo "==========================="
        echo "# Test payment:"
        echo 'curl -X POST http://localhost:8003/payments \'
        echo '  -H "Content-Type: application/json" \'
        echo '  -d '"'"'{"booking_id": "manual_test", "amount": 100, "payment_method": "credit_card", "payment_details": {"card_number": "4111111111111111"}}'"'"
        echo ""
        echo "# Get transaction:"
        echo "curl http://localhost:8003/payments/{transaction_id}"
        echo ""
        
        # Wait for user interruption
        wait
    else
        print_error "Tests failed. Check the logs for details."
        exit 1
    fi
}

# Run main function
main "$@"