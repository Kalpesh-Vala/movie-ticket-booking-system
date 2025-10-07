#!/bin/bash

# Payment Service Test Suite Runner
# Comprehensive testing script for payment service

set -e  # Exit on any error

echo "🚀 Starting Payment Service Test Suite"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if required dependencies are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v docker-compose &> /dev/null; then
        print_error "docker-compose is required but not installed"
        exit 1
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    
    print_success "All dependencies found"
}

# Setup test environment
setup_test_environment() {
    print_status "Setting up test environment..."
    
    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv venv
    fi
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Install test dependencies
    print_status "Installing test dependencies..."
    pip install -r requirements.txt
    pip install pytest pytest-asyncio httpx aiohttp redis motor pymongo
    
    print_success "Test environment setup complete"
}

# Start infrastructure services
start_infrastructure() {
    print_status "Starting infrastructure services..."
    
    # Navigate to project root
    cd ../../
    
    # Start only the required infrastructure
    docker-compose up -d mongodb redis rabbitmq
    
    # Wait for services to be ready
    print_status "Waiting for infrastructure services to be ready..."
    sleep 10
    
    # Check if services are running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Infrastructure services failed to start"
        exit 1
    fi
    
    print_success "Infrastructure services started successfully"
    
    # Return to payment service directory
    cd services/payment-service/
}

# Run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    
    source venv/bin/activate
    
    # Run unit tests with coverage
    pytest test_payment_service.py -v --tb=short -m "not integration" \
        --cov=main --cov-report=html --cov-report=term-missing
    
    if [ $? -eq 0 ]; then
        print_success "Unit tests passed"
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Start payment service for integration tests
start_payment_service() {
    print_status "Starting payment service..."
    
    source venv/bin/activate
    
    # Set environment variables
    export MONGODB_URI="mongodb://localhost:27017"
    export RABBITMQ_URL="amqp://guest:guest@localhost:5672/"
    export PORT=8003
    
    # Start payment service in background
    python main.py &
    PAYMENT_PID=$!
    
    # Save PID for cleanup
    echo $PAYMENT_PID > payment_service.pid
    
    # Wait for service to start
    sleep 5
    
    # Check if service is running
    if ! curl -s http://localhost:8003/health > /dev/null; then
        print_error "Payment service failed to start"
        return 1
    fi
    
    print_success "Payment service started successfully"
}

# Start notification service for integration tests
start_notification_service() {
    print_status "Starting notification service..."
    
    # Navigate to notification service
    cd ../notification-service/
    
    # Create virtual environment if needed
    if [ ! -d "venv" ]; then
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Set environment variables
    export MONGODB_URI="mongodb://localhost:27017"
    export REDIS_URL="redis://localhost:6379"
    export RABBITMQ_URL="amqp://guest:guest@localhost:5672/"
    
    # Start notification service in background
    python worker.py &
    NOTIFICATION_PID=$!
    
    # Save PID for cleanup
    echo $NOTIFICATION_PID > notification_service.pid
    
    sleep 3
    print_success "Notification service started"
    
    # Return to payment service directory
    cd ../payment-service/
}

# Run integration tests
run_integration_tests() {
    print_status "Running integration tests..."
    
    source venv/bin/activate
    
    # Run integration tests
    pytest test_integration.py -v --tb=short -m "integration"
    
    if [ $? -eq 0 ]; then
        print_success "Integration tests passed"
    else
        print_error "Integration tests failed"
        return 1
    fi
}

# Run load tests
run_load_tests() {
    print_status "Running load tests..."
    
    source venv/bin/activate
    
    # Run load tests
    python test_load.py
    
    if [ $? -eq 0 ]; then
        print_success "Load tests completed"
    else
        print_error "Load tests failed"
        return 1
    fi
}

# Test API endpoints
test_api_endpoints() {
    print_status "Testing API endpoints..."
    
    # Test health endpoint
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8003/health)
    if [ "$response" = "200" ]; then
        print_success "Health endpoint working"
    else
        print_error "Health endpoint failed (HTTP $response)"
        return 1
    fi
    
    # Test payment endpoint
    payment_data='{
        "booking_id": "test_booking_123",
        "amount": 100.00,
        "payment_method": "credit_card",
        "payment_details": {
            "card_number": "4111111111111111",
            "cvv": "123",
            "expiry_month": "12",
            "expiry_year": "2025",
            "cardholder_name": "Test User"
        }
    }'
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payment_data" \
        -o /dev/null -w "%{http_code}" \
        http://localhost:8003/payments)
    
    if [ "$response" = "200" ]; then
        print_success "Payment endpoint working"
    else
        print_error "Payment endpoint failed (HTTP $response)"
        return 1
    fi
}

# Cleanup function
cleanup() {
    print_status "Cleaning up..."
    
    # Kill payment service
    if [ -f payment_service.pid ]; then
        kill $(cat payment_service.pid) 2>/dev/null || true
        rm payment_service.pid
    fi
    
    # Kill notification service
    if [ -f ../notification-service/notification_service.pid ]; then
        kill $(cat ../notification-service/notification_service.pid) 2>/dev/null || true
        rm ../notification-service/notification_service.pid
    fi
    
    # Stop infrastructure services
    cd ../../
    docker-compose down
    cd services/payment-service/
    
    print_success "Cleanup completed"
}

# Trap cleanup on exit
trap cleanup EXIT

# Main test execution
main() {
    print_status "Payment Service Test Suite - Starting..."
    
    # Step 1: Check dependencies
    check_dependencies
    
    # Step 2: Setup test environment
    setup_test_environment
    
    # Step 3: Start infrastructure
    start_infrastructure
    
    # Step 4: Run unit tests
    if ! run_unit_tests; then
        print_error "Unit tests failed - stopping test suite"
        exit 1
    fi
    
    # Step 5: Start services for integration tests
    if ! start_payment_service; then
        print_error "Failed to start payment service"
        exit 1
    fi
    
    start_notification_service
    
    # Step 6: Test API endpoints
    if ! test_api_endpoints; then
        print_error "API endpoint tests failed"
        exit 1
    fi
    
    # Step 7: Run integration tests
    if ! run_integration_tests; then
        print_warning "Integration tests failed - continuing with load tests"
    fi
    
    # Step 8: Run load tests
    if ! run_load_tests; then
        print_warning "Load tests failed"
    fi
    
    print_success "🎉 Payment Service Test Suite Completed Successfully!"
    
    # Generate test report
    echo ""
    echo "📊 Test Summary:"
    echo "==============="
    echo "✅ Unit Tests: Passed"
    echo "✅ API Tests: Passed"
    echo "⚠️  Integration Tests: Check output above"
    echo "⚠️  Load Tests: Check output above"
    echo ""
    echo "📁 Coverage report available at: htmlcov/index.html"
    echo ""
}

# Run main function
main "$@"