# Booking Service API Documentation

## Overview

The Booking Service is a FastAPI-based microservice with GraphQL API that orchestrates the complete movie ticket booking workflow. It integrates with multiple services using different communication patterns:

- **GraphQL API** for client interactions
- **gRPC** for high-performance cinema service communication
- **REST** for user and payment service integration  
- **RabbitMQ** for event-driven notifications

## Service Information

- **Base URL**: `http://localhost:8004`
- **GraphQL Endpoint**: `/graphql`
- **GraphQL Playground**: `http://localhost:8004/graphql` (GET request)
- **Technology**: Python + FastAPI + Strawberry GraphQL
- **Database**: MongoDB
- **Event System**: RabbitMQ

## Architecture Overview

```
Client → Kong Gateway → Booking Service (GraphQL)
    ↓
    ├── User Service (REST API)
    ├── Cinema Service (gRPC)
    ├── Payment Service (REST API)  
    └── RabbitMQ Events → Notification Service
```

## Table of Contents
- [Health Check](#health-check)
- [GraphQL Schema](#graphql-schema)
- [Query Operations](#query-operations)
- [Mutation Operations](#mutation-operations)
- [Data Models](#data-models)
- [Workflow Examples](#workflow-examples)
- [Error Handling](#error-handling)
- [Testing](#testing)

---

## Health Check

### Get Service Health
```http
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "booking-service"
}
```

### Root Endpoint
```http
GET /
```

**Response:**
```json
{
  "message": "Movie Ticket Booking Service",
  "graphql_endpoint": "/graphql"
}
```

---

## GraphQL Schema

### Access GraphQL Playground
```http
GET /graphql
```

### GraphQL Introspection Query
```graphql
query IntrospectionQuery {
  __schema {
    types {
      name
      kind
      description
      fields {
        name
        type {
          name
          kind
        }
      }
    }
  }
}
```

---

## Data Models

### BookingType
```graphql
type BookingType {
  id: String!
  user_id: String!
  showtime_id: String!
  seats: [String!]!
  total_amount: Float!
  status: String!
  created_at: DateTime!
  updated_at: DateTime!
}
```

### CreateBookingResponse
```graphql
type CreateBookingResponse {
  success: Boolean!
  booking: BookingType
  message: String!
  lock_id: String
}
```

### Booking Status Values
- `pending_payment` - Booking created, awaiting payment
- `confirmed` - Payment successful, seats confirmed
- `cancelled` - Booking cancelled by user or system
- `refund_pending` - Refund initiated, processing
- `refunded` - Refund completed

---

## Query Operations

### 1. Get Booking by ID

**Query:**
```graphql
query GetBooking($bookingId: String!) {
  get_booking(booking_id: $bookingId) {
    id
    user_id
    showtime_id
    seats
    total_amount
    status
    created_at
    updated_at
  }
}
```

**Variables:**
```json
{
  "bookingId": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Example Response:**
```json
{
  "data": {
    "get_booking": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "user_id": "507f1f77bcf86cd799439011",
      "showtime_id": "showtime_123",
      "seats": ["A1", "A2"],
      "total_amount": 30.0,
      "status": "confirmed",
      "created_at": "2024-12-15T10:30:00Z",
      "updated_at": "2024-12-15T10:35:00Z"
    }
  }
}
```

### 2. Get User Bookings

**Query:**
```graphql
query GetUserBookings($userId: String!) {
  get_user_bookings(user_id: $userId) {
    id
    showtime_id
    seats
    total_amount
    status
    created_at
    updated_at
  }
}
```

**Variables:**
```json
{
  "userId": "507f1f77bcf86cd799439011"
}
```

**Example Response:**
```json
{
  "data": {
    "get_user_bookings": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "showtime_id": "showtime_123",
        "seats": ["A1", "A2"],
        "total_amount": 30.0,
        "status": "confirmed",
        "created_at": "2024-12-15T10:30:00Z",
        "updated_at": "2024-12-15T10:35:00Z"
      }
    ]
  }
}
```

---

## Mutation Operations

### 1. Create Booking

**Critical Orchestration Workflow:**
1. Validates user via User Service (REST)
2. Gets showtime details via Cinema Service (gRPC)
3. Locks seats via Cinema Service (gRPC) 
4. Creates booking record in MongoDB
5. Publishes event to RabbitMQ for notifications

**Mutation:**
```graphql
mutation CreateBooking($userId: String!, $showtimeId: String!, $seatNumbers: [String!]!) {
  create_booking(
    user_id: $userId,
    showtime_id: $showtimeId,
    seat_numbers: $seatNumbers
  ) {
    success
    booking {
      id
      user_id
      showtime_id
      seats
      total_amount
      status
      created_at
      updated_at
    }
    message
    lock_id
  }
}
```

**Variables:**
```json
{
  "userId": "507f1f77bcf86cd799439011",
  "showtimeId": "showtime_123",
  "seatNumbers": ["A1", "A2"]
}
```

**Success Response:**
```json
{
  "data": {
    "create_booking": {
      "success": true,
      "booking": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "user_id": "507f1f77bcf86cd799439011",
        "showtime_id": "showtime_123",
        "seats": ["A1", "A2"],
        "total_amount": 30.0,
        "status": "pending_payment",
        "created_at": "2024-12-15T10:30:00Z",
        "updated_at": "2024-12-15T10:30:00Z"
      },
      "message": "Booking created successfully. Please complete payment within 5 minutes.",
      "lock_id": "lock_550e8400-e29b-41d4-a716-446655440001"
    }
  }
}
```

**Error Response:**
```json
{
  "data": {
    "create_booking": {
      "success": false,
      "booking": null,
      "message": "Failed to lock seats: Seats A1, A2 are already booked",
      "lock_id": null
    }
  }
}
```

### 2. Process Payment

**Complete Payment Orchestration Workflow:**
1. Validates booking exists and is in pending_payment status
2. Checks seat lock expiry
3. Gets user details via User Service (REST)
4. Gets showtime details via Cinema Service (gRPC)
5. Processes payment via Payment Service (REST)
6. Confirms seat booking via Cinema Service (gRPC)
7. Updates booking status to confirmed
8. Publishes booking confirmation event to RabbitMQ

**Mutation:**
```graphql
mutation ProcessPayment($bookingId: String!, $paymentMethod: String, $cardDetails: String) {
  process_payment(
    booking_id: $bookingId,
    payment_method: $paymentMethod,
    card_details: $cardDetails
  ) {
    success
    booking {
      id
      status
      updated_at
    }
    message
  }
}
```

**Variables:**
```json
{
  "bookingId": "550e8400-e29b-41d4-a716-446655440000",
  "paymentMethod": "credit_card",
  "cardDetails": null
}
```

**Success Response:**
```json
{
  "data": {
    "process_payment": {
      "success": true,
      "booking": {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "status": "confirmed",
        "updated_at": "2024-12-15T10:35:00Z"
      },
      "message": "Booking confirmed successfully! Check your email for confirmation details."
    }
  }
}
```

**Error Responses:**

*Booking Not Found:*
```json
{
  "data": {
    "process_payment": {
      "success": false,
      "booking": null,
      "message": "Booking not found"
    }
  }
}
```

*Payment Timeout:*
```json
{
  "data": {
    "process_payment": {
      "success": false,
      "booking": null,
      "message": "Booking expired. Seats are no longer reserved."
    }
  }
}
```

*Payment Failed:*
```json
{
  "data": {
    "process_payment": {
      "success": false,
      "booking": null,
      "message": "Payment failed: Insufficient funds"
    }
  }
}
```

---

## Service Integration Details

### User Service Integration (REST)
- **Endpoint**: `GET /api/v1/users/{user_id}`
- **Purpose**: Validate user exists before booking
- **Response**: User details including email for notifications

### Cinema Service Integration (gRPC)
- **Methods**:
  - `GetShowtimeDetails` - Get movie, cinema, pricing info
  - `LockSeats` - Reserve seats with timeout
  - `ConfirmSeatBooking` - Finalize seat reservation
- **Benefits**: High-performance, type-safe communication for critical operations

### Payment Service Integration (REST)
- **Endpoint**: `POST /api/payments/process`
- **Purpose**: Process credit card/PayPal payments
- **Response**: Transaction ID and payment status

### Event Publishing (RabbitMQ)
- **Exchange**: `movie_app_events`
- **Routing Keys**:
  - `booking.pending_payment` - Booking created, awaiting payment
  - `booking.confirmed` - Payment successful, booking confirmed
  - `booking.refunded` - Refund processed due to failure

---

## Complete Booking Workflow Example

### Step 1: Create Booking
```bash
curl -X POST http://localhost:8004/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { create_booking(user_id: \"user123\", showtime_id: \"show456\", seat_numbers: [\"A1\", \"A2\"]) { success booking { id status lock_id } message } }"
  }'
```

### Step 2: Process Payment (within 5 minutes)
```bash
curl -X POST http://localhost:8004/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation { process_payment(booking_id: \"booking_id_from_step1\") { success booking { id status } message } }"
  }'
```

### Step 3: Verify Booking
```bash
curl -X POST http://localhost:8004/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query { get_booking(booking_id: \"booking_id_from_step1\") { id status seats total_amount } }"
  }'
```

---

## Error Handling

### GraphQL Error Format
```json
{
  "errors": [
    {
      "message": "User not found",
      "locations": [{"line": 2, "column": 3}],
      "path": ["create_booking"]
    }
  ],
  "data": {
    "create_booking": null
  }
}
```

### Common Error Scenarios

1. **User Not Found**
   - Message: "User not found"
   - Cause: Invalid user_id in booking request

2. **Showtime Not Found**
   - Message: "Showtime not found"
   - Cause: Invalid showtime_id or showtime no longer available

3. **Seats Unavailable**
   - Message: "Failed to lock seats: Seats A1, A2 are already booked"
   - Cause: Selected seats already reserved by another user

4. **Payment Timeout**
   - Message: "Booking expired. Seats are no longer reserved."
   - Cause: Payment not completed within 5-minute window

5. **Payment Failed**
   - Message: "Payment failed: [specific reason]"
   - Cause: Payment processing error (insufficient funds, invalid card, etc.)

6. **Seat Confirmation Failed**
   - Message: "Payment processed but seat confirmation failed. Refund initiated."
   - Cause: Edge case where payment succeeds but seat locking fails

---

## Business Rules

### Seat Locking
- **Lock Duration**: 5 minutes (300 seconds)
- **Auto-Release**: Seats automatically released if payment not completed
- **Concurrent Protection**: gRPC-based pessimistic locking prevents double booking

### Payment Processing
- **Timeout Handling**: Expired bookings are cancelled automatically
- **Refund Logic**: Automatic refund initiation for payment/confirmation mismatches
- **Transaction Integrity**: Full rollback on any step failure

### Event Publishing
- **Asynchronous Notifications**: Non-blocking event publishing to RabbitMQ
- **Event Types**: pending_payment, confirmed, refunded
- **Retry Logic**: Built-in retry mechanism for failed event publishing

---

## Configuration

### Environment Variables
```env
# Service Configuration
PORT=8004
MONGODB_URI=mongodb://admin:admin123@localhost:27017/movie_booking?authSource=admin

# Service Integration URLs
USER_SERVICE_URL=http://user-service:8080
PAYMENT_SERVICE_URL=http://payment-service:8003
CINEMA_SERVICE_GRPC_URL=cinema-service:9090

# RabbitMQ Configuration
RABBITMQ_URL=amqp://admin:admin123@localhost:5672/
RABBITMQ_EXCHANGE=movie_app_events
```

### Database Collections
- **bookings** - Main booking records
- **booking_events** - Event audit trail (optional)

---

## Testing

### GraphQL Playground
Access the interactive GraphQL playground at:
```
http://localhost:8004/graphql
```

### Sample Test Queries

**Test Health:**
```bash
curl http://localhost:8004/health
```

**Test Schema Introspection:**
```bash
curl -X POST http://localhost:8004/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name } } }"}'
```

**Test Complete Booking Flow:**
```bash
# 1. Create booking
curl -X POST http://localhost:8004/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation CreateBooking($userId: String!, $showtimeId: String!, $seats: [String!]!) { create_booking(user_id: $userId, showtime_id: $showtimeId, seat_numbers: $seats) { success booking { id status } message } }",
    "variables": {
      "userId": "test_user_123",
      "showtimeId": "test_showtime_456", 
      "seats": ["A1", "A2"]
    }
  }'

# 2. Process payment (use booking ID from step 1)
curl -X POST http://localhost:8004/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "mutation ProcessPayment($bookingId: String!) { process_payment(booking_id: $bookingId) { success booking { status } message } }",
    "variables": {
      "bookingId": "BOOKING_ID_FROM_STEP_1"
    }
  }'
```

### Integration Tests
Run the comprehensive test suite:
```bash
cd services/booking-service
python -m pytest tests/ -v
```

### Performance Testing
- **Concurrent Booking Tests**: Verify seat locking works under load
- **Payment Timeout Tests**: Verify proper cleanup of expired bookings  
- **Event Publishing Tests**: Verify RabbitMQ integration reliability

---

## Monitoring & Observability

### Key Metrics
- **Booking Creation Rate**: Bookings created per minute
- **Payment Success Rate**: Percentage of successful payments
- **Seat Lock Utilization**: Active vs expired locks
- **Service Integration Latency**: Response times for gRPC/REST calls
- **Event Publishing Rate**: Events published to RabbitMQ

### Health Checks
- **Database Connectivity**: MongoDB connection status
- **Service Dependencies**: User, Cinema, Payment service availability
- **Message Queue**: RabbitMQ connection and queue health
- **gRPC Client**: Cinema service gRPC connectivity

### Logging
- **Booking Lifecycle**: Complete audit trail for each booking
- **Service Integration**: Log all external service calls
- **Error Scenarios**: Detailed error logging with context
- **Performance Metrics**: Response times and resource usage

---

## Production Considerations

### Security
- **Input Validation**: Validate all GraphQL inputs
- **Authentication**: Implement JWT token validation
- **Rate Limiting**: Prevent booking abuse
- **Data Sanitization**: Prevent injection attacks

### Scalability  
- **Horizontal Scaling**: Stateless service design
- **Database Optimization**: Proper indexing for booking queries
- **Connection Pooling**: Efficient database connections
- **Circuit Breakers**: Fault tolerance for service dependencies

### Reliability
- **Graceful Degradation**: Fallback mechanisms for service failures
- **Transaction Safety**: Proper rollback on partial failures
- **Event Delivery**: Ensure notification events are delivered
- **Monitoring**: Comprehensive observability and alerting

---

This documentation provides complete coverage of the Booking Service GraphQL API with practical examples for testing via Kong Gateway and understanding the complex orchestration workflows that make the booking system reliable and scalable.