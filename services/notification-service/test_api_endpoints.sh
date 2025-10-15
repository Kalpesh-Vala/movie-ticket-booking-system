#!/bin/bash

# Notification Service HTTP API Testing Script
# Tests specific HTTP endpoints for notification service

echo "=========================================="
echo "Notification Service HTTP API Testing"
echo "=========================================="
echo ""

# Configuration
NOTIFICATION_URL="http://localhost:8084"
KONG_URL="http://localhost:8000"
TEST_EMAIL="whitehat1860@gmail.com"
CONTENT_TYPE="Content-Type: application/json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test variables
BOOKING_ID="API-TEST-$(date +%s)"
USER_ID="test-user-$(date +%s)"
TRANSACTION_ID="API-TXN-$(date +%s)"

# Function to print test results
print_result() {
    local test_name="$1"
    local status_code="$2"
    local expected_code="$3"
    local response="$4"
    local method="$5"
    
    echo "Testing: $test_name"
    echo "Method: $method"
    
    if [[ "$status_code" == "$expected_code" ]]; then
        echo -e "${GREEN}✓ Success${NC} (Status: $status_code)"
    else
        echo -e "${RED}✗ Failed${NC} (Status: $status_code, Expected: $expected_code)"
    fi
    
    # Pretty print JSON response if possible
    if command -v jq &> /dev/null && echo "$response" | jq . &> /dev/null; then
        echo "Response:"
        echo "$response" | jq .
    else
        # Truncate response if too long
        if [[ ${#response} -gt 300 ]]; then
            echo "Response: ${response:0:300}... (truncated)"
        else
            echo "Response: $response"
        fi
    fi
    
    echo ""
    echo "----------------------------------------"
    echo ""
}

echo "🔍 Testing Notification Service HTTP API"
echo "Service URL: $NOTIFICATION_URL"
echo "Kong Gateway: $KONG_URL"
echo "Test Email: $TEST_EMAIL"
echo ""

# Test 1: Root endpoint
echo "1. Testing root endpoint"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$NOTIFICATION_URL/")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Root Endpoint" "$http_code" "200" "$body" "GET /"

# Test 2: Health check (direct)
echo "2. Testing health check endpoint (direct)"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$NOTIFICATION_URL/health")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Health Check Direct" "$http_code" "200" "$body" "GET /health"

# Test 3: Actuator health check
echo "3. Testing actuator health endpoint"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$NOTIFICATION_URL/actuator/health")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Actuator Health Check" "$http_code" "200" "$body" "GET /actuator/health"

# Test 4: Kong Gateway health check
echo "4. Testing Kong Gateway health route"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$KONG_URL/health/notification")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Kong Health Check" "$http_code" "200" "$body" "GET /health/notification"

# Test 5: Test email endpoint
echo "5. Testing email sending endpoint"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$NOTIFICATION_URL/test/email" \
    -H "$CONTENT_TYPE" \
    -d "{
        \"recipient\": \"$TEST_EMAIL\",
        \"subject\": \"Notification API Test - $(date)\",
        \"message\": \"This is a test email from the notification service HTTP API.\",
        \"email_type\": \"api_test\"
    }")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Test Email Sending" "$http_code" "200" "$body" "POST /test/email"

# Test 6: Booking confirmation notification
echo "6. Testing booking confirmation notification"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$NOTIFICATION_URL/notifications/booking-confirmation" \
    -H "$CONTENT_TYPE" \
    -d "{
        \"user_email\": \"$TEST_EMAIL\",
        \"booking_id\": \"$BOOKING_ID\",
        \"movie_title\": \"Test Movie - API\",
        \"showtime\": \"$(date -d '+1 day' '+%Y-%m-%d %H:%M')\",
        \"cinema_name\": \"API Test Cinema\",
        \"seats\": [\"A1\", \"A2\"],
        \"total_amount\": 30.00
    }")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Booking Confirmation" "$http_code" "200" "$body" "POST /notifications/booking-confirmation"

# Test 7: Payment success notification
echo "7. Testing payment success notification"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$NOTIFICATION_URL/notifications/payment-confirmation" \
    -H "$CONTENT_TYPE" \
    -d "{
        \"user_email\": \"$TEST_EMAIL\",
        \"booking_id\": \"$BOOKING_ID\",
        \"transaction_id\": \"$TRANSACTION_ID\",
        \"amount\": 30.00,
        \"payment_method\": \"credit_card\",
        \"status\": \"success\"
    }")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Payment Success Notification" "$http_code" "200" "$body" "POST /notifications/payment-confirmation"

# Test 8: Payment failed notification
echo "8. Testing payment failed notification"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$NOTIFICATION_URL/notifications/payment-confirmation" \
    -H "$CONTENT_TYPE" \
    -d "{
        \"user_email\": \"$TEST_EMAIL\",
        \"booking_id\": \"$BOOKING_ID\",
        \"transaction_id\": \"TXN-FAILED-$(date +%s)\",
        \"amount\": 30.00,
        \"payment_method\": \"credit_card\",
        \"status\": \"failed\"
    }")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Payment Failed Notification" "$http_code" "200" "$body" "POST /notifications/payment-confirmation"

# Test 9: Custom notification
echo "9. Testing custom notification"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$NOTIFICATION_URL/notifications/custom" \
    -H "$CONTENT_TYPE" \
    -d "{
        \"event_type\": \"booking.confirmed\",
        \"recipient_email\": \"$TEST_EMAIL\",
        \"event_data\": {
            \"booking_id\": \"CUSTOM-$BOOKING_ID\",
            \"movie_title\": \"Custom Test Movie\",
            \"showtime\": \"$(date -d '+2 days' '+%Y-%m-%d %H:%M')\",
            \"cinema_name\": \"Custom Cinema\",
            \"seats\": [\"B3\", \"B4\"],
            \"total_amount\": 40.00
        }
    }")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Custom Notification" "$http_code" "200" "$body" "POST /notifications/custom"

# Test 10: Get notification logs
echo "10. Testing notification logs endpoint"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$NOTIFICATION_URL/notifications/logs?limit=5")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Notification Logs" "$http_code" "200" "$body" "GET /notifications/logs"

# Test 11: Get service statistics
echo "11. Testing service statistics endpoint"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$NOTIFICATION_URL/stats")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Service Statistics" "$http_code" "200" "$body" "GET /stats"

# Test 12: Kong Gateway notification API route
echo "12. Testing Kong Gateway notification API route"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$KONG_URL/api/notifications/")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Kong Notification API" "$http_code" "200" "$body" "GET /api/notifications/"

# Test 13: Invalid endpoint
echo "13. Testing invalid endpoint (should return 404)"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$NOTIFICATION_URL/invalid-endpoint")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Invalid Endpoint" "$http_code" "404" "$body" "GET /invalid-endpoint"

# Test 14: Invalid JSON payload
echo "14. Testing invalid JSON payload (should return 422)"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
    -X POST "$NOTIFICATION_URL/test/email" \
    -H "$CONTENT_TYPE" \
    -d "{invalid json}")
http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
print_result "Invalid JSON Payload" "$http_code" "422" "$body" "POST /test/email"

echo "================================================"
echo ""
echo "🎯 HTTP API Testing Summary:"
echo "- Root endpoint: Base service information"
echo "- Health checks: Direct and Kong Gateway routes"  
echo "- Email testing: Test email sent to $TEST_EMAIL"
echo "- Booking notifications: Confirmation emails"
echo "- Payment notifications: Success and failure emails" 
echo "- Custom notifications: Flexible event processing"
echo "- Logs and stats: Service monitoring endpoints"
echo "- Error handling: Invalid requests and endpoints"
echo ""
echo "📧 Check your email at $TEST_EMAIL for test notifications!"
echo ""
echo "✅ Notification Service HTTP API Testing Complete!"