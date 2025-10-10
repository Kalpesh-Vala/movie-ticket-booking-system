# Payment Service API Documentation

## Overview

The Payment Service is a FastAPI-based microservice that handles payment processing for movie ticket bookings. It integrates with RabbitMQ to publish payment events and supports various payment methods.

## Base URL

```
http://localhost:8003
```

## Authentication

Currently, the service operates without authentication. In production, implement JWT or API key authentication.

## API Endpoints

### 1. Health Check

#### `GET /health`

Check if the payment service is running and healthy.

**Response:**

```json
{
  "status": "healthy",
  "service": "payment-service",
  "timestamp": "2024-12-15T10:30:00Z"
}
```

**Status Codes:**

- `200 OK` - Service is healthy

---

### 2. Process Payment

#### `POST /payment/process`

Process a payment for a movie ticket booking.

**Request Body:**

```json
{
  "user_id": "user_123",
  "booking_id": "BOOK-789012",
  "amount": 25.5,
  "payment_method": "credit_card",
  "card_details": {
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
    user_id: str
    booking_id: str
    amount: float
    payment_method: str  # "credit_card", "debit_card", "paypal", "stripe"
    card_details: Optional[CardDetails] = None
    paypal_details: Optional[PayPalDetails] = None

class CardDetails(BaseModel):
    card_number: str
    expiry_month: str
    expiry_year: str
    cvv: str
    cardholder_name: str

class PayPalDetails(BaseModel):
    email: str
    payment_id: str
```

**Success Response (200):**

```json
{
  "status": "success",
  "transaction_id": "TXN-456789",
  "booking_id": "BOOK-789012",
  "amount": 25.5,
  "payment_method": "credit_card",
  "processed_at": "2024-12-15T10:30:45Z",
  "message": "Payment processed successfully"
}
```

**Failure Response (400):**

```json
{
  "status": "failed",
  "booking_id": "BOOK-789012",
  "amount": 25.5,
  "payment_method": "credit_card",
  "error_code": "INSUFFICIENT_FUNDS",
  "error_message": "Insufficient funds in account",
  "processed_at": "2024-12-15T10:30:45Z"
}
```

**Status Codes:**

- `200 OK` - Payment processed successfully
- `400 Bad Request` - Payment failed or invalid request
- `422 Unprocessable Entity` - Validation errors
- `500 Internal Server Error` - Server error

---

### 3. Refund Payment

#### `POST /payment/refund`

Process a refund for a previous payment.

**Request Body:**

```json
{
  "booking_id": "BOOK-789012",
  "original_transaction_id": "TXN-456789",
  "refund_amount": 25.5,
  "reason": "Customer cancellation",
  "user_id": "user_123"
}
```

**Request Schema:**

```python
class RefundRequest(BaseModel):
    booking_id: str
    original_transaction_id: str
    refund_amount: float
    reason: str
    user_id: str
```

**Success Response (200):**

```json
{
  "status": "success",
  "refund_transaction_id": "REF-123456",
  "original_transaction_id": "TXN-456789",
  "booking_id": "BOOK-789012",
  "refund_amount": 25.5,
  "processed_at": "2024-12-15T10:35:00Z",
  "message": "Refund processed successfully"
}
```

**Status Codes:**

- `200 OK` - Refund processed successfully
- `400 Bad Request` - Invalid refund request
- `404 Not Found` - Original transaction not found
- `422 Unprocessable Entity` - Validation errors

---

### 4. Payment Status

#### `GET /payment/status/{transaction_id}`

Get the status of a payment transaction.

**Path Parameters:**

- `transaction_id` (string) - The transaction ID to check

**Response:**

```json
{
  "transaction_id": "TXN-456789",
  "status": "completed",
  "booking_id": "BOOK-789012",
  "amount": 25.5,
  "payment_method": "credit_card",
  "created_at": "2024-12-15T10:30:45Z",
  "processed_at": "2024-12-15T10:30:47Z"
}
```

**Status Values:**

- `pending` - Payment is being processed
- `completed` - Payment successful
- `failed` - Payment failed
- `refunded` - Payment has been refunded

**Status Codes:**

- `200 OK` - Transaction found
- `404 Not Found` - Transaction not found

---

### 5. Payment Methods

#### `GET /payment/methods`

Get available payment methods.

**Response:**

```json
{
  "payment_methods": [
    {
      "id": "credit_card",
      "name": "Credit Card",
      "description": "Visa, MasterCard, American Express",
      "enabled": true
    },
    {
      "id": "debit_card",
      "name": "Debit Card",
      "description": "Bank debit cards",
      "enabled": true
    },
    {
      "id": "paypal",
      "name": "PayPal",
      "description": "Pay with your PayPal account",
      "enabled": true
    },
    {
      "id": "stripe",
      "name": "Stripe",
      "description": "Secure online payments",
      "enabled": false
    }
  ]
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
  - `payment.refund` - Refund processed

### Event Schemas

#### Payment Success Event

```json
{
  "event_id": "evt_payment_001",
  "event_type": "payment.success",
  "user_id": "user_123",
  "user_email": "user@example.com",
  "booking_id": "BOOK-789012",
  "transaction_id": "TXN-456789",
  "amount": 25.5,
  "payment_method": "credit_card",
  "timestamp": "2024-12-15T10:30:45Z"
}
```

#### Payment Failed Event

```json
{
  "event_id": "evt_payment_002",
  "event_type": "payment.failed",
  "user_id": "user_123",
  "user_email": "user@example.com",
  "booking_id": "BOOK-789012",
  "amount": 25.5,
  "payment_method": "credit_card",
  "failure_reason": "Insufficient funds",
  "error_code": "INSUFFICIENT_FUNDS",
  "timestamp": "2024-12-15T10:30:45Z"
}
```

#### Payment Refund Event

```json
{
  "event_id": "evt_payment_003",
  "event_type": "payment.refund",
  "user_id": "user_123",
  "user_email": "user@example.com",
  "booking_id": "BOOK-789012",
  "original_transaction_id": "TXN-456789",
  "refund_transaction_id": "REF-123456",
  "refund_amount": 25.5,
  "reason": "Customer cancellation",
  "timestamp": "2024-12-15T10:35:00Z"
}
```

---

## Error Handling

### Error Response Format

```json
{
  "error": {
    "code": "PAYMENT_FAILED",
    "message": "Payment could not be processed",
    "details": {
      "reason": "Insufficient funds",
      "transaction_id": null,
      "retry_possible": true
    }
  },
  "timestamp": "2024-12-15T10:30:45Z"
}
```

### Common Error Codes

| Code                    | Description                   | HTTP Status |
| ----------------------- | ----------------------------- | ----------- |
| `INVALID_CARD`          | Invalid card details          | 400         |
| `INSUFFICIENT_FUNDS`    | Not enough funds              | 400         |
| `CARD_EXPIRED`          | Card has expired              | 400         |
| `CARD_DECLINED`         | Card declined by bank         | 400         |
| `PAYMENT_GATEWAY_ERROR` | Gateway service error         | 502         |
| `DUPLICATE_TRANSACTION` | Transaction already processed | 409         |
| `INVALID_AMOUNT`        | Invalid payment amount        | 400         |
| `REFUND_NOT_ALLOWED`    | Refund not permitted          | 400         |

---

## Rate Limiting

- **Rate Limit:** 100 requests per minute per IP
- **Burst Limit:** 20 requests per 10 seconds
- **Headers:**
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

---

## Examples

### Process Credit Card Payment

```bash
curl -X POST http://localhost:8003/payment/process \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user_123",
    "booking_id": "BOOK-789012",
    "amount": 25.50,
    "payment_method": "credit_card",
    "card_details": {
      "card_number": "4111111111111111",
      "expiry_month": "12",
      "expiry_year": "2025",
      "cvv": "123",
      "cardholder_name": "John Doe"
    }
  }'
```

### Process Refund

```bash
curl -X POST http://localhost:8003/payment/refund \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": "BOOK-789012",
    "original_transaction_id": "TXN-456789",
    "refund_amount": 25.50,
    "reason": "Customer cancellation",
    "user_id": "user_123"
  }'
```

### Check Payment Status

```bash
curl http://localhost:8003/payment/status/TXN-456789
```

---

## Testing

### Test Endpoints

```bash
# Health check
curl http://localhost:8003/health

# Get payment methods
curl http://localhost:8003/payment/methods

# Test payment (will fail with test data)
curl -X POST http://localhost:8003/payment/process \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","booking_id":"TEST-123","amount":10.00,"payment_method":"credit_card"}'
```

### Test Cards

For testing purposes, you can use these test card numbers:

| Card Type  | Number           | Result   |
| ---------- | ---------------- | -------- |
| Visa       | 4111111111111111 | Success  |
| Visa       | 4000000000000002 | Declined |
| MasterCard | 5555555555554444 | Success  |
| Amex       | 378282246310005  | Success  |

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
PAYMENT_GATEWAY_URL=https://api.paymentgateway.com
PAYMENT_GATEWAY_API_KEY=your_api_key

# RabbitMQ Configuration
RABBITMQ_URL=amqp://localhost:5672/
RABBITMQ_EXCHANGE=movie_app_events

# Database Configuration (if used)
DATABASE_URL=postgresql://user:pass@localhost:5432/payments

# Security
JWT_SECRET_KEY=your_jwt_secret
ENCRYPTION_KEY=your_encryption_key
```

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

### Docker Compose

```yaml
version: "3.8"
services:
  payment-service:
    build: .
    ports:
      - "8003:8003"
    environment:
      - RABBITMQ_URL=amqp://rabbitmq:5672/
    depends_on:
      - rabbitmq
```
