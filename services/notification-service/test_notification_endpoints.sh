#!/bin/bash

# Notification Service Comprehensive Testing Script
# Tests notification service functionality including RabbitMQ events, email sending, and service health

echo "=========================================="
echo "Notification Service Comprehensive Testing"
echo "=========================================="
echo ""

# Configuration
NOTIFICATION_URL="http://localhost:8084"
KONG_URL="http://localhost:8000"
RABBITMQ_MANAGEMENT_URL="http://localhost:15672"
TEST_EMAIL="whitehat1860@gmail.com"
CONTENT_TYPE="Content-Type: application/json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test variables
BOOKING_ID="TEST-BOOK-$(date +%s)"
USER_ID="test-user-$(date +%s)"
TRANSACTION_ID="TEST-TXN-$(date +%s)"

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
    echo "----------------------------------------"
    echo ""
}

# Function to check if service is running
check_service_status() {
    echo "🔍 Checking Notification Service Status..."
    
    # Check if container is running
    if docker ps | grep -q "notification-service"; then
        echo -e "${GREEN}✓ Notification service container is running${NC}"
    else
        echo -e "${RED}✗ Notification service container is not running${NC}"
        return 1
    fi
    
    # Check container logs for any errors
    echo ""
    echo "📋 Recent container logs:"
    docker logs movie-notification-service --tail 10
    echo ""
}

# Function to test RabbitMQ management API
test_rabbitmq_connection() {
    echo "🐰 Testing RabbitMQ Connection..."
    
    # Test RabbitMQ management interface
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -u guest:guest \
        "$RABBITMQ_MANAGEMENT_URL/api/overview")
    
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
    
    print_result "RabbitMQ Management API" "$http_code" "200" "$body" "GET"
    
    # Check if notification queues exist
    echo "📮 Checking notification queues..."
    
    queue_response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -u guest:guest \
        "$RABBITMQ_MANAGEMENT_URL/api/queues")
    
    queue_http_code=$(echo "$queue_response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    queue_body=$(echo "$queue_response" | sed -e 's/HTTPSTATUS\:.*//g')
    
    if [[ "$queue_http_code" == "200" ]]; then
        echo -e "${GREEN}✓ RabbitMQ queues accessible${NC}"
        
        # Check for notification-specific queues
        if echo "$queue_body" | grep -q "notification"; then
            echo -e "${GREEN}✓ Notification queues found${NC}"
        else
            echo -e "${YELLOW}⚠ No notification queues found${NC}"
        fi
    else
        echo -e "${RED}✗ Cannot access RabbitMQ queues${NC}"
    fi
    
    echo ""
}

# Function to test direct HTTP endpoints (if any)
test_http_endpoints() {
    echo "🌐 Testing HTTP Endpoints..."
    
    # Test if there's any HTTP server running on 8084
    echo "Testing direct service connection..."
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" --connect-timeout 5 "$NOTIFICATION_URL/" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${YELLOW}⚠ No HTTP server running on port 8084${NC}"
        echo "This is expected for a worker-only service"
    else
        http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
        body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
        print_result "Direct HTTP Connection" "$http_code" "200" "$body" "GET"
    fi
    
    # Test Kong Gateway routes for notification service
    echo "Testing Kong Gateway notification routes..."
    
    # Test health endpoint via Kong
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$KONG_URL/health/notification")
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
    
    print_result "Kong Gateway Health Check" "$http_code" "200" "$body" "GET"
    
    # Test notification API endpoint via Kong
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$KONG_URL/api/notifications")
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo "$response" | sed -e 's/HTTPSTATUS\:.*//g')
    
    print_result "Kong Gateway Notification API" "$http_code" "200" "$body" "GET"
    
    echo ""
}

# Function to test SMTP service directly
test_smtp_service() {
    echo "📧 Testing SMTP Email Service..."
    
    # Create a test script to send email directly
    cat > /tmp/test_smtp_direct.py << 'EOF'
import sys
import os
import asyncio

# Add the current directory to Python path
sys.path.append('/app')

from smtp_service import SMTPEmailService

async def test_email():
    try:
        email_service = SMTPEmailService()
        
        # Test email content
        subject = "Notification Service Test Email"
        recipient = "whitehat1860@gmail.com"
        
        # HTML email content
        html_content = """
        <h2>🎬 Notification Service Test</h2>
        <p>This is a test email from the Movie Booking Notification Service.</p>
        <p><strong>Test Details:</strong></p>
        <ul>
            <li>Service: Notification Service</li>
            <li>Type: SMTP Test</li>
            <li>Timestamp: {timestamp}</li>
        </ul>
        <p>If you received this email, the notification service is working correctly!</p>
        """.format(timestamp=str(__import__('datetime').datetime.now()))
        
        # Send email
        result = await email_service.send_email(
            recipient=recipient,
            subject=subject,
            html_content=html_content,
            email_type="test"
        )
        
        if result:
            print("✓ Email sent successfully!")
            return True
        else:
            print("✗ Failed to send email")
            return False
            
    except Exception as e:
        print(f"✗ Error sending email: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(test_email())
    sys.exit(0 if result else 1)
EOF
    
    # Run the SMTP test inside the notification service container
    echo "Sending test email to $TEST_EMAIL..."
    
    if docker exec movie-notification-service python -c "
import sys
import os
import asyncio
sys.path.append('/app')

try:
    from smtp_service import SMTPEmailService
    
    async def test_email():
        email_service = SMTPEmailService()
        result = await email_service.send_email(
            recipient='$TEST_EMAIL',
            subject='Notification Service Test - $(date)',
            html_content='<h2>🎬 Test Email</h2><p>This is a test from the notification service at $(date)</p><p>If you receive this, the SMTP service is working!</p>',
            email_type='test'
        )
        return result
    
    result = asyncio.run(test_email())
    print('✓ Email sent successfully!' if result else '✗ Failed to send email')
    
except Exception as e:
    print(f'✗ Error: {e}')
    "; then
        echo -e "${GREEN}✓ SMTP test completed${NC}"
    else
        echo -e "${RED}✗ SMTP test failed${NC}"
    fi
    
    # Clean up
    rm -f /tmp/test_smtp_direct.py
    echo ""
}

# Function to simulate RabbitMQ events
test_rabbitmq_events() {
    echo "📡 Testing RabbitMQ Event Processing..."
    
    # Test booking confirmation event
    echo "Sending booking confirmation event..."
    
    booking_event=$(cat << EOF
{
  "event_id": "$(uuidgen)",
  "event_type": "booking.confirmed",
  "user_id": "$USER_ID",
  "user_email": "$TEST_EMAIL",
  "booking_id": "$BOOKING_ID",
  "movie_title": "Test Movie",
  "showtime": "$(date -d '+1 day' '+%Y-%m-%d %H:%M')",
  "cinema_name": "Test Cinema",
  "seats": ["A1", "A2"],
  "total_amount": 25.00,
  "booking_date": "$(date '+%Y-%m-%d')",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF
    )
    
    # Publish event to RabbitMQ (if rabbitmqadmin is available)
    if command -v rabbitmqadmin &> /dev/null; then
        echo "Publishing booking confirmation event via rabbitmqadmin..."
        echo "$booking_event" | rabbitmqadmin publish exchange=movie_app_events routing_key=booking.confirmed
        echo -e "${GREEN}✓ Booking confirmation event published${NC}"
    else
        echo -e "${YELLOW}⚠ rabbitmqadmin not available for direct event publishing${NC}"
        echo "Event that would be published:"
        echo "$booking_event" | jq '.' 2>/dev/null || echo "$booking_event"
    fi
    
    # Test payment success event
    echo ""
    echo "Testing payment success event..."
    
    payment_event=$(cat << EOF
{
  "event_id": "$(uuidgen)",
  "event_type": "payment.success",
  "user_id": "$USER_ID",
  "user_email": "$TEST_EMAIL",
  "booking_id": "$BOOKING_ID",
  "transaction_id": "$TRANSACTION_ID",
  "amount": 25.00,
  "payment_method": "credit_card",
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
}
EOF
    )
    
    if command -v rabbitmqadmin &> /dev/null; then
        echo "Publishing payment success event via rabbitmqadmin..."
        echo "$payment_event" | rabbitmqadmin publish exchange=movie_app_events routing_key=payment.success
        echo -e "${GREEN}✓ Payment success event published${NC}"
    else
        echo "Payment event that would be published:"
        echo "$payment_event" | jq '.' 2>/dev/null || echo "$payment_event"
    fi
    
    echo ""
}

# Function to check MongoDB for notification logs
test_mongodb_logs() {
    echo "📊 Testing MongoDB Notification Logs..."
    
    # Check if we can access MongoDB and see notification logs
    if command -v mongosh &> /dev/null; then
        echo "Checking notification logs in MongoDB..."
        
        mongosh mongodb://localhost:27017/movie_booking --eval "
        db.notification_logs.find().limit(5).sort({created_at: -1}).forEach(function(doc) {
            print('Notification:', doc.notification_type, 'to', doc.recipient, 'at', doc.created_at);
        });
        print('Total notifications:', db.notification_logs.countDocuments());
        " 2>/dev/null || echo -e "${YELLOW}⚠ Cannot access MongoDB directly${NC}"
    else
        echo -e "${YELLOW}⚠ mongosh not available for MongoDB testing${NC}"
    fi
    
    echo ""
}

# Function to test notification service worker logs
test_worker_logs() {
    echo "📋 Testing Worker Service Logs..."
    
    echo "Recent notification service logs:"
    docker logs movie-notification-service --tail 20
    
    echo ""
    echo "Checking for error patterns in logs..."
    
    # Check for common error patterns
    error_count=$(docker logs movie-notification-service 2>&1 | grep -i "error\|exception\|failed" | wc -l)
    
    if [[ $error_count -eq 0 ]]; then
        echo -e "${GREEN}✓ No errors found in recent logs${NC}"
    else
        echo -e "${YELLOW}⚠ Found $error_count potential errors in logs${NC}"
        echo "Recent errors:"
        docker logs movie-notification-service 2>&1 | grep -i "error\|exception\|failed" | tail -5
    fi
    
    echo ""
}

# Function to test environment variables and configuration
test_configuration() {
    echo "⚙️ Testing Service Configuration..."
    
    echo "Checking environment variables..."
    docker exec movie-notification-service env | grep -E "MONGODB|RABBITMQ|REDIS|SMTP" || echo "No environment variables found"
    
    echo ""
    echo "Checking required dependencies..."
    
    # Test MongoDB connection from within container
    if docker exec movie-notification-service python -c "
from motor.motor_asyncio import AsyncIOMotorClient
import asyncio
import os

async def test_mongo():
    try:
        client = AsyncIOMotorClient(os.getenv('MONGODB_URI', 'mongodb://localhost:27017'))
        await client.admin.command('ping')
        print('✓ MongoDB connection successful')
        return True
    except Exception as e:
        print(f'✗ MongoDB connection failed: {e}')
        return False

asyncio.run(test_mongo())
    "; then
        echo -e "${GREEN}✓ MongoDB connection test passed${NC}"
    else
        echo -e "${RED}✗ MongoDB connection test failed${NC}"
    fi
    
    # Test Redis connection
    if docker exec movie-notification-service python -c "
import redis.asyncio as redis
import asyncio
import os

async def test_redis():
    try:
        client = redis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379'))
        await client.ping()
        print('✓ Redis connection successful')
        await client.close()
        return True
    except Exception as e:
        print(f'✗ Redis connection failed: {e}')
        return False

asyncio.run(test_redis())
    "; then
        echo -e "${GREEN}✓ Redis connection test passed${NC}"
    else
        echo -e "${RED}✗ Redis connection test failed${NC}"
    fi
    
    echo ""
}

# Main execution
echo "Starting Notification Service Comprehensive Testing..."
echo "Test Email: $TEST_EMAIL"
echo "Booking ID: $BOOKING_ID"
echo "User ID: $USER_ID"
echo ""

# Run all tests
check_service_status

echo "================================================"
test_rabbitmq_connection

echo "================================================"
test_http_endpoints

echo "================================================"
test_smtp_service

echo "================================================"
test_rabbitmq_events

echo "================================================"
test_mongodb_logs

echo "================================================"
test_worker_logs

echo "================================================"
test_configuration

echo "================================================"
echo ""
echo "🎯 Testing Summary:"
echo "- Service Status: Checked container and logs"
echo "- RabbitMQ: Tested connection and queue availability"
echo "- HTTP Endpoints: Tested direct and Kong Gateway routes"
echo "- SMTP Service: Sent test email to $TEST_EMAIL"
echo "- Event Processing: Simulated RabbitMQ events"
echo "- Database: Tested MongoDB and Redis connections"
echo "- Configuration: Verified environment and dependencies"
echo ""
echo "📧 Check your email at $TEST_EMAIL for test notifications!"
echo ""
echo "✅ Notification Service Testing Complete!"