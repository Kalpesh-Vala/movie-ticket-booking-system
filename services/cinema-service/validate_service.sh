#!/bin/bash

# Simple validation script for Cinema Service
echo "=========================================="
echo "Cinema Service Validation Tests"
echo "=========================================="

BASE_URL="http://localhost:8002"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_count=0
pass_count=0

run_test() {
    local description="$1"
    local curl_command="$2"
    local expected_status="$3"
    
    test_count=$((test_count + 1))
    echo -e "\n${BLUE}Test $test_count: $description${NC}"
    
    response=$(eval "$curl_command")
    status=$(echo "$response" | tail -n1 | grep -o '[0-9]\{3\}')
    
    if [ "$status" = "$expected_status" ]; then
        echo -e "${GREEN}✓ PASSED (Status: $status)${NC}"
        pass_count=$((pass_count + 1))
    else
        echo -e "${RED}✗ FAILED (Expected: $expected_status, Got: $status)${NC}"
    fi
}

# Test 1: Health Check
run_test "Health Check" "curl -s -w '\n%{http_code}' $BASE_URL/actuator/health" "200"

# Test 2: Get All Cinemas
run_test "Get All Cinemas" "curl -s -w '\n%{http_code}' '$BASE_URL/api/v1/cinemas?size=1'" "200"

# Test 3: Get Cinema by ID
run_test "Get Cinema by ID" "curl -s -w '\n%{http_code}' $BASE_URL/api/v1/cinemas/cinema-1" "200"

# Test 4: Get All Movies
run_test "Get All Movies" "curl -s -w '\n%{http_code}' $BASE_URL/api/v1/movies" "200"

# Test 5: Get Movie by ID
run_test "Get Movie by ID" "curl -s -w '\n%{http_code}' $BASE_URL/api/v1/movies/movie-1" "200"

# Test 6: Get Screens for Cinema
run_test "Get Screens for Cinema" "curl -s -w '\n%{http_code}' $BASE_URL/api/v1/cinemas/cinema-1/screens" "200"

# Test 7: Get All Showtimes
run_test "Get All Showtimes" "curl -s -w '\n%{http_code}' $BASE_URL/api/v1/showtimes" "200"

# Test 8: Get Seats for Showtime
run_test "Get Seats for Showtime" "curl -s -w '\n%{http_code}' '$BASE_URL/api/v1/showtimes/showtime-1/seats?size=1'" "200"

# Test 9: Get Available Seats
run_test "Get Available Seats" "curl -s -w '\n%{http_code}' '$BASE_URL/api/v1/showtimes/showtime-1/seats/available?size=1'" "200"

# Test 10: Search Movies
run_test "Search Movies" "curl -s -w '\n%{http_code}' '$BASE_URL/api/v1/movies/search?title=Avengers'" "200"

# Test 11: Lock Seats (with correct seat numbers)
run_test "Lock Seats" "curl -s -w '\n%{http_code}' -X POST -H 'Content-Type: application/json' -d '[\"A01\", \"A02\"]' '$BASE_URL/api/v1/showtimes/showtime-1/seats/lock?userId=test-user'" "200"

# Test 12: Check Locked Seats
run_test "Check Locked Seats" "curl -s -w '\n%{http_code}' '$BASE_URL/api/v1/showtimes/showtime-1/seats?status=LOCKED'" "200"

# Test 13: Release Seats
run_test "Release Seats" "curl -s -w '\n%{http_code}' -X POST -H 'Content-Type: application/json' -d '[\"A01\", \"A02\"]' '$BASE_URL/api/v1/showtimes/showtime-1/seats/release'" "200"

# Test 14: Error Handling - Non-existent Cinema
run_test "Non-existent Cinema" "curl -s -w '\n%{http_code}' $BASE_URL/api/v1/cinemas/non-existent" "404"

# Test 15: Error Handling - Non-existent Movie
run_test "Non-existent Movie" "curl -s -w '\n%{http_code}' $BASE_URL/api/v1/movies/non-existent" "404"

echo -e "\n${BLUE}=========================================="
echo "Test Summary"
echo "==========================================${NC}"
echo -e "Total Tests: $test_count"
echo -e "${GREEN}Passed: $pass_count${NC}"
echo -e "${RED}Failed: $((test_count - pass_count))${NC}"

if [ $pass_count -eq $test_count ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! The Cinema Service is working correctly.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Please check the service.${NC}"
    exit 1
fi