# 🚀 Payment & Notification Services - Quick Reference

## 📋 API Endpoints Summary

### Payment Service (Port 8003)

| Method | Endpoint                           | Purpose                       | Request Body Required |
| ------ | ---------------------------------- | ----------------------------- | --------------------- |
| `GET`  | `/health`                          | Service health check          | ❌                    |
| `GET`  | `/payment/methods`                 | Get available payment methods | ❌                    |
| `POST` | `/payment/process`                 | Process a payment             | ✅                    |
| `POST` | `/payment/refund`                  | Process a refund              | ✅                    |
| `GET`  | `/payment/status/{transaction_id}` | Get payment status            | ❌                    |

### Notification Service (Event Consumer)

| Event Type        | Routing Key         | Purpose                      | Email Template         |
| ----------------- | ------------------- | ---------------------------- | ---------------------- |
| Booking Confirmed | `booking.confirmed` | Booking success notification | `booking_confirmation` |
| Booking Cancelled | `booking.cancelled` | Cancellation notification    | `booking_cancellation` |
| Payment Success   | `payment.success`   | Payment confirmation         | `payment_success`      |
| Payment Failed    | `payment.failed`    | Payment failure alert        | `payment_failed`       |
| Payment Refund    | `payment.refund`    | Refund confirmation          | `payment_refund`       |

## 🔧 Quick Setup Commands

### Start Services

```bash
# Payment Service
cd services/payment-service
uvicorn main:app --port 8003 --reload

# Notification Service
cd services/notification-service
python worker.py
```

### Test Endpoints

```bash
# Health Check
curl http://localhost:8003/health

# Process Payment
curl -X POST http://localhost:8003/payment/process \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user123","booking_id":"BOOK-456","amount":25.50,"payment_method":"credit_card"}'

# Test Email Notifications
python services/notification-service/test_smtp.py
```

## 📧 Email Template Variables

### Booking Confirmation

```json
{
  "booking_id": "BOOK-123456",
  "movie_title": "Movie Name",
  "showtime": "2024-12-15 7:30 PM",
  "seats": ["A1", "A2"],
  "total_amount": "25.50"
}
```

### Payment Success

```json
{
  "transaction_id": "TXN-789012",
  "booking_id": "BOOK-123456",
  "amount": "25.50",
  "payment_method": "credit_card"
}
```

## ⚡ Event Publishing Examples

### Python (Payment Service)

```python
import json
import pika

# Publish payment success event
event = {
    "event_id": "evt_001",
    "event_type": "payment.success",
    "user_email": "user@example.com",
    "booking_id": "BOOK-123",
    "transaction_id": "TXN-456",
    "amount": 25.50,
    "timestamp": "2024-12-15T10:30:00Z"
}

connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()
channel.basic_publish(
    exchange='movie_app_events',
    routing_key='payment.success',
    body=json.dumps(event)
)
```

## 🔐 Environment Variables

### Payment Service

```env
PAYMENT_GATEWAY_URL=https://api.stripe.com
PAYMENT_GATEWAY_API_KEY=sk_test_your_key
RABBITMQ_URL=amqp://localhost:5672/
```

### Notification Service

```env
SMTP_SERVER=smtp.gmail.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
RABBITMQ_URL=amqp://localhost:5672/
REDIS_URL=redis://localhost:6379
MONGODB_URI=mongodb://localhost:27017
```

## 🚨 Common HTTP Status Codes

| Code  | Meaning          | When It Occurs                          |
| ----- | ---------------- | --------------------------------------- |
| `200` | Success          | Payment processed, status retrieved     |
| `400` | Bad Request      | Invalid payment details, payment failed |
| `404` | Not Found        | Transaction not found                   |
| `422` | Validation Error | Invalid request format                  |
| `500` | Server Error     | Internal service error                  |

## 📊 Monitoring Endpoints

```bash
# RabbitMQ Management UI
http://localhost:15672

# Check queue status
docker exec rabbitmq rabbitmqctl list_queues

# Redis monitoring
docker exec redis redis-cli monitor

# Service logs
docker-compose logs -f payment-service
docker-compose logs -f notification-service
```

## 🛠️ Debug Commands

```bash
# Test SMTP configuration
python -c "from smtp_service import SMTPEmailService; SMTPEmailService().test_configuration()"

# Check RabbitMQ connections
docker exec rabbitmq rabbitmqctl list_connections

# Monitor Redis keys
docker exec redis redis-cli keys "*"

# Check MongoDB collections
docker exec mongodb mongo --eval "db.notification_logs.find().limit(5)"
```

## 🎯 Testing Scenarios

### Successful Payment Flow

1. POST to `/payment/process` → Returns 200 with transaction_id
2. Payment service publishes `payment.success` event
3. Notification service sends confirmation email
4. Check email inbox for confirmation

### Failed Payment Flow

1. POST to `/payment/process` with invalid card → Returns 400
2. Payment service publishes `payment.failed` event
3. Notification service sends failure email with retry instructions

### Refund Flow

1. POST to `/payment/refund` → Returns 200 with refund_transaction_id
2. Payment service publishes `payment.refund` event
3. Notification service sends refund confirmation email

## 📚 Full Documentation Links

- **Payment Service API:** [`services/payment-service/API_DOCUMENTATION.md`](./services/payment-service/API_DOCUMENTATION.md)
- **Notification Service API:** [`services/notification-service/API_DOCUMENTATION.md`](./services/notification-service/API_DOCUMENTATION.md)
- **Complete Index:** [`API_DOCUMENTATION_INDEX.md`](./API_DOCUMENTATION_INDEX.md)

---

**🔗 Quick Links:**

- [Setup Guide](#quick-setup-commands)
- [Testing Guide](#testing-scenarios)
- [Troubleshooting](./API_DOCUMENTATION_INDEX.md#troubleshooting-guide)
- [Security Guide](./API_DOCUMENTATION_INDEX.md#security--authentication)
