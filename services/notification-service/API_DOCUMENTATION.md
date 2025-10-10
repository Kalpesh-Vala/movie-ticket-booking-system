# Notification Service API Documentation

## Overview

The Notification Service is an event-driven microservice that consumes events from RabbitMQ and sends notifications via email (SMTP) and SMS. It handles booking confirmations, payment notifications, cancellations, and refunds with idempotency checking and audit logging.

## Architecture

The Notification Service operates as a **consumer-only service** that processes events from RabbitMQ queues. It doesn't expose REST API endpoints but provides comprehensive event processing capabilities.

```
RabbitMQ Events → Notification Worker → SMTP Service → Email Provider → User's Inbox
                      ↓
                 Redis (Idempotency) + MongoDB (Audit Logs)
```

## Event Consumption

### RabbitMQ Configuration

- **Exchange:** `movie_app_events` (topic exchange)
- **Queues:**
  - `notification.booking_events` - Booking-related notifications
  - `notification.payment_events` - Payment-related notifications
- **Routing Keys:**
  - `booking.confirmed`
  - `booking.cancelled`
  - `booking.refunded`
  - `payment.success`
  - `payment.failed`
  - `payment.refund`

## Supported Event Types

### 1. Booking Events

#### Booking Confirmed Event

**Routing Key:** `booking.confirmed`

**Event Schema:**

```json
{
  "event_id": "evt_booking_001",
  "event_type": "booking.confirmed",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "booking_id": "BOOK-789012",
  "movie_title": "Inception",
  "showtime": "2024-12-15 8:00 PM",
  "cinema_name": "AMC Theater",
  "seats": ["B5", "B6"],
  "total_amount": 30.0,
  "booking_date": "2024-12-15",
  "timestamp": "2024-12-15T10:30:00Z"
}
```

**Generated Notifications:**

- ✉️ **Email:** Booking confirmation with QR code and details
- 📱 **SMS:** Brief confirmation message (if phone number provided)

**Email Template:** `booking_confirmation`

---

#### Booking Cancelled Event

**Routing Key:** `booking.cancelled`

**Event Schema:**

```json
{
  "event_id": "evt_booking_002",
  "event_type": "booking.cancelled",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "booking_id": "BOOK-789012",
  "cancellation_reason": "User requested cancellation",
  "cancelled_at": "2024-12-15T11:00:00Z",
  "refund_eligible": true,
  "refund_amount": 30.0,
  "timestamp": "2024-12-15T11:00:00Z"
}
```

**Generated Notifications:**

- ✉️ **Email:** Cancellation confirmation with refund information
- 📱 **SMS:** Cancellation confirmation

**Email Template:** `booking_cancellation`

---

#### Booking Refunded Event

**Routing Key:** `booking.refunded`

**Event Schema:**

```json
{
  "event_id": "evt_booking_003",
  "event_type": "booking.refunded",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "booking_id": "BOOK-789012",
  "refund_amount": 30.0,
  "refund_transaction_id": "REF-123456",
  "original_transaction_id": "TXN-456789",
  "processing_time": "5-7 business days",
  "timestamp": "2024-12-15T11:30:00Z"
}
```

**Generated Notifications:**

- ✉️ **Email:** Refund confirmation with transaction details
- 📱 **SMS:** Refund processed notification

**Email Template:** `payment_refund`

---

### 2. Payment Events

#### Payment Success Event

**Routing Key:** `payment.success`

**Event Schema:**

```json
{
  "event_id": "evt_payment_001",
  "event_type": "payment.success",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "booking_id": "BOOK-789012",
  "transaction_id": "TXN-456789",
  "amount": 30.0,
  "payment_method": "credit_card",
  "card_last_four": "1111",
  "processed_at": "2024-12-15T10:30:45Z",
  "timestamp": "2024-12-15T10:30:45Z"
}
```

**Generated Notifications:**

- ✉️ **Email:** Payment successful confirmation with receipt
- 📱 **SMS:** Payment confirmation

**Email Template:** `payment_success`

---

#### Payment Failed Event

**Routing Key:** `payment.failed`

**Event Schema:**

```json
{
  "event_id": "evt_payment_002",
  "event_type": "payment.failed",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "booking_id": "BOOK-789012",
  "amount": 30.0,
  "payment_method": "credit_card",
  "failure_reason": "Insufficient funds",
  "error_code": "INSUFFICIENT_FUNDS",
  "retry_possible": true,
  "retry_url": "https://movieapp.com/payment/retry/BOOK-789012",
  "timestamp": "2024-12-15T10:30:45Z"
}
```

**Generated Notifications:**

- ✉️ **Email:** Payment failure notice with retry instructions
- 📱 **SMS:** Payment failed alert

**Email Template:** `payment_failed`

---

#### Payment Refund Event

**Routing Key:** `payment.refund`

**Event Schema:**

```json
{
  "event_id": "evt_payment_003",
  "event_type": "payment.refund",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "booking_id": "BOOK-789012",
  "original_transaction_id": "TXN-456789",
  "refund_transaction_id": "REF-123456",
  "refund_amount": 30.0,
  "reason": "Customer cancellation",
  "processing_time": "5-7 business days",
  "timestamp": "2024-12-15T11:30:00Z"
}
```

**Generated Notifications:**

- ✉️ **Email:** Refund processed confirmation
- 📱 **SMS:** Refund confirmation

**Email Template:** `payment_refund`

---

## Email Templates

### Template Overview

The service includes 5 professional HTML email templates:

| Template               | Purpose            | Key Features                      |
| ---------------------- | ------------------ | --------------------------------- |
| `booking_confirmation` | Booking success    | Movie details, QR code, seat info |
| `booking_cancellation` | Booking cancelled  | Cancellation reason, refund info  |
| `payment_success`      | Payment successful | Transaction details, receipt      |
| `payment_failed`       | Payment failed     | Retry button, troubleshooting     |
| `payment_refund`       | Refund processed   | Transaction IDs, timeline         |

### Template Variables

#### Booking Confirmation Template

```json
{
  "booking_id": "BOOK-123456",
  "movie_title": "The Matrix",
  "showtime": "2024-12-15 7:30 PM",
  "cinema_name": "AMC Theater",
  "seats": ["A1", "A2"],
  "total_amount": "25.50",
  "booking_date": "2024-12-15",
  "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?data=BOOK-123456"
}
```

#### Payment Success Template

```json
{
  "transaction_id": "TXN-789012",
  "booking_id": "BOOK-123456",
  "amount": "25.50",
  "payment_method": "credit_card",
  "card_last_four": "1111",
  "processed_at": "2024-12-15T10:30:45Z"
}
```

#### Payment Failed Template

```json
{
  "booking_id": "BOOK-123456",
  "amount": "25.50",
  "payment_method": "credit_card",
  "failure_reason": "Insufficient funds",
  "retry_url": "https://movieapp.com/payment/retry/BOOK-123456",
  "support_email": "support@movieapp.com"
}
```

---

## SMTP Configuration

### Email Service Features

- **Async SMTP Integration** using `aiosmtplib`
- **HTML Templates** with Jinja2 template engine
- **Multi-Provider Support** (Gmail, Outlook, Yahoo, custom SMTP)
- **TLS Encryption** for secure email transmission
- **Attachment Support** for tickets and receipts
- **Graceful Fallbacks** when SMTP is unavailable

### SMTP Configuration

```env
# SMTP Server Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=notifications@movieapp.com
SMTP_PASSWORD=app_password_here

# Email Sender Information
FROM_EMAIL=notifications@movieapp.com
FROM_NAME=Movie Ticket Booking System
```

### Supported Email Providers

| Provider | SMTP Server           | Port    | Security     |
| -------- | --------------------- | ------- | ------------ |
| Gmail    | smtp.gmail.com        | 587     | STARTTLS     |
| Outlook  | smtp-mail.outlook.com | 587     | STARTTLS     |
| Yahoo    | smtp.mail.yahoo.com   | 587     | STARTTLS     |
| Custom   | your-smtp.com         | 587/465 | STARTTLS/SSL |

---

## SMS Configuration (Planned)

### SMS Service Integration

```json
{
  "provider": "twilio",
  "account_sid": "your_account_sid",
  "auth_token": "your_auth_token",
  "from_number": "+1234567890"
}
```

### SMS Templates

- **Booking Confirmed:** "Your booking BOOK-123456 for [Movie] on [Date] is confirmed!"
- **Payment Success:** "Payment of $25.50 for booking BOOK-123456 successful. Transaction: TXN-789012"
- **Payment Failed:** "Payment failed for booking BOOK-123456. Please retry at [URL]"

---

## Idempotency & Reliability

### Idempotency Checking

The service uses Redis to prevent duplicate notifications:

```
Key Pattern: event:{event_id}:status
Values: processing, processed, failed
TTL: 24 hours
```

### Processing Flow

1. **Receive Event** from RabbitMQ
2. **Check Idempotency** in Redis
3. **Mark as Processing** if not already processed
4. **Send Notifications** (Email + SMS)
5. **Log to MongoDB** for audit trail
6. **Mark as Processed** in Redis
7. **Acknowledge** RabbitMQ message

### Error Handling

- **SMTP Failures:** Fall back to simulation mode
- **Template Errors:** Log error and skip notification
- **Redis Unavailable:** Process without idempotency (log warning)
- **MongoDB Unavailable:** Continue processing (log error)

---

## Audit Logging

### MongoDB Audit Collection

**Collection:** `notification_logs`

**Document Schema:**

```json
{
  "_id": "ObjectId",
  "event_id": "evt_payment_001",
  "notification_type": "email",
  "recipient": "customer@example.com",
  "subject": "Payment Successful",
  "template": "payment_success",
  "status": "sent",
  "sent_at": "2024-12-15T10:30:45Z",
  "event_data": {
    /* original event data */
  },
  "error_message": null,
  "retry_count": 0
}
```

### Audit Fields

| Field               | Description              | Type     |
| ------------------- | ------------------------ | -------- |
| `event_id`          | Unique event identifier  | String   |
| `notification_type` | email, sms, push         | String   |
| `recipient`         | Email/phone number       | String   |
| `status`            | sent, failed, pending    | String   |
| `template`          | Template name used       | String   |
| `sent_at`           | Timestamp when sent      | DateTime |
| `error_message`     | Error details if failed  | String   |
| `retry_count`       | Number of retry attempts | Integer  |

---

## Monitoring & Health

### Health Checks

The service provides health status through internal monitoring:

```json
{
  "service": "notification-service",
  "status": "healthy",
  "components": {
    "rabbitmq": "connected",
    "redis": "connected",
    "mongodb": "connected",
    "smtp": "configured"
  },
  "last_processed": "2024-12-15T10:30:45Z",
  "processed_count": 1250,
  "failed_count": 3
}
```

### Metrics to Monitor

- **Event Processing Rate:** Events per minute
- **Email Success Rate:** Percentage of successful emails
- **Template Rendering Time:** Average template processing time
- **SMTP Response Time:** Email delivery latency
- **Error Rates:** Failed notifications by type
- **Queue Depth:** Pending events in RabbitMQ

### Log Levels

```python
# Log levels and their usage
INFO  - Normal operations, successful sends
WARN  - SMTP fallbacks, non-critical issues
ERROR - Failed notifications, connection errors
DEBUG - Detailed processing information
```

---

## Testing

### Test Scripts Available

1. **`test_smtp.py`** - Test SMTP configuration and email templates
2. **`test_notification_enhanced.py`** - Full integration test with real emails
3. **`test_notification_service.py`** - Basic notification functionality test

### Running Tests

```bash
# Activate virtual environment
source venv/Scripts/activate

# Test SMTP functionality
python test_smtp.py

# Test with real email delivery
python test_notification_enhanced.py

# Basic functionality test
python test_notification_service.py
```

### Mock Event Publishing

For testing, you can publish events to RabbitMQ:

```python
import json
import pika

# Connect to RabbitMQ
connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()

# Publish booking confirmation event
event = {
    "event_id": "test_001",
    "event_type": "booking.confirmed",
    "user_email": "test@example.com",
    "booking_id": "TEST-123",
    "movie_title": "Test Movie",
    "showtime": "2024-12-15 7:30 PM",
    "seats": ["A1"],
    "total_amount": 15.00
}

channel.basic_publish(
    exchange='movie_app_events',
    routing_key='booking.confirmed',
    body=json.dumps(event),
    properties=pika.BasicProperties(delivery_mode=2)  # Persistent
)
```

---

## Configuration

### Environment Variables

```env
# RabbitMQ Configuration
RABBITMQ_URL=amqp://localhost:5672/
RABBITMQ_EXCHANGE=movie_app_events
RABBITMQ_BOOKING_QUEUE=notification.booking_events
RABBITMQ_PAYMENT_QUEUE=notification.payment_events

# Redis Configuration (for idempotency)
REDIS_URL=redis://localhost:6379

# MongoDB Configuration (for audit logs)
MONGODB_URI=mongodb://localhost:27017
MONGODB_DATABASE=movie_booking
MONGODB_COLLECTION=notification_logs

# SMTP Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=notifications@movieapp.com
SMTP_PASSWORD=your_app_password
FROM_EMAIL=notifications@movieapp.com
FROM_NAME=Movie Ticket Booking System

# SMS Configuration (Optional)
SMS_PROVIDER=twilio
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_FROM_NUMBER=+1234567890

# Service Configuration
LOG_LEVEL=INFO
MAX_RETRY_ATTEMPTS=3
NOTIFICATION_TIMEOUT=30
```

---

## Deployment

### Docker Deployment

```dockerfile
FROM python:3.9-slim
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 notifier && chown -R notifier:notifier /app
USER notifier

# Start the worker
CMD ["python", "worker.py"]
```

### Docker Compose

```yaml
version: "3.8"
services:
  notification-service:
    build: .
    environment:
      - RABBITMQ_URL=amqp://rabbitmq:5672/
      - REDIS_URL=redis://redis:6379
      - MONGODB_URI=mongodb://mongodb:27017
      - SMTP_SERVER=smtp.gmail.com
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
    depends_on:
      - rabbitmq
      - redis
      - mongodb
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  mongodb:
    image: mongo:7
    volumes:
      - mongo_data:/data/db

volumes:
  redis_data:
  mongo_data:
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: notification-service
  template:
    metadata:
      labels:
        app: notification-service
    spec:
      containers:
        - name: notification-service
          image: movieapp/notification-service:latest
          env:
            - name: RABBITMQ_URL
              value: "amqp://rabbitmq:5672/"
            - name: REDIS_URL
              value: "redis://redis:6379"
            - name: SMTP_USERNAME
              valueFrom:
                secretKeyRef:
                  name: smtp-credentials
                  key: username
            - name: SMTP_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: smtp-credentials
                  key: password
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
```

---

## Security Considerations

### Email Security

- **TLS Encryption:** All SMTP connections use STARTTLS
- **App Passwords:** Use app-specific passwords for Gmail
- **No Logging:** Never log email credentials or sensitive data
- **Rate Limiting:** Prevent spam by limiting email frequency

### Event Processing Security

- **Input Validation:** Validate all event data before processing
- **SQL Injection:** Use parameterized queries for database operations
- **XSS Prevention:** Sanitize data in email templates
- **Access Control:** Limit RabbitMQ queue access

### Infrastructure Security

- **Network Isolation:** Run in private networks
- **Secrets Management:** Use Kubernetes secrets or HashiCorp Vault
- **Container Security:** Run as non-root user
- **Log Sanitization:** Remove sensitive data from logs

---

## Troubleshooting

### Common Issues

#### SMTP Authentication Failures

```
ERROR: (535, '5.7.8 Username and Password not accepted')
```

**Solution:**

- For Gmail: Enable 2FA and use App Password
- Check username/password configuration
- Verify SMTP server and port settings

#### RabbitMQ Connection Issues

```
ERROR: Connection to RabbitMQ failed
```

**Solution:**

- Check RabbitMQ server is running
- Verify connection URL format
- Check network connectivity and firewall rules

#### Template Rendering Errors

```
ERROR: Template 'unknown_template' not found
```

**Solution:**

- Check template name spelling
- Verify template exists in smtp_service.py
- Check template data matches expected variables

#### Redis Connection Issues

```
WARN: Redis unavailable, processing without idempotency
```

**Solution:**

- Check Redis server status
- Verify Redis URL configuration
- Monitor Redis memory usage

### Debug Commands

```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs -f notification-service

# Check RabbitMQ queues
docker exec rabbitmq rabbitmqctl list_queues

# Check Redis keys
docker exec redis redis-cli keys "event:*"

# Test SMTP configuration
python -c "from smtp_service import SMTPEmailService; SMTPEmailService().test_configuration()"
```

---

## API Integration Examples

### Publishing Events from Other Services

#### From Booking Service (Node.js)

```javascript
const amqp = require("amqplib");

async function publishBookingConfirmed(bookingData) {
  const connection = await amqp.connect("amqp://localhost:5672");
  const channel = await connection.createChannel();

  const event = {
    event_id: `booking_${bookingData.id}_${Date.now()}`,
    event_type: "booking.confirmed",
    user_email: bookingData.user_email,
    booking_id: bookingData.booking_id,
    movie_title: bookingData.movie_title,
    showtime: bookingData.showtime,
    seats: bookingData.seats,
    total_amount: bookingData.total_amount,
    timestamp: new Date().toISOString(),
  };

  await channel.publish(
    "movie_app_events",
    "booking.confirmed",
    Buffer.from(JSON.stringify(event)),
    { persistent: true }
  );

  await connection.close();
}
```

#### From Payment Service (Python)

```python
import json
import pika
from datetime import datetime

def publish_payment_success(payment_data):
    connection = pika.BlockingConnection(
        pika.ConnectionParameters('localhost')
    )
    channel = connection.channel()

    event = {
        'event_id': f"payment_{payment_data['transaction_id']}",
        'event_type': 'payment.success',
        'user_email': payment_data['user_email'],
        'booking_id': payment_data['booking_id'],
        'transaction_id': payment_data['transaction_id'],
        'amount': payment_data['amount'],
        'payment_method': payment_data['payment_method'],
        'timestamp': datetime.utcnow().isoformat()
    }

    channel.basic_publish(
        exchange='movie_app_events',
        routing_key='payment.success',
        body=json.dumps(event),
        properties=pika.BasicProperties(delivery_mode=2)
    )

    connection.close()
```

---

This comprehensive documentation covers all aspects of the Notification Service, from event consumption to email delivery, making it easy for developers to integrate with and maintain the service.
