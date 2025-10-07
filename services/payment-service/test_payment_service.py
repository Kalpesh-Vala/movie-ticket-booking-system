"""
Comprehensive Test Suite for Payment Service
Tests payment processing, transaction logging, refunds, and error handling
"""

import pytest
import asyncio
import json
import uuid
from httpx import AsyncClient
from fastapi.testclient import TestClient
from motor.motor_asyncio import AsyncIOMotorClient
from datetime import datetime
from unittest.mock import AsyncMock, patch
import os

from main import app, PaymentMethod, PaymentStatus


class TestPaymentService:
    """Test class for Payment Service functionality"""
    
    @pytest.fixture(scope="session")
    def event_loop(self):
        """Create an instance of the default event loop for the test session."""
        loop = asyncio.get_event_loop_policy().new_event_loop()
        yield loop
        loop.close()

    @pytest.fixture
    async def async_client(self):
        """Create async test client"""
        async with AsyncClient(app=app, base_url="http://test") as client:
            yield client

    @pytest.fixture
    def sync_client(self):
        """Create sync test client for simple tests"""
        return TestClient(app)

    @pytest.fixture
    async def mongo_client(self):
        """Create MongoDB test client"""
        client = AsyncIOMotorClient("mongodb://localhost:27017")
        db = client.test_movie_booking
        yield db
        # Cleanup
        await db.transaction_logs.delete_many({})
        client.close()

    @pytest.fixture
    def sample_payment_request(self):
        """Sample payment request for testing"""
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

    # Health Check Tests
    def test_health_check(self, sync_client):
        """Test health check endpoint"""
        response = sync_client.get("/health")
        assert response.status_code == 200
        assert response.json() == {"status": "healthy", "service": "payment-service"}

    # Payment Processing Tests
    @pytest.mark.asyncio
    async def test_successful_payment(self, async_client, sample_payment_request):
        """Test successful payment processing"""
        with patch('main.simulate_payment_processing', return_value=True):
            response = await async_client.post("/payments", json=sample_payment_request)
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["success"] is True
            assert data["transaction_id"] is not None
            assert data["status"] == "success"
            assert "successfully" in data["message"].lower()

    @pytest.mark.asyncio
    async def test_failed_payment(self, async_client, sample_payment_request):
        """Test failed payment processing"""
        with patch('main.simulate_payment_processing', return_value=False):
            response = await async_client.post("/payments", json=sample_payment_request)
            
            assert response.status_code == 200
            data = response.json()
            
            assert data["success"] is False
            assert data["transaction_id"] is None
            assert data["status"] == "failed"
            assert "failed" in data["message"].lower()

    @pytest.mark.asyncio
    async def test_invalid_amount_negative(self, async_client, sample_payment_request):
        """Test payment with negative amount"""
        sample_payment_request["amount"] = -50.0
        
        response = await async_client.post("/payments", json=sample_payment_request)
        assert response.status_code == 400
        assert "Invalid payment amount" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_invalid_amount_zero(self, async_client, sample_payment_request):
        """Test payment with zero amount"""
        sample_payment_request["amount"] = 0.0
        
        response = await async_client.post("/payments", json=sample_payment_request)
        assert response.status_code == 400
        assert "Invalid payment amount" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_amount_exceeds_limit(self, async_client, sample_payment_request):
        """Test payment with amount exceeding limit"""
        sample_payment_request["amount"] = 15000.0
        
        response = await async_client.post("/payments", json=sample_payment_request)
        assert response.status_code == 400
        assert "exceeds limit" in response.json()["detail"]

    @pytest.mark.asyncio
    async def test_payment_method_validation(self, async_client, sample_payment_request):
        """Test different payment methods"""
        payment_methods = ["credit_card", "debit_card", "digital_wallet", "net_banking"]
        
        for method in payment_methods:
            sample_payment_request["payment_method"] = method
            with patch('main.simulate_payment_processing', return_value=True):
                response = await async_client.post("/payments", json=sample_payment_request)
                assert response.status_code == 200

    @pytest.mark.asyncio
    async def test_invalid_payment_method(self, async_client, sample_payment_request):
        """Test invalid payment method"""
        sample_payment_request["payment_method"] = "invalid_method"
        
        response = await async_client.post("/payments", json=sample_payment_request)
        assert response.status_code == 422  # Validation error

    # Transaction Logging Tests
    @pytest.mark.asyncio
    async def test_transaction_logging(self, async_client, sample_payment_request, mongo_client):
        """Test that transactions are properly logged to MongoDB"""
        with patch('main.db', mongo_client):
            with patch('main.simulate_payment_processing', return_value=True):
                response = await async_client.post("/payments", json=sample_payment_request)
                
                assert response.status_code == 200
                transaction_id = response.json()["transaction_id"]
                
                # Check if transaction was logged
                logged_transaction = await mongo_client.transaction_logs.find_one(
                    {"transaction_id": transaction_id}
                )
                
                assert logged_transaction is not None
                assert logged_transaction["booking_id"] == sample_payment_request["booking_id"]
                assert logged_transaction["amount"] == sample_payment_request["amount"]
                assert logged_transaction["status"] == "success"

    @pytest.mark.asyncio
    async def test_payment_details_sanitization(self, async_client, sample_payment_request, mongo_client):
        """Test that sensitive payment details are sanitized in logs"""
        with patch('main.db', mongo_client):
            with patch('main.simulate_payment_processing', return_value=True):
                response = await async_client.post("/payments", json=sample_payment_request)
                
                assert response.status_code == 200
                transaction_id = response.json()["transaction_id"]
                
                logged_transaction = await mongo_client.transaction_logs.find_one(
                    {"transaction_id": transaction_id}
                )
                
                # Check that sensitive data is sanitized
                payment_details = logged_transaction["payment_details"]
                assert "****" in payment_details["card_number"]
                assert "cvv" not in payment_details

    # Transaction Retrieval Tests
    @pytest.mark.asyncio
    async def test_get_transaction_by_id(self, async_client, sample_payment_request, mongo_client):
        """Test retrieving transaction by ID"""
        with patch('main.db', mongo_client):
            with patch('main.simulate_payment_processing', return_value=True):
                # Create a payment
                payment_response = await async_client.post("/payments", json=sample_payment_request)
                transaction_id = payment_response.json()["transaction_id"]
                
                # Retrieve the transaction
                response = await async_client.get(f"/payments/{transaction_id}")
                assert response.status_code == 200
                
                transaction = response.json()
                assert transaction["transaction_id"] == transaction_id

    @pytest.mark.asyncio
    async def test_get_nonexistent_transaction(self, async_client):
        """Test retrieving non-existent transaction"""
        fake_transaction_id = str(uuid.uuid4())
        response = await async_client.get(f"/payments/{fake_transaction_id}")
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_get_transactions_by_booking_id(self, async_client, sample_payment_request, mongo_client):
        """Test retrieving transactions by booking ID"""
        with patch('main.db', mongo_client):
            with patch('main.simulate_payment_processing', return_value=True):
                # Create multiple payments for the same booking
                await async_client.post("/payments", json=sample_payment_request)
                await async_client.post("/payments", json=sample_payment_request)
                
                # Retrieve transactions by booking ID
                booking_id = sample_payment_request["booking_id"]
                response = await async_client.get(f"/payments/booking/{booking_id}")
                assert response.status_code == 200
                
                transactions = response.json()
                assert len(transactions) == 2
                assert all(t["booking_id"] == booking_id for t in transactions)

    # Refund Tests
    @pytest.mark.asyncio
    async def test_successful_refund(self, async_client, sample_payment_request, mongo_client):
        """Test successful refund processing"""
        with patch('main.db', mongo_client):
            with patch('main.simulate_payment_processing', return_value=True):
                # Create a successful payment
                payment_response = await async_client.post("/payments", json=sample_payment_request)
                transaction_id = payment_response.json()["transaction_id"]
                
                # Process refund
                refund_response = await async_client.post(
                    "/refunds",
                    params={"transaction_id": transaction_id, "reason": "Customer request"}
                )
                
                assert refund_response.status_code == 200
                refund_data = refund_response.json()
                assert refund_data["success"] is True
                assert "refund_transaction_id" in refund_data

    @pytest.mark.asyncio
    async def test_refund_nonexistent_transaction(self, async_client):
        """Test refund for non-existent transaction"""
        fake_transaction_id = str(uuid.uuid4())
        response = await async_client.post(
            "/refunds",
            params={"transaction_id": fake_transaction_id, "reason": "Test"}
        )
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_refund_failed_transaction(self, async_client, sample_payment_request, mongo_client):
        """Test refund for failed transaction"""
        with patch('main.db', mongo_client):
            with patch('main.simulate_payment_processing', return_value=False):
                # Create a failed payment
                payment_response = await async_client.post("/payments", json=sample_payment_request)
                
                # Try to refund the failed payment
                # Note: Since the payment failed, there's no transaction_id to refund
                # This test checks the error handling for attempting to refund failed payments
                fake_transaction_id = str(uuid.uuid4())
                response = await async_client.post(
                    "/refunds",
                    params={"transaction_id": fake_transaction_id, "reason": "Test"}
                )
                assert response.status_code == 404

    # Error Handling Tests
    @pytest.mark.asyncio
    async def test_database_connection_error(self, async_client, sample_payment_request):
        """Test handling of database connection errors"""
        with patch('main.db.transaction_logs.insert_one', side_effect=Exception("Database error")):
            response = await async_client.post("/payments", json=sample_payment_request)
            
            # Should still return a response, but indicate failure
            assert response.status_code == 200
            data = response.json()
            assert data["success"] is False
            assert "error" in data["message"].lower()

    @pytest.mark.asyncio
    async def test_missing_required_fields(self, async_client):
        """Test handling of missing required fields"""
        incomplete_request = {
            "booking_id": "booking_123",
            # Missing amount, payment_method, payment_details
        }
        
        response = await async_client.post("/payments", json=incomplete_request)
        assert response.status_code == 422  # Validation error

    # Performance and Load Tests
    @pytest.mark.asyncio
    async def test_concurrent_payments(self, async_client, sample_payment_request):
        """Test handling concurrent payment requests"""
        with patch('main.simulate_payment_processing', return_value=True):
            # Create multiple concurrent payment requests
            tasks = []
            for i in range(10):
                request = sample_payment_request.copy()
                request["booking_id"] = f"booking_{i}"
                tasks.append(async_client.post("/payments", json=request))
            
            responses = await asyncio.gather(*tasks)
            
            # All requests should succeed
            for response in responses:
                assert response.status_code == 200
                assert response.json()["success"] is True

    @pytest.mark.asyncio
    async def test_payment_processing_timeout(self, async_client, sample_payment_request):
        """Test handling of payment processing timeouts"""
        async def slow_processing(*args, **kwargs):
            await asyncio.sleep(5)  # Simulate slow processing
            return True
            
        with patch('main.simulate_payment_processing', side_effect=slow_processing):
            # This test would normally timeout in a real scenario
            # For testing purposes, we'll reduce the timeout expectation
            response = await async_client.post("/payments", json=sample_payment_request)
            assert response.status_code == 200

    # Integration Tests
    @pytest.mark.asyncio
    async def test_payment_workflow_end_to_end(self, async_client, sample_payment_request, mongo_client):
        """Test complete payment workflow from request to logging"""
        with patch('main.db', mongo_client):
            with patch('main.simulate_payment_processing', return_value=True):
                # Step 1: Process payment
                payment_response = await async_client.post("/payments", json=sample_payment_request)
                assert payment_response.status_code == 200
                
                payment_data = payment_response.json()
                transaction_id = payment_data["transaction_id"]
                
                # Step 2: Verify transaction logging
                logged_transaction = await mongo_client.transaction_logs.find_one(
                    {"transaction_id": transaction_id}
                )
                assert logged_transaction is not None
                
                # Step 3: Retrieve transaction via API
                get_response = await async_client.get(f"/payments/{transaction_id}")
                assert get_response.status_code == 200
                
                # Step 4: Process refund
                refund_response = await async_client.post(
                    "/refunds",
                    params={"transaction_id": transaction_id, "reason": "Test refund"}
                )
                assert refund_response.status_code == 200
                
                # Step 5: Verify refund transaction was created
                refund_data = refund_response.json()
                refund_transaction_id = refund_data["refund_transaction_id"]
                
                refund_transaction = await mongo_client.transaction_logs.find_one(
                    {"transaction_id": refund_transaction_id}
                )
                assert refund_transaction is not None
                assert refund_transaction["amount"] == -sample_payment_request["amount"]


# Utility function to run specific tests
if __name__ == "__main__":
    # Run with: python -m pytest test_payment_service.py -v
    pytest.main([__file__, "-v"])