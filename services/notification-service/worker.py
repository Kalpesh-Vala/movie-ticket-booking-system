"""
Notification Service Worker
Consumes RabbitMQ events and sends notifications with idempotency checking
"""

import asyncio
import json
import logging
import os
import uuid
from datetime import datetime
from typing import Dict, Any, Optional

import aio_pika
import redis.asyncio as redis
from motor.motor_asyncio import AsyncIOMotorClient

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class NotificationWorker:
    def __init__(self):
        # RabbitMQ connection
        self.rabbitmq_url = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
        self.exchange_name = "movie_app_events"
        self.queue_name = "notification.booking_events"
        
        # Redis for idempotency checking
        self.redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
        self.redis_client = None
        
        # MongoDB for logging
        self.mongodb_uri = os.getenv("MONGODB_URI", "mongodb://localhost:27017")
        self.mongo_client = None
        self.db = None
        
        # Connection objects
        self.connection = None
        self.channel = None
        self.exchange = None
        self.queue = None

    async def initialize(self):
        """Initialize all connections"""
        # Connect to RabbitMQ
        self.connection = await aio_pika.connect_robust(self.rabbitmq_url)
        self.channel = await self.connection.channel()
        await self.channel.set_qos(prefetch_count=10)  # Process 10 messages concurrently
        
        # Declare exchange and queue
        self.exchange = await self.channel.declare_exchange(
            self.exchange_name, 
            aio_pika.ExchangeType.TOPIC,
            durable=True
        )
        
        self.queue = await self.channel.declare_queue(
            self.queue_name,
            durable=True,
            arguments={"x-dead-letter-exchange": f"{self.exchange_name}.dlx"}
        )
        
        # Bind queue to routing keys for booking events
        await self.queue.bind(self.exchange, "booking.confirmed")
        await self.queue.bind(self.exchange, "booking.cancelled")
        await self.queue.bind(self.exchange, "booking.refunded")
        
        # Connect to Redis
        self.redis_client = redis.from_url(self.redis_url)
        
        # Connect to MongoDB
        self.mongo_client = AsyncIOMotorClient(self.mongodb_uri)
        self.db = self.mongo_client.movie_booking
        
        logger.info("Notification worker initialized successfully")

    async def start_consuming(self):
        """Start consuming messages from RabbitMQ"""
        logger.info("Starting to consume messages...")
        await self.queue.consume(self.process_message)

    async def process_message(self, message: aio_pika.IncomingMessage):
        """
        CRITICAL CALLBACK FUNCTION: Process incoming RabbitMQ messages
        This function demonstrates:
        1. Idempotency checking with Redis
        2. Message processing
        3. Notification sending simulation
        4. Logging to MongoDB
        """
        async with message.process():
            try:
                # Parse message
                body = json.loads(message.body.decode())
                event_id = body.get("event_id")
                event_type = body.get("event_type")
                
                logger.info(f"Processing event: {event_type} with ID: {event_id}")

                # CRITICAL: Check idempotency using Redis
                # This ensures we don't process the same event multiple times
                if await self.is_already_processed(event_id):
                    logger.info(f"Event {event_id} already processed, skipping")
                    return

                # Mark event as being processed
                await self.mark_as_processing(event_id)

                # Process the event based on type
                success = await self.handle_event(event_type, body)

                if success:
                    # Mark as successfully processed
                    await self.mark_as_processed(event_id)
                    logger.info(f"Successfully processed event {event_id}")
                else:
                    # Mark as failed (will be retried)
                    await self.mark_as_failed(event_id)
                    logger.error(f"Failed to process event {event_id}")
                    raise Exception("Event processing failed")

            except json.JSONDecodeError as e:
                logger.error(f"Invalid JSON in message: {e}")
                # Don't requeue malformed messages
                return
                
            except Exception as e:
                logger.error(f"Error processing message: {e}")
                # This will cause the message to be requeued for retry
                raise

    async def is_already_processed(self, event_id: str) -> bool:
        """Check if event has already been processed using Redis"""
        try:
            status = await self.redis_client.get(f"event:{event_id}:status")
            return status is not None and status.decode() in ["processed", "processing"]
        except Exception as e:
            logger.error(f"Error checking event status in Redis: {e}")
            return False

    async def mark_as_processing(self, event_id: str):
        """Mark event as currently being processed"""
        try:
            await self.redis_client.setex(
                f"event:{event_id}:status", 
                300,  # 5 minutes TTL
                "processing"
            )
        except Exception as e:
            logger.error(f"Error marking event as processing: {e}")

    async def mark_as_processed(self, event_id: str):
        """Mark event as successfully processed"""
        try:
            await self.redis_client.setex(
                f"event:{event_id}:status", 
                86400,  # 24 hours TTL
                "processed"
            )
        except Exception as e:
            logger.error(f"Error marking event as processed: {e}")

    async def mark_as_failed(self, event_id: str):
        """Mark event as failed"""
        try:
            await self.redis_client.setex(
                f"event:{event_id}:status", 
                3600,  # 1 hour TTL for retry
                "failed"
            )
        except Exception as e:
            logger.error(f"Error marking event as failed: {e}")

    async def handle_event(self, event_type: str, event_data: Dict[str, Any]) -> bool:
        """Handle different types of events"""
        try:
            if event_type == "booking.confirmed":
                return await self.handle_booking_confirmed(event_data)
            elif event_type == "booking.cancelled":
                return await self.handle_booking_cancelled(event_data)
            elif event_type == "booking.refunded":
                return await self.handle_booking_refunded(event_data)
            else:
                logger.warning(f"Unknown event type: {event_type}")
                return True  # Don't retry unknown events

        except Exception as e:
            logger.error(f"Error handling event {event_type}: {e}")
            return False

    async def handle_booking_confirmed(self, event_data: Dict[str, Any]) -> bool:
        """Handle booking confirmation notification"""
        try:
            booking_id = event_data["booking_id"]
            user_id = event_data["user_id"]
            
            # Get user details (in production, you'd call user service)
            user_email = f"user_{user_id}@example.com"  # Placeholder
            
            # Simulate sending confirmation email
            await self.send_email_notification(
                to_email=user_email,
                subject="Booking Confirmed - Movie Tickets",
                template="booking_confirmation",
                data={
                    "booking_id": booking_id,
                    "showtime_id": event_data.get("showtime_id"),
                    "seats": event_data.get("seats", []),
                    "total_amount": event_data.get("total_amount", 0)
                }
            )
            
            # Log the notification
            await self.log_notification(
                event_id=event_data["event_id"],
                notification_type="email",
                recipient=user_email,
                subject="Booking Confirmed - Movie Tickets",
                status="sent",
                event_data=event_data
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Error handling booking confirmation: {e}")
            return False

    async def handle_booking_cancelled(self, event_data: Dict[str, Any]) -> bool:
        """Handle booking cancellation notification"""
        try:
            booking_id = event_data["booking_id"]
            user_id = event_data["user_id"]
            
            user_email = f"user_{user_id}@example.com"
            
            await self.send_email_notification(
                to_email=user_email,
                subject="Booking Cancelled",
                template="booking_cancellation",
                data={
                    "booking_id": booking_id,
                    "cancellation_reason": event_data.get("reason", "Unknown")
                }
            )
            
            await self.log_notification(
                event_id=event_data["event_id"],
                notification_type="email",
                recipient=user_email,
                subject="Booking Cancelled",
                status="sent",
                event_data=event_data
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Error handling booking cancellation: {e}")
            return False

    async def handle_booking_refunded(self, event_data: Dict[str, Any]) -> bool:
        """Handle booking refund notification"""
        try:
            booking_id = event_data["booking_id"]
            user_id = event_data["user_id"]
            
            user_email = f"user_{user_id}@example.com"
            
            await self.send_email_notification(
                to_email=user_email,
                subject="Refund Processed",
                template="refund_notification",
                data={
                    "booking_id": booking_id,
                    "refund_amount": event_data.get("refund_amount", 0),
                    "transaction_id": event_data.get("transaction_id")
                }
            )
            
            await self.log_notification(
                event_id=event_data["event_id"],
                notification_type="email",
                recipient=user_email,
                subject="Refund Processed",
                status="sent",
                event_data=event_data
            )
            
            return True
            
        except Exception as e:
            logger.error(f"Error handling booking refund: {e}")
            return False

    async def send_email_notification(self, to_email: str, subject: str, 
                                    template: str, data: Dict[str, Any]):
        """
        Simulate sending email notification
        In production, this would integrate with email services like SendGrid, SES, etc.
        """
        logger.info(f"📧 Sending email to {to_email}")
        logger.info(f"📧 Subject: {subject}")
        logger.info(f"📧 Template: {template}")
        logger.info(f"📧 Data: {data}")
        
        # Simulate email sending delay
        await asyncio.sleep(0.5)
        
        logger.info(f"📧 Email sent successfully to {to_email}")

    async def send_sms_notification(self, phone_number: str, message: str):
        """
        Simulate sending SMS notification
        In production, this would integrate with SMS services like Twilio, AWS SNS, etc.
        """
        logger.info(f"📱 Sending SMS to {phone_number}")
        logger.info(f"📱 Message: {message}")
        
        # Simulate SMS sending delay
        await asyncio.sleep(0.3)
        
        logger.info(f"📱 SMS sent successfully to {phone_number}")

    async def log_notification(self, event_id: str, notification_type: str, 
                             recipient: str, subject: str, status: str, 
                             event_data: Dict[str, Any]):
        """Log notification details to MongoDB"""
        try:
            notification_log = {
                "_id": str(uuid.uuid4()),
                "event_id": event_id,
                "notification_type": notification_type,
                "recipient": recipient,
                "subject": subject,
                "status": status,
                "event_data": event_data,
                "created_at": datetime.utcnow(),
                "sent_at": datetime.utcnow() if status == "sent" else None
            }
            
            await self.db.notification_logs.insert_one(notification_log)
            logger.info(f"Notification logged: {notification_log['_id']}")
            
        except Exception as e:
            logger.error(f"Error logging notification: {e}")

    async def cleanup(self):
        """Cleanup connections"""
        if self.redis_client:
            await self.redis_client.close()
        
        if self.mongo_client:
            self.mongo_client.close()
        
        if self.connection:
            await self.connection.close()


async def main():
    """Main function to run the notification worker"""
    worker = NotificationWorker()
    
    try:
        await worker.initialize()
        logger.info("🚀 Notification worker started")
        await worker.start_consuming()
        
        # Keep the worker running
        try:
            await asyncio.Future()  # Run forever
        except KeyboardInterrupt:
            logger.info("🛑 Shutting down notification worker")
            
    finally:
        await worker.cleanup()


if __name__ == "__main__":
    asyncio.run(main())