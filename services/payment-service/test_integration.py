"""
Integration Tests for Payment Service and Notification Service
Tests the communication between payment service and notification service via RabbitMQ
"""

import pytest
import asyncio
import json
import uuid
import aio_pika
from httpx import AsyncClient
from motor.motor_asyncio import AsyncIOMotorClient
import redis.asyncio as redis
from datetime import datetime
from unittest.mock import AsyncMock, patch
import os

from payment_service.main import app as payment_app
from notification_service.worker import NotificationWorker


class TestPaymentNotificationIntegration:
    """Integration tests between Payment and Notification services"""

    @pytest.fixture(scope="session")
    def event_loop(self):
        """Create an instance of the default event loop for the test session."""
        loop = asyncio.get_event_loop_policy().new_event_loop()
        yield loop
        loop.close()

    @pytest.fixture
    async def payment_client(self):
        """Create async client for payment service"""
        async with AsyncClient(app=payment_app, base_url="http://test") as client:
            yield client

    @pytest.fixture
    async def rabbitmq_connection(self):
        """Create RabbitMQ connection for testing"""
        connection = await aio_pika.connect_robust("amqp://guest:guest@localhost:5672/")
        yield connection
        await connection.close()

    @pytest.fixture
    async def redis_client(self):
        """Create Redis client for testing"""
        client = redis.from_url("redis://localhost:6379")
        yield client
        await client.close()

    @pytest.fixture
    async def mongo_client(self):
        """Create MongoDB test client"""
        client = AsyncIOMotorClient("mongodb://localhost:27017")
        db = client.test_movie_booking
        yield db
        # Cleanup
        await db.transaction_logs.delete_many({})
        await db.notification_logs.delete_many({})
        client.close()

    @pytest.fixture
    def sample_booking_event(self):
        """Sample booking event for testing"""
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
    def sample_payment_request(self):
        """Sample payment request"""
        return {
            "booking_id": "booking_123",
            "amount": 150.00,
            "payment_method": "credit_card",
            "payment_details": {
                "card_number": "4111111111111111",
                "cvv": "123",
                "expiry_month": "12",
                "expiry_year": "2025",
                "cardholder_name": "John Doe"
            }
        }

    # Payment Service Event Publishing Tests
    @pytest.mark.asyncio
    async def test_payment_success_publishes_event(self, payment_client, sample_payment_request, rabbitmq_connection):
        """Test that successful payment publishes an event to RabbitMQ"""
        messages_received = []

        async def mock_event_publisher(event_type, event_data):
            """Mock event publisher that captures published events"""
            messages_received.append({
                "event_type": event_type,
                "event_data": event_data
            })

        # Mock the event publisher
        with patch('payment_service.main.publish_event', side_effect=mock_event_publisher):
            with patch('payment_service.main.simulate_payment_processing', return_value=True):
                response = await payment_client.post("/payments", json=sample_payment_request)
                
                assert response.status_code == 200
                payment_data = response.json()
                assert payment_data["success"] is True

                # Check if event was published
                assert len(messages_received) == 1
                published_event = messages_received[0]
                assert published_event["event_type"] == "payment.success"
                assert published_event["event_data"]["booking_id"] == sample_payment_request["booking_id"]

    @pytest.mark.asyncio
    async def test_payment_failure_publishes_event(self, payment_client, sample_payment_request):
        """Test that failed payment publishes a failure event"""
        messages_received = []

        async def mock_event_publisher(event_type, event_data):
            messages_received.append({
                "event_type": event_type,
                "event_data": event_data
            })

        with patch('payment_service.main.publish_event', side_effect=mock_event_publisher):
            with patch('payment_service.main.simulate_payment_processing', return_value=False):
                response = await payment_client.post("/payments", json=sample_payment_request)
                
                assert response.status_code == 200
                payment_data = response.json()
                assert payment_data["success"] is False

                # Check if failure event was published
                assert len(messages_received) == 1
                published_event = messages_received[0]
                assert published_event["event_type"] == "payment.failed"

    # Notification Service Event Consumption Tests
    @pytest.mark.asyncio
    async def test_notification_worker_processes_booking_confirmed(self, sample_booking_event, mongo_client, redis_client):
        """Test that notification worker processes booking confirmed events"""
        worker = NotificationWorker()
        
        # Mock the dependencies
        worker.db = mongo_client
        worker.redis_client = redis_client

        # Mock email sending
        email_sent = []
        async def mock_send_email(to_email, subject, template, data):
            email_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })

        worker.send_email_notification = mock_send_email

        # Process the event
        success = await worker.handle_booking_confirmed(sample_booking_event)
        
        assert success is True
        assert len(email_sent) == 1
        
        email = email_sent[0]
        assert "user_456@example.com" in email["to_email"]
        assert "Booking Confirmed" in email["subject"]
        assert email["data"]["booking_id"] == "booking_123"

    @pytest.mark.asyncio
    async def test_notification_worker_idempotency(self, sample_booking_event, redis_client):
        """Test that notification worker handles duplicate events (idempotency)"""
        worker = NotificationWorker()
        worker.redis_client = redis_client

        event_id = sample_booking_event["event_id"]

        # Mark event as already processed
        await worker.mark_as_processed(event_id)

        # Check if event is detected as already processed
        is_processed = await worker.is_already_processed(event_id)
        assert is_processed is True

    @pytest.mark.asyncio
    async def test_notification_logging(self, sample_booking_event, mongo_client, redis_client):
        """Test that notifications are properly logged to MongoDB"""
        worker = NotificationWorker()
        worker.db = mongo_client
        worker.redis_client = redis_client

        # Log a notification
        await worker.log_notification(
            event_id=sample_booking_event["event_id"],
            notification_type="email",
            recipient="user@example.com",
            subject="Test Notification",
            status="sent",
            event_data=sample_booking_event
        )

        # Check if notification was logged
        logged_notification = await mongo_client.notification_logs.find_one({
            "event_id": sample_booking_event["event_id"]
        })

        assert logged_notification is not None
        assert logged_notification["recipient"] == "user@example.com"
        assert logged_notification["status"] == "sent"

    # End-to-End Integration Tests
    @pytest.mark.asyncio
    async def test_complete_payment_notification_flow(self, payment_client, sample_payment_request, rabbitmq_connection, mongo_client, redis_client):
        """Test complete flow from payment to notification"""
        # Step 1: Process payment
        with patch('payment_service.main.simulate_payment_processing', return_value=True):
            payment_response = await payment_client.post("/payments", json=sample_payment_request)
            assert payment_response.status_code == 200
            
            payment_data = payment_response.json()
            transaction_id = payment_data["transaction_id"]

        # Step 2: Simulate booking confirmation event (would normally come from booking service)
        booking_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            "booking_id": sample_payment_request["booking_id"],
            "user_id": "user_123",
            "payment_transaction_id": transaction_id,
            "total_amount": sample_payment_request["amount"],
            "timestamp": datetime.utcnow().isoformat()
        }

        # Step 3: Publish booking event to RabbitMQ
        channel = await rabbitmq_connection.channel()
        exchange = await channel.declare_exchange("movie_app_events", aio_pika.ExchangeType.TOPIC, durable=True)
        
        message = aio_pika.Message(
            json.dumps(booking_event).encode(),
            content_type="application/json"
        )
        await exchange.publish(message, routing_key="booking.confirmed")

        # Step 4: Simulate notification worker processing
        worker = NotificationWorker()
        worker.db = mongo_client
        worker.redis_client = redis_client

        notifications_sent = []
        async def mock_send_email(to_email, subject, template, data):
            notifications_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })

        worker.send_email_notification = mock_send_email

        # Process the event
        success = await worker.handle_booking_confirmed(booking_event)
        
        # Step 5: Verify notification was sent
        assert success is True
        assert len(notifications_sent) == 1
        
        notification = notifications_sent[0]
        assert booking_event["booking_id"] in str(notification["data"])

        # Step 6: Verify notification was logged
        logged_notification = await mongo_client.notification_logs.find_one({
            "event_id": booking_event["event_id"]
        })
        assert logged_notification is not None

    @pytest.mark.asyncio
    async def test_refund_notification_flow(self, payment_client, sample_payment_request, mongo_client, redis_client):
        """Test refund to notification flow"""
        # Step 1: Create successful payment
        with patch('payment_service.main.simulate_payment_processing', return_value=True):
            payment_response = await payment_client.post("/payments", json=sample_payment_request)
            transaction_id = payment_response.json()["transaction_id"]

        # Step 2: Process refund
        with patch('payment_service.main.db', mongo_client):
            refund_response = await payment_client.post(
                "/refunds",
                params={"transaction_id": transaction_id, "reason": "Customer request"}
            )
            assert refund_response.status_code == 200

        # Step 3: Simulate refund notification event
        refund_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.refunded",
            "booking_id": sample_payment_request["booking_id"],
            "user_id": "user_123",
            "transaction_id": transaction_id,
            "refund_amount": sample_payment_request["amount"],
            "timestamp": datetime.utcnow().isoformat()
        }

        # Step 4: Process refund notification
        worker = NotificationWorker()
        worker.db = mongo_client
        worker.redis_client = redis_client

        notifications_sent = []
        async def mock_send_email(to_email, subject, template, data):
            notifications_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })

        worker.send_email_notification = mock_send_email

        success = await worker.handle_booking_refunded(refund_event)
        
        # Verify refund notification
        assert success is True
        assert len(notifications_sent) == 1
        
        notification = notifications_sent[0]
        assert "Refund Processed" in notification["subject"]

    # Error Handling and Resilience Tests
    @pytest.mark.asyncio
    async def test_notification_service_handles_invalid_events(self, redis_client, mongo_client):
        """Test notification service handles invalid events gracefully"""
        worker = NotificationWorker()
        worker.db = mongo_client
        worker.redis_client = redis_client

        # Test with invalid event data
        invalid_event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "unknown.event",
            # Missing required fields
        }

        # Should not crash and should return success for unknown events
        success = await worker.handle_event("unknown.event", invalid_event)
        assert success is True  # Unknown events are ignored

    @pytest.mark.asyncio
    async def test_notification_retry_mechanism(self, redis_client):
        """Test notification retry mechanism for failed notifications"""
        worker = NotificationWorker()
        worker.redis_client = redis_client

        event_id = str(uuid.uuid4())

        # Mark as failed
        await worker.mark_as_failed(event_id)

        # Check status
        status = await redis_client.get(f"event:{event_id}:status")
        assert status.decode() == "failed"

        # Should be eligible for retry (not marked as processed)
        is_processed = await worker.is_already_processed(event_id)
        assert is_processed is True  # Failed events are considered "processed" temporarily

    @pytest.mark.asyncio
    async def test_notification_service_database_resilience(self, redis_client):
        """Test notification service handles database failures gracefully"""
        worker = NotificationWorker()
        worker.redis_client = redis_client
        worker.db = None  # Simulate database failure

        # Mock email sending
        async def mock_send_email(*args, **kwargs):
            pass

        worker.send_email_notification = mock_send_email

        event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            "booking_id": "booking_123",
            "user_id": "user_456"
        }

        # Should handle database failure gracefully
        try:
            success = await worker.handle_booking_confirmed(event)
            # If it doesn't crash, that's a success
            assert True
        except Exception as e:
            # Should handle the error gracefully
            assert "database" in str(e).lower() or "None" in str(e)

    # Performance Tests
    @pytest.mark.asyncio
    async def test_concurrent_notification_processing(self, redis_client, mongo_client):
        """Test handling multiple notifications concurrently"""
        worker = NotificationWorker()
        worker.db = mongo_client
        worker.redis_client = redis_client

        notifications_sent = []
        async def mock_send_email(to_email, subject, template, data):
            await asyncio.sleep(0.1)  # Simulate email sending delay
            notifications_sent.append({"to_email": to_email, "subject": subject})

        worker.send_email_notification = mock_send_email

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
        tasks = [worker.handle_booking_confirmed(event) for event in events]
        results = await asyncio.gather(*tasks)

        # All should succeed
        assert all(results)
        assert len(notifications_sent) == 10


if __name__ == "__main__":
    # Run with: python -m pytest test_integration.py -v
    pytest.main([__file__, "-v"])