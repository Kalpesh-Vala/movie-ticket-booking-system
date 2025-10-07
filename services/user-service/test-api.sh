#!/bin/bash

# MongoDB Test Script for User Service
# This script helps you test your user service API endpoints

BASE_URL="http://localhost:8001"

echo "🚀 Testing Movie Ticket User Service API"
echo "========================================="

# Test 1: Health Check
echo ""
echo "1️⃣ Testing Health Check..."
curl -X GET $BASE_URL/health -w "\n"

# Test 2: Register a new user
echo ""
echo "2️⃣ Testing User Registration..."
REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User"
  }')
echo $REGISTER_RESPONSE

# Test 3: Login with the new user
echo ""
echo "3️⃣ Testing User Login..."
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "testuser@example.com",
    "password": "password123"
  }')
echo $LOGIN_RESPONSE

# Extract JWT token
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$TOKEN" ]; then
    echo ""
    echo "4️⃣ Testing Protected Endpoint (Get Profile)..."
    curl -s -X GET $BASE_URL/api/v1/profile \
      -H "Authorization: Bearer $TOKEN" \
      -w "\n"
else
    echo ""
    echo "❌ Could not extract token for protected endpoint testing"
fi

echo ""
echo "✅ API Testing Complete!"

# Check MongoDB data
echo ""
echo "5️⃣ Checking MongoDB Database..."
mongosh movie_booking --quiet --eval "
print('Total users in database: ' + db.users.countDocuments());
print('Recently created user:');
db.users.find({email: 'testuser@example.com'}, {password: 0}).forEach(user => print(JSON.stringify(user, null, 2)));
"