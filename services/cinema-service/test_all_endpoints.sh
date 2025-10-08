#!/bin/bash

# Cinema Service API Testing Script

echo "=========================================="
echo "Cinema Service API Endpoint Testing"
echo "=========================================="

BASE_URL="http://localhost:8002"
API_PREFIX="/api/v1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test an endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    
    echo -e "\n${BLUE}Testing: $description${NC}"
    echo -e "${YELLOW}$method $endpoint${NC}"
    
    if [ "$method" = "GET" ]; then
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" "$BASE_URL$endpoint")
    elif [ "$method" = "POST" ] && [ -n "$data" ]; then
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    elif [ "$method" = "PUT" ] && [ -n "$data" ]; then
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X PUT \
            -H "Content-Type: application/json" \
            -d "$data" \
            "$BASE_URL$endpoint")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X DELETE "$BASE_URL$endpoint")
    fi
    
    http_status=$(echo "$response" | grep "HTTP_STATUS" | cut -d: -f2)
    body=$(echo "$response" | grep -v "HTTP_STATUS")
    
    if [ "$http_status" -ge 200 ] && [ "$http_status" -lt 300 ]; then
        echo -e "${GREEN}✓ Success (Status: $http_status)${NC}"
        # Limit output to first 500 characters to avoid circular reference issues
        echo "$body" | head -c 500
        if [ ${#body} -gt 500 ]; then
            echo "... (response truncated)"
        fi
    else
        echo -e "${RED}✗ Failed (Status: $http_status)${NC}"
        echo "$body"
    fi
}

# 1. Health Check
test_endpoint "GET" "/actuator/health" "Health Check"

# 2. Cinema Endpoints
echo -e "\n${BLUE}=== CINEMA ENDPOINTS ===${NC}"

# Get all cinemas (with limit to avoid circular reference issues)
test_endpoint "GET" "$API_PREFIX/cinemas?size=2" "Get All Cinemas (Limited)"

# Get cinema by ID
test_endpoint "GET" "$API_PREFIX/cinemas/cinema-1" "Get Cinema by ID"

# Get screens for a cinema
test_endpoint "GET" "$API_PREFIX/cinemas/cinema-1/screens" "Get Screens for Cinema"

# 3. Movie Endpoints
echo -e "\n${BLUE}=== MOVIE ENDPOINTS ===${NC}"

# Get all movies
test_endpoint "GET" "$API_PREFIX/movies" "Get All Movies"

# Get movie by ID
test_endpoint "GET" "$API_PREFIX/movies/movie-1" "Get Movie by ID"

# 4. Screen Endpoints
echo -e "\n${BLUE}=== SCREEN ENDPOINTS ===${NC}"

# Get screen by ID
test_endpoint "GET" "$API_PREFIX/screens/screen-1" "Get Screen by ID"

# Get showtimes for a screen
test_endpoint "GET" "$API_PREFIX/screens/screen-1/showtimes" "Get Showtimes for Screen"

# 5. Showtime Endpoints
echo -e "\n${BLUE}=== SHOWTIME ENDPOINTS ===${NC}"

# Get all showtimes
test_endpoint "GET" "$API_PREFIX/showtimes" "Get All Showtimes"

# Get showtime by ID
test_endpoint "GET" "$API_PREFIX/showtimes/showtime-1" "Get Showtime by ID"

# Get seats for a showtime
test_endpoint "GET" "$API_PREFIX/showtimes/showtime-1/seats" "Get Seats for Showtime"

# Get available seats for a showtime
test_endpoint "GET" "$API_PREFIX/showtimes/showtime-1/seats/available" "Get Available Seats"

# 6. Seat Locking Endpoints
echo -e "\n${BLUE}=== SEAT LOCKING ENDPOINTS ===${NC}"

# Lock a seat
lock_data='["A1", "A2"]'
test_endpoint "POST" "$API_PREFIX/showtimes/showtime-1/seats/lock" "Lock Seats" "$lock_data"

# Check locked seats status
test_endpoint "GET" "$API_PREFIX/showtimes/showtime-1/seats?status=LOCKED" "Get Locked Seats"

# Release seats (unlock)
release_data='["A1", "A2"]'
test_endpoint "POST" "$API_PREFIX/showtimes/showtime-1/seats/release" "Release Seats" "$release_data"

# 7. Search Endpoints
echo -e "\n${BLUE}=== SEARCH ENDPOINTS ===${NC}"

# Search movies by title
test_endpoint "GET" "$API_PREFIX/movies/search?title=Avengers" "Search Movies by Title"

# Search showtimes by movie and date
test_endpoint "GET" "$API_PREFIX/showtimes/search?movieId=movie-1&date=2025-01-15" "Search Showtimes"

# 8. Test Error Handling
echo -e "\n${BLUE}=== ERROR HANDLING ===${NC}"

# Non-existent cinema
test_endpoint "GET" "$API_PREFIX/cinemas/non-existent" "Non-existent Cinema"

# Non-existent movie
test_endpoint "GET" "$API_PREFIX/movies/non-existent" "Non-existent Movie"

# Invalid seat lock request
invalid_data='["INVALID_SEAT"]'
test_endpoint "POST" "$API_PREFIX/showtimes/showtime-1/seats/lock" "Invalid Seat Lock" "$invalid_data"

echo -e "\n${GREEN}=========================================="
echo "Testing Complete!"
echo "==========================================${NC}"