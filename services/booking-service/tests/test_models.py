"""
Unit tests for booking service models
"""

import pytest
from datetime import datetime, timezone
from pydantic import ValidationError

from app.models import Booking, BookingStatus, User, ShowtimeDetails


class TestBooking:
    """Test Booking model"""
    
    def test_booking_creation(self):
        """Test booking model creation"""
        now = datetime.now(timezone.utc)
        booking = Booking(
            id="booking_123",
            user_id="user_456",
            showtime_id="showtime_789",
            seats=["A1", "A2"],
            total_amount=31.98,
            status=BookingStatus.PENDING_PAYMENT,
            created_at=now,
            updated_at=now
        )
        
        assert booking.id == "booking_123"
        assert booking.user_id == "user_456"
        assert booking.showtime_id == "showtime_789"
        assert booking.seats == ["A1", "A2"]
        assert booking.total_amount == 31.98
        assert booking.status == BookingStatus.PENDING_PAYMENT
        assert booking.created_at == now
        assert booking.updated_at == now
    
    def test_booking_to_dict(self):
        """Test booking conversion to dictionary"""
        now = datetime.now(timezone.utc)
        booking = Booking(
            id="booking_123",
            user_id="user_456",
            showtime_id="showtime_789",
            seats=["A1", "A2"],
            total_amount=31.98,
            status=BookingStatus.PENDING_PAYMENT,
            created_at=now,
            updated_at=now
        )
        
        booking_dict = booking.to_dict()
        
        assert booking_dict["_id"] == "booking_123"
        assert booking_dict["user_id"] == "user_456"
        assert booking_dict["status"] == "pending_payment"
        assert booking_dict["seats"] == ["A1", "A2"]
        assert booking_dict["total_amount"] == 31.98
    
    def test_booking_status_enum(self):
        """Test booking status enum values"""
        assert BookingStatus.PENDING_PAYMENT.value == "pending_payment"
        assert BookingStatus.CONFIRMED.value == "confirmed"
        assert BookingStatus.CANCELLED.value == "cancelled"
        assert BookingStatus.REFUND_PENDING.value == "refund_pending"
        assert BookingStatus.REFUNDED.value == "refunded"
    
    def test_booking_validation_error(self):
        """Test booking validation errors"""
        with pytest.raises(ValidationError):
            # Missing required fields
            Booking(
                user_id="user_456",
                showtime_id="showtime_789"
                # Missing other required fields
            )


class TestUser:
    """Test User model"""
    
    def test_user_creation(self):
        """Test user model creation"""
        user = User(
            id="user_123",
            email="test@example.com",
            full_name="Test User",
            phone="+1234567890"
        )
        
        assert user.id == "user_123"
        assert user.email == "test@example.com"
        assert user.full_name == "Test User"
        assert user.phone == "+1234567890"
    
    def test_user_optional_phone(self):
        """Test user creation without phone"""
        user = User(
            id="user_123",
            email="test@example.com",
            full_name="Test User"
        )
        
        assert user.phone is None
    
    def test_user_validation_error(self):
        """Test user validation errors"""
        with pytest.raises(ValidationError):
            # Missing required fields
            User(
                email="test@example.com"
                # Missing id and full_name which are required
            )


class TestShowtimeDetails:
    """Test ShowtimeDetails model"""
    
    def test_showtime_creation(self):
        """Test showtime details creation"""
        now = datetime.now(timezone.utc)
        showtime = ShowtimeDetails(
            showtime_id="showtime_123",
            movie_id="movie_456",
            cinema_id="cinema_789",
            screen_id="screen_001",
            start_time=now,
            end_time=now,
            base_price=15.99,
            available_seats=["A1", "A2", "A3"]
        )
        
        assert showtime.showtime_id == "showtime_123"
        assert showtime.movie_id == "movie_456"
        assert showtime.cinema_id == "cinema_789"
        assert showtime.screen_id == "screen_001"
        assert showtime.base_price == 15.99
        assert showtime.available_seats == ["A1", "A2", "A3"]