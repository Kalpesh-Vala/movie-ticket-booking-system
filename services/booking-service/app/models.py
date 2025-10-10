"""
Booking Service Data Models
"""

import uuid
from datetime import datetime, timezone
from enum import Enum
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class BookingStatus(str, Enum):
    PENDING_PAYMENT = "pending_payment"
    CONFIRMED = "confirmed"
    CANCELLED = "cancelled"
    REFUND_PENDING = "refund_pending"
    REFUNDED = "refunded"


class SeatInfo(BaseModel):
    row: str
    number: int
    category: str = "standard"  # standard, premium, vip


class Booking(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    user_id: str
    showtime_id: str
    seats: List[str]
    total_amount: float
    status: BookingStatus
    lock_id: Optional[str] = None
    lock_expires_at: Optional[datetime] = None
    payment_transaction_id: Optional[str] = None
    confirmed_at: Optional[datetime] = None
    cancellation_reason: Optional[str] = None
    refund_reason: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for MongoDB insertion"""
        data = self.dict()
        data["_id"] = self.id
        data["status"] = self.status.value
        return data


class ShowtimeDetails(BaseModel):
    """Model for showtime details from cinema service"""
    showtime_id: str
    movie_id: str
    cinema_id: str
    screen_id: str
    start_time: datetime
    end_time: datetime
    base_price: float
    available_seats: List[str]
    movie_title: Optional[str] = "Unknown Movie"
    cinema_name: Optional[str] = "Unknown Cinema"


class User(BaseModel):
    """Model for user details from user service"""
    id: str
    email: str
    first_name: str
    last_name: str
    phone: Optional[str] = None
    
    @property
    def full_name(self) -> str:
        """Get full name from first and last name"""
        return f"{self.first_name} {self.last_name}".strip()


class PaymentRequest(BaseModel):
    """Model for payment processing"""
    booking_id: str
    amount: float
    payment_method: str
    payment_details: str


class PaymentResponse(BaseModel):
    """Model for payment response"""
    success: bool
    transaction_id: Optional[str] = None
    message: str


class LockSeatRequest(BaseModel):
    """Model for seat locking request"""
    showtime_id: str
    seat_numbers: List[str]
    booking_id: str
    lock_duration_seconds: int


class LockSeatResponse(BaseModel):
    """Model for seat locking response"""
    success: bool
    lock_id: Optional[str] = None
    expires_at: Optional[datetime] = None
    message: str


class ConfirmBookingRequest(BaseModel):
    """Model for booking confirmation request"""
    lock_id: str
    booking_id: str
    user_id: str


class ConfirmBookingResponse(BaseModel):
    """Model for booking confirmation response"""
    success: bool
    message: str