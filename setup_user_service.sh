#!/bin/bash

# User Service Setup Script
# Builds and starts the User Service (Go + MongoDB)

echo "👤 Setting up User Service"
echo "=========================="

# Function to print status
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_error() {
    echo "[ERROR] $1"
}

# Check if MongoDB is running
print_status "Checking if MongoDB is running..."
if ! docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    print_error "MongoDB is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "MongoDB is running"

# Clean up existing user service container
print_status "Cleaning up existing User Service container..."
docker-compose stop user-service 2>/dev/null || true
docker-compose rm -f user-service 2>/dev/null || true

# Build User Service
echo ""
print_status "Building User Service..."
docker-compose build user-service

if [ $? -ne 0 ]; then
    print_error "Failed to build User Service"
    exit 1
fi
print_success "User Service built successfully"

# Start User Service
echo ""
print_status "Starting User Service..."
docker-compose up -d user-service

# Wait for User Service to be ready
print_status "Waiting for User Service to be ready..."
max_attempts=20
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl.exe -s -f "http://localhost:8080/health" > /dev/null 2>&1; then
        print_success "User Service is ready!"
        break
    fi
    
    echo "  Attempt $attempt/$max_attempts - User Service not ready yet..."
    sleep 3
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "User Service failed to start after $max_attempts attempts"
    
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check logs: docker-compose logs user-service"
    echo "  2. Check if MongoDB is running: docker-compose ps mongodb"
    echo "  3. Check database connection: docker-compose exec user-service cat /app/main.go | grep mongo"
    echo "  4. Restart service: docker-compose restart user-service"
    exit 1
fi

# Test User Service endpoints
echo ""
print_status "Testing User Service endpoints..."

# Test health endpoint
echo "Testing health endpoint..."
health_response=$(curl.exe -s "http://localhost:8080/health")
if [ $? -eq 0 ]; then
    print_success "Health endpoint working: $health_response"
else
    print_error "Health endpoint failed"
fi

# Test create user endpoint
echo "Testing create user endpoint..."
create_response=$(curl.exe -s -X POST "http://localhost:8080/api/users" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test User","email":"test@example.com","password":"password123"}')

if [ $? -eq 0 ]; then
    print_success "Create user endpoint working"
    echo "  Response: $create_response"
else
    print_error "Create user endpoint failed"
fi

echo ""
print_success "🎉 User Service is running and ready!"
echo ""
echo "📊 User Service Details:"
echo "  - Service URL:       http://localhost:8080"
echo "  - Health Check:      http://localhost:8080/health"
echo "  - API Endpoint:      http://localhost:8080/api/users"
echo "  - Via Kong Gateway:  http://localhost:8000/api/users"
echo "  - Database:          MongoDB (movie_tickets_db.users collection)"
echo ""
echo "🔧 Management Commands:"
echo "  - View logs:         docker-compose logs user-service"
echo "  - Restart service:   docker-compose restart user-service"
echo "  - Stop service:      docker-compose stop user-service"
echo "  - Access container:  docker-compose exec user-service sh"
echo ""
echo "📋 API Endpoints:"
echo "  - POST /api/users    - Create user"
echo "  - GET /api/users     - List users"
echo "  - GET /api/users/:id - Get user by ID"
echo "  - PUT /api/users/:id - Update user"
echo "  - DELETE /api/users/:id - Delete user"
echo ""
echo "✅ User Service setup complete!"
echo ""
echo "Next: Run ./setup_cinema_service.sh"