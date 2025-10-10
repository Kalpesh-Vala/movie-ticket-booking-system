#!/bin/bash

# Stop All Services Script
# Gracefully stops all services in the correct order

echo "🛑 Stopping Movie Ticket Booking System"
echo "========================================"

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

# Stop services in reverse order of dependencies
echo ""
print_status "Stopping Notification Service..."
docker-compose stop notification-service
print_success "Notification Service stopped"

echo ""
print_status "Stopping Booking Service..."
docker-compose stop booking-service
print_success "Booking Service stopped"

echo ""
print_status "Stopping Payment Service..."
docker-compose stop payment-service
print_success "Payment Service stopped"

echo ""
print_status "Stopping Cinema Service..."
docker-compose stop cinema-service
print_success "Cinema Service stopped"

echo ""
print_status "Stopping User Service..."
docker-compose stop user-service
print_success "User Service stopped"

echo ""
print_status "Stopping Kong Gateway..."
docker-compose stop kong
print_success "Kong Gateway stopped"

echo ""
print_status "Stopping Infrastructure Services..."
docker-compose stop postgres mongodb redis rabbitmq
print_success "Infrastructure Services stopped"

echo ""
print_status "Stopping Management Tools..."
docker-compose stop mongo-express pgadmin redis-commander
print_success "Management Tools stopped"

echo ""
print_success "🎉 All services have been stopped!"
echo ""
echo "🔧 Management Commands:"
echo "  - Start infrastructure:  ./setup_infrastructure.sh"
echo "  - Start Kong Gateway:    ./setup_kong.sh"
echo "  - Start all services:    ./complete_setup.sh"
echo "  - View stopped containers: docker-compose ps -a"
echo "  - Remove all containers: docker-compose down"
echo "  - Remove with volumes:   docker-compose down -v"