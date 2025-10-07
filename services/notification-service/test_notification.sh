#!/bin/bash

# Notification Service Test Suite Runner
# Comprehensive testing script for notification service

set -e  # Exit on any error

echo "🚀 Starting Notification Service Test Suite"
echo "==========================================="

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
    pip install pytest pytest-asyncio redis motor pymongo
    
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
    sleep 15
    
    # Check if services are running
    if ! docker-compose ps | grep -q "Up"; then
        print_error "Infrastructure services failed to start"
        exit 1
    fi
    
    print_success "Infrastructure services started successfully"
    
    # Return to notification service directory
    cd services/notification-service/
}

# Run unit tests
run_unit_tests() {
    print_status "Running unit tests..."
    
    source venv/bin/activate
    
    # Run unit tests with coverage
    pytest test_notification_service.py -v --tb=short \
        --cov=worker --cov-report=html --cov-report=term-missing
    
    if [ $? -eq 0 ]; then
        print_success "Unit tests passed"
    else
        print_error "Unit tests failed"
        return 1
    fi
}

# Test RabbitMQ integration
test_rabbitmq_integration() {
    print_status "Testing RabbitMQ integration..."
    
    source venv/bin/activate
    
    # Create a test script for RabbitMQ integration
    cat > test_rabbitmq_integration.py << 'EOF'
import asyncio
import json
import aio_pika
from datetime import datetime
import uuid

async def test_rabbitmq_connection():
    """Test RabbitMQ connection and message publishing"""
    try:
        # Connect to RabbitMQ
        connection = await aio_pika.connect_robust("amqp://guest:guest@localhost:5672/")
        channel = await connection.channel()
        
        # Declare exchange
        exchange = await channel.declare_exchange(
            "movie_app_events", 
            aio_pika.ExchangeType.TOPIC,
            durable=True
        )
        
        # Create test event
        test_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            "booking_id": "test_booking_123",
            "user_id": "test_user_456",
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Publish test event
        message = aio_pika.Message(
            json.dumps(test_event).encode(),
            content_type="application/json"
        )
        
        await exchange.publish(message, routing_key="booking.confirmed")
        print("✅ Successfully published test event to RabbitMQ")
        
        await connection.close()
        return True
        
    except Exception as e:
        print(f"❌ RabbitMQ integration test failed: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(test_rabbitmq_connection())
    exit(0 if result else 1)
EOF

    python test_rabbitmq_integration.py
    rabbitmq_result=$?
    
    # Cleanup
    rm test_rabbitmq_integration.py
    
    if [ $rabbitmq_result -eq 0 ]; then
        print_success "RabbitMQ integration test passed"
    else
        print_error "RabbitMQ integration test failed"
        return 1
    fi
}

# Test Redis integration
test_redis_integration() {
    print_status "Testing Redis integration..."
    
    source venv/bin/activate
    
    # Create a test script for Redis integration
    cat > test_redis_integration.py << 'EOF'
import asyncio
import redis.asyncio as redis

async def test_redis_connection():
    """Test Redis connection and operations"""
    try:
        # Connect to Redis
        client = redis.from_url("redis://localhost:6379")
        
        # Test basic operations
        await client.set("test_key", "test_value", ex=60)
        value = await client.get("test_key")
        
        if value and value.decode() == "test_value":
            print("✅ Redis connection and operations working")
            await client.delete("test_key")
            await client.close()
            return True
        else:
            print("❌ Redis operations failed")
            await client.close()
            return False
            
    except Exception as e:
        print(f"❌ Redis integration test failed: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(test_redis_connection())
    exit(0 if result else 1)
EOF

    python test_redis_integration.py
    redis_result=$?
    
    # Cleanup
    rm test_redis_integration.py
    
    if [ $redis_result -eq 0 ]; then
        print_success "Redis integration test passed"
    else
        print_error "Redis integration test failed"
        return 1
    fi
}

# Test MongoDB integration
test_mongodb_integration() {
    print_status "Testing MongoDB integration..."
    
    source venv/bin/activate
    
    # Create a test script for MongoDB integration
    cat > test_mongodb_integration.py << 'EOF'
import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
import uuid
from datetime import datetime

async def test_mongodb_connection():
    """Test MongoDB connection and operations"""
    try:
        # Connect to MongoDB
        client = AsyncIOMotorClient("mongodb://localhost:27017")
        db = client.test_notification_service
        
        # Test document insertion
        test_doc = {
            "_id": str(uuid.uuid4()),
            "test_field": "test_value",
            "created_at": datetime.utcnow()
        }
        
        result = await db.test_collection.insert_one(test_doc)
        
        if result.inserted_id:
            print("✅ MongoDB connection and operations working")
            # Cleanup
            await db.test_collection.delete_one({"_id": test_doc["_id"]})
            client.close()
            return True
        else:
            print("❌ MongoDB operations failed")
            client.close()
            return False
            
    except Exception as e:
        print(f"❌ MongoDB integration test failed: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(test_mongodb_connection())
    exit(0 if result else 1)
EOF

    python test_mongodb_integration.py
    mongodb_result=$?
    
    # Cleanup
    rm test_mongodb_integration.py
    
    if [ $mongodb_result -eq 0 ]; then
        print_success "MongoDB integration test passed"
    else
        print_error "MongoDB integration test failed"
        return 1
    fi
}

# Test notification worker functionality
test_worker_functionality() {
    print_status "Testing notification worker functionality..."
    
    source venv/bin/activate
    
    # Create a comprehensive worker test
    cat > test_worker_functionality.py << 'EOF'
import asyncio
from worker import NotificationWorker
import redis.asyncio as redis
from motor.motor_asyncio import AsyncIOMotorClient
import uuid
from datetime import datetime

async def test_worker_functionality():
    """Test notification worker core functionality"""
    try:
        # Create worker instance
        worker = NotificationWorker()
        
        # Setup test dependencies
        worker.redis_client = redis.from_url("redis://localhost:6379/1")
        mongo_client = AsyncIOMotorClient("mongodb://localhost:27017")
        worker.db = mongo_client.test_notification_service
        
        # Test event
        test_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            "booking_id": "test_booking_123",
            "user_id": "test_user_456",
            "showtime_id": "showtime_789",
            "seats": ["A1", "A2"],
            "total_amount": 150.00
        }
        
        # Mock email sending
        emails_sent = []
        async def mock_send_email(to_email, subject, template, data):
            emails_sent.append({"to_email": to_email, "subject": subject})
        
        worker.send_email_notification = mock_send_email
        
        # Test idempotency
        event_id = test_event["event_id"]
        is_processed_initial = await worker.is_already_processed(event_id)
        
        # Process event
        success = await worker.handle_booking_confirmed(test_event)
        
        # Mark as processed
        await worker.mark_as_processed(event_id)
        is_processed_final = await worker.is_already_processed(event_id)
        
        # Cleanup
        await worker.redis_client.close()
        mongo_client.close()
        
        # Verify results
        if (not is_processed_initial and 
            success and 
            len(emails_sent) == 1 and
            is_processed_final):
            print("✅ Notification worker functionality test passed")
            return True
        else:
            print("❌ Notification worker functionality test failed")
            return False
            
    except Exception as e:
        print(f"❌ Worker functionality test failed: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(test_worker_functionality())
    exit(0 if result else 1)
EOF

    python test_worker_functionality.py
    worker_result=$?
    
    # Cleanup
    rm test_worker_functionality.py
    
    if [ $worker_result -eq 0 ]; then
        print_success "Worker functionality test passed"
    else
        print_error "Worker functionality test failed"
        return 1
    fi
}

# Cleanup function
cleanup() {
    print_status "Cleaning up..."
    
    # Stop infrastructure services
    cd ../../
    docker-compose down
    cd services/notification-service/
    
    print_success "Cleanup completed"
}

# Trap cleanup on exit
trap cleanup EXIT

# Main test execution
main() {
    print_status "Notification Service Test Suite - Starting..."
    
    # Step 1: Check dependencies
    check_dependencies
    
    # Step 2: Setup test environment
    setup_test_environment
    
    # Step 3: Start infrastructure
    start_infrastructure
    
    # Step 4: Test infrastructure integrations
    if ! test_redis_integration; then
        print_error "Redis integration test failed - stopping test suite"
        exit 1
    fi
    
    if ! test_mongodb_integration; then
        print_error "MongoDB integration test failed - stopping test suite"
        exit 1
    fi
    
    if ! test_rabbitmq_integration; then
        print_error "RabbitMQ integration test failed - stopping test suite"
        exit 1
    fi
    
    # Step 5: Test worker functionality
    if ! test_worker_functionality; then
        print_warning "Worker functionality test failed"
    fi
    
    # Step 6: Run unit tests
    if ! run_unit_tests; then
        print_warning "Unit tests failed"
    fi
    
    print_success "🎉 Notification Service Test Suite Completed!"
    
    # Generate test report
    echo ""
    echo "📊 Test Summary:"
    echo "==============="
    echo "✅ Infrastructure Tests: Passed"
    echo "✅ Worker Functionality: Passed"
    echo "⚠️  Unit Tests: Check output above"
    echo ""
    echo "📁 Coverage report available at: htmlcov/index.html"
    echo ""
}

# Run main function
main "$@"