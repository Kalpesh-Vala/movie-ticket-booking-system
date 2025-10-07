# Movie Ticket Booking Service

A microservice that orchestrates the movie ticket booking workflow using GraphQL, gRPC, REST APIs, and event-driven messaging.

## 🏗️ Architecture Overview

This service demonstrates multiple communication patterns in a microservices architecture:

- **GraphQL API** - Client-facing API for booking operations
- **gRPC Client** - High-performance communication with Cinema Service for seat operations
- **REST Clients** - Communication with User and Payment services
- **Event Publishing** - Asynchronous messaging via RabbitMQ for decoupled processing

## 🚀 Features

- **Booking Creation** - Complete booking workflow with seat locking
- **Payment Processing** - Integration with payment service
- **Event-Driven Architecture** - Asynchronous event publishing
- **Error Handling** - Comprehensive error handling and rollback mechanisms
- **Seat Management** - Temporary seat locking with automatic expiration
- **User Validation** - Integration with user service for authentication

## 📋 Prerequisites

- Python 3.11+
- MongoDB (for booking data storage)
- RabbitMQ (for event messaging)
- Cinema Service (gRPC - for seat management)
- User Service (REST - for user validation)
- Payment Service (REST - for payment processing)

## 🛠️ Installation

### 1. Install Dependencies

```bash
# Install Python dependencies
pip install -r requirements.txt
```

### 2. Environment Setup

Copy the `.env` file and configure your environment:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```env
# Database Settings
MONGODB_URL=mongodb://admin:password@localhost:27017/movietickets?authSource=admin

# Service URLs
USER_SERVICE_URL=http://localhost:8001
PAYMENT_SERVICE_URL=http://localhost:8002
CINEMA_SERVICE_URL=localhost:50051

# RabbitMQ Settings
RABBITMQ_URL=amqp://admin:password@localhost:5672/

# Booking Configuration
SEAT_LOCK_DURATION=300
PAYMENT_TIMEOUT=300
```

### 3. Start Required Services

Make sure these services are running:

```bash
# Start MongoDB and RabbitMQ
docker-compose up -d mongodb rabbitmq

# Start other microservices
# - Cinema Service (gRPC on port 50051)
# - User Service (REST on port 8001)
# - Payment Service (REST on port 8002)
```

## 🏃‍♂️ Running the Service

### Development Mode

```bash
# Using the startup script (recommended)
./start.sh

# Or directly with uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Production Mode

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

### Docker

```bash
docker build -t booking-service .
docker run -p 8000:8000 booking-service
```

## 🧪 Testing

### Run All Tests

```bash
pytest
```

### Run Specific Test Categories

```bash
# Unit tests only
pytest -m unit

# Integration tests only
pytest -m integration

# Exclude slow tests
pytest -m "not slow"
```

### Run Tests with Coverage

```bash
pytest --cov=app --cov-report=html
```

### Test Individual Components

```bash
# Test models
pytest tests/test_models.py

# Test GraphQL resolvers
pytest tests/test_graphql_resolvers.py

# Test REST clients
pytest tests/test_rest_client.py

# Test gRPC client
pytest tests/test_grpc_client.py

# Test main application
pytest tests/test_main.py
```

## 📡 API Usage

### GraphQL Endpoint

The service exposes a GraphQL API at `http://localhost:8000/graphql`

#### Create Booking

```graphql
mutation CreateBooking {
  createBooking(
    userId: "user_123"
    showtimeId: "showtime_456"
    seatNumbers: ["A1", "A2"]
  ) {
    success
    message
    lockId
    booking {
      id
      userId
      showtimeId
      seats
      totalAmount
      status
      createdAt
    }
  }
}
```

#### Process Payment

```graphql
mutation ProcessPayment {
  processPayment(
    bookingId: "booking_123"
    paymentMethod: "credit_card"
    paymentDetails: "card_token_xyz"
  ) {
    success
    message
    booking {
      id
      status
      paymentTransactionId
    }
  }
}
```

#### Get Booking

```graphql
query GetBooking {
  getBooking(bookingId: "booking_123") {
    id
    userId
    showtimeId
    seats
    totalAmount
    status
    createdAt
    updatedAt
  }
}
```

#### Get User Bookings

```graphql
query GetUserBookings {
  getUserBookings(userId: "user_123") {
    id
    showtimeId
    seats
    totalAmount
    status
    createdAt
  }
}
```

## 🔄 Booking Workflow

The booking process follows this workflow:

1. **User Validation** - Verify user exists via REST call to User Service
2. **Showtime Validation** - Get showtime details via gRPC call to Cinema Service
3. **Seat Locking** - Lock seats temporarily via gRPC (5-minute timeout)
4. **Booking Creation** - Create booking record in MongoDB
5. **Event Publishing** - Publish booking event to RabbitMQ
6. **Payment Processing** - Process payment via REST call to Payment Service
7. **Seat Confirmation** - Confirm permanent seat booking via gRPC
8. **Booking Confirmation** - Update booking status and publish confirmation event

## 📊 Monitoring & Health Checks

### Health Check

```bash
curl http://localhost:8000/health
```

### Application Metrics

The service provides basic health monitoring:

- Database connectivity
- RabbitMQ connectivity
- Service dependencies status

## 🐛 Troubleshooting

### Common Issues

1. **MongoDB Connection Failed**
   ```bash
   # Check if MongoDB is running
   docker ps | grep mongo
   
   # Check MongoDB logs
   docker logs <mongo-container-id>
   ```

2. **RabbitMQ Connection Failed**
   ```bash
   # Check if RabbitMQ is running
   docker ps | grep rabbitmq
   
   # Access RabbitMQ management UI
   # http://localhost:15672 (admin/password)
   ```

3. **gRPC Connection Failed**
   ```bash
   # Check if Cinema Service is running
   netstat -tulpn | grep 50051
   ```

4. **REST Service Connection Failed**
   ```bash
   # Check User Service
   curl http://localhost:8001/health
   
   # Check Payment Service
   curl http://localhost:8002/health
   ```

### Debugging

Enable debug logging:

```bash
export DEBUG=true
python -m uvicorn app.main:app --reload
```

## 📁 Project Structure

```
booking-service/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI application
│   ├── models.py            # Pydantic models
│   ├── database.py          # MongoDB connection
│   ├── graphql_resolvers.py # GraphQL resolvers
│   ├── grpc_client.py       # gRPC client for Cinema Service
│   ├── rest_client.py       # REST clients for User/Payment
│   ├── event_publisher.py   # RabbitMQ event publisher
│   └── config.py            # Configuration settings
├── tests/
│   ├── __init__.py
│   ├── conftest.py          # Test fixtures
│   ├── test_models.py       # Model tests
│   ├── test_graphql_resolvers.py
│   ├── test_grpc_client.py
│   ├── test_rest_client.py
│   └── test_main.py         # Integration tests
├── .env                     # Environment variables
├── .env.example             # Environment template
├── requirements.txt         # Python dependencies
├── pytest.ini              # Test configuration
├── Dockerfile              # Docker configuration
├── start.sh                 # Startup script
└── README.md               # This file
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MONGODB_URL` | MongoDB connection string | `mongodb://admin:password@localhost:27017/movietickets?authSource=admin` |
| `USER_SERVICE_URL` | User service endpoint | `http://localhost:8001` |
| `PAYMENT_SERVICE_URL` | Payment service endpoint | `http://localhost:8002` |
| `CINEMA_SERVICE_URL` | Cinema service gRPC endpoint | `localhost:50051` |
| `RABBITMQ_URL` | RabbitMQ connection string | `amqp://admin:password@localhost:5672/` |
| `SEAT_LOCK_DURATION` | Seat lock timeout (seconds) | `300` |
| `PAYMENT_TIMEOUT` | Payment timeout (seconds) | `300` |
| `API_TIMEOUT` | API call timeout (seconds) | `30` |
| `ENVIRONMENT` | Environment mode | `development` |
| `DEBUG` | Enable debug logging | `true` |

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Run the test suite
6. Submit a pull request

## 📝 License

This project is part of the Movie Ticket Booking System microservices architecture.

## 🔗 Related Services

- [Cinema Service](../cinema-service/) - gRPC service for movie and seat management
- [User Service](../user-service/) - REST service for user management
- [Payment Service](../payment-service/) - REST service for payment processing
- [Notification Service](../notification-service/) - Event consumer for notifications