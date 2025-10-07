#!/usr/bin/env python3
"""
Booking Service Test Runner
Run this to test the booking service without external dependencies
"""

import asyncio
import sys
import subprocess
from pathlib import Path

# Add the current directory to Python path
sys.path.append(str(Path(__file__).parent))

def run_tests():
    """Run unit tests"""
    print("🧪 Running unit tests...")
    result = subprocess.run([
        sys.executable, "-m", "pytest", 
        "tests/test_models.py", 
        "tests/test_grpc_client.py",
        "-v"
    ], capture_output=True, text=True)
    
    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)
    
    return result.returncode == 0

def test_models():
    """Test that models work correctly"""
    print("📋 Testing models...")
    try:
        from app.models import Booking, BookingStatus, User, ShowtimeDetails
        from datetime import datetime
        
        # Test Booking model
        booking = Booking(
            user_id="user_123",
            showtime_id="showtime_456",
            seats=["A1", "A2"],
            total_amount=31.98,
            status=BookingStatus.PENDING_PAYMENT,
            created_at=datetime.now(),
            updated_at=datetime.now()
        )
        
        # Test User model
        user = User(
            id="user_123",
            email="test@example.com",
            full_name="Test User"
        )
        
        # Test ShowtimeDetails model
        showtime = ShowtimeDetails(
            showtime_id="showtime_456",
            movie_id="movie_123",
            cinema_id="cinema_456",
            screen_id="screen_789",
            start_time=datetime.now(),
            end_time=datetime.now(),
            base_price=15.99,
            available_seats=["A1", "A2", "A3"]
        )
        
        print("✅ All models work correctly!")
        print(f"   - Booking ID: {booking.id}")
        print(f"   - User: {user.full_name} ({user.email})")
        print(f"   - Showtime: {showtime.showtime_id}")
        return True
        
    except Exception as e:
        print(f"❌ Model test failed: {e}")
        return False

def test_app_import():
    """Test that the app can be imported with mocked dependencies"""
    print("📦 Testing app import with mocked dependencies...")
    try:
        from unittest.mock import patch, AsyncMock
        
        with patch('app.database.connect_to_mongo') as mock_connect, \
             patch('app.event_publisher.EventPublisher') as mock_event_publisher_class:
            
            # Setup mocks properly
            mock_connect.return_value = None
            mock_event_publisher = AsyncMock()
            mock_event_publisher.connect = AsyncMock()
            mock_event_publisher.close = AsyncMock()
            mock_event_publisher_class.return_value = mock_event_publisher
            
            from app.main import app
            print("✅ App imported successfully!")
            return True
            
    except Exception as e:
        print(f"❌ App import failed: {e}")
        return False

def test_graphql_schema():
    """Test GraphQL schema creation"""
    print("🔗 Testing GraphQL schema...")
    try:
        from unittest.mock import patch
        
        with patch('app.database.connect_to_mongo'), \
             patch('app.event_publisher.EventPublisher'):
            from app.graphql_resolvers import schema
            
            # Check if schema has the expected types
            schema_str = str(schema)
            
            if "Query" in schema_str and "Mutation" in schema_str:
                print("✅ GraphQL schema created successfully!")
                return True
            else:
                print("❌ GraphQL schema missing required types")
                return False
                
    except Exception as e:
        print(f"❌ GraphQL schema test failed: {e}")
        return False

def main():
    """Main test function"""
    print("🎬 Movie Ticket Booking Service - Test Suite")
    print("=" * 50)
    
    tests = [
        ("Models Test", test_models),
        ("App Import Test", test_app_import),
        ("GraphQL Schema Test", test_graphql_schema),
        ("Unit Tests", run_tests),
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n🔍 {test_name}")
        print("-" * 30)
        success = test_func()
        results.append((test_name, success))
    
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print("=" * 50)
    
    passed = 0
    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} - {test_name}")
        if success:
            passed += 1
    
    print(f"\nResults: {passed}/{len(results)} tests passed")
    
    if passed == len(results):
        print("\n🎉 All tests passed! The booking service is ready.")
        print("\n💡 Next steps:")
        print("   1. Start MongoDB: docker-compose up -d mongodb")
        print("   2. Start RabbitMQ: docker-compose up -d rabbitmq")
        print("   3. Run the service: ./start.sh")
    else:
        print(f"\n⚠️ {len(results) - passed} test(s) failed. Please check the errors above.")
    
    return passed == len(results)

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)