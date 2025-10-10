# Movie Ticket Booking System - Complete Integration Setup

## 🎯 Overview

This document provides step-by-step instructions to set up and test the complete Movie Ticket Booking System with full integration between all 5 microservices through Kong Gateway.

## 🏗️ System Architecture

```
Client → Kong Gateway (Port 8000) → Microservices
├── User Service (Go + MongoDB)
├── Cinema Service (Java + PostgreSQL)  
├── Booking Service (Python + MongoDB + GraphQL)
├── Payment Service (Python + MongoDB)
└── Notification Service (Python + Redis + MongoDB)
```

## 📋 Prerequisites

- Docker Desktop
- Git Bash (Windows)
- curl command available

## 🚀 Quick Start

### Step 1: Clone and Navigate

```bash
# Clone the repository (if not already done)
git clone <repository-url>
cd movie-ticket-booking-system
```

### Step 2: Start All Services

```bash
# Make scripts executable
chmod +x complete_setup.sh
chmod +x windows_integration_test.sh

# Run complete setup
./complete_setup.sh
```

This script will:
- Start all infrastructure (PostgreSQL, MongoDB, Redis, RabbitMQ)
- Initialize Kong Gateway with database
- Start all 5 microservices
- Start management tools

### Step 3: Verify Services

Wait for all services to start (the script shows progress). You should see:

```
✅ Kong Gateway is ready!
✅ User Service is ready!
✅ Cinema Service is ready!
✅ Payment Service is ready!
✅ Booking Service is ready!
```

### Step 4: Run Integration Test

```bash
# Run the complete integration test
./windows_integration_test.sh
```

This will test the complete workflow:
1. ✅ Register user through Kong
2. ✅ Login and get JWT token
3. ✅ Fetch movies/showtimes
4. ✅ Create booking (GraphQL)
5. ✅ Process payment
6. ✅ Verify RabbitMQ events
7. ✅ Check notification delivery

## 🔧 Service Configuration

### Kong Gateway Routes

All external access goes through Kong Gateway at `http://localhost:8000`:

| Service | Route | Methods | Authentication |
|---------|-------|---------|----------------|
| User Service | `/api/v1/register`, `/api/v1/login` | POST | None |
| User Service | `/api/v1/users/*`, `/api/v1/profile` | GET,PUT,DELETE | JWT |
| Cinema Service | `/api/v1/cinemas`, `/api/v1/movies`, `/api/v1/showtimes` | GET | None |
| Booking Service | `/graphql` | GET,POST | None* |
| Payment Service | `/payment/*` | GET,POST | None |

*JWT authentication is disabled for GraphQL to simplify testing

### Environment Variables

Each service uses these key environment variables:

**Booking Service:**
```env
MONGODB_URI=mongodb://admin:admin123@mongodb:27017/movie_booking?authSource=admin
RABBITMQ_URL=amqp://admin:admin123@rabbitmq:5672/
CINEMA_SERVICE_GRPC_URL=cinema-service:9090
USER_SERVICE_REST_URL=http://user-service:8001
PAYMENT_SERVICE_REST_URL=http://payment-service:8003
```

## 🧪 Manual Testing

### 1. Test User Registration

```bash
curl -X POST http://localhost:8000/api/v1/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "first_name": "Test",
    "last_name": "User"
  }'
```

### 2. Test User Login

```bash
curl -X POST http://localhost:8000/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

Save the JWT token from the response.

### 3. Test Movie Fetching

```bash
curl -X GET http://localhost:8000/api/v1/movies
```

### 4. Test Booking Creation (GraphQL)

```bash
curl -X POST http://localhost:8000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation CreateBooking($userId: String!, $showtimeId: String!, $seatNumbers: [String!]!) { createBooking(userId: $userId, showtimeId: $showtimeId, seatNumbers: $seatNumbers) { success booking { id userId showtimeId seats totalAmount status } message lockId } }",
    "variables": {
      "userId": "YOUR_USER_ID",
      "showtimeId": "1",
      "seatNumbers": ["A1", "A2"]
    }
  }'
```

### 5. Test Payment Processing (GraphQL)

```bash
curl -X POST http://localhost:8000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation ProcessPayment($bookingId: String!, $paymentMethod: String!) { processPayment(bookingId: $bookingId, paymentMethod: $paymentMethod) { success booking { id status } message } }",
    "variables": {
      "bookingId": "YOUR_BOOKING_ID",
      "paymentMethod": "credit_card"
    }
  }'
```

## 📊 Monitoring and Management

### Service URLs

- **Kong Gateway**: http://localhost:8000
- **Kong Admin API**: http://localhost:8001
- **RabbitMQ Management**: http://localhost:15672 (admin/admin123)
- **MongoDB Express**: http://localhost:8081 (admin/admin123)
- **PostgreSQL pgAdmin**: http://localhost:8080 (admin@movietickets.com/admin123)
- **Redis Commander**: http://localhost:8082

### Direct Service Access (Development)

- **User Service**: http://localhost:8001
- **Cinema Service**: http://localhost:8002
- **Booking Service**: http://localhost:8010
- **Payment Service**: http://localhost:8003

### Useful Docker Commands

```bash
# View all container status
docker-compose ps

# View logs for all services
docker-compose logs -f

# View logs for specific service
docker logs movie-booking-service -f
docker logs movie-notification-service -f
docker logs movie-payment-service -f

# Restart specific service
docker-compose restart booking-service

# Stop all services
docker-compose down

# Stop and remove all data
docker-compose down -v
```

### Check RabbitMQ Queues

```bash
# List all queues
curl -u admin:admin123 http://localhost:15672/api/queues

# Check specific queue
curl -u admin:admin123 http://localhost:15672/api/queues/%2F/notification.booking_events
```

## 🐛 Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker logs and ensure ports are available
2. **Kong not routing**: Verify Kong configuration with `curl http://localhost:8001/services`
3. **Database connection issues**: Ensure containers are healthy with `docker-compose ps`
4. **RabbitMQ events not flowing**: Check exchange bindings in management UI

### Health Checks

```bash
# Check all service health
curl http://localhost:8001/health         # User Service
curl http://localhost:8002/actuator/health # Cinema Service  
curl http://localhost:8010/health         # Booking Service
curl http://localhost:8003/health         # Payment Service
curl http://localhost:8000                # Kong Gateway
```

### Reset System

```bash
# Complete reset
docker-compose down -v
docker system prune -f
./complete_setup.sh
```

## 🎯 Testing Workflow

The complete workflow demonstrates:

1. **Authentication**: User registration and JWT token generation
2. **Data Fetching**: Movie and showtime retrieval via REST
3. **Seat Locking**: High-performance gRPC communication with Cinema Service
4. **Payment Processing**: REST API integration with Payment Service
5. **Event Publishing**: Asynchronous RabbitMQ messaging
6. **Notifications**: Email/SMS simulation via Notification Service
7. **Data Persistence**: MongoDB and PostgreSQL integration

## 📈 Success Indicators

- ✅ All services report healthy status
- ✅ Kong Gateway routes requests correctly
- ✅ User can register and login
- ✅ Movies and showtimes are accessible
- ✅ Bookings can be created and confirmed
- ✅ Payments are processed successfully
- ✅ RabbitMQ events are published and consumed
- ✅ Notification service logs show email processing

## 🚀 Production Considerations

For production deployment:

1. Enable JWT authentication for all protected routes
2. Use proper SSL/TLS certificates
3. Configure rate limiting appropriately
4. Set up proper monitoring and alerting
5. Use production database credentials
6. Configure email/SMS providers for notifications
7. Set up proper logging and observability

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section
2. Review Docker logs for error messages
3. Verify Kong configuration
4. Check RabbitMQ management interface
5. Ensure all environment variables are correct

---

🎉 **Success!** You now have a fully functional, production-grade microservices architecture with Kong Gateway, demonstrating modern distributed system patterns including GraphQL, gRPC, REST APIs, event-driven messaging, and polyglot persistence.