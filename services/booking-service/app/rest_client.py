"""
REST API Clients for User and Payment Services
This demonstrates HTTP-based microservice communication
"""

import os
import httpx
from typing import Optional, Dict, Any

from .models import User, PaymentResponse


class UserServiceClient:
    """
    HTTP client for user service communication
    Used for user validation and profile operations
    """
    
    def __init__(self):
        self.base_url = os.getenv("USER_SERVICE_URL", "http://localhost:8001")
        self.timeout = httpx.Timeout(30.0)
    
    async def get_user(self, user_id: str) -> Optional[User]:
        """Get user details from user service"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(f"{self.base_url}/api/users/{user_id}")
                
                if response.status_code == 200:
                    user_data = response.json()
                    return User(
                        id=user_data["id"],
                        email=user_data["email"],
                        full_name=user_data["full_name"],
                        phone=user_data.get("phone")
                    )
                elif response.status_code == 404:
                    return None
                else:
                    print(f"Error getting user {user_id}: {response.status_code}")
                    return None
                    
        except httpx.TimeoutException:
            print(f"Timeout getting user {user_id}")
            return None
        except httpx.RequestError as e:
            print(f"Request error getting user {user_id}: {e}")
            return None
        except Exception as e:
            print(f"Error getting user {user_id}: {e}")
            return None
    
    async def validate_user_exists(self, user_id: str) -> bool:
        """Quick validation that user exists"""
        user = await self.get_user(user_id)
        return user is not None


class PaymentServiceClient:
    """
    HTTP client for payment service communication
    Used for payment processing operations
    """
    
    def __init__(self):
        self.base_url = os.getenv("PAYMENT_SERVICE_URL", "http://localhost:8002")
        self.timeout = httpx.Timeout(30.0)
    
    async def process_payment(
        self, 
        booking_id: str, 
        amount: float, 
        payment_method: str, 
        payment_details: str
    ) -> Dict[str, Any]:
        """
        Process payment via payment service
        Returns payment result with transaction ID
        """
        try:
            payment_data = {
                "booking_id": booking_id,
                "amount": amount,
                "payment_method": payment_method,
                "payment_details": payment_details
            }
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/payments/process",
                    json=payment_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return {
                        "success": True,
                        "transaction_id": result.get("transaction_id"),
                        "message": result.get("message", "Payment processed successfully")
                    }
                else:
                    error_data = response.json() if response.headers.get("content-type") == "application/json" else {}
                    return {
                        "success": False,
                        "message": error_data.get("message", f"Payment failed with status {response.status_code}")
                    }
                    
        except httpx.TimeoutException:
            return {
                "success": False,
                "message": "Payment processing timeout"
            }
        except httpx.RequestError as e:
            return {
                "success": False,
                "message": f"Payment request error: {str(e)}"
            }
        except Exception as e:
            return {
                "success": False,
                "message": f"Payment processing error: {str(e)}"
            }
    
    async def initiate_refund(
        self, 
        transaction_id: str, 
        amount: float, 
        reason: str
    ) -> Dict[str, Any]:
        """
        Initiate refund via payment service
        """
        try:
            refund_data = {
                "transaction_id": transaction_id,
                "amount": amount,
                "reason": reason
            }
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(
                    f"{self.base_url}/api/payments/refund",
                    json=refund_data
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return {
                        "success": True,
                        "refund_id": result.get("refund_id"),
                        "message": result.get("message", "Refund initiated successfully")
                    }
                else:
                    error_data = response.json() if response.headers.get("content-type") == "application/json" else {}
                    return {
                        "success": False,
                        "message": error_data.get("message", f"Refund failed with status {response.status_code}")
                    }
                    
        except Exception as e:
            return {
                "success": False,
                "message": f"Refund processing error: {str(e)}"
            }
    
    async def get_payment_status(self, transaction_id: str) -> Dict[str, Any]:
        """Get payment status from payment service"""
        try:
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.get(f"{self.base_url}/api/payments/{transaction_id}/status")
                
                if response.status_code == 200:
                    return response.json()
                else:
                    return {
                        "success": False,
                        "message": f"Failed to get payment status: {response.status_code}"
                    }
                    
        except Exception as e:
            return {
                "success": False,
                "message": f"Error getting payment status: {str(e)}"
            }