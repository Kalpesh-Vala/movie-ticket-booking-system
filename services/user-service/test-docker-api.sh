#!/bin/bash

# Comprehensive API Testing Script for Dockerized User Service
# This script tests all endpoints of the Movie Ticket User Service

BASE_URL="http://localhost:8001"
API_BASE="$BASE_URL/api/v1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to test HTTP endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local headers=$4
    local expected_status=$5
    local description=$6
    
    print_status "Testing: $description"
    
    if [ -n "$data" ]; then
        if [ -n "$headers" ]; then
            response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method "$url" -H "$headers" -d "$data")
        else
            response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method "$url" -d "$data")
        fi
    else
        if [ -n "$headers" ]; then
            response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method "$url" -H "$headers")
        else
            response=$(curl -s -w "HTTPSTATUS:%{http_code}" -X $method "$url")
        fi
    fi
    
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    response_body=$(echo $response | sed -e 's/HTTPSTATUS:.*//')
    
    if [ "$http_code" -eq "$expected_status" ]; then
        print_success "$method $url - Status: $http_code"
        echo "Response: $response_body"
    else
        print_error "$method $url - Expected: $expected_status, Got: $http_code"
        echo "Response: $response_body"
        return 1
    fi
    echo ""
    return 0
}

echo "🚀 COMPREHENSIVE API TESTING FOR MOVIE TICKET USER SERVICE"
echo "==========================================================="
echo ""

# Wait for service to be ready
print_status "Waiting for service to be ready..."
sleep 5

# Test 1: Health Check
print_status "🏥 HEALTH CHECK TESTS"
echo "====================="
test_endpoint "GET" "$BASE_URL/health" "" "" 200 "Health Check Endpoint"

# Test 2: User Registration Tests
print_status "👤 USER REGISTRATION TESTS"
echo "=========================="

# Generate unique email with timestamp
TIMESTAMP=$(date +%s)
TEST_EMAIL="testuser${TIMESTAMP}@example.com"

# Valid registration
test_endpoint "POST" "$API_BASE/register" "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"password123\",
    \"first_name\": \"Test\",
    \"last_name\": \"User\"
}" "Content-Type: application/json" 201 "Valid User Registration"

# Duplicate email registration (should fail)
test_endpoint "POST" "$API_BASE/register" "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"password456\",
    \"first_name\": \"Duplicate\",
    \"last_name\": \"User\"
}" "Content-Type: application/json" 409 "Duplicate Email Registration (should fail)"

# Invalid email format
test_endpoint "POST" "$API_BASE/register" '{
    "email": "invalid-email",
    "password": "password123",
    "first_name": "Invalid",
    "last_name": "Email"
}' "Content-Type: application/json" 400 "Invalid Email Format (should fail)"

# Short password
test_endpoint "POST" "$API_BASE/register" '{
    "email": "shortpass@example.com",
    "password": "123",
    "first_name": "Short",
    "last_name": "Password"
}' "Content-Type: application/json" 400 "Short Password (should fail)"

# Missing required fields
test_endpoint "POST" "$API_BASE/register" '{
    "email": "missing@example.com",
    "password": "password123"
}' "Content-Type: application/json" 400 "Missing Required Fields (should fail)"

# Test 3: User Login Tests
print_status "🔐 USER LOGIN TESTS"
echo "=================="

# Valid login
login_response=$(curl -s -X POST "$API_BASE/login" \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"$TEST_EMAIL\",
        \"password\": \"password123\"
    }")

if echo "$login_response" | grep -q "token"; then
    print_success "Valid User Login"
    echo "Response: $login_response"
    
    # Extract JWT token for protected endpoint tests
    JWT_TOKEN=$(echo $login_response | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
    echo "JWT Token extracted: ${JWT_TOKEN:0:50}..."
else
    print_error "Valid User Login Failed"
    echo "Response: $login_response"
    JWT_TOKEN=""
fi
echo ""

# Invalid credentials
test_endpoint "POST" "$API_BASE/login" "{
    \"email\": \"$TEST_EMAIL\",
    \"password\": \"wrongpassword\"
}" "Content-Type: application/json" 401 "Invalid Password (should fail)"

# Non-existent user
test_endpoint "POST" "$API_BASE/login" '{
    "email": "nonexistent@example.com",
    "password": "password123"
}' "Content-Type: application/json" 401 "Non-existent User (should fail)"

# Test 4: Protected Endpoint Tests
if [ -n "$JWT_TOKEN" ]; then
    print_status "🔒 PROTECTED ENDPOINT TESTS"
    echo "==========================="
    
    # Get user profile
    test_endpoint "GET" "$API_BASE/profile" "" "Authorization: Bearer $JWT_TOKEN" 200 "Get User Profile"
    
    # Update user profile
    test_endpoint "PUT" "$API_BASE/profile" '{
        "first_name": "Updated",
        "last_name": "Name",
        "phone_number": "+1234567890"
    }' "Authorization: Bearer $JWT_TOKEN" 200 "Update User Profile"
    
    # Get updated profile to verify changes
    test_endpoint "GET" "$API_BASE/profile" "" "Authorization: Bearer $JWT_TOKEN" 200 "Get Updated Profile"
    
    # Test with invalid token
    test_endpoint "GET" "$API_BASE/profile" "" "Authorization: Bearer invalid-token" 401 "Invalid JWT Token (should fail)"
    
    # Test without authorization header
    test_endpoint "GET" "$API_BASE/profile" "" "" 401 "Missing Authorization Header (should fail)"
    
    # Extract user ID for user-specific tests
    profile_response=$(curl -s -X GET "$API_BASE/profile" -H "Authorization: Bearer $JWT_TOKEN")
    USER_ID=$(echo $profile_response | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    
    if [ -n "$USER_ID" ]; then
        echo "User ID extracted: $USER_ID"
        
        # Get user by ID
        test_endpoint "GET" "$API_BASE/users/$USER_ID" "" "Authorization: Bearer $JWT_TOKEN" 200 "Get User by ID"
        
        # Update user by ID
        test_endpoint "PUT" "$API_BASE/users/$USER_ID" '{
            "first_name": "Updated Via ID",
            "phone_number": "+9876543210"
        }' "Authorization: Bearer $JWT_TOKEN" 200 "Update User by ID"
        
        # Test with invalid user ID
        test_endpoint "GET" "$API_BASE/users/invalid-id" "" "Authorization: Bearer $JWT_TOKEN" 400 "Invalid User ID (should fail)"
    fi
    
else
    print_error "Skipping protected endpoint tests - No JWT token available"
fi

# Test 5: Database Verification
print_status "🗄️  DATABASE VERIFICATION"
echo "========================"

print_status "Checking MongoDB container and data..."

# Check if MongoDB container is running
if docker ps | grep -q "user-service-mongodb"; then
    print_success "MongoDB container is running"
    
    # Connect to MongoDB and check data
    mongo_result=$(docker exec user-service-mongodb mongosh movie_booking --quiet --eval "
        print('Users count: ' + db.users.countDocuments());
        print('Sample user:');
        var user = db.users.findOne({email: '$TEST_EMAIL'}, {password: 0});
        if (user) {
            print(JSON.stringify(user, null, 2));
        } else {
            print('No user found with email: $TEST_EMAIL');
        }
    " 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        print_success "Database connection successful"
        echo "$mongo_result"
    else
        print_error "Database connection failed"
    fi
else
    print_error "MongoDB container is not running"
fi

echo ""

# Test 6: Docker Health Checks
print_status "🏥 DOCKER HEALTH CHECKS"
echo "======================="

print_status "Checking Docker container health..."
docker_status=$(docker compose ps --format "table {{.Name}}\t{{.Status}}")
echo "$docker_status"

# Summary
echo ""
print_status "📊 TEST SUMMARY"
echo "==============="

# Count running containers
running_containers=$(docker compose ps | grep -c "Up")
total_containers=$(docker compose ps | wc -l)
total_containers=$((total_containers - 1)) # Subtract header line

if [ "$running_containers" -eq "$total_containers" ]; then
    print_success "All containers are running ($running_containers/$total_containers)"
else
    print_warning "Some containers may have issues ($running_containers/$total_containers running)"
fi

# Check service accessibility
if curl -s "$BASE_URL/health" > /dev/null; then
    print_success "User service is accessible"
else
    print_error "User service is not accessible"
fi

echo ""
print_status "✨ API Testing Complete!"
echo ""
echo "🔗 Service URLs:"
echo "   - User Service: http://localhost:8001"
echo "   - Health Check: http://localhost:8001/health"
echo "   - API Base: http://localhost:8001/api/v1"
echo ""
echo "🐳 Docker Commands:"
echo "   - View logs: docker compose logs -f"
echo "   - Stop services: docker compose down"
echo "   - Restart services: docker compose restart"