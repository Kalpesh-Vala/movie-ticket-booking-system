#!/bin/bash

# gRPC Cinema Service Testing Script

echoecho -e "\n${YELLOW}Listing available services...${NC}"
grpcurl -plaintext $GRPC_HOST list

echo -e "\n${YELLOW}Listing methods for cinema.CinemaService...${NC}"
grpcurl -plaintext $GRPC_HOST list cinema.CinemaService======================================="
echo "Cinema Service gRPC Endpoint Testing"
echo "=========================================="

GRPC_HOST="localhost:9090"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    echo -e "${RED}grpcurl is not installed. Installing...${NC}"
    echo "Please install grpcurl manually:"
    echo "  - On Ubuntu/Debian: sudo apt-get install grpcurl"
    echo "  - On macOS: brew install grpcurl"
    echo "  - Or download from: https://github.com/fullstorydev/grpcurl"
    exit 1
fi

# Function to test a gRPC method
test_grpc_method() {
    local service=$1
    local method=$2
    local description=$3
    local data=$4
    
    echo -e "\n${BLUE}Testing: $description${NC}"
    echo -e "${YELLOW}$service/$method${NC}"
    
    if [ -n "$data" ]; then
        echo "Request data: $data"
        response=$(grpcurl -plaintext -d "$data" $GRPC_HOST $service/$method 2>&1)
    else
        response=$(grpcurl -plaintext $GRPC_HOST $service/$method 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Success${NC}"
        echo "$response"
    else
        echo -e "${RED}✗ Failed${NC}"
        echo "$response"
    fi
}

# Test gRPC server reflection (list services)
echo -e "\n${BLUE}=== GRPC SERVER REFLECTION ===${NC}"
echo -e "${YELLOW}Listing available services...${NC}"
grpcurl -plaintext $GRPC_HOST list

echo -e "\n${YELLOW}Listing methods for CinemaService...${NC}"
grpcurl -plaintext $GRPC_HOST list CinemaService

# 1. Cinema Service Methods
echo -e "\n${BLUE}=== CINEMA SERVICE METHODS ===${NC}"

# Get seat availability
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" "Check Seat Availability" '{"showtime_id": "showtime-1", "seat_numbers": ["A01", "A02"]}'

# Lock seats
test_grpc_method "cinema.CinemaService" "LockSeats" "Lock Seats" '{
    "showtime_id": "showtime-1",
    "seat_numbers": ["A01", "A02"],
    "booking_id": "test-booking-123",
    "lock_duration_seconds": 300
}'

# Get showtime details
test_grpc_method "cinema.CinemaService" "GetShowtimeDetails" "Get Showtime Details" '{"showtime_id": "showtime-1"}'

# Release seat lock
test_grpc_method "cinema.CinemaService" "ReleaseSeatLock" "Release Seat Lock" '{
    "lock_id": "test-lock-id",
    "booking_id": "test-booking-123"
}'

# Confirm seat booking
test_grpc_method "cinema.CinemaService" "ConfirmSeatBooking" "Confirm Seat Booking" '{
    "lock_id": "test-lock-id",
    "booking_id": "test-booking-123",
    "user_id": "test-user-123"
}'

# Test error cases
echo -e "\n${BLUE}=== ERROR HANDLING ===${NC}"

# Non-existent showtime
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" "Non-existent Showtime" '{"showtime_id": "non-existent", "seat_numbers": ["A01"]}'

# Invalid seat numbers
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" "Invalid Seat Numbers" '{"showtime_id": "showtime-1", "seat_numbers": ["INVALID_SEAT"]}'

echo -e "\n${GREEN}=========================================="
echo "gRPC Testing Complete!"
echo "==========================================${NC}"