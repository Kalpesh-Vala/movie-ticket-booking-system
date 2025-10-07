#!/bin/bash

# Quick Manual Test Script
# Simple verification that payment and notification services are working

echo "🧪 Quick Manual Test for Payment & Notification Services"
echo "======================================================="

# Check if services are running
check_service() {
    local service_url=$1
    local service_name=$2
    
    echo "🔍 Checking $service_name..."
    
    if curl -s "$service_url" > /dev/null; then
        echo "✅ $service_name is running"
        return 0
    else
        echo "❌ $service_name is not running"
        return 1
    fi
}

# Test payment endpoint
test_payment() {
    echo "💳 Testing payment endpoint..."
    
    payment_data='{
        "booking_id": "manual_test_123",
        "amount": 99.99,
        "payment_method": "credit_card",
        "payment_details": {
            "card_number": "4111111111111111",
            "cvv": "123",
            "expiry_month": "12",
            "expiry_year": "2025",
            "cardholder_name": "Manual Test User"
        }
    }'
    
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$payment_data" \
        http://localhost:8003/payments)
    
    echo "Response: $response"
    
    success=$(echo "$response" | python3 -c "import sys, json; print(json.load(sys.stdin).get('success', False))" 2>/dev/null)
    
    if [ "$success" = "True" ]; then
        echo "✅ Payment test successful"
        return 0
    else
        echo "❌ Payment test failed"
        return 1
    fi
}

# Main execution
main() {
    echo "Starting quick manual tests..."
    echo ""
    
    # Check if payment service is running
    if check_service "http://localhost:8003/health" "Payment Service"; then
        # Test payment functionality
        test_payment
    else
        echo "⚠️  Payment service is not running. Start it with:"
        echo "   cd services/payment-service && python main.py"
        exit 1
    fi
    
    echo ""
    echo "🏁 Manual tests completed!"
    echo ""
    echo "To run comprehensive tests:"
    echo "  Payment Service: cd services/payment-service && ./run_tests.sh"
    echo "  Notification Service: cd services/notification-service && ./test_notification.sh"
    echo "  Integration Tests: ./run_integration_tests.sh"
}

main "$@"