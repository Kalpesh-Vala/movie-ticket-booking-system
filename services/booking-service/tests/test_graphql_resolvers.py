"""
Integration tests for GraphQL resolvers
"""

import pytest
from unittest.mock import AsyncMock, patch
from datetime import datetime, timezone

from app.graphql_resolvers import Query, Mutation
from app.models import User, ShowtimeDetails, LockSeatResponse, BookingStatus


class TestGraphQLResolverFunctions:
    """Test GraphQL resolver functions directly"""
    
    @pytest.mark.asyncio
    async def test_get_booking_success(self, mock_database):
        """Test successful booking retrieval"""
        # Mock database response
        booking_doc = {
            "_id": "booking_123",
            "user_id": "user_456",
            "showtime_id": "showtime_789",
            "seats": ["A1", "A2"],
            "total_amount": 31.98,
            "status": "pending_payment",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc)
        }
        mock_database.bookings.find_one.return_value = booking_doc
        
        query = Query()
        
        with patch('app.graphql_resolvers.get_database', return_value=mock_database):
            # Call the resolver function directly
            result = await query.get_booking.__wrapped__(query, "booking_123")
        
        assert result is not None
        assert result.id == "booking_123"
        assert result.user_id == "user_456"
        assert result.seats == ["A1", "A2"]
        assert result.status == "pending_payment"
    
    @pytest.mark.asyncio
    async def test_get_booking_not_found(self, mock_database):
        """Test booking not found"""
        mock_database.bookings.find_one.return_value = None
        
        query = Query()
        
        with patch('app.graphql_resolvers.get_database', return_value=mock_database):
            result = await query.get_booking.__wrapped__(query, "nonexistent_booking")
        
        assert result is None
    
    @pytest.mark.asyncio
    async def test_get_user_bookings(self, mock_database):
        """Test user bookings retrieval"""
        # Mock database response
        booking_docs = [
            {
                "_id": "booking_1",
                "user_id": "user_456",
                "showtime_id": "showtime_789",
                "seats": ["A1"],
                "total_amount": 15.99,
                "status": "confirmed",
                "created_at": datetime.now(timezone.utc),
                "updated_at": datetime.now(timezone.utc)
            },
            {
                "_id": "booking_2",
                "user_id": "user_456",
                "showtime_id": "showtime_790",
                "seats": ["B1", "B2"],
                "total_amount": 31.98,
                "status": "pending_payment",
                "created_at": datetime.now(timezone.utc),
                "updated_at": datetime.now(timezone.utc)
            }
        ]
        
        mock_cursor = AsyncMock()
        mock_cursor.sort.return_value = mock_cursor  # Chain sort call
        mock_cursor.to_list.return_value = booking_docs
        mock_database.bookings.find.return_value = mock_cursor
        
        query = Query()
        
        with patch('app.graphql_resolvers.get_database', return_value=mock_database):
            results = await query.get_user_bookings.__wrapped__(query, "user_456")
        
        assert len(results) == 2
        assert results[0].id == "booking_1"
        assert results[1].id == "booking_2"


class TestGraphQLMutationFunctions:
    """Test GraphQL mutation functions directly"""
    
    @pytest.mark.asyncio
    async def test_create_booking_success(
        self, 
        mock_database, 
        sample_booking_data,
        sample_user_data,
        sample_showtime_data
    ):
        """Test successful booking creation"""
        mutation = Mutation()
        
        # Mock successful responses
        mock_user = User(**sample_user_data)
        mock_showtime = ShowtimeDetails(**sample_showtime_data)
        mock_lock_response = LockSeatResponse(
            success=True,
            lock_id="lock_123",
            expires_at=datetime.now(timezone.utc),
            message="Seats locked successfully"
        )
        
        with patch('app.graphql_resolvers.UserServiceClient') as mock_user_client_class, \
             patch('app.graphql_resolvers.CinemaServiceClient') as mock_cinema_client_class, \
             patch('app.graphql_resolvers.EventPublisher') as mock_event_publisher_class, \
             patch('app.graphql_resolvers.get_database', return_value=mock_database):
            
            # Setup mocks
            mock_user_client = AsyncMock()
            mock_user_client.get_user.return_value = mock_user
            mock_user_client_class.return_value = mock_user_client
            
            mock_cinema_client = AsyncMock()
            mock_cinema_client.get_showtime_details.return_value = mock_showtime
            mock_cinema_client.lock_seats.return_value = mock_lock_response
            mock_cinema_client_class.return_value = mock_cinema_client
            
            mock_event_publisher = AsyncMock()
            mock_event_publisher_class.return_value = mock_event_publisher
            
            mock_database.bookings.insert_one.return_value = None
            
            # Execute mutation using __wrapped__ to access the actual function
            result = await mutation.create_booking.__wrapped__(
                mutation,
                user_id=sample_booking_data["user_id"],
                showtime_id=sample_booking_data["showtime_id"],
                seat_numbers=sample_booking_data["seat_numbers"]
            )
        
        assert result.success is True
        assert result.booking is not None
        assert result.booking.user_id == sample_booking_data["user_id"]
        assert result.booking.seats == sample_booking_data["seat_numbers"]
        assert result.lock_id == "lock_123"
        assert "successfully" in result.message
    
    @pytest.mark.asyncio
    async def test_create_booking_user_not_found(self, mock_database, sample_booking_data):
        """Test booking creation with invalid user"""
        mutation = Mutation()
        
        with patch('app.graphql_resolvers.UserServiceClient') as mock_user_client_class:
            mock_user_client = AsyncMock()
            mock_user_client.get_user.return_value = None  # User not found
            mock_user_client_class.return_value = mock_user_client
            
            result = await mutation.create_booking.__wrapped__(
                mutation,
                user_id=sample_booking_data["user_id"],
                showtime_id=sample_booking_data["showtime_id"],
                seat_numbers=sample_booking_data["seat_numbers"]
            )
        
        assert result.success is False
        assert result.booking is None
        assert "User not found" in result.message