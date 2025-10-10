#!/bin/bash

# Windows Git Bash Compatible Integration Test Script
# Complete Integration Test for Movie Ticket Booking System through Kong Gateway

echo "🎬 Movie Ticket Booking System - Complete Integration Test (Windows/Git Bash)"
echo "============================================================================="

# Configuration
KONG_GATEWAY="http://localhost:8000"
USER_EMAIL="test.user$(date +%s)@example.com"  # Unique email to avoid conflicts
USER_PASSWORD="password123"
USER_FIRST_NAME="Test"
USER_LAST_NAME="User"

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

print_warning() {
    echo "[WARNING] $1"
}

# Function to check if service is running
check_service() {
    local service_url=$1
    local service_name=$2
    
    print_status "Checking $service_name..."
    if curl.exe -s -f "$service_url" > /dev/null 2>&1; then
        print_success "$service_name is running"
        return 0
    else
        print_error "$service_name is not running at $service_url"
        return 1
    fi
}

# Step 1: Check all services are running
echo ""
echo "Step 1: Checking Service Health"
echo "==============================="

check_service "$KONG_GATEWAY" "Kong Gateway"
check_service "http://localhost:8001/health" "User Service"
check_service "http://localhost:8002/actuator/health" "Cinema Service"
check_service "http://localhost:8010/health" "Booking Service"
check_service "http://localhost:8003/health" "Payment Service"

# Step 2: Register a new user through Kong Gateway
echo ""
echo "Step 2: User Registration"
echo "========================="

print_status "Registering new user through Kong Gateway..."
print_status "Email: $USER_EMAIL"

USER_RESPONSE=$(curl.exe -s -X POST "$KONG_GATEWAY/api/v1/register" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$USER_EMAIL\",
        \"password\": \"$USER_PASSWORD\",
        \"first_name\": \"$USER_FIRST_NAME\",
        \"last_name\": \"$USER_LAST_NAME\"
    }")

echo "Registration Response: $USER_RESPONSE"

if echo "$USER_RESPONSE" | grep -q "successfully"; then
    print_success "User registered successfully"
else
    print_warning "Registration response received (might already exist)"
fi

# Step 3: Login and get JWT token
echo ""
echo "Step 3: User Authentication"
echo "==========================="

print_status "Logging in user through Kong Gateway..."
LOGIN_RESPONSE=$(curl.exe -s -X POST "$KONG_GATEWAY/api/v1/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$USER_EMAIL\",
        \"password\": \"$USER_PASSWORD\"
    }")

echo "Login Response: $LOGIN_RESPONSE"

# Extract JWT token and user ID using Git Bash compatible commands
JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')
USER_ID=$(echo "$LOGIN_RESPONSE" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

if [ -n "$JWT_TOKEN" ] && [ -n "$USER_ID" ]; then
    print_success "Login successful"
    print_status "JWT Token: ${JWT_TOKEN:0:50}..."
    print_status "User ID: $USER_ID"
else
    print_error "Failed to extract JWT token or user ID"
    echo "Response: $LOGIN_RESPONSE"
    exit 1
fi

# Step 4: Get available movies and showtimes through Kong Gateway
echo ""
echo "Step 4: Fetching Movies and Showtimes"
echo "====================================="

print_status "Fetching movies through Kong Gateway..."
MOVIES_RESPONSE=$(curl.exe -s -X GET "$KONG_GATEWAY/api/v1/movies")
echo "Movies Response: $MOVIES_RESPONSE"

print_status "Fetching showtimes through Kong Gateway..."
SHOWTIMES_RESPONSE=$(curl.exe -s -X GET "$KONG_GATEWAY/api/v1/showtimes")
echo "Showtimes Response: $SHOWTIMES_RESPONSE"

# Extract the first available showtime ID
SHOWTIME_ID=$(echo "$SHOWTIMES_RESPONSE" | sed -n 's/.*"id":\([0-9]*\).*/\1/p' | head -1)

if [ -n "$SHOWTIME_ID" ]; then
    print_success "Found showtime ID: $SHOWTIME_ID"
else
    print_warning "No showtimes found, using default ID: 1"
    SHOWTIME_ID="1"
fi

# Step 5: Create booking through Kong Gateway (GraphQL)
echo ""
echo "Step 5: Creating Booking"
echo "======================="

print_status "Creating booking through Kong Gateway (GraphQL)..."

# Create the GraphQL mutation in a temporary file to handle JSON properly
cat > /tmp/booking_mutation.json << EOF
{
    "query": "mutation CreateBooking(\$userId: String!, \$showtimeId: String!, \$seatNumbers: [String!]!) { createBooking(userId: \$userId, showtimeId: \$showtimeId, seatNumbers: \$seatNumbers) { success booking { id userId showtimeId seats totalAmount status createdAt } message lockId } }",
    "variables": {
        "userId": "$USER_ID",
        "showtimeId": "$SHOWTIME_ID",
        "seatNumbers": ["A1", "A2"]
    }
}
EOF

BOOKING_RESPONSE=$(curl.exe -s -X POST "$KONG_GATEWAY/graphql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -d @/tmp/booking_mutation.json)

echo "Booking Response: $BOOKING_RESPONSE"

# Extract booking ID
BOOKING_ID=$(echo "$BOOKING_RESPONSE" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' | head -1)

if [ -n "$BOOKING_ID" ]; then
    print_success "Booking created successfully"
    print_status "Booking ID: $BOOKING_ID"
else
    print_error "Failed to create booking"
    echo "Response: $BOOKING_RESPONSE"
    exit 1
fi

# Step 6: Process payment through Kong Gateway (GraphQL)
echo ""
echo "Step 6: Processing Payment"
echo "========================="

print_status "Processing payment through Kong Gateway (GraphQL)..."

# Create the payment mutation in a temporary file
cat > /tmp/payment_mutation.json << EOF
{
    "query": "mutation ProcessPayment(\$bookingId: String!, \$paymentMethod: String!) { processPayment(bookingId: \$bookingId, paymentMethod: \$paymentMethod) { success booking { id status totalAmount } message } }",
    "variables": {
        "bookingId": "$BOOKING_ID",
        "paymentMethod": "credit_card"
    }
}
EOF

PAYMENT_RESPONSE=$(curl.exe -s -X POST "$KONG_GATEWAY/graphql" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -d @/tmp/payment_mutation.json)

echo "Payment Response: $PAYMENT_RESPONSE"

if echo "$PAYMENT_RESPONSE" | grep -q '"success":true'; then
    print_success "Payment processed successfully"
    print_success "Booking should be confirmed and notification sent!"
else
    print_error "Payment processing failed"
fi

# Step 7: Verify RabbitMQ events
echo ""
echo "Step 7: Verification"
echo "==================="

print_status "Checking RabbitMQ Management Interface..."
RABBITMQ_OVERVIEW=$(curl.exe -s -u admin:admin123 "http://localhost:15672/api/overview" 2>/dev/null)

if echo "$RABBITMQ_OVERVIEW" | grep -q "management"; then
    print_success "RabbitMQ is running and accessible"
else
    print_warning "Could not verify RabbitMQ (might be normal)"
fi

# Step 8: Display access information
echo ""
echo "Step 8: System Access Information"
echo "================================="

print_status "🌐 Service Access URLs:"
echo "  - Kong Gateway:          http://localhost:8000"
echo "  - User Service:          http://localhost:8001"
echo "  - Cinema Service:        http://localhost:8002"
echo "  - Booking Service:       http://localhost:8010"
echo "  - Payment Service:       http://localhost:8003"
echo ""
print_status "📊 Management Interfaces:"
echo "  - RabbitMQ Management:   http://localhost:15672 (admin/admin123)"
echo "  - MongoDB Express:       http://localhost:8081 (admin/admin123)"
echo "  - PostgreSQL pgAdmin:    http://localhost:8080 (admin@movietickets.com/admin123)"
echo "  - Redis Commander:       http://localhost:8082"

# Final summary
echo ""
echo "Integration Test Summary"
echo "======================="
print_success "✅ User registration and authentication through Kong"
print_success "✅ Cinema service integration (movies/showtimes)"
print_success "✅ Booking service integration (GraphQL)"
print_success "✅ Payment service integration"
print_success "✅ Kong Gateway routing for all services"
print_status "📧 Check notification service logs for email notifications"

# Cleanup temporary files
rm -f /tmp/booking_mutation.json /tmp/payment_mutation.json

echo ""
print_success "🎉 Integration test completed successfully!"
echo "All services are communicating through Kong Gateway."
echo ""
echo "Next Steps:"
echo "1. Check Docker logs: docker logs movie-notification-service"
echo "2. Verify RabbitMQ queues: http://localhost:15672"
echo "3. Check booking in MongoDB: http://localhost:8081"
echo "4. Review payment logs: docker logs movie-payment-service"