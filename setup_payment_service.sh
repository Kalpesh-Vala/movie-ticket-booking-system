#!/bin/bash

# Payment Service Setup Script
# Builds and starts the Payment Service (Python + MongoDB)

echo "💳 Setting up Payment Service"
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

# Check if MongoDB is running
print_status "Checking if MongoDB is running..."
if ! docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    print_error "MongoDB is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "MongoDB is running"

# Clean up existing payment service container
print_status "Cleaning up existing Payment Service container..."
docker-compose stop payment-service 2>/dev/null || true
docker-compose rm -f payment-service 2>/dev/null || true

# Build Payment Service
echo ""
print_status "Building Payment Service..."
docker-compose build payment-service

if [ $? -ne 0 ]; then
    print_error "Failed to build Payment Service"
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check Dockerfile in services/payment-service/"
    echo "  2. Check requirements.txt dependencies"
    echo "  3. Check if Python version is compatible"
    echo "  4. Try: docker-compose build --no-cache payment-service"
    exit 1
fi
print_success "Payment Service built successfully"

# Start Payment Service
echo ""
print_status "Starting Payment Service..."
docker-compose up -d payment-service

# Wait for Payment Service to be ready
print_status "Waiting for Payment Service to be ready..."
max_attempts=20
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl.exe -s -f "http://localhost:8003/health" > /dev/null 2>&1; then
        print_success "Payment Service is ready!"
        break
    fi
    
    echo "  Attempt $attempt/$max_attempts - Payment Service not ready yet..."
    sleep 3
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Payment Service failed to start after $max_attempts attempts"
    
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check logs: docker-compose logs payment-service"
    echo "  2. Check if MongoDB is running: docker-compose ps mongodb"
    echo "  3. Check database connection in main.py"
    echo "  4. Restart service: docker-compose restart payment-service"
    echo "  5. Check if port 8003 is available: netstat -an | findstr 8003"
    echo "  6. Check environment variables: docker-compose exec payment-service env"
    exit 1
fi

# Test Payment Service endpoints
echo ""
print_status "Testing Payment Service endpoints..."

# Test health endpoint
echo "Testing health endpoint..."
health_response=$(curl.exe -s "http://localhost:8003/health")
if [ $? -eq 0 ]; then
    print_success "Health endpoint working: $health_response"
else
    print_error "Health endpoint failed"
fi

# Test create payment endpoint
echo "Testing create payment endpoint..."
payment_data='{
    "booking_id": "test_booking_123",
    "user_id": "test_user_123",
    "amount": 25.50,
    "currency": "USD",
    "payment_method": "credit_card",
    "card_details": {
        "card_number": "4111111111111111",
        "expiry_month": "12",
        "expiry_year": "2025",
        "cvv": "123",
        "cardholder_name": "Test User"
    }
}'

create_response=$(curl.exe -s -X POST "http://localhost:8003/api/payments" \
    -H "Content-Type: application/json" \
    -d "$payment_data")

if [ $? -eq 0 ]; then
    print_success "Create payment endpoint working"
    echo "  Response: $create_response"
else
    print_error "Create payment endpoint failed"
fi

# Test list payments endpoint
echo "Testing list payments endpoint..."
payments_response=$(curl.exe -s "http://localhost:8003/api/payments")
if [ $? -eq 0 ]; then
    print_success "List payments endpoint working"
    echo "  Response: $payments_response"
else
    print_error "List payments endpoint failed"
fi

echo ""
print_success "🎉 Payment Service is running and ready!"
echo ""
echo "📊 Payment Service Details:"
echo "  - Service URL:       http://localhost:8003"
echo "  - Health Check:      http://localhost:8003/health"
echo "  - API Endpoint:      http://localhost:8003/api/payments"
echo "  - Via Kong Gateway:  http://localhost:8000/api/payments"
echo "  - Database:          MongoDB (movie_tickets_db.payments collection)"
echo ""
echo "🔧 Management Commands:"
echo "  - View logs:         docker-compose logs payment-service"
echo "  - Restart service:   docker-compose restart payment-service"
echo "  - Stop service:      docker-compose stop payment-service"
echo "  - Access container:  docker-compose exec payment-service bash"
echo "  - Run tests:         docker-compose exec payment-service python -m pytest"
echo ""
echo "📋 API Endpoints:"
echo "  - POST /api/payments           - Create payment"
echo "  - GET /api/payments            - List payments"
echo "  - GET /api/payments/:id        - Get payment by ID"
echo "  - PUT /api/payments/:id/status - Update payment status"
echo "  - POST /api/payments/:id/refund - Process refund"
echo ""
echo "💳 Supported Payment Methods:"
echo "  - Credit Card (Visa, MasterCard, Amex)"
echo "  - Debit Card"
echo "  - PayPal (simulated)"
echo "  - Bank Transfer (simulated)"
echo ""
echo "🔒 Security Features:"
echo "  - Card number encryption"
echo "  - CVV validation"
echo "  - Expiry date validation"
echo "  - Payment status tracking"
echo "  - Transaction logging"
echo ""
echo "✅ Payment Service setup complete!"
echo ""
echo "Next: Run ./setup_booking_service.sh"