#!/bin/bash

# Cinema Service Setup Script
# Builds and starts the Cinema Service (Java + PostgreSQL)

echo "🎬 Setting up Cinema Service"
echo "============================"

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

# Check if PostgreSQL is running
print_status "Checking if PostgreSQL is running..."
if ! docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    print_error "PostgreSQL is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "PostgreSQL is running"

# Clean up existing cinema service container
print_status "Cleaning up existing Cinema Service container..."
docker-compose stop cinema-service 2>/dev/null || true
docker-compose rm -f cinema-service 2>/dev/null || true

# Build Cinema Service
echo ""
print_status "Building Cinema Service..."
docker-compose build cinema-service

if [ $? -ne 0 ]; then
    print_error "Failed to build Cinema Service"
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check if Maven build is successful"
    echo "  2. Check if Java version is compatible"
    echo "  3. Check Dockerfile in services/cinema-service/"
    echo "  4. Check pom.xml dependencies"
    exit 1
fi
print_success "Cinema Service built successfully"

# Start Cinema Service
echo ""
print_status "Starting Cinema Service..."
docker-compose up -d cinema-service

# Wait for Cinema Service to be ready
print_status "Waiting for Cinema Service to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    # Check REST endpoint
    if curl.exe -s -f "http://localhost:8002/actuator/health" > /dev/null 2>&1; then
        print_success "Cinema Service REST API is ready!"
        break
    fi
    
    echo "  Attempt $attempt/$max_attempts - Cinema Service not ready yet..."
    sleep 3
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Cinema Service failed to start after $max_attempts attempts"
    
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check logs: docker-compose logs cinema-service"
    echo "  2. Check if PostgreSQL is running: docker-compose ps postgres"
    echo "  3. Check database connection in application.properties"
    echo "  4. Restart service: docker-compose restart cinema-service"
    echo "  5. Check if port 8081 is available: netstat -an | findstr 8081"
    exit 1
fi

# Test Cinema Service endpoints
echo ""
print_status "Testing Cinema Service endpoints..."

# Test health endpoint
echo "Testing health endpoint..."
health_response=$(curl.exe -s "http://localhost:8002/actuator/health")
if [ $? -eq 0 ]; then
    print_success "Health endpoint working: $health_response"
else
    print_error "Health endpoint failed"
fi

# Test list cinemas endpoint
echo "Testing list cinemas endpoint..."
cinemas_response=$(curl.exe -s "http://localhost:8002/api/v1/cinemas")
if [ $? -eq 0 ]; then
    print_success "List cinemas endpoint working"
    echo "  Response: $cinemas_response"
else
    print_error "List cinemas endpoint failed"
fi

# Test gRPC endpoint
echo "Testing gRPC endpoint availability..."
if command -v nc &> /dev/null; then
    if nc -z localhost 9090; then
        print_success "gRPC server is listening on port 9090"
    else
        print_error "gRPC server is not accessible on port 9090"
    fi
else
    print_status "nc command not available, skipping gRPC port check"
fi

echo ""
print_success "🎉 Cinema Service is running and ready!"
echo ""
echo "📊 Cinema Service Details:"
echo "  - REST API URL:      http://localhost:8002"
echo "  - gRPC Server:       localhost:9090"
echo "  - Health Check:      http://localhost:8002/actuator/health"
echo "  - API Endpoint:      http://localhost:8002/api/v1/cinemas"
echo "  - Via Kong Gateway:  http://localhost:8000/api/cinemas"
echo "  - Database:          PostgreSQL (cinema_db)"
echo ""
echo "🔧 Management Commands:"
echo "  - View logs:         docker-compose logs cinema-service"
echo "  - Restart service:   docker-compose restart cinema-service"
echo "  - Stop service:      docker-compose stop cinema-service"
echo "  - Access container:  docker-compose exec cinema-service bash"
echo ""
echo "📋 REST API Endpoints:"
echo "  - GET /api/v1/cinemas           - List all cinemas"
echo "  - GET /api/v1/cinemas/:id       - Get cinema by ID"
echo "  - POST /api/v1/cinemas          - Create cinema"
echo "  - PUT /api/v1/cinemas/:id       - Update cinema"
echo "  - DELETE /api/v1/cinemas/:id    - Delete cinema"
echo "  - GET /api/v1/cinemas/:id/movies - Get movies for cinema"
echo "  - POST /api/v1/cinemas/:id/movies - Add movie to cinema"
echo ""
echo "📋 gRPC Services:"
echo "  - CinemaService              - Cinema CRUD operations"
echo "  - MovieService               - Movie management"
echo "  - ShowtimeService            - Showtime management"
echo ""
echo "✅ Cinema Service setup complete!"
echo ""
echo "Next: Run ./setup_payment_service.sh"