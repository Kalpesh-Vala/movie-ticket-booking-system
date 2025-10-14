#!/bin/bash

# Cinema Service gRPC Testing Guide and Script
# This script provides comprehensive testing for all gRPC endpoints

echo "=========================================="
echo "Cinema Service gRPC Testing Guide"
echo "=========================================="

GRPC_HOST="localhost:9090"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}This script tests all available gRPC endpoints for the Cinema Service${NC}"
echo -e "${YELLOW}Available gRPC Methods:${NC}"
echo "1. CheckSeatAvailability - Check if seats are available for booking"
echo "2. LockSeats - Lock seats for a specific duration"
echo "3. ReleaseSeatLock - Release previously locked seats"
echo "4. ConfirmSeatBooking - Confirm and finalize seat booking"
echo "5. GetShowtimeDetails - Get detailed information about a showtime"

echo -e "\n${CYAN}=== GRPCURL INSTALLATION ===${NC}"

# Check if grpcurl is available
if ! command -v grpcurl &> /dev/null; then
    echo -e "${RED}grpcurl is not installed.${NC}"
    echo -e "${YELLOW}Installation options:${NC}"
    echo ""
    echo -e "${BLUE}For Linux/Ubuntu:${NC}"
    echo "  sudo apt-get update"
    echo "  sudo apt-get install grpcurl"
    echo ""
    echo -e "${BLUE}For macOS:${NC}"
    echo "  brew install grpcurl"
    echo ""
    echo -e "${BLUE}For Windows:${NC}"
    echo "  # Download from GitHub releases"
    echo "  curl -L https://github.com/fullstorydev/grpcurl/releases/latest/download/grpcurl_windows_x86_64.tar.gz -o grpcurl.tar.gz"
    echo "  tar -xzf grpcurl.tar.gz"
    echo "  # Move grpcurl.exe to a directory in your PATH"
    echo ""
    echo -e "${BLUE}Alternative - Using Go:${NC}"
    echo "  go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest"
    echo ""
    echo -e "${YELLOW}After installation, run this script again to execute the tests.${NC}"
    
    # Provide manual test commands
    echo -e "\n${CYAN}=== MANUAL TESTING COMMANDS ===${NC}"
    echo -e "${YELLOW}Once grpcurl is installed, you can run these commands manually:${NC}"
    echo ""
    
    echo -e "${BLUE}1. List available services:${NC}"
    echo "grpcurl -plaintext $GRPC_HOST list"
    echo ""
    
    echo -e "${BLUE}2. List methods for CinemaService:${NC}"
    echo "grpcurl -plaintext $GRPC_HOST list cinema.CinemaService"
    echo ""
    
    echo -e "${BLUE}3. Check seat availability:${NC}"
    echo 'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": ["A7", "A8"]}'"'"' '$GRPC_HOST' cinema.CinemaService/CheckSeatAvailability'
    echo ""
    
    echo -e "${BLUE}4. Lock seats:${NC}"
    echo 'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": ["B5", "B6"], "booking_id": "test-booking-123", "lock_duration_seconds": 300}'"'"' '$GRPC_HOST' cinema.CinemaService/LockSeats'
    echo ""
    
    echo -e "${BLUE}5. Get showtime details:${NC}"
    echo 'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001"}'"'"' '$GRPC_HOST' cinema.CinemaService/GetShowtimeDetails'
    echo ""
    
    echo -e "${BLUE}6. Release seat lock:${NC}"
    echo 'grpcurl -plaintext -d '"'"'{"lock_id": "your-lock-id", "booking_id": "test-booking-123"}'"'"' '$GRPC_HOST' cinema.CinemaService/ReleaseSeatLock'
    echo ""
    
    echo -e "${BLUE}7. Confirm seat booking:${NC}"
    echo 'grpcurl -plaintext -d '"'"'{"lock_id": "your-lock-id", "booking_id": "test-booking-123", "user_id": "test-user"}'"'"' '$GRPC_HOST' cinema.CinemaService/ConfirmSeatBooking'
    echo ""
    
    exit 1
fi

echo -e "${GREEN}✓ grpcurl is available${NC}"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to run a test
run_test() {
    local test_name="$1"
    local description="$2"
    local command="$3"
    local expected_field="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${CYAN}Test $TOTAL_TESTS: $description${NC}"
    echo -e "${YELLOW}Command: $command${NC}"
    
    # Execute the command
    response=$(eval "$command" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        if [ -n "$expected_field" ]; then
            if echo "$response" | grep -q "$expected_field"; then
                echo -e "${GREEN}✓ PASS - $test_name${NC}"
                PASSED_TESTS=$((PASSED_TESTS + 1))
            else
                echo -e "${RED}✗ FAIL - $test_name (expected field '$expected_field' not found)${NC}"
                FAILED_TESTS=$((FAILED_TESTS + 1))
            fi
        else
            echo -e "${GREEN}✓ PASS - $test_name${NC}"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        fi
    else
        echo -e "${RED}✗ FAIL - $test_name${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    
    echo -e "${BLUE}Response:${NC}"
    echo "$response" | head -5
    if [ $(echo "$response" | wc -l) -gt 5 ]; then
        echo "... (response truncated)"
    fi
}

# Check gRPC server connectivity
echo -e "\n${CYAN}=== GRPC SERVER CONNECTIVITY ===${NC}"

if grpcurl -plaintext $GRPC_HOST list >/dev/null 2>&1; then
    echo -e "${GREEN}✓ gRPC server is accessible at $GRPC_HOST${NC}"
else
    echo -e "${RED}✗ Cannot connect to gRPC server at $GRPC_HOST${NC}"
    echo "Make sure the cinema service is running with:"
    echo "  docker-compose logs cinema-service"
    echo "  docker-compose restart cinema-service"
    exit 1
fi

# List services and methods
echo -e "\n${BLUE}Available services:${NC}"
grpcurl -plaintext $GRPC_HOST list

echo -e "\n${BLUE}Available methods for cinema.CinemaService:${NC}"
grpcurl -plaintext $GRPC_HOST list cinema.CinemaService

# Start testing
echo -e "\n${CYAN}=== STARTING GRPC ENDPOINT TESTS ===${NC}"

# Test 1: Check seat availability - valid seats
run_test "Seat Availability Check" \
         "Check availability for valid seats A7, A8" \
         'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": ["A7", "A8"]}'"'"' '$GRPC_HOST' cinema.CinemaService/CheckSeatAvailability' \
         '"available"'

# Test 2: Check seat availability - invalid showtime
run_test "Invalid Showtime Check" \
         "Check availability with invalid showtime" \
         'grpcurl -plaintext -d '"'"'{"showtime_id": "invalid-showtime", "seat_numbers": ["A1"]}'"'"' '$GRPC_HOST' cinema.CinemaService/CheckSeatAvailability' \
         '"message"'

# Test 3: Lock seats
BOOKING_ID="grpc-test-$(date +%s)"
echo -e "\n${YELLOW}Using booking ID: $BOOKING_ID${NC}"

lock_command='grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": ["B9", "B10"], "booking_id": "'$BOOKING_ID'", "lock_duration_seconds": 300}'"'"' '$GRPC_HOST' cinema.CinemaService/LockSeats'

run_test "Seat Locking" \
         "Lock seats B9, B10" \
         "$lock_command" \
         '"success"'

# Extract lock_id for subsequent tests
echo -e "\n${YELLOW}Extracting lock_id from response...${NC}"
lock_response=$(eval "$lock_command" 2>/dev/null)
LOCK_ID=$(echo "$lock_response" | grep -o '"lock_id": "[^"]*"' | cut -d'"' -f4)

if [ -n "$LOCK_ID" ] && [ "$LOCK_ID" != "null" ]; then
    echo -e "${GREEN}✓ Lock ID extracted: $LOCK_ID${NC}"
    
    # Test 4: Verify seats are locked
    run_test "Locked Seat Verification" \
             "Verify seats B9, B10 are locked" \
             'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": ["B9", "B10"]}'"'"' '$GRPC_HOST' cinema.CinemaService/CheckSeatAvailability' \
             '"unavailable_seats"'
    
    # Test 5: Get showtime details
    run_test "Showtime Details" \
             "Get details for showtime-001" \
             'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001"}'"'"' '$GRPC_HOST' cinema.CinemaService/GetShowtimeDetails' \
             '"showtime"'
    
    # Test 6: Release lock
    run_test "Lock Release" \
             "Release lock for seats B9, B10" \
             'grpcurl -plaintext -d '"'"'{"lock_id": "'$LOCK_ID'", "booking_id": "'$BOOKING_ID'"}'"'"' '$GRPC_HOST' cinema.CinemaService/ReleaseSeatLock' \
             '"success"'
    
    # Test 7: Verify seats are available again
    run_test "Released Seat Verification" \
             "Verify seats B9, B10 are available after release" \
             'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": ["B9", "B10"]}'"'"' '$GRPC_HOST' cinema.CinemaService/CheckSeatAvailability' \
             '"available": true'
    
else
    echo -e "${RED}✗ Could not extract lock_id, skipping dependent tests${NC}"
fi

# Test 8: Complete booking workflow
WORKFLOW_BOOKING_ID="workflow-$(date +%s)"
echo -e "\n${YELLOW}Testing complete booking workflow with booking ID: $WORKFLOW_BOOKING_ID${NC}"

workflow_lock_command='grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": ["D9", "D10"], "booking_id": "'$WORKFLOW_BOOKING_ID'", "lock_duration_seconds": 300}'"'"' '$GRPC_HOST' cinema.CinemaService/LockSeats'

run_test "Workflow Lock" \
         "Lock seats D9, D10 for booking workflow" \
         "$workflow_lock_command" \
         '"success"'

# Extract lock_id for booking confirmation
workflow_response=$(eval "$workflow_lock_command" 2>/dev/null)
WORKFLOW_LOCK_ID=$(echo "$workflow_response" | grep -o '"lock_id": "[^"]*"' | cut -d'"' -f4)

if [ -n "$WORKFLOW_LOCK_ID" ] && [ "$WORKFLOW_LOCK_ID" != "null" ]; then
    # Test 9: Confirm booking
    run_test "Booking Confirmation" \
             "Confirm booking for seats D9, D10" \
             'grpcurl -plaintext -d '"'"'{"lock_id": "'$WORKFLOW_LOCK_ID'", "booking_id": "'$WORKFLOW_BOOKING_ID'", "user_id": "grpc-test-user"}'"'"' '$GRPC_HOST' cinema.CinemaService/ConfirmSeatBooking' \
             '"success"'
fi

# Test 10: Error handling - invalid operations
run_test "Invalid Lock Release" \
         "Try to release invalid lock" \
         'grpcurl -plaintext -d '"'"'{"lock_id": "invalid-lock", "booking_id": "invalid-booking"}'"'"' '$GRPC_HOST' cinema.CinemaService/ReleaseSeatLock' \
         '"success": false'

# Test 11: Empty seat numbers
run_test "Empty Seat Numbers" \
         "Check availability with empty seat list" \
         'grpcurl -plaintext -d '"'"'{"showtime_id": "showtime-001", "seat_numbers": []}'"'"' '$GRPC_HOST' cinema.CinemaService/CheckSeatAvailability' \
         '"message"'

# Final summary
echo -e "\n${BLUE}==========================================${NC}"
echo -e "${BLUE}              Test Summary${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "${CYAN}Total Tests: $TOTAL_TESTS${NC}"
echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "${RED}Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All gRPC tests passed! Service is working correctly.${NC}"
    echo -e "${GREEN}All endpoints are properly implemented and responding.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Check the cinema service logs:${NC}"
    echo -e "${YELLOW}  docker-compose logs cinema-service${NC}"
    echo -e "${YELLOW}  docker-compose restart cinema-service${NC}"
    exit 1
fi