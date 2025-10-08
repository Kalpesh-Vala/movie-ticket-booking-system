#!/bin/bash

# gRPC Cinema Service Testing Script

echo "=========================================="
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

# Get all cinemas
test_grpc_method "CinemaService" "GetAllCinemas" "Get All Cinemas" '{}'

# Get cinema by ID
test_grpc_method "CinemaService" "GetCinemaById" "Get Cinema by ID" '{"id": "cinema-1"}'

# Get screens by cinema ID
test_grpc_method "CinemaService" "GetScreensByCinemaId" "Get Screens by Cinema ID" '{"cinemaId": "cinema-1"}'

# Get all movies
test_grpc_method "CinemaService" "GetAllMovies" "Get All Movies" '{}'

# Get movie by ID
test_grpc_method "CinemaService" "GetMovieById" "Get Movie by ID" '{"id": "movie-1"}'

# Get showtimes by screen ID
test_grpc_method "CinemaService" "GetShowtimesByScreenId" "Get Showtimes by Screen ID" '{"screenId": "screen-1"}'

# Get seats by showtime ID
test_grpc_method "CinemaService" "GetSeatsByShowtimeId" "Get Seats by Showtime ID" '{"showtimeId": "showtime-1"}'

# Get available seats
test_grpc_method "CinemaService" "GetAvailableSeats" "Get Available Seats" '{"showtimeId": "showtime-1"}'

# Lock seats
test_grpc_method "CinemaService" "LockSeats" "Lock Seats" '{
    "showtimeId": "showtime-1",
    "seatNumbers": ["A1", "A2"],
    "userId": "test-user-123"
}'

# Check seat status
test_grpc_method "CinemaService" "GetSeatsByShowtimeId" "Check Seat Status After Lock" '{"showtimeId": "showtime-1"}'

# Release seats
test_grpc_method "CinemaService" "ReleaseSeats" "Release Seats" '{
    "showtimeId": "showtime-1",
    "seatNumbers": ["A1", "A2"]
}'

# Search movies
test_grpc_method "CinemaService" "SearchMovies" "Search Movies" '{"title": "Avengers"}'

# Search showtimes
test_grpc_method "CinemaService" "SearchShowtimes" "Search Showtimes" '{
    "movieId": "movie-1",
    "date": "2025-01-15"
}'

# Test error cases
echo -e "\n${BLUE}=== ERROR HANDLING ===${NC}"

# Non-existent cinema
test_grpc_method "CinemaService" "GetCinemaById" "Non-existent Cinema" '{"id": "non-existent"}'

# Non-existent movie
test_grpc_method "CinemaService" "GetMovieById" "Non-existent Movie" '{"id": "non-existent"}'

# Invalid seat lock
test_grpc_method "CinemaService" "LockSeats" "Invalid Seat Lock" '{
    "showtimeId": "showtime-1",
    "seatNumbers": ["INVALID_SEAT"],
    "userId": "test-user-123"
}'

echo -e "\n${GREEN}=========================================="
echo "gRPC Testing Complete!"
echo "==========================================${NC}"