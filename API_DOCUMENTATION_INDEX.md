# Payment & Notification Services - Complete API Documentation

## 📋 Documentation Overview

This comprehensive API documentation covers both the **Payment Service** and **Notification Service** that work together to handle payment processing and user notifications in the Movie Ticket Booking System.

## 🏗️ System Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Frontend      │───▶│  Payment Service │───▶│    RabbitMQ         │
│   Application   │    │  (REST API)      │    │   Event Queue       │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                                          │
                                                          ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   User's Email  │◀───│ Notification     │◀───│    Event Consumer   │
│   Inbox         │    │ Service (SMTP)   │    │                     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Redis + MongoDB │
                       │ (Idempotency &  │
                       │  Audit Logs)    │
                       └─────────────────┘
```

## 📚 Service Documentation

### 🔹 Payment Service

**File:** [`services/payment-service/API_DOCUMENTATION.md`](./services/payment-service/API_DOCUMENTATION.md)

**Service Type:** REST API  
**Port:** 8003  
**Purpose:** Process payments, handle refunds, manage payment methods

**Key Endpoints:**

- `POST /payment/process` - Process credit card payments
- `POST /payment/refund` - Process refunds
- `GET /payment/status/{transaction_id}` - Check payment status
- `GET /payment/methods` - Get available payment methods
- `GET /health` - Service health check

### 🔹 Notification Service

**File:** [`services/notification-service/API_DOCUMENTATION.md`](./services/notification-service/API_DOCUMENTATION.md)

**Service Type:** Event Consumer  
**Protocol:** RabbitMQ AMQP  
**Purpose:** Send email notifications, SMS alerts, audit logging

**Supported Events:**

- `booking.confirmed` - Booking confirmation emails
- `booking.cancelled` - Cancellation notifications
- `payment.success` - Payment success emails
- `payment.failed` - Payment failure alerts
- `payment.refund` - Refund confirmation emails

## 🔄 Service Integration Flow

### 1. Payment Processing Flow

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant PaymentService
    participant RabbitMQ
    participant NotificationService
    participant EmailProvider

    User->>Frontend: Submit payment
    Frontend->>PaymentService: POST /payment/process
    PaymentService->>PaymentService: Process payment
    PaymentService->>RabbitMQ: Publish payment.success event
    PaymentService->>Frontend: Return success response
    Frontend->>User: Show success message

    RabbitMQ->>NotificationService: Deliver payment.success event
    NotificationService->>EmailProvider: Send confirmation email
    EmailProvider->>User: Deliver email notification
```

### 2. Booking Confirmation Flow

```mermaid
sequenceDiagram
    participant BookingService
    participant RabbitMQ
    participant NotificationService
    participant User

    BookingService->>RabbitMQ: Publish booking.confirmed event
    RabbitMQ->>NotificationService: Deliver event
    NotificationService->>NotificationService: Render email template
    NotificationService->>User: Send booking confirmation email
```

## 📊 Event Schema Reference

### Core Event Structure

All events follow this base schema:

```json
{
  "event_id": "unique_event_identifier",
  "event_type": "event.type",
  "user_id": "user_123",
  "user_email": "customer@example.com",
  "timestamp": "2024-12-15T10:30:00Z"
  // Event-specific data...
}
```

### Event Types & Data

| Event Type          | Source Service  | Target Service       | Description                    |
| ------------------- | --------------- | -------------------- | ------------------------------ |
| `payment.success`   | Payment Service | Notification Service | Payment completed successfully |
| `payment.failed`    | Payment Service | Notification Service | Payment processing failed      |
| `payment.refund`    | Payment Service | Notification Service | Refund processed               |
| `booking.confirmed` | Booking Service | Notification Service | Booking confirmed              |
| `booking.cancelled` | Booking Service | Notification Service | Booking cancelled              |

## 🛠️ Development Setup

### Prerequisites

- Python 3.9+
- Node.js 16+ (for other services)
- RabbitMQ Server
- Redis Server
- MongoDB Server
- SMTP Email Account (Gmail recommended)

### Quick Start

1. **Clone Repository**

```bash
git clone <repository-url>
cd movie-ticket-booking-system
```

2. **Setup Payment Service**

```bash
cd services/payment-service
pip install -r requirements.txt
uvicorn main:app --port 8003 --reload
```

3. **Setup Notification Service**

```bash
cd services/notification-service
python -m venv venv
source venv/Scripts/activate  # Windows
pip install -r requirements.txt

# Configure SMTP (copy .env.example to .env and fill in credentials)
cp .env.example .env

# Start the worker
python worker.py
```

4. **Start Infrastructure**

```bash
# Start RabbitMQ, Redis, MongoDB using Docker
docker-compose up -d rabbitmq redis mongodb
```

## 🧪 Testing

### Payment Service Tests

```bash
cd services/payment-service

# Test health endpoint
curl http://localhost:8003/health

# Test payment processing
curl -X POST http://localhost:8003/payment/process \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "booking_id": "BOOK-123",
    "amount": 25.50,
    "payment_method": "credit_card"
  }'
```

### Notification Service Tests

```bash
cd services/notification-service

# Test SMTP configuration
python test_smtp.py

# Test with real email delivery
python test_notification_enhanced.py

# Basic functionality test
python test_notification_service.py
```

### Integration Testing

```bash
# Test complete payment + notification flow
cd services/payment-service
python test_integration.py
```

## 📧 Email Templates

The Notification Service includes 5 professional HTML email templates:

### Template Showcase

1. **🎬 Booking Confirmation**

   - Movie details with poster
   - QR code for entry
   - Seat and showtime information
   - Cinema directions

2. **💳 Payment Success**

   - Transaction receipt
   - Payment method details
   - Booking reference
   - Next steps

3. **❌ Payment Failed**

   - Clear error explanation
   - Retry payment button
   - Troubleshooting tips
   - Support contact

4. **🚫 Booking Cancelled**

   - Cancellation confirmation
   - Refund information
   - Policy details
   - Alternative showtimes

5. **💰 Refund Processed**
   - Refund transaction details
   - Processing timeline
   - Bank processing info
   - Receipt for records

### Template Variables

Each template supports dynamic content through Jinja2 variables:

```json
{
  "booking_id": "BOOK-123456",
  "movie_title": "The Matrix",
  "user_name": "John Doe",
  "amount": "25.50",
  "transaction_id": "TXN-789012"
}
```

## 🔐 Security & Authentication

### Payment Service Security

- **PCI DSS Compliance:** Never store card data
- **Input Validation:** Comprehensive request validation
- **Rate Limiting:** Prevent payment abuse
- **HTTPS Only:** Secure data transmission
- **Audit Logging:** Complete transaction history

### Notification Service Security

- **TLS Email Encryption:** Secure SMTP connections
- **App Password Authentication:** Secure email credentials
- **Input Sanitization:** Prevent XSS in email templates
- **Idempotency:** Prevent duplicate notifications
- **Access Control:** Limited RabbitMQ permissions

## 🏗️ Production Deployment

### Docker Compose Deployment

```yaml
version: "3.8"
services:
  payment-service:
    build: ./services/payment-service
    ports:
      - "8003:8003"
    environment:
      - RABBITMQ_URL=amqp://rabbitmq:5672/
    depends_on:
      - rabbitmq

  notification-service:
    build: ./services/notification-service
    environment:
      - RABBITMQ_URL=amqp://rabbitmq:5672/
      - REDIS_URL=redis://redis:6379
      - MONGODB_URI=mongodb://mongodb:27017
      - SMTP_USERNAME=${SMTP_USERNAME}
      - SMTP_PASSWORD=${SMTP_PASSWORD}
    depends_on:
      - rabbitmq
      - redis
      - mongodb

  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - ./config/rabbitmq:/etc/rabbitmq

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

### Environment Configuration

```env
# Payment Service
PAYMENT_GATEWAY_URL=https://api.stripe.com
PAYMENT_GATEWAY_API_KEY=sk_live_your_key

# Notification Service
SMTP_SERVER=smtp.gmail.com
SMTP_USERNAME=notifications@yourdomain.com
SMTP_PASSWORD=your_app_password
FROM_NAME=Your Movie App

# Infrastructure
RABBITMQ_URL=amqp://username:password@rabbitmq:5672/
REDIS_URL=redis://redis:6379
MONGODB_URI=mongodb://mongodb:27017/movieapp
```

## 📊 Monitoring & Observability

### Key Metrics to Monitor

#### Payment Service Metrics

- Payment success rate (%)
- Average payment processing time
- Failed payment reasons distribution
- Transaction volume per hour
- Revenue per time period

#### Notification Service Metrics

- Email delivery success rate (%)
- Template rendering time
- Event processing latency
- Queue depth and processing rate
- SMTP connection health

### Health Check Endpoints

```bash
# Payment Service Health
GET http://localhost:8003/health

# Infrastructure Health Checks
curl http://localhost:15672/api/overview  # RabbitMQ Management
redis-cli ping  # Redis Health
mongo --eval "db.adminCommand('ismaster')"  # MongoDB Health
```

### Log Aggregation

Both services provide structured JSON logging for easy aggregation:

```json
{
  "timestamp": "2024-12-15T10:30:45Z",
  "level": "INFO",
  "service": "payment-service",
  "transaction_id": "TXN-456789",
  "message": "Payment processed successfully",
  "user_id": "user_123",
  "amount": 25.5
}
```

## 🐛 Troubleshooting Guide

### Common Issues & Solutions

#### Payment Service Issues

1. **Payment Gateway Timeout**

   ```
   ERROR: Gateway timeout after 30 seconds
   ```

   - Check gateway API status
   - Increase timeout configuration
   - Implement retry logic

2. **Invalid Card Details**
   ```
   ERROR: Card validation failed
   ```
   - Verify card number format
   - Check expiry date validation
   - Validate CVV length

#### Notification Service Issues

1. **SMTP Authentication Failed**

   ```
   ERROR: (535) Username and Password not accepted
   ```

   - Use App Password for Gmail
   - Check credentials configuration
   - Verify SMTP server settings

2. **Template Rendering Error**

   ```
   ERROR: Template variable 'booking_id' not found
   ```

   - Check event data completeness
   - Verify template variable names
   - Add default values for optional fields

3. **RabbitMQ Connection Lost**
   ```
   ERROR: Connection to RabbitMQ lost
   ```
   - Check RabbitMQ server status
   - Verify connection URL
   - Implement connection retry logic

### Debug Commands

```bash
# Check RabbitMQ queues
docker exec rabbitmq rabbitmqctl list_queues

# Monitor Redis keys
docker exec redis redis-cli monitor

# Check MongoDB collections
docker exec mongodb mongo --eval "db.notification_logs.count()"

# View service logs
docker-compose logs -f payment-service
docker-compose logs -f notification-service
```

## 🔗 Additional Resources

### API Testing Tools

- **Postman Collection:** Available in `/docs/postman/`
- **OpenAPI Spec:** Available at `/docs/openapi.json`
- **Swagger UI:** `http://localhost:8003/docs` (Payment Service)

### Development Resources

- **Database Schemas:** `/docs/database/`
- **Event Examples:** `/docs/events/`
- **Template Gallery:** `/docs/templates/`

### Support & Contribution

- **Issue Tracking:** GitHub Issues
- **Contributing Guide:** `CONTRIBUTING.md`
- **Code of Conduct:** `CODE_OF_CONDUCT.md`

---

## 📞 Support

For technical support or questions about the API documentation:

- **Email:** dev-team@movieapp.com
- **Slack:** #payment-notifications
- **Documentation Issues:** [GitHub Issues](https://github.com/yourorg/movie-booking/issues)

---

**Last Updated:** December 15, 2024  
**API Version:** v1.0  
**Documentation Version:** 1.0
