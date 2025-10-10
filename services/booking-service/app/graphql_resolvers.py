"""
Booking Service GraphQL Resolvers
Critical orchestration logic for the booking workflow
"""

import asyncio
import uuid
from datetime import datetime
from typing import List, Optional

import strawberry
from strawberry.types import Info

from .models import Booking, BookingStatus, SeatInfo
from .grpc_client import CinemaServiceClient
from .rest_client import UserServiceClient, PaymentServiceClient
from .event_publisher import EventPublisher
from .database import get_database


@strawberry.type
class BookingType:
    id: str
    user_id: str
    showtime_id: str
    seats: List[str]
    total_amount: float
    status: str
    created_at: datetime
    updated_at: datetime


@strawberry.type
class CreateBookingResponse:
    success: bool
    booking: Optional[BookingType]
    message: str
    lock_id: Optional[str]


@strawberry.type
class Query:
    @strawberry.field
    async def get_booking(self, booking_id: str) -> Optional[BookingType]:
        """Get booking by ID"""
        db = await get_database()
        booking_doc = await db.bookings.find_one({"_id": booking_id})
        
        if not booking_doc:
            return None
            
        return BookingType(
            id=booking_doc["_id"],
            user_id=booking_doc["user_id"],
            showtime_id=booking_doc["showtime_id"],
            seats=booking_doc["seats"],
            total_amount=booking_doc["total_amount"],
            status=booking_doc["status"],
            created_at=booking_doc["created_at"],
            updated_at=booking_doc["updated_at"]
        )

    @strawberry.field
    async def get_user_bookings(self, user_id: str) -> List[BookingType]:
        """Get all bookings for a user"""
        db = await get_database()
        bookings_cursor = db.bookings.find({"user_id": user_id})
        bookings_cursor = bookings_cursor.sort("created_at", -1)
        bookings = await bookings_cursor.to_list(length=100)
        
        return [
            BookingType(
                id=booking["_id"],
                user_id=booking["user_id"],
                showtime_id=booking["showtime_id"],
                seats=booking["seats"],
                total_amount=booking["total_amount"],
                status=booking["status"],
                created_at=booking["created_at"],
                updated_at=booking["updated_at"]
            )
            for booking in bookings
        ]


@strawberry.type
class Mutation:
    @strawberry.field
    async def create_booking(
        self, 
        user_id: str, 
        showtime_id: str, 
        seat_numbers: List[str]
    ) -> CreateBookingResponse:
        """
        CRITICAL FUNCTION: Create booking with orchestration
        This function demonstrates the complete booking workflow:
        1. Validate user via REST call
        2. Lock seats via gRPC call  
        3. Create booking record
        4. Publish event to RabbitMQ
        """
        
        try:
            # Step 1: Validate user exists via REST API call to user-service
            user_client = UserServiceClient()
            user = await user_client.get_user(user_id)
            if not user:
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message="User not found",
                    lock_id=None
                )

            # Step 2: Get showtime details and calculate total amount via gRPC
            cinema_client = CinemaServiceClient()
            showtime_details = await cinema_client.get_showtime_details(showtime_id)
            if not showtime_details:
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message="Showtime not found",
                    lock_id=None
                )

            # Calculate total amount
            total_amount = len(seat_numbers) * showtime_details.base_price

            # Step 3: CRITICAL gRPC CALL - Lock seats in cinema-service
            # This uses high-performance gRPC for the critical seat locking operation
            booking_id = str(uuid.uuid4())
            lock_duration = 300  # 5 minutes
            
            lock_result = await cinema_client.lock_seats(
                showtime_id=showtime_id,
                seat_numbers=seat_numbers,
                booking_id=booking_id,
                lock_duration_seconds=lock_duration
            )

            if not lock_result.success:
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message=f"Failed to lock seats: {lock_result.message}",
                    lock_id=None
                )

            # Step 4: Create booking record in MongoDB
            now = datetime.utcnow()
            booking = Booking(
                id=booking_id,
                user_id=user_id,
                showtime_id=showtime_id,
                seats=seat_numbers,
                total_amount=total_amount,
                status=BookingStatus.PENDING_PAYMENT,
                lock_id=lock_result.lock_id,
                lock_expires_at=lock_result.expires_at,
                created_at=now,
                updated_at=now
            )

            # Save to database
            db = await get_database()
            await db.bookings.insert_one(booking.to_dict())

            # Step 5: PUBLISH EVENT to RabbitMQ for asynchronous processing
            # This decouples the booking service from downstream processing
            event_publisher = EventPublisher()
            await event_publisher.publish_booking_event(
                event_type="booking.pending_payment",
                booking_id=booking_id,
                user_id=user_id,
                showtime_id=showtime_id,
                seats=seat_numbers,
                total_amount=total_amount,
                lock_id=lock_result.lock_id
            )

            return CreateBookingResponse(
                success=True,
                booking=BookingType(
                    id=booking.id,
                    user_id=booking.user_id,
                    showtime_id=booking.showtime_id,
                    seats=booking.seats,
                    total_amount=booking.total_amount,
                    status=booking.status.value,
                    created_at=booking.created_at,
                    updated_at=booking.updated_at
                ),
                message="Booking created successfully. Please complete payment within 5 minutes.",
                lock_id=lock_result.lock_id
            )

        except Exception as e:
            # Log error and return failure response
            print(f"Error creating booking: {str(e)}")
            return CreateBookingResponse(
                success=False,
                booking=None,
                message=f"Internal error: {str(e)}",
                lock_id=None
            )

    @strawberry.field
    async def process_payment(
        self, 
        booking_id: str, 
        payment_method: str = "credit_card",
        card_details: Optional[str] = None
    ) -> CreateBookingResponse:
        """
        Process payment for a booking
        This demonstrates the payment workflow orchestration with full service integration
        """
        try:
            # Get booking
            db = await get_database()
            booking_doc = await db.bookings.find_one({"_id": booking_id})
            
            if not booking_doc:
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message="Booking not found",
                    lock_id=None
                )

            if booking_doc["status"] != BookingStatus.PENDING_PAYMENT.value:
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message="Booking is not in pending payment status",
                    lock_id=None
                )

            # Check if seat lock is still valid
            lock_expires_at = booking_doc.get("lock_expires_at")
            if lock_expires_at and lock_expires_at < datetime.utcnow():
                # Lock expired, cancel booking
                await db.bookings.update_one(
                    {"_id": booking_id},
                    {
                        "$set": {
                            "status": BookingStatus.CANCELLED.value,
                            "updated_at": datetime.utcnow(),
                            "cancellation_reason": "Payment timeout"
                        }
                    }
                )
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message="Booking expired. Seats are no longer reserved.",
                    lock_id=None
                )

            # Get user details for payment processing and notifications
            user_client = UserServiceClient()
            user = await user_client.get_user(booking_doc["user_id"])
            if not user:
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message="User not found",
                    lock_id=None
                )

            # Get showtime details for notifications
            cinema_client = CinemaServiceClient()
            showtime_details = await cinema_client.get_showtime_details(booking_doc["showtime_id"])

            # Process payment via REST API call to payment-service
            payment_client = PaymentServiceClient()
            payment_result = await payment_client.process_payment(
                user_id=booking_doc["user_id"],
                booking_id=booking_id,
                amount=booking_doc["total_amount"],
                payment_method=payment_method,
                card_details=None  # Using default test card details
            )

            if not payment_result["success"]:
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message=f"Payment failed: {payment_result['message']}",
                    lock_id=None
                )

            # Confirm seat booking via gRPC
            confirm_result = await cinema_client.confirm_seat_booking(
                lock_id=booking_doc["lock_id"],
                booking_id=booking_id,
                user_id=booking_doc["user_id"]
            )

            if not confirm_result.success:
                # Payment succeeded but seat confirmation failed
                # This should trigger a refund process
                await self._handle_payment_seat_confirmation_failure(
                    booking_id, payment_result["transaction_id"], user.email
                )
                return CreateBookingResponse(
                    success=False,
                    booking=None,
                    message="Payment processed but seat confirmation failed. Refund initiated.",
                    lock_id=None
                )

            # Update booking status to confirmed
            updated_booking = await db.bookings.find_one_and_update(
                {"_id": booking_id},
                {
                    "$set": {
                        "status": BookingStatus.CONFIRMED.value,
                        "payment_transaction_id": payment_result["transaction_id"],
                        "confirmed_at": datetime.utcnow(),
                        "updated_at": datetime.utcnow()
                    }
                },
                return_document=True
            )

            # Publish booking confirmed event with all details for notification service
            event_publisher = EventPublisher()
            await event_publisher.publish_booking_event(
                event_type="booking.confirmed",
                booking_id=booking_id,
                user_email=user.email,
                user_id=booking_doc["user_id"],
                movie_title=showtime_details.movie_title if showtime_details else "Unknown Movie",
                showtime=showtime_details.start_time.strftime("%Y-%m-%d %I:%M %p") if showtime_details else "Unknown Time",
                seats=booking_doc["seats"],
                total_amount=booking_doc["total_amount"],
                cinema_name=showtime_details.cinema_name if showtime_details else "Unknown Cinema",
                transaction_id=payment_result["transaction_id"]
            )

            return CreateBookingResponse(
                success=True,
                booking=BookingType(
                    id=updated_booking["_id"],
                    user_id=updated_booking["user_id"],
                    showtime_id=updated_booking["showtime_id"],
                    seats=updated_booking["seats"],
                    total_amount=updated_booking["total_amount"],
                    status=updated_booking["status"],
                    created_at=updated_booking["created_at"],
                    updated_at=updated_booking["updated_at"]
                ),
                message="Booking confirmed successfully! Check your email for confirmation details.",
                lock_id=None
            )

        except Exception as e:
            print(f"Error processing payment: {str(e)}")
            return CreateBookingResponse(
                success=False,
                booking=None,
                message=f"Payment processing failed: {str(e)}",
                lock_id=None
            )

    async def _handle_payment_seat_confirmation_failure(self, booking_id: str, transaction_id: str, user_email: str):
        """Handle the edge case where payment succeeds but seat confirmation fails"""
        # This should trigger a refund process and proper error handling
        db = await get_database()
        await db.bookings.update_one(
            {"_id": booking_id},
            {
                "$set": {
                    "status": BookingStatus.REFUND_PENDING.value,
                    "updated_at": datetime.utcnow(),
                    "refund_reason": "Seat confirmation failed after payment"
                }
            }
        )

        # Publish refund event for notification service
        event_publisher = EventPublisher()
        await event_publisher.publish_booking_event(
            event_type="booking.refunded",
            booking_id=booking_id,
            user_email=user_email,
            user_id="",  # Will be filled from booking record if needed
            movie_title="",  # Will be filled from showtime details if needed
            showtime="",
            seats=[],
            total_amount=0.0,
            transaction_id=transaction_id,
            refund_reason="Seat confirmation failed after payment"
        )


# Create the GraphQL schema
schema = strawberry.Schema(query=Query, mutation=Mutation)