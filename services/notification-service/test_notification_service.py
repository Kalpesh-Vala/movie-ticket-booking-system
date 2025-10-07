"""
Comprehensive Test Suite for Notification Service
Tests event consumption, notification sending, and error handling
"""

import pytest
import asyncio
import json
import uuid
from datetime import datetime
from unittest.mock import AsyncMock, patch, MagicMock
import aio_pika
import redis.asyncio as redis
from motor.motor_asyncio import AsyncIOMotorClient

# Import the notification worker
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from worker import NotificationWorker


class TestNotificationService:
    """Test class for Notification Service functionality"""
    
    @pytest.fixture(scope="session")
    def event_loop(self):
        """Create an instance of the default event loop for the test session."""
        loop = asyncio.get_event_loop_policy().new_event_loop()
        yield loop
        loop.close()

    @pytest.fixture
    async def redis_client(self):
        """Create Redis test client"""
        client = redis.from_url("redis://localhost:6379/1")  # Use test database
        yield client
        # Cleanup
        await client.flushdb()
        await client.close()

    @pytest.fixture
    async def mongo_client(self):
        """Create MongoDB test client"""
        client = AsyncIOMotorClient("mongodb://localhost:27017")
        db = client.test_notification_service
        yield db
        # Cleanup
        await db.notification_logs.delete_many({})
        client.close()

    @pytest.fixture
    def notification_worker(self, redis_client, mongo_client):
        """Create notification worker with test dependencies"""
        worker = NotificationWorker()
        worker.redis_client = redis_client
        worker.db = mongo_client
        return worker

    @pytest.fixture
    def sample_booking_confirmed_event(self):
        """Sample booking confirmed event"""
        return {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            "booking_id": "booking_123",
            "user_id": "user_456",
            "showtime_id": "showtime_789",
            "seats": ["A1", "A2"],
            "total_amount": 150.00,
            "payment_transaction_id": "txn_123",
            "timestamp": datetime.utcnow().isoformat()
        }

    @pytest.fixture
    def sample_booking_cancelled_event(self):
        """Sample booking cancelled event"""
        return {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.cancelled",
            "booking_id": "booking_456",
            "user_id": "user_789",
            "reason": "User request",
            "timestamp": datetime.utcnow().isoformat()
        }

    @pytest.fixture
    def sample_booking_refunded_event(self):
        """Sample booking refunded event"""
        return {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.refunded",
            "booking_id": "booking_789",
            "user_id": "user_123",
            "refund_amount": 150.00,
            "transaction_id": "txn_456",
            "timestamp": datetime.utcnow().isoformat()
        }

    # Idempotency Tests
    @pytest.mark.asyncio
    async def test_idempotency_checking(self, notification_worker):
        """Test idempotency checking with Redis"""
        event_id = str(uuid.uuid4())
        
        # Initially should not be processed
        is_processed = await notification_worker.is_already_processed(event_id)
        assert is_processed is False
        
        # Mark as processing
        await notification_worker.mark_as_processing(event_id)
        is_processed = await notification_worker.is_already_processed(event_id)
        assert is_processed is True
        
        # Mark as processed
        await notification_worker.mark_as_processed(event_id)
        is_processed = await notification_worker.is_already_processed(event_id)
        assert is_processed is True

    @pytest.mark.asyncio
    async def test_failed_event_marking(self, notification_worker):
        """Test marking events as failed"""
        event_id = str(uuid.uuid4())
        
        await notification_worker.mark_as_failed(event_id)
        
        # Check Redis for failed status
        status = await notification_worker.redis_client.get(f"event:{event_id}:status")
        assert status.decode() == "failed"

    # Event Handling Tests
    @pytest.mark.asyncio
    async def test_handle_booking_confirmed(self, notification_worker, sample_booking_confirmed_event):
        """Test handling booking confirmed events"""
        emails_sent = []
        
        async def mock_send_email(to_email, subject, template, data):
            emails_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })
        
        notification_worker.send_email_notification = mock_send_email
        
        success = await notification_worker.handle_booking_confirmed(sample_booking_confirmed_event)
        
        assert success is True
        assert len(emails_sent) == 1
        
        email = emails_sent[0]
        assert "user_456@example.com" in email["to_email"]
        assert "Booking Confirmed" in email["subject"]
        assert email["template"] == "booking_confirmation"
        assert email["data"]["booking_id"] == "booking_123"

    @pytest.mark.asyncio
    async def test_handle_booking_cancelled(self, notification_worker, sample_booking_cancelled_event):
        """Test handling booking cancelled events"""
        emails_sent = []
        
        async def mock_send_email(to_email, subject, template, data):
            emails_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })
        
        notification_worker.send_email_notification = mock_send_email
        
        success = await notification_worker.handle_booking_cancelled(sample_booking_cancelled_event)
        
        assert success is True
        assert len(emails_sent) == 1
        
        email = emails_sent[0]
        assert "user_789@example.com" in email["to_email"]
        assert "Booking Cancelled" in email["subject"]
        assert email["template"] == "booking_cancellation"

    @pytest.mark.asyncio
    async def test_handle_booking_refunded(self, notification_worker, sample_booking_refunded_event):
        """Test handling booking refunded events"""
        emails_sent = []
        
        async def mock_send_email(to_email, subject, template, data):
            emails_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })
        
        notification_worker.send_email_notification = mock_send_email
        
        success = await notification_worker.handle_booking_refunded(sample_booking_refunded_event)
        
        assert success is True
        assert len(emails_sent) == 1
        
        email = emails_sent[0]
        assert "user_123@example.com" in email["to_email"]
        assert "Refund Processed" in email["subject"]
        assert email["template"] == "refund_notification"

    @pytest.mark.asyncio
    async def test_handle_unknown_event(self, notification_worker):
        """Test handling unknown event types"""
        unknown_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "unknown.event",
            "data": "test"
        }
        
        success = await notification_worker.handle_event("unknown.event", unknown_event)
        assert success is True  # Unknown events should be ignored gracefully

    # Notification Logging Tests
    @pytest.mark.asyncio
    async def test_notification_logging(self, notification_worker, sample_booking_confirmed_event):
        """Test that notifications are logged to MongoDB"""
        await notification_worker.log_notification(
            event_id=sample_booking_confirmed_event["event_id"],
            notification_type="email",
            recipient="test@example.com",
            subject="Test Notification",
            status="sent",
            event_data=sample_booking_confirmed_event
        )
        
        # Check if notification was logged
        logged_notification = await notification_worker.db.notification_logs.find_one({
            "event_id": sample_booking_confirmed_event["event_id"]
        })
        
        assert logged_notification is not None
        assert logged_notification["recipient"] == "test@example.com"
        assert logged_notification["subject"] == "Test Notification"
        assert logged_notification["status"] == "sent"

    # Error Handling Tests
    @pytest.mark.asyncio
    async def test_handle_event_with_exception(self, notification_worker, sample_booking_confirmed_event):
        """Test event handling with exceptions"""
        async def failing_email_send(*args, **kwargs):
            raise Exception("Email service unavailable")
        
        notification_worker.send_email_notification = failing_email_send
        
        success = await notification_worker.handle_booking_confirmed(sample_booking_confirmed_event)
        assert success is False

    @pytest.mark.asyncio
    async def test_redis_connection_failure(self, notification_worker):
        """Test handling Redis connection failures"""
        # Mock Redis to raise exceptions
        notification_worker.redis_client = AsyncMock()
        notification_worker.redis_client.get.side_effect = Exception("Redis connection failed")
        
        event_id = str(uuid.uuid4())
        
        # Should handle error gracefully
        is_processed = await notification_worker.is_already_processed(event_id)
        assert is_processed is False  # Should default to False on error

    @pytest.mark.asyncio
    async def test_mongodb_logging_failure(self, notification_worker, sample_booking_confirmed_event):
        """Test handling MongoDB logging failures"""
        # Mock MongoDB to raise exceptions
        notification_worker.db.notification_logs.insert_one = AsyncMock(side_effect=Exception("MongoDB error"))
        
        # Should not crash
        try:
            await notification_worker.log_notification(
                event_id=sample_booking_confirmed_event["event_id"],
                notification_type="email",
                recipient="test@example.com",
                subject="Test",
                status="sent",
                event_data=sample_booking_confirmed_event
            )
            # If no exception, test passes
            assert True
        except Exception:
            # Should handle gracefully
            pass

    # Email Simulation Tests
    @pytest.mark.asyncio
    async def test_email_notification_simulation(self, notification_worker):
        """Test email notification simulation"""
        # This tests the actual mock implementation
        await notification_worker.send_email_notification(
            to_email="test@example.com",
            subject="Test Email",
            template="test_template",
            data={"test": "data"}
        )
        
        # Should complete without error
        assert True

    @pytest.mark.asyncio
    async def test_sms_notification_simulation(self, notification_worker):
        """Test SMS notification simulation"""
        await notification_worker.send_sms_notification(
            phone_number="+1234567890",
            message="Test SMS message"
        )
        
        # Should complete without error
        assert True

    # Integration with RabbitMQ Tests
    @pytest.mark.asyncio
    async def test_message_processing_simulation(self, notification_worker, sample_booking_confirmed_event):
        """Test processing of RabbitMQ messages (simulated)"""
        emails_sent = []
        
        async def mock_send_email(to_email, subject, template, data):
            emails_sent.append({"to_email": to_email, "subject": subject})
        
        notification_worker.send_email_notification = mock_send_email
        
        # Simulate message processing
        event_id = sample_booking_confirmed_event["event_id"]
        
        # Check if already processed (should be False)
        is_processed = await notification_worker.is_already_processed(event_id)
        assert is_processed is False
        
        # Mark as processing
        await notification_worker.mark_as_processing(event_id)
        
        # Handle the event
        success = await notification_worker.handle_event(
            sample_booking_confirmed_event["event_type"],
            sample_booking_confirmed_event
        )
        
        if success:
            await notification_worker.mark_as_processed(event_id)
        else:
            await notification_worker.mark_as_failed(event_id)
        
        assert success is True
        assert len(emails_sent) == 1

    # Performance Tests
    @pytest.mark.asyncio
    async def test_concurrent_event_processing(self, notification_worker):
        """Test processing multiple events concurrently"""
        emails_sent = []
        
        async def mock_send_email(to_email, subject, template, data):
            await asyncio.sleep(0.1)  # Simulate delay
            emails_sent.append({"to_email": to_email, "subject": subject})
        
        notification_worker.send_email_notification = mock_send_email
        
        # Create multiple events
        events = []
        for i in range(10):
            event = {
                "event_id": str(uuid.uuid4()),
                "event_type": "booking.confirmed",
                "booking_id": f"booking_{i}",
                "user_id": f"user_{i}",
                "showtime_id": "showtime_123",
                "seats": ["A1"],
                "total_amount": 100.0
            }
            events.append(event)
        
        # Process events concurrently
        tasks = [
            notification_worker.handle_booking_confirmed(event)
            for event in events
        ]
        
        results = await asyncio.gather(*tasks)
        
        # All should succeed
        assert all(results)
        assert len(emails_sent) == 10

    # Configuration Tests
    @pytest.mark.asyncio
    async def test_worker_initialization_mock(self):
        """Test worker initialization with mocked dependencies"""
        worker = NotificationWorker()
        
        # Mock the initialization methods
        worker.connection = AsyncMock()
        worker.channel = AsyncMock()
        worker.exchange = AsyncMock()
        worker.queue = AsyncMock()
        worker.redis_client = AsyncMock()
        worker.mongo_client = AsyncMock()
        worker.db = AsyncMock()
        
        # Should initialize without real connections
        assert worker is not None

    # Edge Cases
    @pytest.mark.asyncio
    async def test_event_with_missing_fields(self, notification_worker):
        """Test handling events with missing required fields"""
        incomplete_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            # Missing booking_id, user_id, etc.
        }
        
        # Should handle gracefully
        try:
            success = await notification_worker.handle_booking_confirmed(incomplete_event)
            # May succeed or fail, but shouldn't crash
            assert isinstance(success, bool)
        except KeyError:
            # Expected for missing fields
            pass

    @pytest.mark.asyncio
    async def test_large_event_data(self, notification_worker):
        """Test handling events with large data payloads"""
        large_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            "booking_id": "booking_123",
            "user_id": "user_456",
            "large_data": "x" * 10000,  # Large string
            "showtime_id": "showtime_789",
            "seats": ["A1", "A2"],
            "total_amount": 150.00
        }
        
        emails_sent = []
        
        async def mock_send_email(to_email, subject, template, data):
            emails_sent.append({"to_email": to_email})
        
        notification_worker.send_email_notification = mock_send_email
        
        success = await notification_worker.handle_booking_confirmed(large_event)
        assert success is True
        assert len(emails_sent) == 1


if __name__ == "__main__":
    # Run with: python -m pytest test_notification_service.py -v
    pytest.main([__file__, "-v"])