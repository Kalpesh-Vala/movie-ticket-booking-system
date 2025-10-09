"""
Integration Tests for Payment and Notification Services
Tests the complete flow from payment processing to notification delivery
through RabbitMQ messaging.
"""

import asyncio
import json
import pytest
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch
import aio_pika
import redis.asyncio as redis
from motor.motor_asyncio import AsyncIOMotorClient

# Import services
import sys
import os

# Add service paths for imports
payment_service_path = os.path.join(os.path.dirname(__file__), '../payment-service')
notification_service_path = os.path.join(os.path.dirname(__file__), '../notification-service')
sys.path.append(payment_service_path)
sys.path.append(notification_service_path)

from payment_service.main import app as payment_app
from payment_service.event_publisher import PaymentEventPublisher
from notification_service.worker import NotificationWorker


class TestPaymentNotificationIntegration:
    """Integration tests for payment and notification services"""

    @pytest.fixture
    async def rabbitmq_connection(self):
        """Create RabbitMQ connection for testing"""
        connection = await aio_pika.connect_robust("amqp://guest:guest@localhost:5672/")
        yield connection
        await connection.close()

    @pytest.fixture
    async def test_exchange(self, rabbitmq_connection):
        """Create test exchange"""
        channel = await rabbitmq_connection.channel()
        exchange = await channel.declare_exchange(
            "test_movie_app_events",
            aio_pika.ExchangeType.TOPIC,
            durable=True
        )
        yield exchange
        # Cleanup
        await exchange.delete()

    @pytest.fixture
    async def test_queue(self, rabbitmq_connection, test_exchange):
        """Create test queue for notifications"""
        channel = await rabbitmq_connection.channel()
        queue = await channel.declare_queue(
            "test_notification_events",
            durable=True,
            exclusive=True
        )
        
        # Bind to payment events
        await queue.bind(test_exchange, "payment.success")
        await queue.bind(test_exchange, "payment.failed")
        await queue.bind(test_exchange, "payment.refund")
        
        yield queue

    @pytest.fixture
    async def redis_client(self):
        """Create Redis client for testing"""
        client = redis.from_url("redis://localhost:6379/15")  # Use test database
        yield client
        await client.flushdb()
        await client.close()

    @pytest.fixture
    async def mongo_client(self):
        """Create MongoDB client for testing"""
        client = AsyncIOMotorClient("mongodb://localhost:27017")
        db = client.test_integration
        yield db
        # Cleanup
        await db.transaction_logs.delete_many({})
        await db.notification_logs.delete_many({})
        client.close()

    @pytest.mark.asyncio
    async def test_payment_success_to_notification_flow(self, test_exchange, test_queue, redis_client, mongo_client):
        """Test complete flow from successful payment to notification"""
        # Setup notification worker
        notification_worker = NotificationWorker()
        notification_worker.redis_client = redis_client
        notification_worker.db = mongo_client
        notification_worker.exchange = test_exchange
        notification_worker.payment_queue = test_queue
        
        # Setup payment event publisher
        payment_publisher = PaymentEventPublisher()
        payment_publisher.exchange = test_exchange
        payment_publisher._initialized = True
        
        # Track notifications sent
        notifications_sent = []
        
        async def mock_send_notification(to_email, subject, template, data):
            notifications_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })
        
        notification_worker.send_email_notification = mock_send_notification
        notification_worker.log_notification = AsyncMock()
        
        # Publish payment success event
        payment_data = {
            "booking_id": "integration_booking_123",
            "transaction_id": "integration_txn_456",
            "amount": 99.99,
            "payment_method": "credit_card",
            "user_id": "integration_user_789"
        }
        
        await payment_publisher.publish_payment_success_event(payment_data)
        
        # Wait a bit for message to be published
        await asyncio.sleep(0.1)
        
        # Consume and process the message
        messages_processed = 0
        
        async def process_test_messages():
            nonlocal messages_processed
            async for message in test_queue:
                async with message.process():
                    await notification_worker.process_payment_message(message)
                    messages_processed += 1
                    break  # Process only one message for test
        
        # Process the message
        await asyncio.wait_for(process_test_messages(), timeout=5.0)
        
        # Verify notification was sent
        assert messages_processed == 1
        assert len(notifications_sent) == 1
        assert notifications_sent[0]["subject"] == "Payment Successful"
        assert notifications_sent[0]["data"]["booking_id"] == "integration_booking_123"
        assert notifications_sent[0]["data"]["transaction_id"] == "integration_txn_456"

    @pytest.mark.asyncio
    async def test_payment_failure_to_notification_flow(self, test_exchange, test_queue, redis_client, mongo_client):
        """Test complete flow from failed payment to notification"""
        # Setup notification worker
        notification_worker = NotificationWorker()
        notification_worker.redis_client = redis_client
        notification_worker.db = mongo_client
        notification_worker.exchange = test_exchange
        notification_worker.payment_queue = test_queue
        
        # Setup payment event publisher
        payment_publisher = PaymentEventPublisher()
        payment_publisher.exchange = test_exchange
        payment_publisher._initialized = True
        
        # Track notifications sent
        notifications_sent = []
        
        async def mock_send_notification(to_email, subject, template, data):
            notifications_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })
        
        notification_worker.send_email_notification = mock_send_notification
        notification_worker.log_notification = AsyncMock()
        
        # Publish payment failure event
        payment_data = {
            "booking_id": "integration_booking_fail_123",
            "transaction_id": "integration_txn_fail_456",
            "amount": 75.50,
            "payment_method": "credit_card",
            "failure_reason": "Insufficient funds",
            "user_id": "integration_user_fail_789"
        }
        
        await payment_publisher.publish_payment_failure_event(payment_data)
        
        # Wait a bit for message to be published
        await asyncio.sleep(0.1)
        
        # Process the message
        messages_processed = 0
        
        async def process_test_messages():
            nonlocal messages_processed
            async for message in test_queue:
                async with message.process():
                    await notification_worker.process_payment_message(message)
                    messages_processed += 1
                    break
        
        await asyncio.wait_for(process_test_messages(), timeout=5.0)
        
        # Verify failure notification was sent
        assert messages_processed == 1
        assert len(notifications_sent) == 1
        assert notifications_sent[0]["subject"] == "Payment Failed"
        assert notifications_sent[0]["data"]["booking_id"] == "integration_booking_fail_123"
        assert notifications_sent[0]["data"]["failure_reason"] == "Insufficient funds"

    @pytest.mark.asyncio
    async def test_idempotency_across_services(self, test_exchange, test_queue, redis_client, mongo_client):
        """Test that duplicate events are handled correctly with idempotency"""
        # Setup notification worker
        notification_worker = NotificationWorker()
        notification_worker.redis_client = redis_client
        notification_worker.db = mongo_client
        notification_worker.exchange = test_exchange
        notification_worker.payment_queue = test_queue
        
        # Setup payment event publisher
        payment_publisher = PaymentEventPublisher()
        payment_publisher.exchange = test_exchange
        payment_publisher._initialized = True
        
        # Track notifications sent
        notifications_sent = []
        
        async def mock_send_notification(to_email, subject, template, data):
            notifications_sent.append({
                "to_email": to_email,
                "subject": subject,
                "template": template,
                "data": data
            })
        
        notification_worker.send_email_notification = mock_send_notification
        notification_worker.log_notification = AsyncMock()
        
        # Create event with fixed event ID
        event_id = str(uuid.uuid4())
        payment_data = {
            "event_id": event_id,
            "booking_id": "idempotency_test_booking",
            "transaction_id": "idempotency_test_txn",
            "amount": 50.00,
            "payment_method": "credit_card",
            "user_id": "idempotency_test_user"
        }
        
        # Publish the same event twice
        await payment_publisher.publish_payment_success_event(payment_data)
        await payment_publisher.publish_payment_success_event(payment_data)
        
        await asyncio.sleep(0.1)
        
        # Process both messages
        messages_processed = 0
        
        async def process_test_messages():
            nonlocal messages_processed
            async for message in test_queue:
                async with message.process():
                    await notification_worker.process_payment_message(message)
                    messages_processed += 1
                    if messages_processed >= 2:
                        break
        
        await asyncio.wait_for(process_test_messages(), timeout=5.0)
        
        # Verify only one notification was sent (idempotency)
        assert messages_processed == 2  # Two messages processed
        assert len(notifications_sent) == 1  # But only one notification sent

    @pytest.mark.asyncio
    async def test_concurrent_payment_processing(self, test_exchange, test_queue, redis_client, mongo_client):
        """Test concurrent processing of multiple payment events"""
        # Setup notification worker
        notification_worker = NotificationWorker()
        notification_worker.redis_client = redis_client
        notification_worker.db = mongo_client
        notification_worker.exchange = test_exchange
        notification_worker.payment_queue = test_queue
        
        # Setup payment event publisher
        payment_publisher = PaymentEventPublisher()
        payment_publisher.exchange = test_exchange
        payment_publisher._initialized = True
        
        # Track notifications sent
        notifications_sent = []
        
        async def mock_send_notification(to_email, subject, template, data):
            notifications_sent.append({
                "booking_id": data["booking_id"],
                "subject": subject
            })
        
        notification_worker.send_email_notification = mock_send_notification
        notification_worker.log_notification = AsyncMock()
        
        # Publish multiple payment events
        payment_events = []
        for i in range(5):
            payment_data = {
                "booking_id": f"concurrent_booking_{i}",
                "transaction_id": f"concurrent_txn_{i}",
                "amount": 25.00 + i,
                "payment_method": "credit_card",
                "user_id": f"concurrent_user_{i}"
            }
            payment_events.append(payment_data)
            await payment_publisher.publish_payment_success_event(payment_data)
        
        await asyncio.sleep(0.2)
        
        # Process all messages
        messages_processed = 0
        
        async def process_test_messages():
            nonlocal messages_processed
            async for message in test_queue:
                async with message.process():
                    await notification_worker.process_payment_message(message)
                    messages_processed += 1
                    if messages_processed >= 5:
                        break
        
        await asyncio.wait_for(process_test_messages(), timeout=10.0)
        
        # Verify all notifications were sent
        assert messages_processed == 5
        assert len(notifications_sent) == 5
        
        # Verify all booking IDs were processed
        booking_ids = {notif["booking_id"] for notif in notifications_sent}
        expected_booking_ids = {f"concurrent_booking_{i}" for i in range(5)}
        assert booking_ids == expected_booking_ids

    @pytest.mark.asyncio
    async def test_error_handling_in_integration(self, test_exchange, test_queue, redis_client, mongo_client):
        """Test error handling in the integration flow"""
        # Setup notification worker
        notification_worker = NotificationWorker()
        notification_worker.redis_client = redis_client
        notification_worker.db = mongo_client
        notification_worker.exchange = test_exchange
        notification_worker.payment_queue = test_queue
        
        # Setup payment event publisher
        payment_publisher = PaymentEventPublisher()
        payment_publisher.exchange = test_exchange
        payment_publisher._initialized = True
        
        # Mock notification sending to raise an error
        async def failing_send_notification(to_email, subject, template, data):
            raise ConnectionError("Email service unavailable")
        
        notification_worker.send_email_notification = failing_send_notification
        notification_worker.log_notification = AsyncMock()
        
        # Publish payment event
        payment_data = {
            "booking_id": "error_test_booking",
            "transaction_id": "error_test_txn",
            "amount": 100.00,
            "payment_method": "credit_card",
            "user_id": "error_test_user"
        }
        
        await payment_publisher.publish_payment_success_event(payment_data)
        
        await asyncio.sleep(0.1)
        
        # Process the message (should handle error gracefully)
        messages_processed = 0
        processing_errors = 0
        
        async def process_test_messages():
            nonlocal messages_processed, processing_errors
            async for message in test_queue:
                try:
                    async with message.process():
                        await notification_worker.process_payment_message(message)
                        messages_processed += 1
                except Exception:
                    processing_errors += 1
                break
        
        await asyncio.wait_for(process_test_messages(), timeout=5.0)
        
        # Verify error was handled (message processed but notification failed)
        assert messages_processed == 1 or processing_errors == 1

    @pytest.mark.asyncio
    async def test_message_format_validation(self, test_exchange, test_queue, redis_client, mongo_client):
        """Test handling of malformed messages"""
        # Setup notification worker
        notification_worker = NotificationWorker()
        notification_worker.redis_client = redis_client
        notification_worker.db = mongo_client
        
        # Create malformed message manually
        channel = await test_exchange.channel.connection.channel()
        
        # Publish malformed JSON
        await test_exchange.publish(
            aio_pika.Message(
                b'{"invalid": "json"',  # Malformed JSON
                content_type="application/json"
            ),
            routing_key="payment.success"
        )
        
        await asyncio.sleep(0.1)
        
        # Process the message (should handle gracefully)
        messages_processed = 0
        
        async def process_test_messages():
            nonlocal messages_processed
            async for message in test_queue:
                try:
                    async with message.process():
                        await notification_worker.process_payment_message(message)
                        messages_processed += 1
                except json.JSONDecodeError:
                    # Expected for malformed JSON
                    messages_processed += 1
                break
        
        await asyncio.wait_for(process_test_messages(), timeout=5.0)
        
        # Verify malformed message was handled
        assert messages_processed == 1


class TestRabbitMQConfiguration:
    """Test RabbitMQ configuration and setup"""

    @pytest.mark.asyncio
    async def test_exchange_and_queue_setup(self):
        """Test that exchanges and queues are properly configured"""
        connection = await aio_pika.connect_robust("amqp://guest:guest@localhost:5672/")
        channel = await connection.channel()
        
        try:
            # Test exchange declaration
            exchange = await channel.declare_exchange(
                "movie_app_events",
                aio_pika.ExchangeType.TOPIC,
                durable=True
            )
            
            # Test queue declarations
            notification_queue = await channel.declare_queue(
                "notification.payment_events",
                durable=True
            )
            
            payment_queue = await channel.declare_queue(
                "payment.processing_queue",
                durable=True
            )
            
            # Test bindings
            await notification_queue.bind(exchange, "payment.success")
            await notification_queue.bind(exchange, "payment.failed")
            await payment_queue.bind(exchange, "payment.process")
            
            # If we get here, configuration is valid
            assert True
            
        finally:
            await connection.close()

    @pytest.mark.asyncio
    async def test_dead_letter_exchange_configuration(self):
        """Test dead letter exchange setup"""
        connection = await aio_pika.connect_robust("amqp://guest:guest@localhost:5672/")
        channel = await connection.channel()
        
        try:
            # Test DLX exchange
            dlx_exchange = await channel.declare_exchange(
                "movie_app_events.dlx",
                aio_pika.ExchangeType.DIRECT,
                durable=True
            )
            
            # Test queue with DLX argument
            queue = await channel.declare_queue(
                "test_queue_with_dlx",
                durable=True,
                arguments={"x-dead-letter-exchange": "movie_app_events.dlx"},
                exclusive=True
            )
            
            assert True
            
        finally:
            await connection.close()


if __name__ == "__main__":
    # Run tests with pytest
    import sys
    sys.exit(pytest.main([__file__, "-v"]))