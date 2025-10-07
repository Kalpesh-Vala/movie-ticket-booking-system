"""
Test configuration and fixtures for booking service tests
"""

import pytest
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from fastapi.testclient import TestClient
from datetime import datetime, timezone

# Import app with mocked dependencies
with patch('app.database.connect_to_mongo'), \
     patch('app.main.EventPublisher'):
    from app.main import app

from app.grpc_client import CinemaServiceClient
from app.rest_client import UserServiceClient, PaymentServiceClient
from app.event_publisher import EventPublisher


@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    yield loop
    loop.close()


@pytest.fixture
def client():
    """Create a test client for FastAPI app"""
    with patch('app.main.connect_to_mongo'), \
         patch('app.main.EventPublisher'):
        return TestClient(app)


@pytest.fixture
async def mock_database():
    """Mock database for testing"""
    mock_db = AsyncMock()
    mock_collection = AsyncMock()
    mock_db.bookings = mock_collection
    return mock_db


@pytest.fixture
def mock_cinema_client():
    """Mock cinema service client"""
    client = AsyncMock(spec=CinemaServiceClient)
    return client


@pytest.fixture
def mock_user_client():
    """Mock user service client"""
    client = AsyncMock(spec=UserServiceClient)
    return client


@pytest.fixture
def mock_payment_client():
    """Mock payment service client"""
    client = AsyncMock(spec=PaymentServiceClient)
    return client


@pytest.fixture
def mock_event_publisher():
    """Mock event publisher"""
    publisher = AsyncMock(spec=EventPublisher)
    return publisher


@pytest.fixture
def sample_booking_data():
    """Sample booking data for tests"""
    return {
        "user_id": "user_123",
        "showtime_id": "showtime_456",
        "seat_numbers": ["A1", "A2"],
        "total_amount": 31.98
    }


@pytest.fixture
def sample_user_data():
    """Sample user data for tests"""
    return {
        "id": "user_123",
        "email": "test@example.com",
        "full_name": "Test User",
        "phone": "+1234567890"
    }


@pytest.fixture
def sample_showtime_data():
    """Sample showtime data for tests"""
    return {
        "showtime_id": "showtime_456",
        "movie_id": "movie_123",
        "cinema_id": "cinema_789",
        "screen_id": "screen_001",
        "start_time": datetime.now(timezone.utc),
        "end_time": datetime.now(timezone.utc),
        "base_price": 15.99,
        "available_seats": ["A1", "A2", "A3", "B1", "B2"]
    }