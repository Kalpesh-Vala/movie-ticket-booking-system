#!/bin/bash

# Complete gRPC Cinema Service Testing Script
# Tests all available gRPC endpoints with real data

echo "=========================================="
echo "Cinema Service gRPC Complete Testing"
echo "=========================================="

GRPC_HOST="localhost:9090"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored status
print_status() {
    local status=$1
    local message=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $message"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC} - $message"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    elif [ "$status" = "INFO" ]; then
        echo -e "${BLUE}ℹ INFO${NC} - $message"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}⚠ WARN${NC} - $message"
    fi
}

# Function to test a gRPC method
test_grpc_method() {
    local service=$1
    local method=$2
    local description=$3
    local data=$4
    local expected_field=$5  # Optional: field to check for success
    
    echo -e "\n${CYAN}Testing: $description${NC}"
    echo -e "${YELLOW}Method: $service/$method${NC}"
    
    if [ -n "$data" ]; then
        echo -e "${PURPLE}Request:${NC} $data"
        response=$(grpcurl -plaintext -d "$data" $GRPC_HOST $service/$method 2>&1)
    else
        response=$(grpcurl -plaintext $GRPC_HOST $service/$method 2>&1)
    fi
    
    if [ $? -eq 0 ]; then
        # Check if response contains expected field (if provided)
        if [ -n "$expected_field" ]; then
            if echo "$response" | grep -q "$expected_field"; then
                print_status "PASS" "$description"
            else
                print_status "FAIL" "$description - Expected field '$expected_field' not found"
            fi
        else
            print_status "PASS" "$description"
        fi
        echo -e "${GREEN}Response:${NC} $response"
        return 0
    else
        print_status "FAIL" "$description"
        echo -e "${RED}Error:${NC} $response"
        return 1
    fi
}

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
    print_status "FAIL" "grpcurl is not installed"
    echo "Please install grpcurl:"
    echo "  - On Ubuntu/Debian: sudo apt-get install grpcurl"
    echo "  - On macOS: brew install grpcurl"
    echo "  - On Windows: Download from https://github.com/fullstorydev/grpcurl"
    exit 1
fi

print_status "PASS" "grpcurl is available"

# Test gRPC server connectivity
echo -e "\n${BLUE}=== GRPC SERVER CONNECTIVITY ===${NC}"
if grpcurl -plaintext $GRPC_HOST list >/dev/null 2>&1; then
    print_status "PASS" "gRPC server is accessible at $GRPC_HOST"
else
    print_status "FAIL" "Cannot connect to gRPC server at $GRPC_HOST"
    echo "Make sure the cinema service is running with gRPC enabled"
    exit 1
fi

# List available services
echo -e "\n${BLUE}=== GRPC SERVER REFLECTION ===${NC}"
echo -e "${YELLOW}Available services:${NC}"
services=$(grpcurl -plaintext $GRPC_HOST list 2>/dev/null)
echo "$services"

if echo "$services" | grep -q "cinema.CinemaService"; then
    print_status "PASS" "cinema.CinemaService is available"
else
    print_status "FAIL" "cinema.CinemaService not found"
    exit 1
fi

# List available methods
echo -e "\n${YELLOW}Available methods for cinema.CinemaService:${NC}"
methods=$(grpcurl -plaintext $GRPC_HOST list cinema.CinemaService 2>/dev/null)
echo "$methods"

# Test each gRPC method
echo -e "\n${BLUE}=== CINEMA SERVICE GRPC METHODS ===${NC}"

# 1. Check Seat Availability - Valid seats
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
    "Check seat availability for valid seats" \
    '{"showtime_id": "showtime-001", "seat_numbers": ["A7", "A8"]}' \
    '"available"'

# 2. Check Seat Availability - Mixed seats (some may be locked)
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
    "Check seat availability with mixed seats" \
    '{"showtime_id": "showtime-001", "seat_numbers": ["A1", "A2", "A7", "A8"]}' \
    '"message"'

# 3. Lock Seats - Available seats
echo -e "\n${CYAN}--- Seat Locking Workflow ---${NC}"
BOOKING_ID="grpc-test-$(date +%s)"
LOCK_ID=""

lock_response=$(grpcurl -plaintext -d "{
    \"showtime_id\": \"showtime-001\",
    \"seat_numbers\": [\"B5\", \"B6\"],
    \"booking_id\": \"$BOOKING_ID\",
    \"lock_duration_seconds\": 300
}" $GRPC_HOST cinema.CinemaService/LockSeats 2>&1)

if [ $? -eq 0 ] && echo "$lock_response" | grep -q '"success": true'; then
    print_status "PASS" "Lock seats B5, B6"
    echo -e "${GREEN}Response:${NC} $lock_response"
    
    # Extract lock_id from response
    LOCK_ID=$(echo "$lock_response" | grep -o '"lock_id": "[^"]*"' | cut -d'"' -f4)
    print_status "INFO" "Extracted lock_id: $LOCK_ID"
    
else
    print_status "FAIL" "Lock seats B5, B6"
    echo -e "${RED}Response:${NC} $lock_response"
fi

# 4. Check Seat Availability - Verify locked seats
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
    "Verify seats are locked" \
    '{"showtime_id": "showtime-001", "seat_numbers": ["B5", "B6"]}' \
    '"unavailable_seats"'

# 5. Get Showtime Details
test_grpc_method "cinema.CinemaService" "GetShowtimeDetails" \
    "Get showtime details" \
    '{"showtime_id": "showtime-001"}' \
    '"showtime"'

# 6. Release Seat Lock (if we have a lock_id)
if [ -n "$LOCK_ID" ] && [ "$LOCK_ID" != "null" ]; then
    test_grpc_method "cinema.CinemaService" "ReleaseSeatLock" \
        "Release seat lock" \
        "{\"lock_id\": \"$LOCK_ID\", \"booking_id\": \"$BOOKING_ID\"}" \
        '"success": true'
        
    # Verify seats are available again
    test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
        "Verify seats are available after release" \
        '{"showtime_id": "showtime-001", "seat_numbers": ["B5", "B6"]}' \
        '"available": true'
else
    print_status "WARN" "Skipping release test - no valid lock_id"
fi

# 7. Complete Booking Workflow
echo -e "\n${CYAN}--- Complete Booking Workflow ---${NC}"
WORKFLOW_BOOKING_ID="workflow-test-$(date +%s)"

# Step 1: Lock seats for booking workflow
workflow_lock_response=$(grpcurl -plaintext -d "{
    \"showtime_id\": \"showtime-001\",
    \"seat_numbers\": [\"C7\", \"C8\"],
    \"booking_id\": \"$WORKFLOW_BOOKING_ID\",
    \"lock_duration_seconds\": 300
}" $GRPC_HOST cinema.CinemaService/LockSeats 2>&1)

if [ $? -eq 0 ] && echo "$workflow_lock_response" | grep -q '"success": true'; then
    print_status "PASS" "Workflow: Lock seats C7, C8"
    
    WORKFLOW_LOCK_ID=$(echo "$workflow_lock_response" | grep -o '"lock_id": "[^"]*"' | cut -d'"' -f4)
    
    # Step 2: Confirm booking
    if [ -n "$WORKFLOW_LOCK_ID" ] && [ "$WORKFLOW_LOCK_ID" != "null" ]; then
        test_grpc_method "cinema.CinemaService" "ConfirmSeatBooking" \
            "Confirm seat booking" \
            "{\"lock_id\": \"$WORKFLOW_LOCK_ID\", \"booking_id\": \"$WORKFLOW_BOOKING_ID\", \"user_id\": \"grpc-test-user\"}" \
            '"success"'
            
        # Step 3: Verify seats are now booked (should be unavailable)
        test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
            "Verify seats are booked" \
            '{"showtime_id": "showtime-001", "seat_numbers": ["C7", "C8"]}' \
            '"available": false'
    else
        print_status "WARN" "Skipping confirm booking - no valid lock_id"
    fi
else
    print_status "FAIL" "Workflow: Lock seats C7, C8"
    echo -e "${RED}Response:${NC} $workflow_lock_response"
fi

# 8. Error Handling Tests
echo -e "\n${CYAN}--- Error Handling Tests ---${NC}"

# Test with non-existent showtime
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
    "Non-existent showtime" \
    '{"showtime_id": "non-existent-showtime", "seat_numbers": ["A1"]}' \
    '"message"'

# Test with invalid seat numbers
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
    "Invalid seat numbers" \
    '{"showtime_id": "showtime-001", "seat_numbers": ["INVALID_SEAT", "ANOTHER_INVALID"]}' \
    '"message"'

# Test with invalid lock release
test_grpc_method "cinema.CinemaService" "ReleaseSeatLock" \
    "Invalid lock release" \
    '{"lock_id": "invalid-lock-id", "booking_id": "invalid-booking"}' \
    '"success": false'

# Test with empty seat numbers
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
    "Empty seat numbers" \
    '{"showtime_id": "showtime-001", "seat_numbers": []}' \
    '"message"'

# Test showtime details with invalid ID
test_grpc_method "cinema.CinemaService" "GetShowtimeDetails" \
    "Invalid showtime details" \
    '{"showtime_id": "invalid-showtime"}' \
    '"message"'

# 9. Performance and Edge Case Tests
echo -e "\n${CYAN}--- Performance and Edge Case Tests ---${NC}"

# Test with many seats
test_grpc_method "cinema.CinemaService" "CheckSeatAvailability" \
    "Check availability for many seats" \
    '{"showtime_id": "showtime-001", "seat_numbers": ["D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10"]}' \
    '"available"'

# Test concurrent locking (same seats)
echo -e "\n${PURPLE}Testing concurrent locking behavior...${NC}"
CONCURRENT_BOOKING_1="concurrent-1-$(date +%s)"
CONCURRENT_BOOKING_2="concurrent-2-$(date +%s)"

# Try to lock the same seats with different booking IDs
concurrent_response_1=$(grpcurl -plaintext -d "{
    \"showtime_id\": \"showtime-001\",
    \"seat_numbers\": [\"E1\", \"E2\"],
    \"booking_id\": \"$CONCURRENT_BOOKING_1\",
    \"lock_duration_seconds\": 300
}" $GRPC_HOST cinema.CinemaService/LockSeats 2>&1)

concurrent_response_2=$(grpcurl -plaintext -d "{
    \"showtime_id\": \"showtime-001\",
    \"seat_numbers\": [\"E1\", \"E2\"],
    \"booking_id\": \"$CONCURRENT_BOOKING_2\",
    \"lock_duration_seconds\": 300
}" $GRPC_HOST cinema.CinemaService/LockSeats 2>&1)

if echo "$concurrent_response_1" | grep -q '"success": true' && echo "$concurrent_response_2" | grep -q '"success": false'; then
    print_status "PASS" "Concurrent locking prevention works correctly"
elif echo "$concurrent_response_1" | grep -q '"success": false' && echo "$concurrent_response_2" | grep -q '"success": true'; then
    print_status "PASS" "Concurrent locking prevention works correctly (reverse order)"
else
    print_status "FAIL" "Concurrent locking prevention may have issues"
fi

echo -e "${GREEN}First booking response:${NC} $concurrent_response_1"
echo -e "${GREEN}Second booking response:${NC} $concurrent_response_2"

# Final Summary
echo -e "\n${BLUE}==========================================${NC}"
echo -e "${BLUE}            Test Summary${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "${CYAN}Total Tests:${NC} $TOTAL_TESTS"
echo -e "${GREEN}Passed:${NC} $PASSED_TESTS"
echo -e "${RED}Failed:${NC} $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed! gRPC service is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Check the output above for details.${NC}"
    exit 1
fi