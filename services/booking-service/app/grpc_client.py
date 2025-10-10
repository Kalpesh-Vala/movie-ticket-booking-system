"""
gRPC Client for Cinema Service Communication
This demonstrates high-performance gRPC communication for critical operations
"""

import os
import grpc
from datetime import datetime
from typing import Optional

from .models import ShowtimeDetails, LockSeatResponse, ConfirmBookingResponse


class CinemaServiceClient:
    """
    gRPC client for communicating with cinema service
    Used for high-performance operations like seat locking
    """
    
    def __init__(self):
        self.channel = None
        self.stub = None
        self.cinema_service_url = os.getenv("CINEMA_SERVICE_GRPC_URL", "localhost:9090")
    
    async def _get_stub(self):
        """Get gRPC stub with connection management"""
        if self.channel is None:
            self.channel = grpc.aio.insecure_channel(self.cinema_service_url)
            # Import will be available after protobuf generation
            # from .grpc_generated import cinema_pb2_grpc
            # self.stub = cinema_pb2_grpc.CinemaServiceStub(self.channel)
        return self.stub
    
    async def get_showtime_details(self, showtime_id: str) -> Optional[ShowtimeDetails]:
        """
        Get showtime details via gRPC
        This is a placeholder - actual implementation requires protobuf generation
        """
        try:
            # Placeholder implementation
            # In real implementation, this would use:
            # stub = await self._get_stub()
            # request = cinema_pb2.GetShowtimeRequest(showtime_id=showtime_id)
            # response = await stub.GetShowtime(request)
            
            # For demo purposes, return mock data
            return ShowtimeDetails(
                showtime_id=showtime_id,
                movie_id="movie_123",
                cinema_id="cinema_456",
                screen_id="screen_789",
                start_time=datetime.now(),
                end_time=datetime.now(),
                base_price=15.99,
                available_seats=["A1", "A2", "A3", "B1", "B2"]
            )
            
        except grpc.RpcError as e:
            print(f"gRPC error getting showtime details: {e}")
            return None
        except Exception as e:
            print(f"Error getting showtime details: {e}")
            return None
    
    async def lock_seats(
        self, 
        showtime_id: str, 
        seat_numbers: list, 
        booking_id: str, 
        lock_duration_seconds: int
    ) -> LockSeatResponse:
        """
        Lock seats via gRPC - CRITICAL OPERATION
        This ensures atomicity of seat reservations
        """
        try:
            # Placeholder implementation
            # In real implementation:
            # stub = await self._get_stub()
            # request = cinema_pb2.LockSeatsRequest(
            #     showtime_id=showtime_id,
            #     seat_numbers=seat_numbers,
            #     booking_id=booking_id,
            #     lock_duration_seconds=lock_duration_seconds
            # )
            # response = await stub.LockSeats(request)
            
            # Mock successful response
            return LockSeatResponse(
                success=True,
                lock_id=f"lock_{booking_id}",
                expires_at=datetime.utcnow(),
                message="Seats locked successfully"
            )
            
        except grpc.RpcError as e:
            print(f"gRPC error locking seats: {e}")
            return LockSeatResponse(
                success=False,
                message=f"gRPC error: {e.details()}"
            )
        except Exception as e:
            print(f"Error locking seats: {e}")
            return LockSeatResponse(
                success=False,
                message=f"Error: {str(e)}"
            )
    
    async def confirm_seat_booking(
        self, 
        lock_id: str, 
        booking_id: str, 
        user_id: str
    ) -> ConfirmBookingResponse:
        """
        Confirm seat booking via gRPC
        Converts temporary lock to permanent booking
        """
        try:
            # Placeholder implementation
            # In real implementation:
            # stub = await self._get_stub()
            # request = cinema_pb2.ConfirmBookingRequest(
            #     lock_id=lock_id,
            #     booking_id=booking_id,
            #     user_id=user_id
            # )
            # response = await stub.ConfirmBooking(request)
            
            # Mock successful response
            return ConfirmBookingResponse(
                success=True,
                message="Booking confirmed successfully"
            )
            
        except grpc.RpcError as e:
            print(f"gRPC error confirming booking: {e}")
            return ConfirmBookingResponse(
                success=False,
                message=f"gRPC error: {e.details()}"
            )
        except Exception as e:
            print(f"Error confirming booking: {e}")
            return ConfirmBookingResponse(
                success=False,
                message=f"Error: {str(e)}"
            )
    
    async def release_seat_lock(self, lock_id: str) -> bool:
        """
        Release seat lock via gRPC
        Used when booking is cancelled or expired
        """
        try:
            # Placeholder implementation
            return True
            
        except Exception as e:
            print(f"Error releasing seat lock: {e}")
            return False
    
    async def close(self):
        """Close gRPC connection"""
        if self.channel:
            await self.channel.close()