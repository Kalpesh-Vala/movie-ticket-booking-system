"""
SMTP Email Service for Notification System
Handles actual email sending using SMTP protocol with templates
"""

import asyncio
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from typing import Dict, Any, Optional, List
import logging
from jinja2 import Environment, DictLoader
import aiosmtplib
from email.message import EmailMessage

logger = logging.getLogger(__name__)


class SMTPEmailService:
    """SMTP Email Service with template support and async sending"""
    
    def __init__(self):
        # SMTP Configuration from environment variables
        self.smtp_server = os.getenv("SMTP_SERVER", "smtp.gmail.com")
        self.smtp_port = int(os.getenv("SMTP_PORT", "587"))
        self.smtp_username = os.getenv("SMTP_USERNAME", "")
        self.smtp_password = os.getenv("SMTP_PASSWORD", "")
        self.from_email = os.getenv("FROM_EMAIL", self.smtp_username)
        self.from_name = os.getenv("FROM_NAME", "Movie Ticket Booking System")
        
        # Email templates
        self.templates = self._load_email_templates()
        self.jinja_env = Environment(loader=DictLoader(self.templates))
        
        logger.info(f"SMTP Email Service initialized with server: {self.smtp_server}:{self.smtp_port}")

    def _load_email_templates(self) -> Dict[str, str]:
        """Load email templates for different notification types"""
        return {
            "booking_confirmation": """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Booking Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #2c3e50; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .booking-details { background: white; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .success { color: #27ae60; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎬 Booking Confirmed!</h1>
        </div>
        <div class="content">
            <p class="success">Great news! Your movie ticket booking has been confirmed.</p>
            
            <div class="booking-details">
                <h3>Booking Details:</h3>
                <p><strong>Booking ID:</strong> {{ booking_id }}</p>
                <p><strong>Movie:</strong> {{ movie_title }}</p>
                <p><strong>Showtime:</strong> {{ showtime }}</p>
                <p><strong>Seats:</strong> {{ seats|join(', ') }}</p>
                <p><strong>Total Amount:</strong> ${{ total_amount }}</p>
            </div>
            
            <p>Please arrive at the cinema at least 15 minutes before showtime.</p>
            <p>Show this email as proof of booking at the cinema entrance.</p>
        </div>
        <div class="footer">
            <p>Thank you for choosing our movie booking service!</p>
            <p>If you have any questions, please contact our support team.</p>
        </div>
    </div>
</body>
</html>
            """,
            
            "booking_cancellation": """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Booking Cancelled</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #e74c3c; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .booking-details { background: white; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .cancelled { color: #e74c3c; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚫 Booking Cancelled</h1>
        </div>
        <div class="content">
            <p class="cancelled">Your movie ticket booking has been cancelled.</p>
            
            <div class="booking-details">
                <h3>Cancelled Booking Details:</h3>
                <p><strong>Booking ID:</strong> {{ booking_id }}</p>
                <p><strong>Cancellation Reason:</strong> {{ cancellation_reason|default('Not specified') }}</p>
                <p><strong>Cancelled At:</strong> {{ cancelled_at|default('Just now') }}</p>
            </div>
            
            <p>If you cancelled this booking, no further action is required.</p>
            <p>If this cancellation was unexpected, please contact our support team immediately.</p>
            <p>Any applicable refunds will be processed within 5-7 business days.</p>
        </div>
        <div class="footer">
            <p>We hope to serve you again soon!</p>
        </div>
    </div>
</body>
</html>
            """,
            
            "payment_success": """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Payment Successful</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #27ae60; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .payment-details { background: white; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .success { color: #27ae60; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>💳 Payment Successful!</h1>
        </div>
        <div class="content">
            <p class="success">Your payment has been processed successfully!</p>
            
            <div class="payment-details">
                <h3>Payment Details:</h3>
                <p><strong>Transaction ID:</strong> {{ transaction_id }}</p>
                <p><strong>Booking ID:</strong> {{ booking_id }}</p>
                <p><strong>Amount Paid:</strong> ${{ amount }}</p>
                <p><strong>Payment Method:</strong> {{ payment_method|title }}</p>
                <p><strong>Status:</strong> <span class="success">Completed</span></p>
            </div>
            
            <p>Your booking is now confirmed and you will receive a separate confirmation email shortly.</p>
            <p>Keep this email as a receipt for your records.</p>
        </div>
        <div class="footer">
            <p>Thank you for your payment!</p>
        </div>
    </div>
</body>
</html>
            """,
            
            "payment_failed": """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Payment Failed</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #e74c3c; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .payment-details { background: white; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .failed { color: #e74c3c; font-weight: bold; }
        .retry-button { background: #3498db; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>❌ Payment Failed</h1>
        </div>
        <div class="content">
            <p class="failed">Unfortunately, your payment could not be processed.</p>
            
            <div class="payment-details">
                <h3>Payment Details:</h3>
                <p><strong>Booking ID:</strong> {{ booking_id }}</p>
                <p><strong>Amount:</strong> ${{ amount }}</p>
                <p><strong>Payment Method:</strong> {{ payment_method|title }}</p>
                <p><strong>Failure Reason:</strong> {{ failure_reason }}</p>
            </div>
            
            <p>Please check your payment information and try again.</p>
            <p>Common issues include:</p>
            <ul>
                <li>Insufficient funds</li>
                <li>Expired card</li>
                <li>Incorrect card details</li>
                <li>Card blocked by bank</li>
            </ul>
            
            <a href="#" class="retry-button">Retry Payment</a>
        </div>
        <div class="footer">
            <p>Need help? Contact our support team.</p>
        </div>
    </div>
</body>
</html>
            """,
            
            "payment_refund": """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Refund Processed</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #f39c12; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .refund-details { background: white; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        .refund { color: #f39c12; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>💰 Refund Processed</h1>
        </div>
        <div class="content">
            <p class="refund">Your refund has been processed successfully!</p>
            
            <div class="refund-details">
                <h3>Refund Details:</h3>
                <p><strong>Booking ID:</strong> {{ booking_id }}</p>
                <p><strong>Original Transaction:</strong> {{ original_transaction_id }}</p>
                <p><strong>Refund Transaction:</strong> {{ refund_transaction_id }}</p>
                <p><strong>Refund Amount:</strong> ${{ refund_amount }}</p>
            </div>
            
            <p>The refund will appear in your account within 5-7 business days.</p>
            <p>The exact timing depends on your bank or payment provider.</p>
        </div>
        <div class="footer">
            <p>Thank you for your understanding!</p>
        </div>
    </div>
</body>
</html>
            """
        }

    async def send_email(self, to_email: str, subject: str, template_name: str, 
                        template_data: Dict[str, Any], attachments: Optional[List[str]] = None) -> bool:
        """
        Send email using SMTP with HTML template
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            template_name: Name of the template to use
            template_data: Data to populate the template
            attachments: Optional list of file paths to attach
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            # Validate configuration
            if not self.smtp_username or not self.smtp_password:
                logger.error("SMTP credentials not configured")
                return False
            
            # Render template
            template = self.jinja_env.get_template(template_name)
            html_content = template.render(**template_data)
            
            # Create message
            message = EmailMessage()
            message["From"] = f"{self.from_name} <{self.from_email}>"
            message["To"] = to_email
            message["Subject"] = subject
            
            # Set HTML content
            message.set_content(html_content, subtype='html')
            
            # Add attachments if provided
            if attachments:
                for attachment_path in attachments:
                    if os.path.exists(attachment_path):
                        with open(attachment_path, 'rb') as f:
                            file_data = f.read()
                            file_name = os.path.basename(attachment_path)
                            message.add_attachment(file_data, filename=file_name)
                        logger.info(f"Added attachment: {file_name}")
            
            # Send email using aiosmtplib
            await aiosmtplib.send(
                message,
                hostname=self.smtp_server,
                port=self.smtp_port,
                start_tls=True,
                username=self.smtp_username,
                password=self.smtp_password,
            )
            
            logger.info(f"📧 Email sent successfully to {to_email} - Subject: {subject}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send email to {to_email}: {e}")
            return False

    async def send_plain_email(self, to_email: str, subject: str, text_content: str) -> bool:
        """
        Send plain text email
        
        Args:
            to_email: Recipient email address
            subject: Email subject
            text_content: Plain text content
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            if not self.smtp_username or not self.smtp_password:
                logger.error("SMTP credentials not configured")
                return False
            
            # Create message
            message = EmailMessage()
            message["From"] = f"{self.from_name} <{self.from_email}>"
            message["To"] = to_email
            message["Subject"] = subject
            message.set_content(text_content)
            
            # Send email
            await aiosmtplib.send(
                message,
                hostname=self.smtp_server,
                port=self.smtp_port,
                start_tls=True,
                username=self.smtp_username,
                password=self.smtp_password,
            )
            
            logger.info(f"📧 Plain email sent successfully to {to_email}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to send plain email to {to_email}: {e}")
            return False

    def test_configuration(self) -> bool:
        """Test SMTP configuration"""
        required_vars = ["SMTP_USERNAME", "SMTP_PASSWORD"]
        missing_vars = [var for var in required_vars if not os.getenv(var)]
        
        if missing_vars:
            logger.error(f"Missing SMTP configuration: {missing_vars}")
            return False
        
        logger.info("SMTP configuration is complete")
        return True

    async def send_test_email(self, to_email: str) -> bool:
        """Send a test email to verify SMTP configuration"""
        test_data = {
            "service_name": "Movie Ticket Booking System",
            "test_time": "now",
            "status": "operational"
        }
        
        test_content = """
        <h2>SMTP Test Email</h2>
        <p>This is a test email from the Movie Ticket Booking System notification service.</p>
        <p>If you received this email, the SMTP configuration is working correctly!</p>
        <p><strong>Service:</strong> {{ service_name }}</p>
        <p><strong>Time:</strong> {{ test_time }}</p>
        <p><strong>Status:</strong> {{ status }}</p>
        """
        
        try:
            template = Environment().from_string(test_content)
            html_content = template.render(**test_data)
            
            message = EmailMessage()
            message["From"] = f"{self.from_name} <{self.from_email}>"
            message["To"] = to_email
            message["Subject"] = "SMTP Test - Movie Booking System"
            message.set_content(html_content, subtype='html')
            
            await aiosmtplib.send(
                message,
                hostname=self.smtp_server,
                port=self.smtp_port,
                start_tls=True,
                username=self.smtp_username,
                password=self.smtp_password,
            )
            
            logger.info(f"✅ Test email sent successfully to {to_email}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Test email failed: {e}")
            return False