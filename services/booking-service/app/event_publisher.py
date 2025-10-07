"""
Event Publisher for RabbitMQ
This demonstrates asynchronous event-driven communication
"""

import json
import os
import asyncio
from datetime import datetime, timezone
from typing import Dict, Any, Optional
import pika
from pika.adapters.asyncio_connection import AsyncioConnection
import logging

# Setup logging
logger = logging.getLogger(__name__)


class EventPublisher:
    """
    RabbitMQ event publisher for booking events
    Enables decoupled, asynchronous communication between services
    """
    
    def __init__(self):
        self.connection: Optional[AsyncioConnection] = None
        self.channel = None  # Will be set when channel is opened
        self.exchange_name = "booking_events"
        self.rabbitmq_url = os.getenv(
            "RABBITMQ_URL", 
            "amqp://admin:password@localhost:5672/"
        )
        self._connection_ready = asyncio.Event()
    
    async def connect(self):
        """Establish connection to RabbitMQ"""
        try:
            # Parse RabbitMQ URL
            parameters = pika.URLParameters(self.rabbitmq_url)
            
            # Create connection
            self.connection = AsyncioConnection(
                parameters,
                on_open_callback=self._on_connection_open,
                on_open_error_callback=self._on_connection_open_error,
                on_close_callback=self._on_connection_closed
            )
            
            # Wait for connection to be ready
            await self._connection_ready.wait()
            print("✅ Connected to RabbitMQ")
            
        except Exception as e:
            print(f"❌ Failed to connect to RabbitMQ: {e}")
            raise e
    
    def _on_connection_open(self, connection):
        """Callback when connection is opened"""
        print("RabbitMQ connection opened")
        connection.channel(on_open_callback=self._on_channel_open)
    
    def _on_connection_open_error(self, connection, error):
        """Callback when connection fails to open"""
        print(f"RabbitMQ connection failed: {error}")
        self._connection_ready.set()
    
    def _on_connection_closed(self, connection, reason):
        """Callback when connection is closed"""
        print(f"RabbitMQ connection closed: {reason}")
        self.connection = None
        self.channel = None
    
    def _on_channel_open(self, channel):
        """Callback when channel is opened"""
        print("RabbitMQ channel opened")
        logger.info("RabbitMQ channel opened")
        self.channel = channel
        
        # Declare exchange - check if channel is valid first
        if self.channel and hasattr(self.channel, 'exchange_declare'):
            self.channel.exchange_declare(
                exchange=self.exchange_name,
                exchange_type='topic',
                durable=True,
                callback=self._on_exchange_declared
            )
        else:
            logger.error("Channel is not properly initialized")
            self._connection_ready.set()
    
    def _on_exchange_declared(self, frame):
        """Callback when exchange is declared"""
        print(f"Exchange '{self.exchange_name}' declared")
        self._connection_ready.set()
    
    async def publish_booking_event(
        self, 
        event_type: str, 
        booking_id: str,
        **event_data
    ):
        """
        Publish booking event to RabbitMQ
        
        Args:
            event_type: Type of event (e.g., 'booking.created', 'booking.confirmed')
            booking_id: ID of the booking
            **event_data: Additional event data
        """
        if not self.channel or (hasattr(self.channel, 'is_closed') and self.channel.is_closed):
            print("❌ RabbitMQ channel not available")
            logger.warning("RabbitMQ channel not available")
            return False
        
        try:
            # Prepare event payload
            event_payload = {
                "event_type": event_type,
                "booking_id": booking_id,
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "service": "booking-service",
                **event_data
            }
            
            # Publish event
            routing_key = event_type  # Use event type as routing key
            
            self.channel.basic_publish(
                exchange=self.exchange_name,
                routing_key=routing_key,
                body=json.dumps(event_payload),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Make message persistent
                    content_type='application/json',
                    timestamp=int(datetime.now(timezone.utc).timestamp())
                )
            )
            
            print(f"✅ Published event: {event_type} for booking {booking_id}")
            return True
            
        except Exception as e:
            print(f"❌ Failed to publish event {event_type}: {e}")
            return False
    
    async def publish_payment_event(
        self, 
        event_type: str, 
        booking_id: str,
        transaction_id: Optional[str] = None,
        **event_data
    ):
        """Publish payment-related events"""
        payment_data = {
            "transaction_id": transaction_id,
            **event_data
        }
        
        return await self.publish_booking_event(
            event_type=event_type,
            booking_id=booking_id,
            **payment_data
        )
    
    async def publish_seat_event(
        self, 
        event_type: str, 
        booking_id: str,
        showtime_id: str,
        seats: list,
        **event_data
    ):
        """Publish seat-related events"""
        seat_data = {
            "showtime_id": showtime_id,
            "seats": seats,
            **event_data
        }
        
        return await self.publish_booking_event(
            event_type=event_type,
            booking_id=booking_id,
            **seat_data
        )
    
    async def close(self):
        """Close RabbitMQ connection"""
        if self.connection and hasattr(self.connection, 'is_closed') and not self.connection.is_closed:
            self.connection.close()
            print("✅ Disconnected from RabbitMQ")
            logger.info("Disconnected from RabbitMQ")


# Example event types that can be published:
"""
BOOKING EVENTS:
- booking.pending_payment: When booking is created and waiting for payment
- booking.confirmed: When payment is successful and booking is confirmed
- booking.cancelled: When booking is cancelled by user or system
- booking.expired: When booking expires due to payment timeout
- booking.refund_required: When refund is needed due to system issues
- booking.refunded: When refund is successfully processed

PAYMENT EVENTS:
- payment.initiated: When payment process starts
- payment.successful: When payment is successful
- payment.failed: When payment fails
- payment.refund_initiated: When refund process starts
- payment.refunded: When refund is completed

SEAT EVENTS:
- seats.locked: When seats are temporarily locked
- seats.confirmed: When seats are permanently booked
- seats.released: When seat locks are released
"""