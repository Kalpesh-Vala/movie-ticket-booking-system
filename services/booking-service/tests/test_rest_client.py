"""
Unit tests for REST API clients
"""

import pytest
from unittest.mock import AsyncMock, patch
import httpx

from app.rest_client import UserServiceClient, PaymentServiceClient
from app.models import User


class TestUserServiceClient:
    """Test User Service REST client"""
    
    @pytest.mark.asyncio
    async def test_get_user_success(self):
        """Test successful user retrieval"""
        client = UserServiceClient()
        
        # Mock response data
        user_data = {
            "id": "user_123",
            "email": "test@example.com",
            "full_name": "Test User",
            "phone": "+1234567890"
        }
        
        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = user_data
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.get_user("user_123")
        
        assert result is not None
        assert isinstance(result, User)
        assert result.id == "user_123"
        assert result.email == "test@example.com"
        assert result.full_name == "Test User"
        assert result.phone == "+1234567890"
    
    @pytest.mark.asyncio
    async def test_get_user_not_found(self):
        """Test user not found"""
        client = UserServiceClient()
        
        mock_response = AsyncMock()
        mock_response.status_code = 404
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.get_user("nonexistent_user")
        
        assert result is None
    
    @pytest.mark.asyncio
    async def test_get_user_timeout(self):
        """Test user service timeout"""
        client = UserServiceClient()
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get.side_effect = httpx.TimeoutException("Timeout")
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.get_user("user_123")
        
        assert result is None
    
    @pytest.mark.asyncio
    async def test_validate_user_exists_true(self):
        """Test user validation - user exists"""
        client = UserServiceClient()
        
        user_data = {
            "id": "user_123",
            "email": "test@example.com",
            "full_name": "Test User"
        }
        
        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = user_data
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.validate_user_exists("user_123")
        
        assert result is True
    
    @pytest.mark.asyncio
    async def test_validate_user_exists_false(self):
        """Test user validation - user does not exist"""
        client = UserServiceClient()
        
        mock_response = AsyncMock()
        mock_response.status_code = 404
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.validate_user_exists("nonexistent_user")
        
        assert result is False


class TestPaymentServiceClient:
    """Test Payment Service REST client"""
    
    @pytest.mark.asyncio
    async def test_process_payment_success(self):
        """Test successful payment processing"""
        client = PaymentServiceClient()
        
        payment_response = {
            "transaction_id": "txn_123",
            "message": "Payment processed successfully"
        }
        
        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = payment_response
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.post.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.process_payment(
                booking_id="booking_123",
                amount=31.98,
                payment_method="credit_card",
                payment_details="card_details"
            )
        
        assert result["success"] is True
        assert result["transaction_id"] == "txn_123"
        assert "successfully" in result["message"]
    
    @pytest.mark.asyncio
    async def test_process_payment_failure(self):
        """Test payment processing failure"""
        client = PaymentServiceClient()
        
        error_response = {
            "message": "Insufficient funds"
        }
        
        mock_response = AsyncMock()
        mock_response.status_code = 400
        mock_response.json.return_value = error_response
        mock_response.headers = {"content-type": "application/json"}
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.post.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.process_payment(
                booking_id="booking_123",
                amount=31.98,
                payment_method="credit_card",
                payment_details="invalid_card"
            )
        
        assert result["success"] is False
        assert "Insufficient funds" in result["message"]
    
    @pytest.mark.asyncio
    async def test_process_payment_timeout(self):
        """Test payment processing timeout"""
        client = PaymentServiceClient()
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.post.side_effect = httpx.TimeoutException("Timeout")
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.process_payment(
                booking_id="booking_123",
                amount=31.98,
                payment_method="credit_card",
                payment_details="card_details"
            )
        
        assert result["success"] is False
        assert "timeout" in result["message"].lower()
    
    @pytest.mark.asyncio
    async def test_initiate_refund_success(self):
        """Test successful refund initiation"""
        client = PaymentServiceClient()
        
        refund_response = {
            "refund_id": "refund_123",
            "message": "Refund initiated successfully"
        }
        
        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = refund_response
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.post.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.initiate_refund(
                transaction_id="txn_123",
                amount=31.98,
                reason="Customer request"
            )
        
        assert result["success"] is True
        assert result["refund_id"] == "refund_123"
        assert "successfully" in result["message"]
    
    @pytest.mark.asyncio
    async def test_get_payment_status_success(self):
        """Test successful payment status retrieval"""
        client = PaymentServiceClient()
        
        status_response = {
            "transaction_id": "txn_123",
            "status": "completed",
            "amount": 31.98
        }
        
        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = status_response
        
        with patch('httpx.AsyncClient') as mock_client_class:
            mock_client = AsyncMock()
            mock_client.get.return_value = mock_response
            mock_client_class.return_value.__aenter__.return_value = mock_client
            
            result = await client.get_payment_status("txn_123")
        
        assert result["transaction_id"] == "txn_123"
        assert result["status"] == "completed"
        assert result["amount"] == 31.98