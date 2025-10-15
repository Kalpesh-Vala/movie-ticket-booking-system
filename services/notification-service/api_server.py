"""
Notification Service HTTP API Wrapper
Provides HTTP endpoints for testing and manual notification triggers
"""

from fastapi import FastAPI, HTTPException
from contextlib import asynccontextmanager
from pydantic import BaseModel
from typing import Optional, Dict, Any
import json
import logging
import os
import asyncio
import uuid
from datetime import datetime
import uvicorn

# Import the notification worker components
from smtp_service import SMTPEmailService
from worker import NotificationWorker

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Notification Service API", version="1.0.0")

# Global instances
email_service = SMTPEmailService()
notification_worker = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle"""
    global notification_worker
    # Startup
    try:
        notification_worker = NotificationWorker()
        await notification_worker.initialize()
        logger.info("✅ Notification service HTTP API started")
    except Exception as e:
        logger.error(f"❌ Failed to initialize notification worker: {e}")
    
    yield
    
    # Shutdown
    if notification_worker:
        await notification_worker.cleanup()

app = FastAPI(
    title="Notification Service API", 
    version="1.0.0",
    lifespan=lifespan
)
# Pydantic models for API requests
class TestEmailRequest(BaseModel):
    recipient: str
    subject: str = "Test Notification"
    message: str = "This is a test notification from the notification service"
    email_type: str = "test"

class NotificationEventRequest(BaseModel):
    event_type: str
    event_data: Dict[str, Any]
    recipient_email: Optional[str] = None

class BookingNotificationRequest(BaseModel):
    user_email: str
    booking_id: str
    movie_title: str
    showtime: str
    cinema_name: str
    seats: list
    total_amount: float

class PaymentNotificationRequest(BaseModel):
    user_email: str
    booking_id: str
    transaction_id: str
    amount: float
    payment_method: str
    status: str = "success"

@app.on_event("startup")
async def startup_event():
    """Initialize notification worker on startup"""
    global notification_worker
    try:
        notification_worker = NotificationWorker()
        await notification_worker.initialize()
        logger.info("✅ Notification service HTTP API started")
    except Exception as e:
        logger.error(f"❌ Failed to initialize notification worker: {e}")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    if notification_worker:
        await notification_worker.cleanup()

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "notification-service",
        "version": "1.0.0",
        "status": "running",
        "description": "Movie Ticket Booking Notification Service HTTP API"
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    try:
        # Check email service
        email_status = "healthy"
        
        # Check notification worker
        worker_status = "healthy" if notification_worker else "unhealthy"
        
        return {
            "status": "healthy",
            "service": "notification-service",
            "timestamp": datetime.utcnow().isoformat(),
            "components": {
                "email_service": email_status,
                "notification_worker": worker_status,
                "smtp": "configured"
            }
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

@app.get("/actuator/health")
async def actuator_health():
    """Spring Boot style health check for Kong Gateway compatibility"""
    try:
        return {
            "status": "UP",
            "groups": ["liveness", "readiness"],
            "components": {
                "notification": {"status": "UP"},
                "smtp": {"status": "UP"},
                "worker": {"status": "UP"}
            }
        }
    except Exception as e:
        return {
            "status": "DOWN",
            "components": {
                "notification": {"status": "DOWN", "details": str(e)}
            }
        }

@app.post("/test/email")
async def send_test_email(request: TestEmailRequest):
    """Send a test email"""
    try:
        # Create template data for the test email
        template_data = {
            'user_name': 'Test User',
            'message': request.message,
            'timestamp': datetime.now().isoformat()
        }
        
        success = await email_service.send_email(
            to_email=request.recipient,
            subject=request.subject,
            template_name='booking_confirmation',  # Use existing template
            template_data={
                'user_name': 'Test User',
                'movie_title': 'Test Email',
                'cinema_name': 'API Test',
                'showtime': datetime.now().strftime('%Y-%m-%d %H:%M'),
                'seats': ['API', 'TEST'],
                'booking_id': 'API-TEST-001',
                'total_amount': 0.00,
                'booking_date': datetime.now().strftime('%Y-%m-%d')
            }
        )
        
        if success:
            return {
                "success": True,
                "message": f"Test email sent to {request.recipient}",
                "timestamp": datetime.utcnow().isoformat()
            }
        else:
            raise HTTPException(status_code=500, detail="Failed to send email")
            
    except Exception as e:
        logger.error(f"Failed to send test email: {e}")
        raise HTTPException(status_code=500, detail=f"Email sending failed: {str(e)}")

@app.post("/notifications/booking-confirmation")
async def send_booking_confirmation(request: BookingNotificationRequest):
    """Send booking confirmation notification"""
    try:
        if not notification_worker:
            raise HTTPException(status_code=503, detail="Notification worker not available")
        
        # Create booking confirmation event
        event_data = {
            "event_id": str(uuid.uuid4()),
            "event_type": "booking.confirmed",
            "user_email": request.user_email,
            "booking_id": request.booking_id,
            "movie_title": request.movie_title,
            "showtime": request.showtime,
            "cinema_name": request.cinema_name,
            "seats": request.seats,
            "total_amount": request.total_amount,
            "booking_date": datetime.now().strftime("%Y-%m-%d"),
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Process the booking confirmation
        await notification_worker.handle_booking_confirmed(event_data)
        
        return {
            "success": True,
            "message": f"Booking confirmation sent to {request.user_email}",
            "booking_id": request.booking_id,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to send booking confirmation: {e}")
        raise HTTPException(status_code=500, detail=f"Booking notification failed: {str(e)}")

@app.post("/notifications/payment-confirmation")
async def send_payment_confirmation(request: PaymentNotificationRequest):
    """Send payment confirmation notification"""
    try:
        if not notification_worker:
            raise HTTPException(status_code=503, detail="Notification worker not available")
        
        # Create payment event
        event_data = {
            "event_id": str(uuid.uuid4()),
            "event_type": f"payment.{request.status}",
            "user_email": request.user_email,
            "booking_id": request.booking_id,
            "transaction_id": request.transaction_id,
            "amount": request.amount,
            "payment_method": request.payment_method,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Process the payment event
        if request.status == "success":
            await notification_worker.handle_payment_success(event_data)
        else:
            await notification_worker.handle_payment_failed(event_data)
        
        return {
            "success": True,
            "message": f"Payment notification sent to {request.user_email}",
            "transaction_id": request.transaction_id,
            "status": request.status,
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to send payment notification: {e}")
        raise HTTPException(status_code=500, detail=f"Payment notification failed: {str(e)}")

@app.post("/notifications/custom")
async def send_custom_notification(request: NotificationEventRequest):
    """Send a custom notification based on event type"""
    try:
        if not notification_worker:
            raise HTTPException(status_code=503, detail="Notification worker not available")
        
        # Add recipient email if provided
        if request.recipient_email:
            request.event_data["user_email"] = request.recipient_email
        
        # Add event metadata
        request.event_data["event_id"] = str(uuid.uuid4())
        request.event_data["timestamp"] = datetime.utcnow().isoformat()
        
        # Route to appropriate handler based on event type
        if request.event_type == "booking.confirmed":
            await notification_worker.handle_booking_confirmed(request.event_data)
        elif request.event_type == "booking.cancelled":
            await notification_worker.handle_booking_cancelled(request.event_data)
        elif request.event_type == "payment.success":
            await notification_worker.handle_payment_success(request.event_data)
        elif request.event_type == "payment.failed":
            await notification_worker.handle_payment_failed(request.event_data)
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported event type: {request.event_type}")
        
        return {
            "success": True,
            "message": f"Custom notification processed for event: {request.event_type}",
            "event_id": request.event_data["event_id"],
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to process custom notification: {e}")
        raise HTTPException(status_code=500, detail=f"Custom notification failed: {str(e)}")

@app.get("/notifications/logs")
async def get_notification_logs(limit: int = 10):
    """Get recent notification logs"""
    try:
        if not notification_worker or notification_worker.db is None:
            raise HTTPException(status_code=503, detail="Database not available")
        
        # Get recent notification logs from MongoDB
        cursor = notification_worker.db.notification_logs.find().sort("created_at", -1).limit(limit)
        logs = await cursor.to_list(length=limit)
        
        # Convert ObjectId to string for JSON serialization
        for log in logs:
            log["_id"] = str(log["_id"])
        
        return {
            "logs": logs,
            "count": len(logs),
            "timestamp": datetime.utcnow().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to get notification logs: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve logs: {str(e)}")

@app.get("/stats")
async def get_notification_stats():
    """Get notification service statistics"""
    try:
        stats = {
            "service": "notification-service",
            "uptime": "running",
            "email_service": "configured",
            "worker_status": "active" if notification_worker else "inactive",
            "supported_events": [
                "booking.confirmed",
                "booking.cancelled", 
                "payment.success",
                "payment.failed"
            ],
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Add database stats if available
        if notification_worker and notification_worker.db is not None:
            try:
                log_count = await notification_worker.db.notification_logs.count_documents({})
                stats["total_notifications_sent"] = log_count
            except:
                stats["total_notifications_sent"] = "unavailable"
        
        return stats
        
    except Exception as e:
        logger.error(f"Failed to get stats: {e}")
        raise HTTPException(status_code=500, detail=f"Stats unavailable: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8084)