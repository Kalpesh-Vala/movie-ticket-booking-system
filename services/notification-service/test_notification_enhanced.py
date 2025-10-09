#!/usr/bin/env python3
"""
Enhanced Notification Service Test with SMTP Integration
Tests the notification service with real SMTP email sending
"""

import asyncio
import json
import logging
import os
import sys
from datetime import datetime

# Add the service directory to the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from worker import NotificationWorker

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

async def test_notification_service_with_smtp():
    """Test notification service with SMTP email functionality"""
    
    print("🔔 Enhanced Notification Service Test with SMTP")
    print("=" * 55)
    
    # Initialize worker
    worker = NotificationWorker()
    
    # Check SMTP configuration
    print("🔧 Checking SMTP Configuration...")
    smtp_configured = worker.email_service.test_configuration()
    if smtp_configured:
        print("✅ SMTP is configured and ready")
        
        # Get test email for real email testing
        test_email = input("\nEnter your email address to receive test notifications: ").strip()
        if not test_email:
            print("❌ Email address required for SMTP testing")
            return False
    else:
        print("⚠️  SMTP not configured - will simulate email sending")
        test_email = "test@example.com"
    
    print()
    
    try:
        # Test 1: Booking confirmation notification
        print("Test 1: Booking Confirmation Notification")
        print("-" * 40)
        
        booking_event = {
            "event_id": "evt_booking_001",
            "event_type": "booking.confirmed",
            "user_id": "user_123",
            "user_email": test_email,
            "booking_id": "BOOK-789012",
            "movie_title": "Inception",
            "showtime": "2024-12-15 8:00 PM",
            "seats": ["B5", "B6"],
            "total_amount": 30.00,
            "timestamp": datetime.now().isoformat()
        }
        
        success = await worker.handle_booking_confirmed(booking_event)
        if success:
            print("✅ Booking confirmation notification processed successfully")
        else:
            print("❌ Booking confirmation notification failed")
        
        print()
        
        # Test 2: Payment success notification
        print("Test 2: Payment Success Notification")
        print("-" * 35)
        
        payment_success_event = {
            "event_id": "evt_payment_001",
            "event_type": "payment.success",
            "user_id": "user_123",
            "user_email": test_email,
            "booking_id": "BOOK-789012",
            "transaction_id": "TXN-456789",
            "amount": 30.00,
            "payment_method": "credit_card",
            "timestamp": datetime.now().isoformat()
        }
        
        success = await worker.handle_payment_success(payment_success_event)
        if success:
            print("✅ Payment success notification processed successfully")
        else:
            print("❌ Payment success notification failed")
        
        print()
        
        # Test 3: Payment failed notification
        print("Test 3: Payment Failed Notification")
        print("-" * 34)
        
        payment_failed_event = {
            "event_id": "evt_payment_002",
            "event_type": "payment.failed",
            "user_id": "user_123",
            "user_email": test_email,
            "booking_id": "BOOK-789012",
            "amount": 30.00,
            "payment_method": "credit_card",
            "failure_reason": "Insufficient funds",
            "timestamp": datetime.now().isoformat()
        }
        
        success = await worker.handle_payment_failed(payment_failed_event)
        if success:
            print("✅ Payment failed notification processed successfully")
        else:
            print("❌ Payment failed notification failed")
        
        print()
        
        # Test 4: Booking cancellation notification
        print("Test 4: Booking Cancellation Notification")
        print("-" * 39)
        
        cancellation_event = {
            "event_id": "evt_booking_002",
            "event_type": "booking.cancelled",
            "user_id": "user_123",
            "user_email": test_email,
            "booking_id": "BOOK-789012",
            "cancellation_reason": "User requested cancellation",
            "cancelled_at": datetime.now().isoformat(),
            "timestamp": datetime.now().isoformat()
        }
        
        success = await worker.handle_booking_cancelled(cancellation_event)
        if success:
            print("✅ Booking cancellation notification processed successfully")
        else:
            print("❌ Booking cancellation notification failed")
        
        print()
        
        # Test 5: Refund notification
        print("Test 5: Refund Notification")
        print("-" * 24)
        
        refund_event = {
            "event_id": "evt_payment_003",
            "event_type": "payment.refund",
            "user_id": "user_123",
            "user_email": test_email,
            "booking_id": "BOOK-789012",
            "original_transaction_id": "TXN-456789",
            "refund_transaction_id": "REF-123456",
            "refund_amount": 30.00,
            "timestamp": datetime.now().isoformat()
        }
        
        success = await worker.handle_payment_refund(refund_event)
        if success:
            print("✅ Refund notification processed successfully")
        else:
            print("❌ Refund notification failed")
        
        print()
        
        # Summary
        print("🎉 Enhanced Notification Service Testing Completed!")
        print("=" * 50)
        
        if smtp_configured and test_email != "test@example.com":
            print(f"📧 Check your email inbox ({test_email}) for the test notifications")
            print("📱 SMS notifications are still simulated (would need Twilio/AWS SNS)")
        else:
            print("📧 Email notifications were simulated (SMTP not configured)")
            print("📱 SMS notifications were simulated")
        
        print("\nTo enable real email sending:")
        print("1. Copy .env.example to .env")
        print("2. Fill in your SMTP credentials")
        print("3. For Gmail: Enable 2FA and create an App Password")
        print("4. Run the test again")
        
        return True
        
    except Exception as e:
        logger.error(f"Test failed with error: {e}")
        return False

def setup_test_environment():
    """Setup test environment variables"""
    # Load .env file if it exists
    env_file = os.path.join(os.path.dirname(__file__), '.env')
    if os.path.exists(env_file):
        print(f"📁 Loading environment from: {env_file}")
        with open(env_file, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key] = value
        print("✅ Environment variables loaded")
    else:
        print("📝 No .env file found - using defaults and simulated email")

async def main():
    """Main test function"""
    print("🎬 Movie Ticket Booking System - Enhanced Notification Test")
    print("=" * 62)
    print()
    
    # Setup environment
    setup_test_environment()
    
    # Run enhanced tests
    await test_notification_service_with_smtp()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n👋 Test interrupted by user")
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        logger.exception("Test error details:")