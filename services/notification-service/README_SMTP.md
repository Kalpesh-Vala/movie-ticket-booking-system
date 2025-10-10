# Notification Service with SMTP Email Integration

## Overview

The Notification Service is a Python-based microservice that consumes events from RabbitMQ and sends notifications via email (SMTP) and SMS. It handles booking confirmations, payment notifications, cancellations, and refunds with idempotency checking and audit logging.

## Features

### 🔔 Notification Types

- **Booking Confirmations** - Send detailed booking confirmation emails
- **Payment Success** - Notify users of successful payments
- **Payment Failed** - Alert users about payment failures with retry options
- **Booking Cancellations** - Confirm booking cancellations
- **Refund Notifications** - Notify users about processed refunds

### 📧 Email Capabilities

- **Real SMTP Integration** - Send actual emails using SMTP protocols
- **HTML Templates** - Rich, responsive email templates for each notification type
- **Template Engine** - Jinja2-powered templates with dynamic content
- **Fallback Simulation** - Graceful fallback to simulation when SMTP not configured
- **Attachment Support** - Ability to attach files to emails

### 🛡️ Reliability Features

- **Idempotency Checking** - Prevent duplicate notifications using Redis
- **Audit Logging** - Complete notification history in MongoDB
- **Error Handling** - Comprehensive error handling with fallbacks
- **Retry Logic** - Built-in retry mechanisms for failed deliveries

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   RabbitMQ      │───▶│ Notification     │───▶│   SMTP Server   │
│   Events        │    │ Service Worker   │    │   (Gmail/etc)   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Redis + MongoDB │
                       │ (Idempotency &  │
                       │  Audit Logs)    │
                       └─────────────────┘
```

## Installation & Setup

### 1. Install Dependencies

```bash
pip install -r requirements.txt
```

### 2. Configure SMTP Settings

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` with your SMTP credentials:

```env
# SMTP Server Configuration
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password

# Email Sender Information
FROM_EMAIL=your-email@gmail.com
FROM_NAME=Movie Ticket Booking System
```

### 3. Gmail Setup (Recommended)

For Gmail users:

1. Enable 2-Factor Authentication on your Google account
2. Go to Google Account Settings → Security → App Passwords
3. Generate an App Password for "Movie Booking System"
4. Use the generated app password as `SMTP_PASSWORD` (not your regular password)

### 4. Other Email Providers

Common SMTP settings:

- **Outlook/Hotmail**: `smtp-mail.outlook.com:587`
- **Yahoo**: `smtp.mail.yahoo.com:587`
- **Custom SMTP**: Contact your email provider for settings

## Usage

### Running the Service

```bash
# Start the notification worker
python worker.py
```

### Testing SMTP Functionality

```bash
# Test SMTP configuration and email sending
python test_smtp.py

# Test enhanced notification service with real emails
python test_notification_enhanced.py

# Test basic notification functionality
python test_notification_service.py
```

## Email Templates

The service includes pre-built HTML email templates:

### 📝 Available Templates

1. **booking_confirmation** - Booking confirmation with details
2. **booking_cancellation** - Booking cancellation notice
3. **payment_success** - Payment successful notification
4. **payment_failed** - Payment failure with retry options
5. **payment_refund** - Refund processed notification

### 🎨 Template Features

- Responsive HTML design
- Professional styling with CSS
- Dynamic content using Jinja2
- Branded headers and footers
- Mobile-friendly layout

### 📊 Template Data

Each template expects specific data:

```python
# Booking Confirmation
{
    "booking_id": "BOOK-123456",
    "movie_title": "The Matrix",
    "showtime": "2024-12-15 7:30 PM",
    "seats": ["A1", "A2"],
    "total_amount": "25.50"
}

# Payment Success
{
    "transaction_id": "TXN-789012",
    "booking_id": "BOOK-123456",
    "amount": "25.50",
    "payment_method": "credit_card"
}
```

## API Integration

### RabbitMQ Event Consumption

The service listens to these queues:

- `notification.booking_events` - Booking-related events
- `notification.payment_events` - Payment-related events

### Event Types

```json
// Booking Confirmed
{
    "event_type": "booking.confirmed",
    "user_email": "user@example.com",
    "booking_id": "BOOK-123",
    "movie_title": "Movie Name",
    "showtime": "2024-12-15 7:30 PM",
    "seats": ["A1", "A2"],
    "total_amount": 25.50
}

// Payment Success
{
    "event_type": "payment.success",
    "user_email": "user@example.com",
    "booking_id": "BOOK-123",
    "transaction_id": "TXN-456",
    "amount": 25.50,
    "payment_method": "credit_card"
}
```

## Configuration

### Environment Variables

| Variable        | Description                  | Default                       |
| --------------- | ---------------------------- | ----------------------------- |
| `SMTP_SERVER`   | SMTP server hostname         | `smtp.gmail.com`              |
| `SMTP_PORT`     | SMTP server port             | `587`                         |
| `SMTP_USERNAME` | SMTP username (email)        | Required                      |
| `SMTP_PASSWORD` | SMTP password (app password) | Required                      |
| `FROM_EMAIL`    | Sender email address         | Same as username              |
| `FROM_NAME`     | Sender display name          | `Movie Ticket Booking System` |
| `RABBITMQ_URL`  | RabbitMQ connection URL      | `amqp://localhost:5672/`      |
| `REDIS_URL`     | Redis connection URL         | `redis://localhost:6379`      |
| `MONGODB_URI`   | MongoDB connection URI       | `mongodb://localhost:27017`   |

## Testing

### Unit Tests

```bash
# Test individual components
python -m pytest tests/
```

### Integration Tests

```bash
# Test SMTP email functionality
python test_smtp.py

# Test notification service with real emails
python test_notification_enhanced.py

# Test with Docker environment
docker-compose up -d
python test_notification_service.py
```

### Load Testing

```bash
# Test with multiple concurrent notifications
python test_load_notifications.py
```

## Monitoring & Logging

### Log Levels

- `INFO` - Normal operation messages
- `WARNING` - SMTP fallbacks and non-critical issues
- `ERROR` - Failed notifications and errors
- `DEBUG` - Detailed debugging information

### Log Format

```
2024-12-15 10:30:45 - INFO - 📧 Email sent successfully to user@example.com
2024-12-15 10:30:46 - ERROR - ❌ Failed to send email: SMTP authentication failed
```

### Audit Trail

All notifications are logged to MongoDB with:

- Event ID and type
- Recipient information
- Delivery status
- Timestamp
- Error details (if any)

## Troubleshooting

### Common Issues

1. **SMTP Authentication Failed**

   - Check username/password
   - For Gmail, ensure App Password is used
   - Verify 2FA is enabled for Gmail

2. **Connection Timeout**

   - Check SMTP server and port
   - Verify firewall settings
   - Test network connectivity

3. **Template Not Found**

   - Check template name spelling
   - Verify template exists in `smtp_service.py`

4. **RabbitMQ Connection Issues**
   - Verify RabbitMQ is running
   - Check connection URL format
   - Ensure queues are properly declared

### Debug Mode

Enable debug logging:

```python
logging.basicConfig(level=logging.DEBUG)
```

### Test Configuration

```bash
# Quick configuration test
python -c "from smtp_service import SMTPEmailService; SMTPEmailService().test_configuration()"
```

## Production Deployment

### Docker Deployment

```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "worker.py"]
```

### Environment Variables in Production

```bash
# Set production SMTP credentials
export SMTP_SERVER=smtp.yourdomain.com
export SMTP_USERNAME=notifications@yourdomain.com
export SMTP_PASSWORD=your-secure-password
```

### Scaling Considerations

- Multiple worker instances can run concurrently
- Redis ensures idempotency across instances
- MongoDB handles concurrent audit logging
- RabbitMQ provides load balancing

## Security

### Best Practices

1. **Never commit SMTP credentials** to version control
2. **Use App Passwords** for Gmail (not account passwords)
3. **Enable TLS/SSL** for SMTP connections
4. **Rotate credentials** regularly
5. **Use environment variables** for sensitive data

### Network Security

- SMTP connections use STARTTLS encryption
- All credentials are transmitted securely
- No plaintext passwords in logs

## Support

### Getting Help

1. Check the logs for error messages
2. Verify SMTP configuration with `test_smtp.py`
3. Test individual components with unit tests
4. Review the troubleshooting section

### Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

This project is part of the Movie Ticket Booking System and follows the same license terms.
