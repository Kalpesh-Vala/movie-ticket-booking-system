"""
Payment Service - FastAPI Implementation
Handles payment processing simulation and transaction logging
"""

from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
import uuid
import asyncio
from datetime import datetime, timezone
from motor.motor_asyncio import AsyncIOMotorClient
import os
from enum import Enum
import random
import logging

# Configure logging first
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Try to import event publisher, but handle gracefully if RabbitMQ is not available
try:
    from event_publisher import publish_payment_event, cleanup_event_publisher
    EVENT_PUBLISHER_AVAILABLE = True
    logger.info("Event publisher loaded successfully")
except Exception as e:
    logger.warning(f"Event publisher not available: {e}")
    EVENT_PUBLISHER_AVAILABLE = False
    
    # Create dummy functions if event publisher fails
    async def publish_payment_event(event_type, data):
        logger.info(f"Would publish event: {event_type} with data: {data}")
    
    async def cleanup_event_publisher():
        logger.info("No event publisher to cleanup")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Payment Service", version="1.0.0")

# MongoDB connection
MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
client = AsyncIOMotorClient(MONGODB_URI)
db = client.movie_booking


class PaymentMethod(str, Enum):
    CREDIT_CARD = "credit_card"
    DEBIT_CARD = "debit_card"
    DIGITAL_WALLET = "digital_wallet"
    NET_BANKING = "net_banking"


class PaymentStatus(str, Enum):
    PENDING = "pending"
    SUCCESS = "success"
    FAILED = "failed"
    REFUNDED = "refunded"


class PaymentRequest(BaseModel):
    booking_id: str
    user_id: str
    amount: float
    payment_method: PaymentMethod
    payment_details: dict  # Card details, wallet info, etc.


class PaymentResponse(BaseModel):
    success: bool
    transaction_id: Optional[str] = None
    message: str
    status: PaymentStatus


class TransactionLog(BaseModel):
    transaction_id: str
    booking_id: str
    amount: float
    payment_method: PaymentMethod
    status: PaymentStatus
    payment_details: dict
    created_at: datetime
    updated_at: datetime
    gateway_response: Optional[dict] = None
    failure_reason: Optional[str] = None


@app.post("/payments", response_model=PaymentResponse)
async def process_payment(payment_request: PaymentRequest):
    """
    CRITICAL PAYMENT PROCESSING ENDPOINT
    This function simulates payment processing and logs all transactions to MongoDB.
    In production, this would integrate with actual payment gateways.
    """
    
    transaction_id = str(uuid.uuid4())
    
    try:
        # Validate payment request
        if payment_request.amount <= 0:
            raise HTTPException(status_code=400, detail="Invalid payment amount")
        
        if payment_request.amount > 10000:  # Example limit
            raise HTTPException(status_code=400, detail="Payment amount exceeds limit")

        # Simulate payment processing with random success/failure
        # In production, this would call actual payment gateway APIs
        payment_success = await simulate_payment_processing(
            payment_request.payment_method,
            payment_request.amount,
            payment_request.payment_details
        )

        # Determine payment status and message
        if payment_success:
            status = PaymentStatus.SUCCESS
            message = "Payment processed successfully"
            gateway_response = {
                "gateway_transaction_id": f"gtw_{uuid.uuid4().hex[:12]}",
                "authorization_code": f"auth_{uuid.uuid4().hex[:8]}",
                "gateway_status": "APPROVED",
                "processing_time_ms": random.randint(500, 2000)
            }
            failure_reason = ""  # Empty string instead of None
        else:
            status = PaymentStatus.FAILED
            message = "Payment processing failed"
            gateway_response = {
                "gateway_transaction_id": f"gtw_{uuid.uuid4().hex[:12]}",
                "error_code": "DECLINED",
                "gateway_status": "DECLINED",
                "processing_time_ms": random.randint(200, 1000)
            }
            failure_reason = "Insufficient funds or card declined"

        # CRITICAL: Log transaction to MongoDB for audit trail
        transaction_log = TransactionLog(
            transaction_id=transaction_id,
            booking_id=payment_request.booking_id,
            amount=payment_request.amount,
            payment_method=payment_request.payment_method,
            status=status,
            payment_details=sanitize_payment_details(payment_request.payment_details),
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
            gateway_response=gateway_response,
            failure_reason=failure_reason
        )

        # Save transaction log to MongoDB
        await db.transaction_logs.insert_one(transaction_log.model_dump())

        # CRITICAL: Publish payment event for notification service
        if payment_success:
            await publish_payment_event("payment.success", {
                "event_id": str(uuid.uuid4()),
                "event_type": "payment.success",
                "booking_id": payment_request.booking_id,
                "transaction_id": transaction_id,
                "amount": payment_request.amount,
                "payment_method": payment_request.payment_method.value,
                "gateway_response": gateway_response,
                "user_id": payment_request.user_id,  # Ensure user_id is included
                "timestamp": datetime.now(timezone.utc).isoformat()
            })
        else:
            await publish_payment_event("payment.failed", {
                "event_id": str(uuid.uuid4()),
                "event_type": "payment.failed",
                "booking_id": payment_request.booking_id,
                "transaction_id": transaction_id,
                "amount": payment_request.amount,
                "payment_method": payment_request.payment_method.value,
                "failure_reason": failure_reason,
                "gateway_response": gateway_response,
                "user_id": payment_request.user_id,  # Ensure user_id is included
                "timestamp": datetime.now(timezone.utc).isoformat()
            })

        # Prepare response
        response = PaymentResponse(
            success=payment_success,
            transaction_id=transaction_id if payment_success else None,
            message=message,
            status=status
        )

        return response

    except HTTPException:
        raise
    except Exception as e:
        # Log error and save failed transaction
        error_message = f"Payment processing error: {str(e)}"
        
        error_transaction = TransactionLog(
            transaction_id=transaction_id,
            booking_id=payment_request.booking_id,
            amount=payment_request.amount,
            payment_method=payment_request.payment_method,
            status=PaymentStatus.FAILED,
            payment_details=sanitize_payment_details(payment_request.payment_details),
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc),
            gateway_response={"error": "system_error", "message": str(e)},
            failure_reason=error_message
        )
        
        await db.transaction_logs.insert_one(error_transaction.model_dump())
        
        return PaymentResponse(
            success=False,
            transaction_id=None,
            message=error_message,
            status=PaymentStatus.FAILED
        )


async def simulate_payment_processing(
    payment_method: PaymentMethod, 
    amount: float, 
    payment_details: dict
) -> bool:
    """
    Simulate payment gateway processing
    In production, this would make actual API calls to payment gateways
    """
    
    # Simulate processing delay
    await asyncio.sleep(random.uniform(0.5, 2.0))
    
    # Simulate different success rates based on payment method
    success_rates = {
        PaymentMethod.CREDIT_CARD: 0.95,
        PaymentMethod.DEBIT_CARD: 0.90,
        PaymentMethod.DIGITAL_WALLET: 0.98,
        PaymentMethod.NET_BANKING: 0.85
    }
    
    success_rate = success_rates.get(payment_method, 0.90)
    
    # Higher chance of failure for large amounts (simulate risk management)
    if amount > 5000:
        success_rate *= 0.8
    
    return random.random() < success_rate


def sanitize_payment_details(payment_details: dict) -> dict:
    """
    Remove sensitive information from payment details before logging
    """
    sanitized = payment_details.copy()
    
    # Mask credit card numbers
    if "card_number" in sanitized:
        card_number = sanitized["card_number"]
        if len(card_number) >= 4:
            sanitized["card_number"] = f"****-****-****-{card_number[-4:]}"
    
    # Remove CVV
    if "cvv" in sanitized:
        sanitized.pop("cvv")
    
    # Remove sensitive wallet information
    sensitive_keys = ["pin", "password", "otp", "cvv", "security_code"]
    for key in sensitive_keys:
        if key in sanitized:
            sanitized.pop(key)
    
    return sanitized


@app.get("/payments/{transaction_id}")
async def get_transaction(transaction_id: str):
    """Get transaction details by ID"""
    transaction = await db.transaction_logs.find_one({"transaction_id": transaction_id})
    
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    # Convert ObjectId to string for JSON serialization
    if "_id" in transaction:
        transaction["_id"] = str(transaction["_id"])
    
    return transaction


@app.get("/payments/booking/{booking_id}")
async def get_booking_transactions(booking_id: str):
    """Get all transactions for a booking"""
    transactions_cursor = db.transaction_logs.find({"booking_id": booking_id})
    transactions = await transactions_cursor.to_list(length=100)
    
    return transactions


@app.post("/refunds")
async def process_refund(transaction_id: str, reason: str):
    """Process refund for a transaction"""
    
    # Find original transaction
    original_transaction = await db.transaction_logs.find_one({"transaction_id": transaction_id})
    
    if not original_transaction:
        raise HTTPException(status_code=404, detail="Original transaction not found")
    
    if original_transaction["status"] != PaymentStatus.SUCCESS:
        raise HTTPException(status_code=400, detail="Can only refund successful transactions")
    
    # Create refund transaction
    refund_transaction_id = str(uuid.uuid4())
    refund_transaction = TransactionLog(
        transaction_id=refund_transaction_id,
        booking_id=original_transaction["booking_id"],
        amount=-original_transaction["amount"],  # Negative amount for refund
        payment_method=original_transaction["payment_method"],
        status=PaymentStatus.REFUNDED,
        payment_details=original_transaction["payment_details"],
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
        gateway_response={
            "refund_reference": f"ref_{uuid.uuid4().hex[:12]}",
            "original_transaction": transaction_id,
            "reason": reason
        }
    )
    
    await db.transaction_logs.insert_one(refund_transaction.model_dump())
    
    # Update original transaction status
    await db.transaction_logs.update_one(
        {"transaction_id": transaction_id},
        {
            "$set": {
                "status": PaymentStatus.REFUNDED,
                "updated_at": datetime.now(timezone.utc)
            }
        }
    )
    
    # Publish refund event
    await publish_payment_event("payment.refunded", {
        "booking_id": original_transaction["booking_id"],
        "original_transaction_id": transaction_id,
        "refund_transaction_id": refund_transaction_id,
        "refund_amount": original_transaction["amount"],
        "reason": reason
    })
    
    return {
        "success": True,
        "refund_transaction_id": refund_transaction_id,
        "message": "Refund processed successfully"
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "payment-service"}


# Add startup and shutdown events
@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on app shutdown"""
    await cleanup_event_publisher()


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8003)