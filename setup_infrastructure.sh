#!/bin/bash

# Infrastructure Services Setup Script
# Start databases and message broker services

echo "🗄️ Starting Infrastructure Services"
echo "===================================="

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

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=20
    local attempt=1
    
    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl.exe -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        echo "  Attempt $attempt/$max_attempts - $service_name not ready yet..."
        sleep 3
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to start after $max_attempts attempts"
    return 1
}

# Check if Docker is running
print_status "Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker Desktop."
    exit 1
fi
print_success "Docker is running"

# Clean up any existing infrastructure containers
print_status "Cleaning up existing infrastructure containers..."
docker-compose stop postgres mongodb redis rabbitmq 2>/dev/null || true
docker-compose rm -f postgres mongodb redis rabbitmq 2>/dev/null || true

# Start PostgreSQL
echo ""
print_status "Starting PostgreSQL..."
docker-compose up -d postgres

print_status "Waiting for PostgreSQL to be ready..."
until docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
    echo "  PostgreSQL not ready yet..."
    sleep 2
done
print_success "PostgreSQL is ready!"

# Start MongoDB
echo ""
print_status "Starting MongoDB..."
docker-compose up -d mongodb

print_status "Waiting for MongoDB to be ready..."
until docker-compose exec -T mongodb mongosh --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    echo "  MongoDB not ready yet..."
    sleep 2
done
print_success "MongoDB is ready!"

# Start Redis
echo ""
print_status "Starting Redis..."
docker-compose up -d redis

print_status "Waiting for Redis to be ready..."
until docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; do
    echo "  Redis not ready yet..."
    sleep 2
done
print_success "Redis is ready!"

# Start RabbitMQ
echo ""
print_status "Starting RabbitMQ..."
docker-compose up -d rabbitmq

wait_for_service "http://localhost:15672" "RabbitMQ Management"

# Start management tools
echo ""
print_status "Starting management tools..."
docker-compose up -d mongo-express pgadmin redis-commander

echo ""
print_success "🎉 All infrastructure services are running!"
echo ""
echo "📊 Infrastructure Access:"
echo "  - PostgreSQL:         localhost:5432 (postgres/postgres123)"
echo "  - MongoDB:            localhost:27017 (admin/admin123)" 
echo "  - Redis:              localhost:6379"
echo "  - RabbitMQ:           localhost:5672"
echo "  - RabbitMQ Management: http://localhost:15672 (admin/admin123)"
echo "  - MongoDB Express:    http://localhost:8081 (admin/admin123)"
echo "  - pgAdmin:            http://localhost:8080 (admin@movietickets.com/admin123)"
echo "  - Redis Commander:    http://localhost:8082"
echo ""
echo "✅ Infrastructure is ready for microservices!"
echo ""
echo "Next steps:"
echo "  1. Run: ./setup_kong.sh"
echo "  2. Run: ./setup_user_service.sh"
echo "  3. Run: ./setup_cinema_service.sh"
echo "  4. Run: ./setup_payment_service.sh"
echo "  5. Run: ./setup_booking_service.sh"
echo "  6. Run: ./setup_notification_service.sh"