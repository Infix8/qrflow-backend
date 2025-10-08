#!/usr/bin/env python3
"""
Test script for Razorpay payment synchronization
"""

import requests
import json
from datetime import datetime, timedelta

# Configuration
BASE_URL = "http://localhost:8000"
ADMIN_USERNAME = "admin"  # Replace with your admin username
ADMIN_PASSWORD = "admin123"  # Replace with your admin password

def login():
    """Login and get access token"""
    response = requests.post(f"{BASE_URL}/api/auth/login", data={
        "username": ADMIN_USERNAME,
        "password": ADMIN_PASSWORD
    })
    
    if response.status_code == 200:
        token_data = response.json()
        return token_data["access_token"]
    else:
        print(f"❌ Login failed: {response.text}")
        return None

def sync_payments(token, from_date=None, to_date=None, count=10):
    """Sync payments from Razorpay API"""
    headers = {"Authorization": f"Bearer {token}"}
    
    params = {
        "count": count,
        "skip": 0
    }
    
    if from_date:
        params["from_date"] = from_date
    if to_date:
        params["to_date"] = to_date
    
    print(f"🔄 Syncing payments from Razorpay...")
    print(f"📅 Date range: {from_date} to {to_date}")
    print(f"📊 Count: {count}")
    
    response = requests.get(
        f"{BASE_URL}/api/payments/sync-from-razorpay",
        headers=headers,
        params=params
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ Sync successful!")
        print(f"📊 Total fetched: {result['total_fetched']}")
        print(f"🎯 QR Flow payments: {result['qr_flow_payments']}")
        print(f"✅ Synced: {result['synced']}")
        print(f"➕ Created: {result['created']}")
        print(f"🔄 Updated: {result['updated']}")
        
        if result['errors']:
            print(f"❌ Errors: {len(result['errors'])}")
            for error in result['errors'][:3]:  # Show first 3 errors
                print(f"   - {error}")
        
        return result
    else:
        print(f"❌ Sync failed: {response.text}")
        return None

def get_payment_status(token, payment_id):
    """Get payment status from Razorpay"""
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(
        f"{BASE_URL}/api/payments/razorpay-status",
        headers=headers,
        params={"payment_id": payment_id}
    )
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ Payment status retrieved:")
        print(f"   ID: {result['payment']['id']}")
        print(f"   Amount: ₹{result['payment']['amount']/100}")
        print(f"   Status: {result['payment']['status']}")
        print(f"   Method: {result['payment']['method']}")
        print(f"   Description: {result['payment']['description']}")
        return result
    else:
        print(f"❌ Failed to get payment status: {response.text}")
        return None

def main():
    print("🚀 Razorpay Payment Sync Test")
    print("=" * 50)
    
    # Login
    print("🔐 Logging in...")
    token = login()
    if not token:
        return
    
    print("✅ Login successful!")
    print()
    
    # Test 1: Sync recent payments (last 7 days)
    print("📅 Test 1: Syncing recent payments (last 7 days)")
    print("-" * 50)
    
    # Calculate date range for last 7 days
    to_date = datetime.now()
    from_date = to_date - timedelta(days=7)
    
    result = sync_payments(
        token,
        from_date=from_date.isoformat(),
        to_date=to_date.isoformat(),
        count=20
    )
    print()
    
    # Test 2: Sync specific payment IDs (from your example)
    print("🎯 Test 2: Checking specific payment IDs")
    print("-" * 50)
    
    test_payment_ids = [
        "pay_RQf7P6MmPiaDcH",
        "pay_RQUmJx0pTRTqYc"
    ]
    
    for payment_id in test_payment_ids:
        print(f"🔍 Checking payment: {payment_id}")
        get_payment_status(token, payment_id)
        print()
    
    # Test 3: Sync with no date filter (recent payments)
    print("📊 Test 3: Syncing recent payments (no date filter)")
    print("-" * 50)
    
    result = sync_payments(token, count=10)
    print()
    
    print("✅ All tests completed!")

if __name__ == "__main__":
    main()
