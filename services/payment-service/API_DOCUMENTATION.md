# Payment Service API Documentation

## Overview

The Payment Service is a FastAPI-based microservice that handles payment processing for movie ticket bookings. It integrates with RabbitMQ to publish payment events and MongoDB for transaction logging. The service supports multiple payment methods and provides comprehensive transaction management.

## Base URLs

**Direct Service Access:**
```
http://localhost:8003
```

**Kong Gateway Access (Recommended):**
```
http://localhost:8000/api/payments
```

## Authentication

Currently, the service operates without authentication. In production, implement JWT or API key authentication.

## API Endpoints

### 1. Health Check

#### `GET /health`

Check if the payment service is running and healthy.

**Kong Gateway Route:** `GET /health/payment`

**Response:**

```json
{
  "status": "healthy",
  "service": "payment-service"
}
```

**Status Codes:**

- `200 OK` - Service is healthy

---

### 2. Process Payment

#### `POST /payments`

Process a payment for a movie ticket booking.

**Kong Gateway Route:** `POST /api/payments`

**Request Body:**

```json
{
  "booking_id": "BOOK-789012",
  "user_id": "user_123",
  "amount": 25.5,
  "payment_method": "credit_card",
  "payment_details": {
    "card_number": "4111111111111111",
    "expiry_month": "12",
    "expiry_year": "2025",
    "cvv": "123",
    "cardholder_name": "John Doe"
  }
}
```

**Request Schema:**

```python
class PaymentRequest(BaseModel):
    booking_id: str
    user_id: str
    amount: float
    payment_method: PaymentMethod  # "credit_card", "debit_card", "digital_wallet", "net_banking"
    payment_details: dict  # Card details, wallet info, etc.

class PaymentMethod(str, Enum):
    CREDIT_CARD = "credit_card"
    DEBIT_CARD = "debit_card"
    DIGITAL_WALLET = "digital_wallet"
    NET_BANKING = "net_banking"
```

**Success Response (200):**

```json
{
  "success": true,
  "transaction_id": "08d50720-08ba-4876-9d98-002f6b25b07e",
  "message": "Payment processed successfully",
  "status": "success"
}
```

**Failure Response (200):**

```json
{
  "success": false,
  "transaction_id": null,
  "message": "Payment failed: Insufficient funds",
  "status": "failed"
}
```

**Status Codes:**

- `200 OK` - Payment processed (check response.success for actual result)
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

---

### 3. Get Transaction Details

#### `GET /payments/{transaction_id}`

Get details of a specific transaction by ID.

**Kong Gateway Route:** `GET /api/payments/{transaction_id}`

**Path Parameters:**

- `transaction_id` (string) - The transaction ID to retrieve

**Response:**

```json
{
  "_id": "675cdb0d6674d8c6d5c8f2e3",
  "transaction_id": "08d50720-08ba-4876-9d98-002f6b25b07e",
  "booking_id": "KONG-BOOK-1734353677",
  "amount": 25.5,
  "payment_method": "credit_card",
  "status": "success",
  "payment_details": {
    "card_number": "****-****-****-1111",
    "expiry_month": "12",
    "expiry_year": "2025",
    "cardholder_name": "John Doe"
  },
  "created_at": "2024-12-16T13:21:17.056000",
  "updated_at": "2024-12-16T13:21:17.056000",
  "gateway_response": {
    "transaction_reference": "txn_abc123def456",
    "gateway_transaction_id": "gw_78901234",
    "auth_code": "AUTH789",
    "processor_response": "Approved"
  }
}
```

**Status Codes:**

- `200 OK` - Transaction found
- `404 Not Found` - Transaction not found

---

### 4. Get Booking Transactions

#### `GET /payments/booking/{booking_id}`

Get all transactions associated with a specific booking.

**Kong Gateway Route:** `GET /api/payments/booking/{booking_id}`

**Path Parameters:**

- `booking_id` (string) - The booking ID to retrieve transactions for

**Response:**

```json
[
  {
    "transaction_id": "08d50720-08ba-4876-9d98-002f6b25b07e",
    "booking_id": "BOOK-789012",
    "amount": 25.5,
    "payment_method": "credit_card",
    "status": "success",
    "created_at": "2024-12-16T13:21:17.056000"
  }
]
```

**Status Codes:**

- `200 OK` - Transactions retrieved (empty array if none found)

---

### 5. Process Refund

#### `POST /refunds`

Process a refund for a previous successful transaction.

**Kong Gateway Route:** `POST /api/refunds`

**Query Parameters:**

- `transaction_id` (required) - Original transaction ID to refund
- `reason` (required) - Reason for the refund

**Example Request:**

```bash
POST /refunds?transaction_id=08d50720-08ba-4876-9d98-002f6b25b07e&reason=Customer%20cancellation
```

**Success Response (200):**

```json
{
  "success": true,
  "refund_transaction_id": "def456gh-ijkl-9012-mnop-345678901234",
  "message": "Refund processed successfully"
}
```

**Error Response (400):**

```json
{
  "detail": "Can only refund successful transactions"
}
```

**Error Response (404):**

```json
{
  "detail": "Original transaction not found"
}
```

**Status Codes:**

- `200 OK` - Refund processed successfully
- `400 Bad Request` - Invalid refund request (e.g., transaction not successful)
- `404 Not Found` - Original transaction not found
- `422 Unprocessable Entity` - Validation errors

---

## Payment Methods

The service supports the following payment methods:

| Method | Enum Value | Status | Description |
|--------|------------|--------|-------------|
| Credit Card | `credit_card` | ✅ Active | Visa, MasterCard, American Express |
| Debit Card | `debit_card` | ✅ Active | Bank debit cards |
| Digital Wallet | `digital_wallet` | ✅ Active | PayPal, Apple Pay, Google Pay |
| Net Banking | `net_banking` | ✅ Active | Direct bank transfers |

### Payment Details Structure

**Credit Card:**
```json
{
  "card_number": "4111111111111111",
  "expiry_month": "12",
  "expiry_year": "2025",
  "cvv": "123",
  "cardholder_name": "John Doe"
}
```

**Digital Wallet:**
```json
{
  "wallet_type": "paypal",
  "wallet_id": "user@example.com",
  "payment_id": "PAYID-123456789"
}
```

**Net Banking:**
```json
{
  "bank_code": "HDFC0001234",
  "account_number": "1234567890",
  "ifsc_code": "HDFC0001234"
}
```

---

## Event Publishing

The Payment Service publishes events to RabbitMQ for other services to consume.

### RabbitMQ Configuration

- **Exchange:** `movie_app_events` (topic exchange)
- **Queue:** `payment.processing_queue`
- **Routing Keys:**
  - `payment.success` - Payment successful
  - `payment.failed` - Payment failed
  - `payment.refunded` - Refund processed

### Event Schemas

#### Payment Success Event

```json
{
  "event_id": "evt_payment_001",
  "event_type": "payment.success",
  "booking_id": "BOOK-789012",
  "transaction_id": "08d50720-08ba-4876-9d98-002f6b25b07e",
  "amount": 25.5,
  "payment_method": "credit_card",
  "gateway_response": {
    "transaction_reference": "txn_abc123def456",
    "gateway_transaction_id": "gw_78901234",
    "auth_code": "AUTH789"
  },
  "user_id": "user_123",
  "timestamp": "2024-12-16T13:21:17Z"
}
```

#### Payment Failed Event

```json
{
  "event_id": "evt_payment_002",
  "event_type": "payment.failed",
  "booking_id": "BOOK-789012",
  "transaction_id": "08d50720-08ba-4876-9d98-002f6b25b07e",
  "amount": 25.5,
  "payment_method": "credit_card",
  "failure_reason": "Insufficient funds",
  "gateway_response": {
    "error_code": "INSUFFICIENT_FUNDS",
    "error_message": "Not enough balance"
  },
  "user_id": "user_123",
  "timestamp": "2024-12-16T13:21:17Z"
}
```

#### Payment Refund Event

```json
{
  "event_id": "evt_payment_003",
  "event_type": "payment.refunded",
  "booking_id": "BOOK-789012",
  "original_transaction_id": "08d50720-08ba-4876-9d98-002f6b25b07e",
  "refund_transaction_id": "def456gh-ijkl-9012-mnop-345678901234",
  "refund_amount": 25.5,
  "reason": "Customer cancellation"
}
```

---

## Error Handling

### Error Response Format

```json
{
  "detail": "Original transaction not found"
}
```

### Common Error Scenarios

| Scenario | HTTP Status | Response |
|----------|-------------|----------|
| Invalid payment data | 422 | Validation error details |
| Transaction not found | 404 | `{"detail": "Transaction not found"}` |
| Refund not allowed | 400 | `{"detail": "Can only refund successful transactions"}` |
| Payment processing error | 200 | `{"success": false, "message": "Payment failed: ..."}` |
| Service unavailable | 500 | `{"detail": "Internal server error"}` |

### Payment Simulation Logic

The service simulates different payment outcomes based on amount:

- **Amount ending in 0**: Payment succeeds
- **Amount ending in 1**: Payment fails (insufficient funds)
- **Amount ending in 2**: Payment fails (card declined)
- **Amount ending in 3**: Payment fails (card expired)
- **Other amounts**: Random success/failure

---

## Rate Limiting

- **Kong Gateway**: 1000 requests per minute (configured in kong.yml)
- **CORS**: Enabled for all origins
- **Headers:**
  - `X-Kong-Upstream-Latency`
  - `X-Kong-Proxy-Latency`

---

## Examples

### Process Credit Card Payment (via Kong Gateway)

```bash
curl -X POST http://localhost:8000/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": "BOOK-789012",
    "user_id": "user_123",
    "amount": 25.50,
    "payment_method": "credit_card",
    "payment_details": {
      "card_number": "4111111111111111",
      "expiry_month": "12",
      "expiry_year": "2025",
      "cvv": "123",
      "cardholder_name": "John Doe"
    }
  }'
```

### Process Digital Wallet Payment

```bash
curl -X POST http://localhost:8000/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": "BOOK-789013",
    "user_id": "user_123",
    "amount": 30.00,
    "payment_method": "digital_wallet",
    "payment_details": {
      "wallet_type": "paypal",
      "wallet_id": "user@example.com",
      "payment_id": "PAYID-123456789"
    }
  }'
```

### Get Transaction Details

```bash
curl http://localhost:8000/api/payments/08d50720-08ba-4876-9d98-002f6b25b07e
```

### Process Refund

```bash
curl -X POST "http://localhost:8000/api/refunds?transaction_id=08d50720-08ba-4876-9d98-002f6b25b07e&reason=Customer%20cancellation"
```

### Health Check

```bash
# Via Kong Gateway
curl http://localhost:8000/health/payment

# Direct service
curl http://localhost:8003/health
```

---

## Testing

### Test Endpoints

```bash
# Health check (Kong Gateway)
curl http://localhost:8000/health/payment

# Health check (Direct)
curl http://localhost:8003/health

# Test payment processing (will succeed with amount ending in 0)
curl -X POST http://localhost:8000/api/payments \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": "TEST-123", 
    "user_id": "test-user", 
    "amount": 10.00, 
    "payment_method": "credit_card",
    "payment_details": {
      "card_number": "4111111111111111",
      "expiry_month": "12", 
      "expiry_year": "2025",
      "cvv": "123",
      "cardholder_name": "Test User"
    }
  }'
```

### Test Cards for Simulation

| Card Number | Expected Result |
|-------------|----------------|
| 4111111111111111 | Success (if amount ends in 0) |
| 4000000000000002 | Declined (if amount ends in 2) |
| 5555555555554444 | Success (if amount ends in 0) |

### Test Amounts

| Amount | Expected Result |
|--------|----------------|
| 10.00 | Payment Success |
| 15.01 | Payment Failed (Insufficient funds) |
| 20.02 | Payment Failed (Card declined) |
| 25.03 | Payment Failed (Card expired) |
| 30.05 | Random success/failure |

---

## Security Considerations

1. **PCI Compliance** - In production, ensure PCI DSS compliance
2. **Card Data** - Never log or store card details
3. **HTTPS** - Always use HTTPS in production
4. **Input Validation** - Validate all input data
5. **Rate Limiting** - Implement proper rate limiting
6. **Audit Logging** - Log all payment transactions
7. **Encryption** - Encrypt sensitive data in transit and at rest

---

## Monitoring & Logging

### Metrics to Monitor

- Payment success rate
- Average processing time
- Error rates by type
- Transaction volume
- Gateway response times

### Log Events

- Payment attempts
- Successful payments
- Failed payments
- Refund requests
- Gateway communications
- Error conditions

---

## Configuration

### Environment Variables

```env
# Payment Service Configuration
PAYMENT_SERVICE_PORT=8003
MONGODB_URI=mongodb://localhost:27017

# RabbitMQ Configuration (Optional)
RABBITMQ_URL=amqp://localhost:5672/
RABBITMQ_EXCHANGE=movie_app_events

# Logging
LOG_LEVEL=INFO
```

### Kong Gateway Integration

The service is fully integrated with Kong Gateway:

- **Service URL**: `http://payment-service:8003/payments` (with `/payments` path)
- **Health Check URL**: `http://payment-service:8003` (separate service)
- **Strip Path**: Enabled for payment routes
- **Rate Limiting**: 1000 requests/minute
- **CORS**: Enabled

### MongoDB Collections

The service uses the following MongoDB collections:

- **transaction_logs**: Stores all payment transactions
  - Fields: `transaction_id`, `booking_id`, `amount`, `payment_method`, `status`, `payment_details`, `created_at`, `updated_at`, `gateway_response`, `failure_reason`

---

## Deployment

### Docker Deployment

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8003
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8003"]
```

### Docker Compose Integration

The service is integrated into the main docker-compose.yml:

```yaml
payment-service:
  build: ./services/payment-service
  container_name: payment-service
  ports:
    - "8003:8003"
  environment:
    - MONGODB_URI=mongodb://mongodb:27017
    - RABBITMQ_URL=amqp://rabbitmq:5672/
  depends_on:
    - mongodb
    - rabbitmq
  networks:
    - movie-booking-network
```
