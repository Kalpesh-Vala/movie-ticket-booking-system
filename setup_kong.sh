#!/bin/bash

# Kong Gateway Setup Script
# Sets up Kong API Gateway and configures routes

echo "🌉 Setting up Kong Gateway"
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

# Check if PostgreSQL is running
print_status "Checking if PostgreSQL is running..."
if ! docker-compose exec -T postgres pg_isready -U postgres > /dev/null 2>&1; then
    print_error "PostgreSQL is not running. Please run ./setup_infrastructure.sh first"
    exit 1
fi
print_success "PostgreSQL is running"

# Clean up existing Kong containers
print_status "Cleaning up existing Kong containers..."
docker-compose stop kong kong-migrations kong-database 2>/dev/null || true
docker-compose rm -f kong kong-migrations kong-database 2>/dev/null || true

# Start Kong database first
echo ""
print_status "Starting Kong database..."
docker-compose up -d kong-database

# Wait for Kong database to be ready
print_status "Waiting for Kong database to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if docker-compose exec -T kong-database pg_isready -U kong > /dev/null 2>&1; then
        print_success "Kong database is ready!"
        break
    fi
    
    echo "  Attempt $attempt/$max_attempts - Kong database not ready yet..."
    sleep 3
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Kong database failed to start after $max_attempts attempts"
    exit 1
fi

# Run Kong migrations
echo ""
print_status "Running Kong database migrations..."
docker-compose up --exit-code-from kong-migrations kong-migrations

if [ $? -ne 0 ]; then
    print_error "Kong migrations failed"
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check Kong database logs: docker-compose logs kong-database"
    echo "  2. Check migration logs: docker-compose logs kong-migrations"
    echo "  3. Ensure Kong database is healthy: docker-compose ps kong-database"
    echo "  4. Restart Kong database: docker-compose restart kong-database"
    exit 1
fi
print_success "Kong migrations completed"

# Start Kong
echo ""
print_status "Starting Kong Gateway..."
docker-compose up -d kong

# Wait for Kong to be ready
print_status "Waiting for Kong to be ready..."
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl.exe -s -f "http://localhost:8001/status" > /dev/null 2>&1; then
        print_success "Kong is ready!"
        break
    fi
    
    echo "  Attempt $attempt/$max_attempts - Kong not ready yet..."
    sleep 3
    attempt=$((attempt + 1))
done

if [ $attempt -gt $max_attempts ]; then
    print_error "Kong failed to start after $max_attempts attempts"
    echo ""
    echo "📋 Troubleshooting steps:"
    echo "  1. Check Kong logs: docker-compose logs kong"
    echo "  2. Check Kong database: docker-compose ps kong-database"
    echo "  3. Check kong.yml configuration file"
    echo "  4. Restart Kong: docker-compose restart kong"
    exit 1
fi

# Verify Kong configuration is loaded
echo ""
print_status "Verifying Kong configuration..."

# Check if services are loaded from kong.yml
services_response=$(curl.exe -s "http://localhost:8001/services" 2>/dev/null)
if [ $? -eq 0 ]; then
    service_count=$(echo "$services_response" | grep -o '"name"' | wc -l)
    if [ "$service_count" -gt 0 ]; then
        print_success "Kong configuration loaded successfully ($service_count services configured)"
    else
        print_status "Kong started but no services loaded from kong.yml yet"
        print_status "Services will be configured automatically when microservices start"
    fi
else
    print_error "Could not verify Kong configuration"
fi

echo ""
print_success "🎉 Kong Gateway is configured and running!"
echo ""
echo "📊 Kong Access:"
echo "  - Kong Admin API:    http://localhost:8001"
echo "  - Kong Gateway:      http://localhost:8000"
echo "  - Kong Manager:      http://localhost:8002"
echo ""
echo "🛣️  API Routes (via Kong Gateway):"
echo "  - User Service:      http://localhost:8000/api/users"
echo "  - Cinema Service:    http://localhost:8000/api/cinemas"
echo "  - Booking Service:   http://localhost:8000/api/bookings"
echo "  - Payment Service:   http://localhost:8000/api/payments"
echo "  - Notification Service: http://localhost:8000/api/notifications"
echo ""
echo "📋 Kong Configuration:"
echo "  - Configuration Type: Declarative (kong.yml file)"
echo "  - Database Backend:   PostgreSQL (kong-database)"
echo "  - Auto-reload:        Enabled"
echo ""
echo "✅ Kong Gateway is ready!"
echo ""
echo "Next: Start the microservices with individual setup scripts"