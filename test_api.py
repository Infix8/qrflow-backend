#!/usr/bin/env python3
"""
Quick API Test Script for QRFlow Backend
This script demonstrates how to test the API endpoints
"""

import requests
import json
import sys

# Configuration
BASE_URL = "http://localhost:8000"
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin123"

def test_health():
    """Test health endpoint"""
    print("🔍 Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("✅ Health check passed:", response.json())
            return True
        else:
            print("❌ Health check failed:", response.status_code)
            return False
    except Exception as e:
        print("❌ Health check error:", str(e))
        return False

def login():
    """Login and get JWT token"""
    print("🔐 Logging in...")
    try:
        data = {
            "username": ADMIN_USERNAME,
            "password": ADMIN_PASSWORD
        }
        response = requests.post(f"{BASE_URL}/api/auth/login", data=data)
        if response.status_code == 200:
            token_data = response.json()
            print("✅ Login successful!")
            return token_data["access_token"]
        else:
            print("❌ Login failed:", response.status_code, response.text)
            return None
    except Exception as e:
        print("❌ Login error:", str(e))
        return None

def test_api_endpoints(token):
    """Test various API endpoints"""
    headers = {"Authorization": f"Bearer {token}"}
    
    print("\n📊 Testing API endpoints...")
    
    # Test 1: Get current user
    print("1. Testing /api/auth/me...")
    try:
        response = requests.get(f"{BASE_URL}/api/auth/me", headers=headers)
        if response.status_code == 200:
            user_data = response.json()
            print(f"✅ Current user: {user_data['username']} ({user_data['role']})")
        else:
            print(f"❌ Failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 2: List clubs
    print("2. Testing /api/admin/clubs...")
    try:
        response = requests.get(f"{BASE_URL}/api/admin/clubs", headers=headers)
        if response.status_code == 200:
            clubs = response.json()
            print(f"✅ Found {len(clubs)} clubs")
            for club in clubs:
                print(f"   - {club['name']}: {club['description']}")
        else:
            print(f"❌ Failed: {response.status_code}")
    except Exception as e:
        print(f"❌ Error: {str(e)}")
    
    # Test 3: Create a test club
    print("3. Testing club creation...")
    try:
        club_data = {
            "name": "Test Club",
            "description": "Test club for API testing"
        }
        response = requests.post(f"{BASE_URL}/api/admin/clubs", 
                               headers=headers, 
                               json=club_data)
        if response.status_code == 200:
            club = response.json()
            print(f"✅ Created club: {club['name']} (ID: {club['id']})")
            return club['id']
        else:
            print(f"❌ Failed: {response.status_code} - {response.text}")
            return None
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return None

def test_webhook_endpoint():
    """Test webhook endpoint"""
    print("\n🔗 Testing webhook endpoint...")
    try:
        # Test with invalid data (should return error)
        response = requests.post(f"{BASE_URL}/api/webhooks/razorpay", 
                               json={"test": "webhook"})
        print(f"Webhook endpoint response: {response.status_code}")
        if response.status_code in [400, 422]:  # Expected for invalid webhook
            print("✅ Webhook endpoint is accessible (returned expected error)")
        else:
            print(f"⚠️  Unexpected response: {response.text}")
    except Exception as e:
        print(f"❌ Webhook test error: {str(e)}")

def main():
    """Main test function"""
    print("🚀 QRFlow Backend API Test")
    print("=" * 50)
    
    # Test 1: Health check
    if not test_health():
        print("❌ Application is not running. Please start it first:")
        print("   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload")
        sys.exit(1)
    
    # Test 2: Login
    token = login()
    if not token:
        print("❌ Cannot proceed without authentication token")
        sys.exit(1)
    
    # Test 3: API endpoints
    club_id = test_api_endpoints(token)
    
    # Test 4: Webhook endpoint
    test_webhook_endpoint()
    
    print("\n" + "=" * 50)
    print("🎉 API Testing Complete!")
    print("\n📋 Next Steps:")
    print("1. Configure Razorpay credentials in .env file")
    print("2. Test payment sync:")
    print("   curl -X POST 'http://localhost:8000/api/payments/sync' -H 'Authorization: Bearer YOUR_TOKEN'")
    print("3. Monitor payment sync logs")
    print("4. Test complete payment flow")
    print("\n📖 See PAYMENT_SYNC_GUIDE.md for detailed instructions")

if __name__ == "__main__":
    main()
