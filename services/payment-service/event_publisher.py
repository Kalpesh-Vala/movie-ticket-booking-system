"""
Event Publisher for Payment Service
Publishes payment events to RabbitMQ for notification service consumption
"""

import asyncio
import json
import logging
import uuid
from datetime import datetime
from typing import Dict, Any
import aio_pika
import os

logger = logging.getLogger(__name__)


class PaymentEventPublisher:
    """Handles publishing of payment events to RabbitMQ"""
    
    def __init__(self):
        self.rabbitmq_url = os.getenv("RABBITMQ_URL", "amqp://guest:guest@localhost:5672/")
        self.exchange_name = "movie_app_events"
        self.connection = None
        self.channel = None
        self.exchange = None
        self._initialized = False

    async def initialize(self):
        """Initialize RabbitMQ connection"""
        try:
            self.connection = await aio_pika.connect_robust(self.rabbitmq_url)
            self.channel = await self.connection.channel()
            
            # Declare exchange
            self.exchange = await self.channel.declare_exchange(
                self.exchange_name,
                aio_pika.ExchangeType.TOPIC,
                durable=True
            )
            
            self._initialized = True
            logger.info("Payment event publisher initialized")
            
        except Exception as e:
            logger.error(f"Failed to initialize event publisher: {e}")
            self._initialized = False

    async def publish_payment_success_event(self, transaction_data: Dict[str, Any]):
        """Publish payment success event"""
        if not self._initialized:
            await self.initialize()
        
        if not self._initialized:
            logger.error("Cannot publish event - publisher not initialized")
            return
        
        event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "payment.success",
            "timestamp": datetime.utcnow().isoformat(),
            "booking_id": transaction_data.get("booking_id"),
            "transaction_id": transaction_data.get("transaction_id"),
            "amount": transaction_data.get("amount"),
            "payment_method": transaction_data.get("payment_method"),
            "user_id": transaction_data.get("user_id"),  # Would come from booking context
            "gateway_response": transaction_data.get("gateway_response", {})
        }
        
        await self._publish_event("payment.success", event)

    async def publish_payment_failure_event(self, transaction_data: Dict[str, Any]):
        """Publish payment failure event"""
        if not self._initialized:
            await self.initialize()
        
        if not self._initialized:
            logger.error("Cannot publish event - publisher not initialized")
            return
        
        event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "payment.failed",
            "timestamp": datetime.utcnow().isoformat(),
            "booking_id": transaction_data.get("booking_id"),
            "transaction_id": transaction_data.get("transaction_id"),
            "amount": transaction_data.get("amount"),
            "payment_method": transaction_data.get("payment_method"),
            "user_id": transaction_data.get("user_id"),
            "failure_reason": transaction_data.get("failure_reason"),
            "gateway_response": transaction_data.get("gateway_response", {})
        }
        
        await self._publish_event("payment.failed", event)

    async def publish_refund_processed_event(self, refund_data: Dict[str, Any]):
        """Publish refund processed event"""
        if not self._initialized:
            await self.initialize()
        
        if not self._initialized:
            logger.error("Cannot publish event - publisher not initialized")
            return
        
        event = {
            "event_id": str(uuid.uuid4()),
            "event_type": "payment.refunded",
            "timestamp": datetime.utcnow().isoformat(),
            "booking_id": refund_data.get("booking_id"),
            "original_transaction_id": refund_data.get("original_transaction_id"),
            "refund_transaction_id": refund_data.get("refund_transaction_id"),
            "refund_amount": refund_data.get("refund_amount"),
            "user_id": refund_data.get("user_id"),
            "reason": refund_data.get("reason")
        }
        
        await self._publish_event("payment.refunded", event)

    async def _publish_event(self, routing_key: str, event_data: Dict[str, Any]):
        """Internal method to publish events to RabbitMQ"""
        try:
            message = aio_pika.Message(
                json.dumps(event_data).encode(),
                content_type="application/json",
                delivery_mode=aio_pika.DeliveryMode.PERSISTENT
            )
            
            await self.exchange.publish(message, routing_key=routing_key)
            logger.info(f"Published event: {routing_key} - {event_data['event_id']}")
            
        except Exception as e:
            logger.error(f"Failed to publish event {routing_key}: {e}")

    async def close(self):
        """Close RabbitMQ connection"""
        if self.connection and not self.connection.is_closed:
            await self.connection.close()
            logger.info("Payment event publisher connection closed")


# Global instance
payment_event_publisher = PaymentEventPublisher()


async def publish_payment_event(event_type: str, transaction_data: Dict[str, Any]):
    """Helper function to publish payment events"""
    try:
        if event_type == "payment.success":
            await payment_event_publisher.publish_payment_success_event(transaction_data)
        elif event_type == "payment.failed":
            await payment_event_publisher.publish_payment_failure_event(transaction_data)
        elif event_type == "payment.refunded":
            await payment_event_publisher.publish_refund_processed_event(transaction_data)
        else:
            logger.warning(f"Unknown event type: {event_type}")
    except Exception as e:
        logger.error(f"Error publishing payment event: {e}")


# Cleanup function for FastAPI shutdown
async def cleanup_event_publisher():
    """Cleanup function to be called on app shutdown"""
    await payment_event_publisher.close()