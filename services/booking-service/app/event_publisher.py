"""
Event Publisher for RabbitMQ
This demonstrates asynchronous event-driven communication using aio-pika
"""

import json
import os
import asyncio
from datetime import datetime, timezone
from typing import Dict, Any, Optional, List
import aio_pika
from aio_pika import connect_robust, Message, DeliveryMode
import logging

# Setup logging
logger = logging.getLogger(__name__)


class EventPublisher:
    """
    RabbitMQ event publisher for booking events using aio-pika
    Enables decoupled, asynchronous communication between services
    """
    
    def __init__(self):
        self.connection: Optional[aio_pika.Connection] = None
        self.channel: Optional[aio_pika.Channel] = None
        self.exchange: Optional[aio_pika.Exchange] = None
        self.exchange_name = os.getenv("RABBITMQ_EXCHANGE", "movie_app_events")
        self.rabbitmq_url = os.getenv(
            "RABBITMQ_URL", 
            "amqp://admin:admin123@localhost:5672/"
        )
    
    async def connect(self):
        """Establish connection to RabbitMQ"""
        try:
            # Create connection
            self.connection = await connect_robust(self.rabbitmq_url)
            
            # Create channel
            self.channel = await self.connection.channel()
            
            # Declare exchange (it should already exist from RabbitMQ config)
            self.exchange = await self.channel.declare_exchange(
                self.exchange_name,
                aio_pika.ExchangeType.TOPIC,
                durable=True
            )
            
            print(f"✅ Connected to RabbitMQ at {self.rabbitmq_url}")
            logger.info(f"Connected to RabbitMQ at {self.rabbitmq_url}")
            
        except Exception as e:
            print(f"❌ Failed to connect to RabbitMQ: {e}")
            logger.error(f"Failed to connect to RabbitMQ: {e}")
            raise e
    
    async def publish_booking_event(
        self, 
        event_type: str, 
        booking_id: str,
        user_email: str,
        user_id: str,
        movie_title: str,
        showtime: str,
        seats: List[str],
        total_amount: float,
        cinema_name: Optional[str] = None,
        **event_data
    ):
        """
        Publish booking event to RabbitMQ in the format expected by notification service
        
        Args:
            event_type: Type of event (e.g., 'booking.confirmed', 'booking.cancelled')
            booking_id: ID of the booking
            user_email: User's email address for notifications
            user_id: ID of the user
            movie_title: Title of the movie
            showtime: Showtime information
            seats: List of seat numbers
            total_amount: Total booking amount
            cinema_name: Name of the cinema
            **event_data: Additional event data
        """
        if not self.channel or self.channel.is_closed:
            print("❌ RabbitMQ channel not available")
            logger.warning("RabbitMQ channel not available")
            return False
        
        try:
            # Prepare event payload in the format expected by notification service
            event_payload = {
                "event_id": f"evt_booking_{booking_id}_{int(datetime.now(timezone.utc).timestamp())}",
                "event_type": event_type,
                "user_email": user_email,
                "user_id": user_id,
                "booking_id": booking_id,
                "movie_title": movie_title,
                "showtime": showtime,
                "seats": seats,
                "total_amount": total_amount,
                "cinema_name": cinema_name,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                **event_data
            }
            
            # Create message
            message = Message(
                json.dumps(event_payload).encode(),
                delivery_mode=DeliveryMode.PERSISTENT,
                content_type='application/json',
                timestamp=datetime.now(timezone.utc)
            )
            
            # Publish event using the event type as routing key
            await self.exchange.publish(
                message,
                routing_key=event_type
            )
            
            print(f"✅ Published event: {event_type} for booking {booking_id}")
            logger.info(f"Published event: {event_type} for booking {booking_id}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to publish event {event_type}: {e}")
            logger.error(f"Failed to publish event {event_type}: {e}")
            return False
    
    async def close(self):
        """Close RabbitMQ connection"""
        if self.connection and not self.connection.is_closed:
            await self.connection.close()
            print("✅ Disconnected from RabbitMQ")
            logger.info("Disconnected from RabbitMQ")


# Event types that can be published to match notification service expectations:
"""
BOOKING EVENTS (routing keys):
- booking.confirmed: When payment is successful and booking is confirmed
- booking.cancelled: When booking is cancelled by user or system
- booking.refunded: When refund is successfully processed

PAYMENT EVENTS (published by payment service, consumed by notification service):
- payment.success: When payment is successful
- payment.failed: When payment fails
- payment.refund: When refund is completed
"""