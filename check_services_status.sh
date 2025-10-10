#!/bin/bash

# Service Status Check Script
# Check the status of all services in the Movie Ticket Booking System

echo "📊 Movie Ticket Booking System Status"
echo "====================================="

# Function to check service health
check_service() {
    local service_name=$1
    local url=$2
    local port=$3
    
    echo -n "  $service_name: "
    
    if [ -n "$url" ]; then
        if curl.exe -s -f "$url" > /dev/null 2>&1; then
            echo "✅ Running"
        else
            echo "❌ Not responding"
        fi
    elif [ -n "$port" ]; then
        if nc -z localhost "$port" 2>/dev/null; then
            echo "✅ Running"
        else
            echo "❌ Not running"
        fi
    else
        # Check Docker container status
        if docker-compose ps "$service_name" | grep -q "Up"; then
            echo "✅ Container running"
        else
            echo "❌ Container stopped"
        fi
    fi
}

# Infrastructure Services
echo ""
echo "🗄️ Infrastructure Services:"
check_service "postgres" "" "5432"
check_service "mongodb" "" "27017"
check_service "redis" "" "6379"
check_service "rabbitmq" "http://localhost:15672" ""

# API Gateway
echo ""
echo "🌉 API Gateway:"
check_service "Kong Gateway" "http://localhost:8001/status" ""

# Microservices
echo ""
echo "🚀 Microservices:"
check_service "User Service" "http://localhost:8080/health" ""
check_service "Cinema Service" "http://localhost:8081/api/cinemas/health" ""
check_service "Booking Service" "http://localhost:8082/health" ""
check_service "Payment Service" "http://localhost:8083/health" ""
check_service "Notification Service" "http://localhost:8084/health" ""

# Management Tools
echo ""
echo "🔧 Management Tools:"
check_service "MongoDB Express" "http://localhost:8081" ""
check_service "pgAdmin" "http://localhost:8080" ""
check_service "Redis Commander" "http://localhost:8082" ""

# Docker container status
echo ""
echo "🐳 Docker Container Status:"
docker-compose ps

# Network connectivity test
echo ""
echo "🔗 Network Connectivity Test:"
echo "  Kong → User Service:"
if curl.exe -s -f "http://localhost:8000/api/users" > /dev/null 2>&1; then
    echo "    ✅ Working"
else
    echo "    ❌ Failed"
fi

echo "  Kong → Cinema Service:"
if curl.exe -s -f "http://localhost:8000/api/cinemas" > /dev/null 2>&1; then
    echo "    ✅ Working"
else
    echo "    ❌ Failed"
fi

echo "  Kong → Booking Service:"
if curl.exe -s -f "http://localhost:8000/api/bookings" > /dev/null 2>&1; then
    echo "    ✅ Working"
else
    echo "    ❌ Failed"
fi

echo "  Kong → Payment Service:"
if curl.exe -s -f "http://localhost:8000/api/payments" > /dev/null 2>&1; then
    echo "    ✅ Working"
else
    echo "    ❌ Failed"
fi

echo "  Kong → Notification Service:"
if curl.exe -s -f "http://localhost:8000/api/notifications" > /dev/null 2>&1; then
    echo "    ✅ Working"
else
    echo "    ❌ Failed"
fi

# Resource usage
echo ""
echo "💽 Resource Usage:"
echo "  CPU Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -10

echo ""
echo "📋 Quick Commands:"
echo "  - View logs for all services: docker-compose logs"
echo "  - View logs for specific service: docker-compose logs <service-name>"
echo "  - Restart specific service: docker-compose restart <service-name>"
echo "  - Stop all services: ./stop_all_services.sh"
echo "  - Full system setup: ./complete_setup.sh"