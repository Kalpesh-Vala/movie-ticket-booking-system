#!/bin/bash

# Complete Setup Script for Movie Ticket Booking System
# Windows Git Bash Compatible

echo "🚀 Movie Ticket Booking System - Complete Setup"
echo "==============================================="

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

print_warning() {
    echo "[WARNING] $1"
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl.exe -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo "  Attempt $attempt/$max_attempts - $service_name not ready yet..."
        sleep 5
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start after $max_attempts attempts"
    return 1
}

# Step 1: Clean up any existing containers
echo ""
echo "Step 1: Cleanup Previous Containers"
echo "==================================="

print_status "Stopping and removing existing containers..."
docker-compose down -v 2>/dev/null || true
docker container prune -f 2>/dev/null || true

# Step 2: Start infrastructure services first
echo ""
echo "Step 2: Starting Infrastructure Services"
echo "========================================"

print_status "Starting databases and message broker..."
docker-compose up -d postgres mongodb redis rabbitmq

print_status "Waiting for infrastructure services to be ready..."
wait_for_service "http://localhost:5432" "PostgreSQL" &
wait_for_service "http://localhost:27017" "MongoDB" &
wait_for_service "http://localhost:6379" "Redis" &
wait_for_service "http://localhost:15672" "RabbitMQ Management"

print_success "Infrastructure services are ready!"

# Step 3: Start Kong Gateway
echo ""
echo "Step 3: Starting Kong Gateway"
echo "============================="

print_status "Starting Kong database and gateway..."
docker-compose up -d kong-database
sleep 10
docker-compose up -d kong-migrations
sleep 10
docker-compose up -d kong

wait_for_service "http://localhost:8000" "Kong Gateway"

# Step 4: Start microservices
echo ""
echo "Step 4: Starting Microservices"
echo "=============================="

print_status "Starting User Service..."
docker-compose up -d user-service
wait_for_service "http://localhost:8001/health" "User Service"

print_status "Starting Cinema Service..."
docker-compose up -d cinema-service
wait_for_service "http://localhost:8002/actuator/health" "Cinema Service"

print_status "Starting Payment Service..."
docker-compose up -d payment-service
wait_for_service "http://localhost:8003/health" "Payment Service"

print_status "Starting Booking Service..."
docker-compose up -d booking-service
wait_for_service "http://localhost:8010/health" "Booking Service"

print_status "Starting Notification Service..."
docker-compose up -d notification-service

# Step 5: Start monitoring tools
echo ""
echo "Step 5: Starting Monitoring Tools"
echo "================================="

print_status "Starting management interfaces..."
docker-compose up -d mongo-express pgadmin redis-commander

print_success "All services started successfully!"

# Step 6: Verify all services are running
echo ""
echo "Step 6: Service Verification"
echo "============================"

print_status "Checking service status..."

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(kong|user-service|cinema-service|booking-service|payment-service|notification-service|postgres|mongodb|redis|rabbitmq)"

# Step 7: Display access information
echo ""
echo "Step 7: System Access Information"
echo "================================="

print_success "🎉 Setup completed successfully!"
echo ""
echo "📡 Service Endpoints (through Kong Gateway):"
echo "  - Kong Gateway:           http://localhost:8000"
echo "  - User Service API:       http://localhost:8000/api/v1/"
echo "  - Cinema Service API:     http://localhost:8000/api/v1/"
echo "  - Booking GraphQL:        http://localhost:8000/graphql"
echo "  - Payment Service API:    http://localhost:8000/payment/"
echo ""
echo "🔧 Direct Service Access (for development):"
echo "  - User Service:           http://localhost:8001"
echo "  - Cinema Service:         http://localhost:8002"
echo "  - Booking Service:        http://localhost:8010"
echo "  - Payment Service:        http://localhost:8003"
echo ""
echo "📊 Management Interfaces:"
echo "  - Kong Admin:             http://localhost:8001 (Kong admin API)"
echo "  - RabbitMQ Management:    http://localhost:15672 (admin/admin123)"
echo "  - MongoDB Express:        http://localhost:8081 (admin/admin123)"
echo "  - PostgreSQL pgAdmin:     http://localhost:8080 (admin@movietickets.com/admin123)"
echo "  - Redis Commander:        http://localhost:8082"
echo ""
echo "🐳 Docker Commands:"
echo "  - View logs:              docker-compose logs -f [service-name]"
echo "  - Stop all:               docker-compose down"
echo "  - Restart service:        docker-compose restart [service-name]"
echo ""
echo "🧪 Testing:"
echo "  - Run integration test:   ./windows_integration_test.sh"
echo "  - GraphQL Playground:     http://localhost:8000/graphql"
echo ""
echo "🚨 Important Notes:"
echo "  - All external access goes through Kong Gateway (port 8000)"
echo "  - JWT authentication is disabled for GraphQL (easier testing)"
echo "  - Check RabbitMQ queues for message flow"
echo "  - Monitor notification service logs for email processing"
echo ""
print_success "System is ready for testing!"

# Optional: Show some useful commands
echo ""
echo "Useful Commands for Monitoring:"
echo "==============================="
echo "# View all container logs"
echo "docker-compose logs -f"
echo ""
echo "# View specific service logs"
echo "docker logs movie-booking-service -f"
echo "docker logs movie-notification-service -f"
echo "docker logs movie-payment-service -f"
echo ""
echo "# Check RabbitMQ queues"
echo "curl -u admin:admin123 http://localhost:15672/api/queues"
echo ""
echo "# Check Kong services"
echo "curl http://localhost:8001/services"
echo ""
echo "# Test user registration"
echo 'curl -X POST http://localhost:8000/api/v1/register \'
echo '  -H "Content-Type: application/json" \'
echo '  -d '\''{"email":"test@example.com","password":"password123","first_name":"Test","last_name":"User"}'\'''
echo ""
echo "Ready to run: ./windows_integration_test.sh"