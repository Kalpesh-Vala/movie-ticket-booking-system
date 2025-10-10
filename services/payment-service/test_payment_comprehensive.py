"""
Comprehensive unit tests for Payment Service
Tests payment processing, event publishing, and error handling
"""

import asyncio
import json
import pytest
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch
from fastapi.testclient import TestClient
from httpx import AsyncClient

# Import the main application and components
from main import app, PaymentMethod, PaymentStatus
from event_publisher import PaymentEventPublisher, publish_payment_event


class TestPaymentAPI:
    """Test cases for Payment Service API endpoints"""

    @pytest.fixture
    def client(self):
        """Create test client"""
        return TestClient(app)

    @pytest.fixture
    async def async_client(self):
        """Create async test client"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            yield client

    @pytest.fixture
    def valid_payment_request(self):
        """Create valid payment request data"""
        return {
            "booking_id": "booking_123456",
            "user_id": "user_789",
            "amount": 75.50,
            "payment_method": "credit_card",
            "payment_details": {
                "card_number": "4111111111111111",
                "card_holder": "John Doe",
                "expiry_month": "12",
                "expiry_year": "2025",
                "cvv": "123"
            }
        }

    def test_health_check(self, client):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "payment-service"

    @pytest.mark.asyncio
    async def test_successful_payment_processing(self, async_client, valid_payment_request):
        """Test successful payment processing end-to-end"""
        with patch('main.simulate_payment_processing', return_value=True), \
             patch('main.publish_payment_event') as mock_publish, \
             patch('main.db') as mock_db:
            
            mock_db.transaction_logs.insert_one = AsyncMock()
            
            response = await async_client.post("/payments", json=valid_payment_request)
            
            assert response.status_code == 200
            data = response.json()
            
            # Verify response structure
            assert data["success"] is True
            assert data["transaction_id"] is not None
            assert data["status"] == "success"
            assert "successfully" in data["message"].lower()
            
            # Verify database insertion was called
            mock_db.transaction_logs.insert_one.assert_called_once()
            
            # Verify event publishing was called
            mock_publish.assert_called_once()

    @pytest.mark.asyncio
    async def test_failed_payment_processing(self, async_client, valid_payment_request):
        """Test failed payment processing"""
        with patch('main.simulate_payment_processing', return_value=False), \
             patch('main.publish_payment_event') as mock_publish, \
             patch('main.db') as mock_db:
            
            mock_db.transaction_logs.insert_one = AsyncMock()
            
            response = await async_client.post("/payments", json=valid_payment_request)
            
            assert response.status_code == 200
            data = response.json()
            
            # Verify response structure for failure
            assert data["success"] is False
            assert data["transaction_id"] is None
            assert data["status"] == "failed"
            assert "failed" in data["message"].lower()
            
            # Verify database insertion was still called (for logging)
            mock_db.transaction_logs.insert_one.assert_called_once()
            
            # Verify failure event publishing was called
            mock_publish.assert_called_once()

    @pytest.mark.asyncio
    async def test_payment_validation_negative_amount(self, async_client, valid_payment_request):
        """Test payment validation with negative amount"""
        valid_payment_request["amount"] = -50.0
        
        response = await async_client.post("/payments", json=valid_payment_request)
        assert response.status_code == 400
        assert "Invalid payment amount" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_payment_validation_zero_amount(self, async_client, valid_payment_request):
        """Test payment validation with zero amount"""
        valid_payment_request["amount"] = 0.0
        
        response = await async_client.post("/payments", json=valid_payment_request)
        assert response.status_code == 400
        assert "Invalid payment amount" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_payment_validation_excessive_amount(self, async_client, valid_payment_request):
        """Test payment validation with amount over limit"""
        valid_payment_request["amount"] = 15000.0  # Over limit
        
        response = await async_client.post("/payments", json=valid_payment_request)
        assert response.status_code == 400
        assert "exceeds limit" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_missing_required_fields(self, async_client):
        """Test payment request with missing required fields"""
        incomplete_request = {
            "booking_id": "booking_123",
            "amount": 50.0
            # Missing user_id, payment_method, payment_details
        }
        
        response = await async_client.post("/payments", json=incomplete_request)
        assert response.status_code == 422  # Validation error

    @pytest.mark.asyncio
    async def test_invalid_payment_method(self, async_client, valid_payment_request):
        """Test payment with invalid payment method"""
        valid_payment_request["payment_method"] = "invalid_method"
        
        response = await async_client.post("/payments", json=valid_payment_request)
        assert response.status_code == 422  # Validation error

    @pytest.mark.asyncio
    async def test_payment_processing_exception(self, async_client, valid_payment_request):
        """Test payment processing with system exception"""
        with patch('main.simulate_payment_processing', side_effect=Exception("System error")), \
             patch('main.db') as mock_db:
            
            mock_db.transaction_logs.insert_one = AsyncMock()
            
            response = await async_client.post("/payments", json=valid_payment_request)
            
            assert response.status_code == 500
            # Verify error transaction was logged
            mock_db.transaction_logs.insert_one.assert_called_once()


class TestPaymentEventPublisher:
    """Test cases for PaymentEventPublisher class"""

    @pytest.fixture
    async def publisher(self):
        """Create PaymentEventPublisher instance for testing"""
        publisher = PaymentEventPublisher()
        # Mock external dependencies
        publisher.connection = AsyncMock()
        publisher.channel = AsyncMock()
        publisher.exchange = AsyncMock()
        publisher._initialized = True
        return publisher

    @pytest.mark.asyncio
    async def test_publisher_initialization(self):
        """Test PaymentEventPublisher initialization"""
        with patch('aio_pika.connect_robust') as mock_connect:
            mock_connection = AsyncMock()
            mock_channel = AsyncMock()
            mock_exchange = AsyncMock()
            
            mock_connect.return_value = mock_connection
            mock_connection.channel.return_value = mock_channel
            mock_channel.declare_exchange.return_value = mock_exchange
            
            publisher = PaymentEventPublisher()
            await publisher.initialize()
            
            # Verify initialization steps
            mock_connect.assert_called_once()
            mock_channel.declare_exchange.assert_called_once()
            assert publisher._initialized is True

    @pytest.mark.asyncio
    async def test_publish_payment_success_event(self, publisher):
        """Test publishing payment success event"""
        transaction_data = {
            "booking_id": "booking_123",
            "transaction_id": "txn_456",
            "amount": 75.50,
            "payment_method": "credit_card"
        }
        
        await publisher.publish_payment_success_event(transaction_data)
        
        # Verify event was published
        publisher.exchange.publish.assert_called_once()

    @pytest.mark.asyncio
    async def test_publish_payment_failure_event(self, publisher):
        """Test publishing payment failure event"""
        transaction_data = {
            "booking_id": "booking_123",
            "transaction_id": "txn_456",
            "amount": 75.50,
            "failure_reason": "Insufficient funds"
        }
        
        await publisher.publish_payment_failure_event(transaction_data)
        
        # Verify event was published
        publisher.exchange.publish.assert_called_once()

    @pytest.mark.asyncio
    async def test_publish_refund_processed_event(self, publisher):
        """Test publishing refund processed event"""
        refund_data = {
            "booking_id": "booking_123",
            "original_transaction_id": "txn_456",
            "refund_amount": 75.50,
            "refund_transaction_id": "refund_789"
        }
        
        await publisher.publish_refund_processed_event(refund_data)
        
        # Verify event was published
        publisher.exchange.publish.assert_called_once()

    @pytest.mark.asyncio
    async def test_publish_event_not_initialized(self):
        """Test publishing event when publisher not initialized"""
        publisher = PaymentEventPublisher()
        publisher._initialized = False
        
        transaction_data = {
            "booking_id": "booking_123",
            "transaction_id": "txn_456"
        }
        
        # Should handle gracefully
        await publisher.publish_payment_success_event(transaction_data)
        # No exception should be raised

    @pytest.mark.asyncio
    async def test_publish_event_helper_function(self):
        """Test the publish_payment_event helper function"""
        transaction_data = {
            "booking_id": "booking_123",
            "transaction_id": "txn_456",
            "amount": 75.50
        }
        
        with patch('event_publisher.payment_event_publisher') as mock_publisher:
            mock_publisher._initialized = True
            mock_publisher.publish_payment_success_event = AsyncMock()
            
            await publish_payment_event("payment.success", transaction_data)
            
            mock_publisher.publish_payment_success_event.assert_called_once_with(transaction_data)

    @pytest.mark.asyncio
    async def test_publish_event_auto_initialization(self):
        """Test that publish_payment_event auto-initializes publisher"""
        transaction_data = {
            "booking_id": "booking_123",
            "transaction_id": "txn_456"
        }
        
        with patch('event_publisher.payment_event_publisher') as mock_publisher:
            mock_publisher._initialized = False
            mock_publisher.initialize = AsyncMock()
            mock_publisher.publish_payment_success_event = AsyncMock()
            
            await publish_payment_event("payment.success", transaction_data)
            
            # Verify initialization was called
            mock_publisher.initialize.assert_called_once()
            mock_publisher.publish_payment_success_event.assert_called_once_with(transaction_data)

    @pytest.mark.asyncio
    async def test_unknown_event_type(self):
        """Test handling unknown event types"""
        with patch('event_publisher.payment_event_publisher') as mock_publisher:
            mock_publisher._initialized = True
            
            await publish_payment_event("payment.unknown", {})
            
            # Should log warning but not crash

    @pytest.mark.asyncio
    async def test_publisher_close(self, publisher):
        """Test closing publisher connection"""
        publisher.connection.is_closed = False
        
        await publisher.close()
        
        publisher.connection.close.assert_called_once()


class TestPaymentIntegration:
    """Integration tests for payment service components"""

    @pytest.mark.asyncio
    async def test_end_to_end_payment_flow(self):
        """Test complete payment flow from request to event publishing"""
        payment_request = {
            "booking_id": "booking_integration_test",
            "user_id": "user_integration_test",
            "amount": 100.00,
            "payment_method": "credit_card",
            "payment_details": {
                "card_number": "4111111111111111",
                "card_holder": "Integration Test",
                "expiry_month": "12",
                "expiry_year": "2025",
                "cvv": "123"
            }
        }
        
        events_published = []
        
        async def mock_publish_event(event_type, data):
            events_published.append({
                "event_type": event_type,
                "data": data
            })
        
        with patch('main.simulate_payment_processing', return_value=True), \
             patch('main.publish_payment_event', side_effect=mock_publish_event), \
             patch('main.db') as mock_db:
            
            mock_db.transaction_logs.insert_one = AsyncMock()
            
            # Create test client and make request
            client = TestClient(app)
            response = client.post("/payments", json=payment_request)
            
            # Verify response
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is True
            
            # Verify event was published
            assert len(events_published) == 1
            assert events_published[0]["event_type"] == "payment.success"
            assert events_published[0]["data"]["booking_id"] == "booking_integration_test"
            
            # Verify database logging
            mock_db.transaction_logs.insert_one.assert_called_once()

    @pytest.mark.asyncio
    async def test_payment_failure_integration(self):
        """Test complete payment failure flow"""
        payment_request = {
            "booking_id": "booking_fail_test",
            "user_id": "user_fail_test",
            "amount": 50.00,
            "payment_method": "credit_card",
            "payment_details": {
                "card_number": "4000000000000002"  # Declined card
            }
        }
        
        events_published = []
        
        async def mock_publish_event(event_type, data):
            events_published.append({
                "event_type": event_type,
                "data": data
            })
        
        with patch('main.simulate_payment_processing', return_value=False), \
             patch('main.publish_payment_event', side_effect=mock_publish_event), \
             patch('main.db') as mock_db:
            
            mock_db.transaction_logs.insert_one = AsyncMock()
            
            client = TestClient(app)
            response = client.post("/payments", json=payment_request)
            
            # Verify failure response
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is False
            
            # Verify failure event was published
            assert len(events_published) == 1
            assert events_published[0]["event_type"] == "payment.failed"
            
            # Verify database logging of failure
            mock_db.transaction_logs.insert_one.assert_called_once()


if __name__ == "__main__":
    # Run tests with pytest
    import sys
    sys.exit(pytest.main([__file__, "-v"]))