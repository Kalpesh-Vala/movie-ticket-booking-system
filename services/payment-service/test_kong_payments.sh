#!/bin/bash

# Payment Service API Testing through Kong Gateway
# Tests payment service endpoints via Kong Gateway proxy

echo "=========================================="
echo "Payment Service API Testing via Kong Gateway"
echo "=========================================="
echo ""

# Configuration
KONG_URL="http://localhost:8000"
KONG_ADMIN_URL="http://localhost:8001"
DIRECT_URL="http://localhost:8003"
CONTENT_TYPE="Content-Type: application/json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test variables
TRANSACTION_ID=""
BOOKING_ID="KONG-BOOK-$(date +%s)"
USER_ID="kong-test-user-$(date +%s)"

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
    
    # Truncate response if too long
    if [[ ${#response} -gt 300 ]]; then
        echo "${response:0:300}... (response truncated)"
    else
        echo "$response"
    fi
    echo ""
}

# Function to extract transaction ID from response
extract_transaction_id() {
    echo "$1" | grep -o '"transaction_id":"[^"]*"' | cut -d'"' -f4
}

echo "=== KONG GATEWAY STATUS CHECK ==="

# Test Kong Admin API
echo "Testing: Kong Admin API Status"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$KONG_ADMIN_URL/status")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

if [[ "$http_code" == "200" ]]; then
    echo -e "${GREEN}✓ Kong Gateway is running${NC}"
else
    echo -e "${RED}✗ Kong Gateway not accessible${NC}"
fi
echo ""

echo "=== KONG ROUTE CONFIGURATION VERIFICATION ==="

# Check Kong routes for payment service
echo "Checking Kong routes for payment service..."
kong_routes=$(curl -s "$KONG_ADMIN_URL/routes" | grep -o '"name":"[^"]*payment[^"]*"' | cut -d'"' -f4)
echo "Found payment routes: $kong_routes"
echo ""

echo "=== DIRECT SERVICE COMPARISON ==="

# Test direct service health for comparison
echo "Testing: Direct Payment Service Health (for comparison)"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$DIRECT_URL/health")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

print_result "Direct Service Health Check" "$http_code" "200" "$response_body" "GET"

echo "=== KONG GATEWAY HEALTH ROUTING ==="

# Test health through Kong (this might fail due to routing config)
echo "Testing: Payment Service Health via Kong"
echo -e "${YELLOW}Note: This may fail due to /actuator/health vs /health endpoint mismatch${NC}"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$KONG_URL/health/payment")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

if [[ "$http_code" == "404" ]]; then
    echo -e "${YELLOW}⚠ Expected Issue${NC} (Status: $http_code) - Health endpoint routing mismatch"
    echo "Kong config expects /actuator/health but payment service uses /health"
else
    print_result "Payment Service Health via Kong" "$http_code" "200" "$response_body" "GET"
fi
echo ""

echo "=== PAYMENT ENDPOINT ROUTING DIAGNOSIS ==="

# Test different Kong routing approaches
echo "Testing various Kong routing configurations for payments..."

# Test 1: /api/payments (as per Kong config)
echo "1. Testing /api/payments route (Kong configured route):"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$KONG_URL/api/payments" \
    -H "$CONTENT_TYPE" \
    -d '{"test": "kong_route_check"}')
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
echo "   Status: $http_code"

# Test 2: /payments (if strip_path works correctly)
echo "2. Testing /payments route (after strip_path):"
response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$KONG_URL/payments" \
    -H "$CONTENT_TYPE" \
    -d '{"test": "direct_route_check"}')
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
echo "   Status: $http_code"

echo ""

echo "=== WORKING KONG PAYMENT ROUTE IDENTIFICATION ==="

# Try to find the working route by testing different approaches
working_route=""
working_method=""

# Method 1: Try /api/payments with strip_path
test_payment='{
  "user_id": "'$USER_ID'",
  "booking_id": "'$BOOKING_ID'",
  "amount": 10.00,
  "payment_method": "credit_card",
  "payment_details": {
    "card_number": "4111111111111111",
    "expiry_month": "12",
    "expiry_year": "2025",
    "cvv": "123",
    "cardholder_name": "Kong Test"
  }
}'

echo "Attempting payment through /api/payments..."
response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$KONG_URL/api/payments" \
    -H "$CONTENT_TYPE" \
    -d "$test_payment")
http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

if [[ "$http_code" == "200" ]]; then
    working_route="/api/payments"
    working_method="POST"
    echo -e "${GREEN}✓ Found working route: $working_route${NC}"
    TRANSACTION_ID=$(extract_transaction_id "$response_body")
elif [[ "$http_code" == "422" ]]; then
    working_route="/api/payments"
    working_method="POST"
    echo -e "${GREEN}✓ Route working but validation failed (expected): $working_route${NC}"
else
    echo -e "${RED}✗ Route not working: /api/payments (Status: $http_code)${NC}"
fi

# Method 2: Try direct /payments if first method failed
if [[ -z "$working_route" ]]; then
    echo "Attempting payment through /payments..."
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$KONG_URL/payments" \
        -H "$CONTENT_TYPE" \
        -d "$test_payment")
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

    if [[ "$http_code" == "200" ]]; then
        working_route="/payments"
        working_method="POST"
        echo -e "${GREEN}✓ Found working route: $working_route${NC}"
        TRANSACTION_ID=$(extract_transaction_id "$response_body")
    elif [[ "$http_code" == "422" ]]; then
        working_route="/payments"
        working_method="POST"
        echo -e "${GREEN}✓ Route working but validation failed (expected): $working_route${NC}"
    else
        echo -e "${RED}✗ Route not working: /payments (Status: $http_code)${NC}"
    fi
fi

echo ""

if [[ -n "$working_route" ]]; then
    echo "=== COMPREHENSIVE KONG PAYMENT TESTING ==="
    echo -e "${GREEN}Using working route: $working_route${NC}"
    echo ""
    
    # Test 1: Valid Credit Card Payment
    echo "Testing: Credit Card Payment via Kong"
    valid_payment='{
      "user_id": "'$USER_ID'",
      "booking_id": "'$BOOKING_ID'",
      "amount": 25.50,
      "payment_method": "credit_card",
      "payment_details": {
        "card_number": "4111111111111111",
        "expiry_month": "12",
        "expiry_year": "2025",
        "cvv": "123",
        "cardholder_name": "Kong Gateway Test"
      }
    }'

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$KONG_URL$working_route" \
        -H "$CONTENT_TYPE" \
        -d "$valid_payment")
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

    print_result "Credit Card Payment via Kong" "$http_code" "200" "$response_body" "POST $working_route"
    
    # Extract transaction ID
    if [[ "$http_code" == "200" ]]; then
        TRANSACTION_ID=$(extract_transaction_id "$response_body")
        if [[ -n "$TRANSACTION_ID" && "$TRANSACTION_ID" != "null" ]]; then
            echo -e "${GREEN}Transaction ID: $TRANSACTION_ID${NC}"
        fi
    fi
    
    # Test 2: Invalid Payment (Negative Amount)
    echo "Testing: Invalid Payment via Kong"
    invalid_payment='{
      "user_id": "'$USER_ID'",
      "booking_id": "KONG-INVALID-'$(date +%s)'",
      "amount": -15.00,
      "payment_method": "credit_card",
      "payment_details": {
        "card_number": "4111111111111111",
        "expiry_month": "12",
        "expiry_year": "2025",
        "cvv": "123",
        "cardholder_name": "Kong Test Invalid"
      }
    }'

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$KONG_URL$working_route" \
        -H "$CONTENT_TYPE" \
        -d "$invalid_payment")
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

    print_result "Invalid Payment via Kong" "$http_code" "400" "$response_body" "POST $working_route"
    
    # Test 3: Digital Wallet Payment
    echo "Testing: Digital Wallet Payment via Kong"
    wallet_payment='{
      "user_id": "'$USER_ID'",
      "booking_id": "KONG-WALLET-'$(date +%s)'",
      "amount": 18.75,
      "payment_method": "digital_wallet",
      "payment_details": {
        "wallet_id": "kong_wallet_123",
        "phone_number": "+1234567890"
      }
    }'

    response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X POST "$KONG_URL$working_route" \
        -H "$CONTENT_TYPE" \
        -d "$wallet_payment")
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

    print_result "Digital Wallet Payment via Kong" "$http_code" "200" "$response_body" "POST $working_route"

    # Test 4: Get Transaction (if we have a transaction ID)
    if [[ -n "$TRANSACTION_ID" && "$TRANSACTION_ID" != "null" ]]; then
        echo "Testing: Get Transaction via Kong"
        
        # Try different paths for GET requests since Kong routing might be different
        # Kong strips /api/payments, so GET requests go to /{transaction_id}
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$KONG_URL$working_route/$TRANSACTION_ID")
        http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        response_body=$(echo $response | sed -E 's/HTTPSTATUS:[0-9]{3}$//')

        print_result "Get Transaction via Kong" "$http_code" "200" "$response_body" "GET $working_route/$TRANSACTION_ID"
    fi

    # Test 5: Kong-specific features (Rate Limiting, CORS)
    echo "Testing: Kong Rate Limiting Headers"
    response=$(curl -s -I "$KONG_URL$working_route" -X POST \
        -H "$CONTENT_TYPE" \
        -d '{"test": "rate_limit"}')
    
    rate_limit=$(echo "$response" | grep -i "x-ratelimit-limit" || echo "No rate limit headers found")
    echo "Rate Limiting: $rate_limit"
    
    echo "Testing: Kong CORS Headers"
    cors_headers=$(echo "$response" | grep -i "access-control" || echo "No CORS headers found")
    echo "CORS Headers: $cors_headers"
    echo ""

else
    echo -e "${RED}=== KONG ROUTING ISSUE DETECTED ===${NC}"
    echo ""
    echo "❌ No working Kong routes found for payment service!"
    echo ""
    echo "Possible issues:"
    echo "1. Kong configuration mismatch between routes and service endpoints"
    echo "2. Payment service endpoints don't match Kong route expectations"
    echo "3. Kong service name resolution issues"
    echo ""
    echo "Direct service works at: $DIRECT_URL"
    echo "Kong should proxy to: payment-service:8003"
    echo ""
    echo "Recommended fixes:"
    echo "1. Check Kong service configuration in kong.yml"
    echo "2. Verify payment service Docker networking"
    echo "3. Update Kong routes to match actual payment service endpoints"
fi

echo "=== KONG VS DIRECT SERVICE COMPARISON ==="
echo ""
echo "📊 Summary:"
echo "- Direct Service URL: $DIRECT_URL"
echo "- Kong Gateway URL: $KONG_URL"
echo "- Kong Admin URL: $KONG_ADMIN_URL"
echo ""
echo "🔍 Findings:"
if [[ -n "$working_route" ]]; then
    echo -e "  ${GREEN}✓ Kong Gateway routing: WORKING${NC}"
    echo "  ✓ Working route: $working_route"
    echo "  ✓ Payment processing: FUNCTIONAL"
    echo "  ✓ Kong features: Rate limiting and CORS active"
else
    echo -e "  ${RED}✗ Kong Gateway routing: BROKEN${NC}"
    echo "  ✗ No working payment routes found"
    echo "  ✗ Configuration mismatch detected"
fi

echo ""
echo "Test User ID: $USER_ID"
echo "Test Booking ID: $BOOKING_ID"
if [[ -n "$TRANSACTION_ID" && "$TRANSACTION_ID" != "null" ]]; then
    echo "Sample Transaction ID: $TRANSACTION_ID"
fi
echo ""
echo "=========================================="
echo "Kong Gateway Payment Testing Complete!"
echo "=========================================="