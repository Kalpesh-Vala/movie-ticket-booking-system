#!/usr/bin/env python3
"""
SMTP Email Service Test Script
Tests the email functionality with real SMTP sending
"""

import asyncio
import logging
import os
import sys
from datetime import datetime

# Add the service directory to the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from smtp_service import SMTPEmailService

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def test_smtp_service():
    """Test SMTP email service with different templates"""
    
    # Initialize email service
    email_service = SMTPEmailService()
    
    print("🔧 SMTP Email Service Test")
    print("=" * 50)
    
    # Check configuration
    if not email_service.test_configuration():
        print("❌ SMTP configuration incomplete. Please set environment variables:")
        print("   - SMTP_USERNAME")
        print("   - SMTP_PASSWORD")
        print("   - SMTP_SERVER (optional, defaults to smtp.gmail.com)")
        print("   - SMTP_PORT (optional, defaults to 587)")
        return False
    
    # Get test email address
    test_email = input("Enter your email address for testing: ").strip()
    if not test_email:
        print("❌ Email address is required for testing")
        return False
    
    print(f"📧 Testing email sending to: {test_email}")
    print()
    
    # Test 1: Send test email
    print("Test 1: Basic SMTP Test Email")
    print("-" * 30)
    try:
        success = await email_service.send_test_email(test_email)
        if success:
            print("✅ Test email sent successfully!")
        else:
            print("❌ Test email failed")
            return False
    except Exception as e:
        print(f"❌ Test email error: {e}")
        return False
    
    print()
    
    # Test 2: Booking confirmation email
    print("Test 2: Booking Confirmation Email")
    print("-" * 35)
    booking_data = {
        "booking_id": "BOOK-123456",
        "movie_title": "The Matrix Reloaded",
        "showtime": "2024-12-15 7:30 PM",
        "seats": ["A1", "A2"],
        "total_amount": "25.50"
    }
    
    try:
        success = await email_service.send_email(
            to_email=test_email,
            subject="Your Movie Booking Confirmation",
            template_name="booking_confirmation",
            template_data=booking_data
        )
        if success:
            print("✅ Booking confirmation email sent!")
        else:
            print("❌ Booking confirmation email failed")
    except Exception as e:
        print(f"❌ Booking confirmation error: {e}")
    
    print()
    
    # Test 3: Payment success email
    print("Test 3: Payment Success Email")
    print("-" * 28)
    payment_data = {
        "transaction_id": "TXN-789012",
        "booking_id": "BOOK-123456",
        "amount": "25.50",
        "payment_method": "credit_card"
    }
    
    try:
        success = await email_service.send_email(
            to_email=test_email,
            subject="Payment Successful - Booking Confirmed",
            template_name="payment_success",
            template_data=payment_data
        )
        if success:
            print("✅ Payment success email sent!")
        else:
            print("❌ Payment success email failed")
    except Exception as e:
        print(f"❌ Payment success error: {e}")
    
    print()
    
    # Test 4: Payment failed email
    print("Test 4: Payment Failed Email")
    print("-" * 26)
    payment_failed_data = {
        "booking_id": "BOOK-123456",
        "amount": "25.50",
        "payment_method": "credit_card",
        "failure_reason": "Insufficient funds"
    }
    
    try:
        success = await email_service.send_email(
            to_email=test_email,
            subject="Payment Failed - Action Required",
            template_name="payment_failed",
            template_data=payment_failed_data
        )
        if success:
            print("✅ Payment failed email sent!")
        else:
            print("❌ Payment failed email failed")
    except Exception as e:
        print(f"❌ Payment failed error: {e}")
    
    print()
    
    # Test 5: Plain text email
    print("Test 5: Plain Text Email")
    print("-" * 23)
    try:
        success = await email_service.send_plain_email(
            to_email=test_email,
            subject="Plain Text Test",
            text_content="This is a plain text email test from the Movie Ticket Booking System."
        )
        if success:
            print("✅ Plain text email sent!")
        else:
            print("❌ Plain text email failed")
    except Exception as e:
        print(f"❌ Plain text error: {e}")
    
    print()
    print("🎉 SMTP Email Service testing completed!")
    print("Check your email inbox for the test messages.")
    
    return True

def setup_test_environment():
    """Setup test environment variables"""
    print("🔧 SMTP Configuration Setup")
    print("=" * 30)
    
    # Check if .env file exists
    env_file = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_file):
        print(f"📁 Found .env file: {env_file}")
        print("Loading environment variables from .env file...")
        
        # Simple .env loader
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value
        print("✅ Environment variables loaded from .env file")
    else:
        print("📝 No .env file found. You can:")
        print("   1. Copy .env.example to .env and fill in your SMTP settings")
        print("   2. Set environment variables manually")
        print("   3. Enter them interactively below")
        
        if input("Do you want to enter SMTP settings interactively? (y/n): ").lower() == 'y':
            print("\nEnter your SMTP settings:")
            os.environ['SMTP_SERVER'] = input("SMTP Server (default: smtp.gmail.com): ") or "smtp.gmail.com"
            os.environ['SMTP_PORT'] = input("SMTP Port (default: 587): ") or "587"
            os.environ['SMTP_USERNAME'] = input("SMTP Username (your email): ")
            os.environ['SMTP_PASSWORD'] = input("SMTP Password (app password for Gmail): ")
            os.environ['FROM_EMAIL'] = os.environ['SMTP_USERNAME']
            os.environ['FROM_NAME'] = input("From Name (default: Movie Booking System): ") or "Movie Booking System"
    
    print()

async def main():
    """Main test function"""
    print("🎬 Movie Ticket Booking System - SMTP Email Test")
    print("=" * 55)
    print()
    
    # Setup environment
    setup_test_environment()
    
    # Run tests
    await test_smtp_service()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        logger.exception("Test error details:")