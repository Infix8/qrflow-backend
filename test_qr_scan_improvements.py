#!/usr/bin/env python3
"""
Test script for improved QR scanning functionality
Tests the new features: better messaging, race condition handling, and edge cases
"""

import requests
import json
import time
from datetime import datetime
import sys

# Configuration
BASE_URL = "http://localhost:8000"  # Adjust if your server runs on different port
TEST_QR_TOKEN = "test_token_here"  # Replace with actual QR token for testing

def test_qr_validation():
    """Test QR token validation endpoint"""
    print("🧪 Testing QR token validation...")
    
    url = f"{BASE_URL}/api/checkin/validate"
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_TOKEN_HERE"  # Replace with actual token
    }
    data = {
        "qr_token": TEST_QR_TOKEN
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error testing validation: {e}")
        return False

def test_qr_scan_success():
    """Test successful QR scan"""
    print("\n🧪 Testing successful QR scan...")
    
    url = f"{BASE_URL}/api/checkin/scan"
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_TOKEN_HERE"  # Replace with actual token
    }
    data = {
        "qr_token": TEST_QR_TOKEN
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error testing scan: {e}")
        return False

def test_duplicate_scan():
    """Test duplicate QR scan (should show already checked in message)"""
    print("\n🧪 Testing duplicate QR scan...")
    
    url = f"{BASE_URL}/api/checkin/scan"
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_TOKEN_HERE"  # Replace with actual token
    }
    data = {
        "qr_token": TEST_QR_TOKEN
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        # Should return success: false with already checked in message
        result = response.json()
        if not result.get("success") and "already checked in" in result.get("message", "").lower():
            print("✅ Duplicate scan handling works correctly!")
            return True
        else:
            print("❌ Duplicate scan handling not working as expected")
            return False
    except Exception as e:
        print(f"❌ Error testing duplicate scan: {e}")
        return False

def test_invalid_token():
    """Test invalid QR token"""
    print("\n🧪 Testing invalid QR token...")
    
    url = f"{BASE_URL}/api/checkin/scan"
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_TOKEN_HERE"  # Replace with actual token
    }
    data = {
        "qr_token": "invalid_token_123"
    }
    
    try:
        response = requests.post(url, json=data, headers=headers)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        # Should return success: false with invalid token message
        result = response.json()
        if not result.get("success") and "invalid" in result.get("message", "").lower():
            print("✅ Invalid token handling works correctly!")
            return True
        else:
            print("❌ Invalid token handling not working as expected")
            return False
    except Exception as e:
        print(f"❌ Error testing invalid token: {e}")
        return False

def test_race_condition():
    """Test race condition by sending multiple simultaneous requests"""
    print("\n🧪 Testing race condition handling...")
    
    import threading
    import concurrent.futures
    
    url = f"{BASE_URL}/api/checkin/scan"
    headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_TOKEN_HERE"  # Replace with actual token
    }
    data = {
        "qr_token": TEST_QR_TOKEN
    }
    
    def make_request():
        try:
            response = requests.post(url, json=data, headers=headers)
            return response.json()
        except Exception as e:
            return {"error": str(e)}
    
    # Send 5 simultaneous requests
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        futures = [executor.submit(make_request) for _ in range(5)]
        results = [future.result() for future in concurrent.futures.as_completed(futures)]
    
    print(f"Results: {json.dumps(results, indent=2)}")
    
    # Check that only one request succeeded and others show already checked in
    success_count = sum(1 for r in results if r.get("success"))
    already_checked_count = sum(1 for r in results if not r.get("success") and "already checked in" in r.get("message", "").lower())
    
    if success_count == 1 and already_checked_count == 4:
        print("✅ Race condition handling works correctly!")
        return True
    else:
        print(f"❌ Race condition handling not working as expected. Success: {success_count}, Already checked: {already_checked_count}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting QR Scan Improvements Test Suite")
    print("=" * 50)
    
    print("\n⚠️  IMPORTANT: Before running tests:")
    print("1. Make sure your server is running on the correct port")
    print("2. Replace 'YOUR_TOKEN_HERE' with a valid authentication token")
    print("3. Replace 'test_token_here' with a valid QR token for testing")
    print("4. Ensure you have attendees in your database")
    
    input("\nPress Enter to continue with tests...")
    
    tests = [
        ("QR Validation", test_qr_validation),
        ("QR Scan Success", test_qr_scan_success),
        ("Duplicate Scan", test_duplicate_scan),
        ("Invalid Token", test_invalid_token),
        ("Race Condition", test_race_condition),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n{'='*20} {test_name} {'='*20}")
        try:
            if test_func():
                passed += 1
                print(f"✅ {test_name} PASSED")
            else:
                print(f"❌ {test_name} FAILED")
        except Exception as e:
            print(f"❌ {test_name} ERROR: {e}")
    
    print(f"\n{'='*50}")
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! QR scanning improvements are working correctly.")
    else:
        print("⚠️  Some tests failed. Please check the implementation.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
