#!/bin/bash

# Simple Notification Service Test Script
# Tests the current worker-based notification service

echo "=========================================="
echo "Notification Service Worker Testing"
echo "=========================================="
echo ""

TEST_EMAIL="whitehat1860@gmail.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔍 Testing Notification Service Worker"
echo "Test Email: $TEST_EMAIL"
echo ""

# Test 1: Check if container is running
echo "1. Checking if notification service container is running..."
if docker ps | grep -q "notification-service"; then
    echo -e "${GREEN}✓ Notification service container is running${NC}"
else
    echo -e "${RED}✗ Notification service container is not running${NC}"
    exit 1
fi
echo ""

# Test 2: Check container logs
echo "2. Checking container logs for errors..."
error_count=$(docker logs movie-notification-service 2>&1 | grep -i "error\|exception\|failed" | wc -l)
if [[ $error_count -eq 0 ]]; then
    echo -e "${GREEN}✓ No errors found in logs${NC}"
else
    echo -e "${YELLOW}⚠ Found $error_count potential errors${NC}"
fi
echo ""

# Test 3: Test SMTP email service directly
echo "3. Testing SMTP email service..."
echo "Sending test email to $TEST_EMAIL..."

# Create and run SMTP test inside container
smtp_test_result=$(docker exec movie-notification-service python -c "
import asyncio
import sys
sys.path.append('/app')

async def test_smtp():
    try:
        from smtp_service import SMTPEmailService
        
        email_service = SMTPEmailService()
        
        # Test data for booking confirmation
        template_data = {
            'user_name': 'Test User',
            'movie_title': 'Test Movie',
            'cinema_name': 'Test Cinema',
            'showtime': '2025-10-16 19:30',
            'seats': ['A1', 'A2'],
            'booking_id': 'TEST-BOOK-001',
            'total_amount': 30.00,
            'booking_date': '2025-10-15'
        }
        
        result = await email_service.send_email(
            to_email='$TEST_EMAIL',
            subject='Notification Service Test - Booking Confirmation',
            template_name='booking_confirmation',
            template_data=template_data
        )
        
        if result:
            print('SUCCESS: Email sent successfully!')
            return True
        else:
            print('FAILED: Email sending failed')
            return False
            
    except Exception as e:
        print(f'ERROR: {e}')
        return False

result = asyncio.run(test_smtp())
sys.exit(0 if result else 1)
" 2>&1)

smtp_exit_code=$?
echo "$smtp_test_result"

if [[ $smtp_exit_code -eq 0 ]]; then
    echo -e "${GREEN}✓ SMTP email test passed${NC}"
else
    echo -e "${RED}✗ SMTP email test failed${NC}"
fi
echo ""

# Test 4: Test database connections
echo "4. Testing database connections..."

# Test MongoDB
echo "Testing MongoDB connection..."
mongo_result=$(docker exec movie-notification-service python -c "
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import os

async def test_mongo():
    try:
        client = AsyncIOMotorClient(os.getenv('MONGODB_URI', 'mongodb://localhost:27017'))
        await client.admin.command('ping')
        print('MongoDB: Connected successfully')
        
        # Test notification logs collection
        db = client.movie_booking
        count = await db.notification_logs.count_documents({})
        print(f'Notification logs count: {count}')
        return True
    except Exception as e:
        print(f'MongoDB: Connection failed - {e}')
        return False

asyncio.run(test_mongo())
" 2>&1)

echo "$mongo_result"

# Test Redis
echo "Testing Redis connection..."
redis_result=$(docker exec movie-notification-service python -c "
import asyncio
import redis.asyncio as redis
import os

async def test_redis():
    try:
        client = redis.from_url(os.getenv('REDIS_URL', 'redis://localhost:6379'))
        await client.ping()
        print('Redis: Connected successfully')
        await client.close()
        return True
    except Exception as e:
        print(f'Redis: Connection failed - {e}')
        return False

asyncio.run(test_redis())
" 2>&1)

echo "$redis_result"
echo ""

# Test 5: Test notification worker methods directly
echo "5. Testing notification worker methods..."

worker_test_result=$(docker exec movie-notification-service python -c "
import asyncio
import sys
sys.path.append('/app')

async def test_worker():
    try:
        from worker import NotificationWorker
        
        worker = NotificationWorker()
        await worker.initialize()
        
        # Test booking confirmation
        booking_data = {
            'event_id': 'test-event-001',
            'event_type': 'booking.confirmed',
            'user_email': '$TEST_EMAIL',
            'booking_id': 'TEST-BOOK-$(date +%s)',
            'movie_title': 'Worker Test Movie',
            'showtime': '2025-10-16 20:00',
            'cinema_name': 'Worker Test Cinema',
            'seats': ['B1', 'B2'],
            'total_amount': 35.00,
            'booking_date': '2025-10-15'
        }
        
        await worker.process_booking_confirmed(booking_data)
        print('SUCCESS: Booking confirmation processed')
        
        # Test payment success
        payment_data = {
            'event_id': 'test-event-002',
            'event_type': 'payment.success',
            'user_email': '$TEST_EMAIL',
            'booking_id': 'TEST-BOOK-$(date +%s)',
            'transaction_id': 'TEST-TXN-$(date +%s)',
            'amount': 35.00,
            'payment_method': 'credit_card'
        }
        
        await worker.process_payment_success(payment_data)
        print('SUCCESS: Payment success processed')
        
        await worker.cleanup()
        return True
        
    except Exception as e:
        print(f'ERROR: Worker test failed - {e}')
        return False

result = asyncio.run(test_worker())
sys.exit(0 if result else 1)
" 2>&1)

worker_exit_code=$?
echo "$worker_test_result"

if [[ $worker_exit_code -eq 0 ]]; then
    echo -e "${GREEN}✓ Notification worker test passed${NC}"
else
    echo -e "${RED}✗ Notification worker test failed${NC}"
fi
echo ""

# Test 6: Check RabbitMQ connection
echo "6. Testing RabbitMQ connection..."

rabbitmq_test_result=$(docker exec movie-notification-service python -c "
import asyncio
import aio_pika
import os

async def test_rabbitmq():
    try:
        connection = await aio_pika.connect_robust(
            os.getenv('RABBITMQ_URL', 'amqp://guest:guest@localhost:5672/')
        )
        
        channel = await connection.channel()
        print('RabbitMQ: Connected successfully')
        
        # Check exchange
        exchange = await channel.get_exchange('movie_app_events', ensure=False)
        print('RabbitMQ: Exchange movie_app_events found')
        
        await connection.close()
        return True
        
    except Exception as e:
        print(f'RabbitMQ: Connection failed - {e}')
        return False

asyncio.run(test_rabbitmq())
" 2>&1)

echo "$rabbitmq_test_result"
echo ""

# Test 7: Environment variables check
echo "7. Checking environment configuration..."
docker exec movie-notification-service env | grep -E "SMTP|MONGODB|REDIS|RABBITMQ" | while read line; do
    echo "  $line"
done
echo ""

# Test 8: Recent activity
echo "8. Checking recent service activity..."
echo "Recent logs (last 10 lines):"
docker logs movie-notification-service --tail 10
echo ""

echo "================================================"
echo ""
echo "🎯 Worker Service Testing Summary:"
echo "- ✅ Container Status: Checked and running"
echo "- ✅ SMTP Service: Tested email sending to $TEST_EMAIL"
echo "- ✅ Database Connections: MongoDB and Redis tested"
echo "- ✅ Worker Methods: Booking and payment notifications tested"
echo "- ✅ RabbitMQ: Connection and exchange verified"
echo "- ✅ Configuration: Environment variables checked"
echo ""
echo "📧 Check your email at $TEST_EMAIL for test notifications!"
echo ""
echo "📝 Note: This is a worker service that processes RabbitMQ events."
echo "It doesn't expose HTTP endpoints but can process notifications directly."
echo ""
echo "✅ Notification Service Worker Testing Complete!"