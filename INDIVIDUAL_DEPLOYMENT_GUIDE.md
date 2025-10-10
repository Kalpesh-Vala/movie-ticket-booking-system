# Individual Service Deployment Guide

This guide provides detailed instructions for deploying each service individually, perfect for troubleshooting and multi-device deployment practice.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kong Gateway  │    │  Infrastructure │    │  Microservices  │
│                 │    │                 │    │                 │
│ • API Gateway   │    │ • PostgreSQL    │    │ • User Service  │
│ • Load Balancer │    │ • MongoDB       │    │ • Cinema Service│
│ • Auth & CORS   │    │ • Redis         │    │ • Booking Svc   │
│ • Rate Limiting │    │ • RabbitMQ      │    │ • Payment Svc   │
└─────────────────┘    └─────────────────┘    │ • Notification  │
                                              └─────────────────┘
```

## 🚀 Quick Start - Individual Services

### Option 1: Interactive Menu Setup
```bash
./setup_individual_services.sh
```

### Option 2: Manual Step-by-Step Setup
```bash
# 1. Infrastructure first
./setup_infrastructure.sh

# 2. Kong Gateway
./setup_kong.sh

# 3. Services (order matters for dependencies)
./setup_user_service.sh
./setup_cinema_service.sh
./setup_payment_service.sh
./setup_booking_service.sh      # Depends on User, Cinema, Payment
./setup_notification_service.sh # Last (consumes events)
```

## 📋 Deployment Sequence

### 1. Infrastructure Services (`./setup_infrastructure.sh`)

**Dependencies:** Docker Desktop running

**What it does:**
- Starts PostgreSQL (Cinema Service database)
- Starts MongoDB (User, Booking, Payment, Notification databases)
- Starts Redis (Notification Service cache)
- Starts RabbitMQ (Event messaging)
- Starts management tools (pgAdmin, MongoDB Express, Redis Commander)

**Access Points:**
- PostgreSQL: `localhost:5432` (postgres/postgres123)
- MongoDB: `localhost:27017` (admin/admin123)
- Redis: `localhost:6379`
- RabbitMQ: `localhost:5672` (Management: http://localhost:15672)

**Troubleshooting:**
```bash
# Check if Docker is running
docker info

# Check container status
docker-compose ps

# View infrastructure logs
docker-compose logs postgres mongodb redis rabbitmq
```

### 2. Kong Gateway (`./setup_kong.sh`)

**Dependencies:** PostgreSQL running

**What it does:**
- Runs Kong database migrations
- Starts Kong Gateway
- Configures API routes for all services
- Sets up CORS and rate limiting plugins

**Access Points:**
- Kong Gateway: `http://localhost:8000`
- Kong Admin API: `http://localhost:8001`
- Kong Manager: `http://localhost:8002`

**API Routes:**
- User Service: `http://localhost:8000/api/users`
- Cinema Service: `http://localhost:8000/api/cinemas`
- Booking Service: `http://localhost:8000/api/bookings`
- Payment Service: `http://localhost:8000/api/payments`
- Notification Service: `http://localhost:8000/api/notifications`

**Troubleshooting:**
```bash
# Check Kong status
curl http://localhost:8001/status

# View Kong logs
docker-compose logs kong

# Check Kong services
curl http://localhost:8001/services

# Check Kong routes
curl http://localhost:8001/routes
```

### 3. User Service (`./setup_user_service.sh`)

**Dependencies:** MongoDB running

**Technology:** Go + MongoDB

**What it does:**
- Builds Go application
- Connects to MongoDB
- Provides user management REST API

**Access Points:**
- Direct: `http://localhost:8080`
- Via Kong: `http://localhost:8000/api/users`
- Health: `http://localhost:8080/health`

**API Endpoints:**
- `POST /api/users` - Create user
- `GET /api/users` - List users
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

**Troubleshooting:**
```bash
# Check service logs
docker-compose logs user-service

# Test health endpoint
curl http://localhost:8080/health

# Check MongoDB connection
docker-compose exec user-service cat /app/main.go | grep mongo

# Restart service
docker-compose restart user-service
```

### 4. Cinema Service (`./setup_cinema_service.sh`)

**Dependencies:** PostgreSQL running

**Technology:** Java Spring Boot + PostgreSQL + gRPC

**What it does:**
- Builds Java application with Maven
- Connects to PostgreSQL
- Provides cinema/movie management via REST and gRPC

**Access Points:**
- REST API: `http://localhost:8081`
- gRPC Server: `localhost:9090`
- Via Kong: `http://localhost:8000/api/cinemas`
- Health: `http://localhost:8081/api/cinemas/health`

**API Endpoints:**
- `GET /api/cinemas` - List cinemas
- `POST /api/cinemas` - Create cinema
- `GET /api/cinemas/:id/movies` - Get movies for cinema
- `POST /api/cinemas/:id/movies` - Add movie to cinema

**gRPC Services:**
- CinemaService - Cinema CRUD
- MovieService - Movie management
- ShowtimeService - Showtime management

**Troubleshooting:**
```bash
# Check service logs
docker-compose logs cinema-service

# Test health endpoint
curl http://localhost:8081/api/cinemas/health

# Check PostgreSQL connection
docker-compose exec postgres psql -U postgres -d cinema_db -c "\dt"

# Test gRPC port
nc -z localhost 9090

# Restart service
docker-compose restart cinema-service
```

### 5. Payment Service (`./setup_payment_service.sh`)

**Dependencies:** MongoDB running

**Technology:** Python FastAPI + MongoDB

**What it does:**
- Builds Python application
- Connects to MongoDB
- Provides payment processing REST API

**Access Points:**
- Direct: `http://localhost:8083`
- Via Kong: `http://localhost:8000/api/payments`
- Health: `http://localhost:8083/health`

**API Endpoints:**
- `POST /api/payments` - Process payment
- `GET /api/payments` - List payments
- `GET /api/payments/:id` - Get payment by ID
- `PUT /api/payments/:id/status` - Update payment status
- `POST /api/payments/:id/refund` - Process refund

**Payment Methods:**
- Credit Card (Visa, MasterCard, Amex)
- Debit Card
- PayPal (simulated)
- Bank Transfer (simulated)

**Troubleshooting:**
```bash
# Check service logs
docker-compose logs payment-service

# Test health endpoint
curl http://localhost:8083/health

# Check MongoDB connection
docker-compose exec mongodb mongosh movie_tickets_db --eval "db.payments.find().limit(5)"

# Run tests
docker-compose exec payment-service python -m pytest

# Restart service
docker-compose restart payment-service
```

### 6. Booking Service (`./setup_booking_service.sh`)

**Dependencies:** MongoDB, RabbitMQ, User Service, Cinema Service, Payment Service

**Technology:** Python FastAPI + GraphQL + MongoDB + gRPC + RabbitMQ

**What it does:**
- Builds Python application
- Connects to all dependencies
- Provides booking management via REST and GraphQL
- Integrates with other services via REST/gRPC
- Publishes events to RabbitMQ

**Access Points:**
- REST API: `http://localhost:8082`
- GraphQL: `http://localhost:8082/graphql`
- Via Kong: `http://localhost:8000/api/bookings`
- Health: `http://localhost:8082/health`

**API Endpoints:**
- `POST /api/bookings` - Create booking
- `GET /api/bookings` - List bookings
- `GET /api/bookings/:id` - Get booking by ID
- `PUT /api/bookings/:id/status` - Update booking status
- `DELETE /api/bookings/:id` - Cancel booking

**GraphQL Operations:**
- Query: `bookings`, `booking(id)`
- Mutation: `createBooking`, `updateBookingStatus`, `cancelBooking`

**Service Integrations:**
- User Service: REST API calls for user validation
- Cinema Service: gRPC calls for movie/showtime data
- Payment Service: REST API calls for payment processing
- Notification Service: RabbitMQ events for notifications

**Troubleshooting:**
```bash
# Check service logs
docker-compose logs booking-service

# Test health endpoint
curl http://localhost:8082/health

# Test GraphQL endpoint
curl -X POST http://localhost:8082/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'

# Check dependencies
curl http://localhost:8080/health  # User Service
curl http://localhost:8081/api/cinemas/health  # Cinema Service
curl http://localhost:8083/health  # Payment Service

# Check RabbitMQ connection
curl -u admin:admin123 http://localhost:15672/api/connections

# Run tests
docker-compose exec booking-service python -m pytest

# Restart service
docker-compose restart booking-service
```

### 7. Notification Service (`./setup_notification_service.sh`)

**Dependencies:** MongoDB, Redis, RabbitMQ

**Technology:** Python FastAPI + MongoDB + Redis + RabbitMQ + SMTP

**What it does:**
- Builds Python application
- Connects to all dependencies
- Provides notification management REST API
- Consumes booking events from RabbitMQ
- Sends email notifications via SMTP

**Access Points:**
- Direct: `http://localhost:8084`
- Via Kong: `http://localhost:8000/api/notifications`
- Health: `http://localhost:8084/health`

**API Endpoints:**
- `POST /api/notifications` - Send notification
- `GET /api/notifications` - List notifications
- `GET /api/notifications/:id` - Get notification by ID
- `PUT /api/notifications/:id` - Update notification status
- `POST /api/notifications/bulk` - Send bulk notifications

**Notification Types:**
- Email notifications (SMTP)
- SMS notifications (simulated)
- Push notifications (simulated)
- In-app notifications

**Event Processing:**
- Consumes from RabbitMQ `booking_events` queue
- Automatic booking confirmation emails
- Payment status notifications
- Booking reminders

**Troubleshooting:**
```bash
# Check service logs
docker-compose logs notification-service

# Test health endpoint
curl http://localhost:8084/health

# Check dependencies
docker-compose exec mongodb mongosh movie_tickets_db --eval "db.notifications.find().limit(5)"
docker-compose exec redis redis-cli ping
curl -u admin:admin123 http://localhost:15672/api/queues

# Check RabbitMQ queues
curl -u admin:admin123 http://localhost:15672/api/queues/%2F/booking_events

# Run tests
docker-compose exec notification-service python -m pytest

# Restart service
docker-compose restart notification-service
```

## 🔧 Management Commands

### Service Status Check
```bash
./check_services_status.sh
```

### Stop All Services
```bash
./stop_all_services.sh
```

### Individual Service Management
```bash
# View logs
docker-compose logs <service-name>

# Restart service
docker-compose restart <service-name>

# Stop service
docker-compose stop <service-name>

# Access service container
docker-compose exec <service-name> bash
```

### Database Access
```bash
# PostgreSQL
docker-compose exec postgres psql -U postgres -d cinema_db

# MongoDB
docker-compose exec mongodb mongosh movie_tickets_db

# Redis
docker-compose exec redis redis-cli
```

## 🌐 Multi-Device Deployment

### Single Device Setup
1. Run all services on one machine using the individual scripts
2. Access via Kong Gateway at `http://localhost:8000`

### Multi-Device Setup

**Device 1 (Infrastructure + Gateway):**
```bash
./setup_infrastructure.sh
./setup_kong.sh
```

**Device 2 (Core Services):**
```bash
# Update docker-compose.yml to point to Device 1 for databases
# Update service configurations with Device 1 IP addresses
./setup_user_service.sh
./setup_cinema_service.sh
```

**Device 3 (Business Services):**
```bash
# Update configurations to point to Device 1 (infrastructure) and Device 2 (core services)
./setup_payment_service.sh
./setup_booking_service.sh
./setup_notification_service.sh
```

### Configuration Updates for Multi-Device
1. Update `docker-compose.yml` with actual IP addresses
2. Update service configuration files with correct URLs
3. Ensure network connectivity between devices
4. Update Kong Gateway routes to point to correct service URLs

## 🧪 Testing Individual Services

### User Service Test
```bash
# Create user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","password":"password123"}'

# List users
curl http://localhost:8080/api/users
```

### Cinema Service Test
```bash
# List cinemas
curl http://localhost:8081/api/cinemas

# Create cinema
curl -X POST http://localhost:8081/api/cinemas \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Cinema","location":"Test City","capacity":100}'
```

### Payment Service Test
```bash
# Process payment
curl -X POST http://localhost:8083/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": "test_booking_123",
    "user_id": "test_user_123",
    "amount": 25.50,
    "currency": "USD",
    "payment_method": "credit_card"
  }'
```

### Booking Service Test
```bash
# Create booking (REST)
curl -X POST http://localhost:8082/api/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "cinema_id": "test_cinema_123",
    "movie_id": "test_movie_123",
    "showtime_id": "test_showtime_123",
    "seats": [{"row": "A", "number": 1}],
    "total_amount": 12.50
  }'

# GraphQL query
curl -X POST http://localhost:8082/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ bookings { id user_id cinema_id status } }"}'
```

### Notification Service Test
```bash
# Send notification
curl -X POST http://localhost:8084/api/notifications \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user_123",
    "type": "booking_confirmation",
    "title": "Booking Confirmed",
    "message": "Your booking has been confirmed.",
    "email": "test@example.com"
  }'
```

## 🚨 Common Issues and Solutions

### Port Conflicts
```bash
# Check port usage
netstat -an | findstr "8080\|8081\|8082\|8083\|8084\|5432\|27017\|6379\|5672"

# Kill process using port
taskkill /PID <process_id> /F
```

### Database Connection Issues
```bash
# Reset databases
docker-compose down -v
docker-compose up -d postgres mongodb redis

# Check database logs
docker-compose logs postgres
docker-compose logs mongodb
```

### Service Build Failures
```bash
# Clean build
docker-compose build --no-cache <service-name>

# Check Dockerfile
cat services/<service-name>/Dockerfile

# Check dependencies
cat services/<service-name>/requirements.txt  # Python services
cat services/<service-name>/pom.xml          # Java services
```

### Network Issues
```bash
# Check Docker network
docker network ls
docker network inspect <network-name>

# Restart Docker
# Stop Docker Desktop, then start again
```

## 📊 Monitoring and Logs

### Centralized Logging
```bash
# All service logs
docker-compose logs -f

# Specific service logs
docker-compose logs -f <service-name>

# Tail last 100 lines
docker-compose logs --tail=100 <service-name>
```

### Health Monitoring
```bash
# Quick health check all services
./check_services_status.sh

# Individual health checks
curl http://localhost:8080/health    # User Service
curl http://localhost:8081/api/cinemas/health  # Cinema Service
curl http://localhost:8082/health    # Booking Service
curl http://localhost:8083/health    # Payment Service
curl http://localhost:8084/health    # Notification Service
```

### Resource Monitoring
```bash
# Docker stats
docker stats

# Container resource usage
docker-compose top

# System resource usage
htop  # or Task Manager on Windows
```

This guide provides comprehensive instructions for individual service deployment, perfect for troubleshooting specific issues and practicing distributed deployment across multiple devices.