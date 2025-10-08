#!/usr/bin/env python3
"""
Simple Test Suite for QRFlow Backend API
Tests all endpoints without logout to avoid token blacklisting issues
"""

import requests
import json
import sys
import time
import csv
import io
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any

# Configuration
BASE_URL = "http://localhost:8000"
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin123"

class SimpleAPITester:
    def __init__(self):
        self.base_url = BASE_URL
        self.token = None
        self.test_results = []
        self.test_data = {
            'club_id': None,
            'user_id': None,
            'event_id': None,
            'attendee_id': None,
            'payment_id': None
        }
        self.created_resources = []  # Track created resources for cleanup

    def log_test(self, test_name: str, success: bool, message: str = "", details: Any = None):
        """Log test results with detailed information"""
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} - {test_name}")
        if message:
            print(f"    {message}")
        if details:
            print(f"    Details: {details}")
        
        self.test_results.append({
            "test": test_name,
            "success": success,
            "message": message,
            "details": details,
            "timestamp": datetime.now().isoformat()
        })

    def get_headers(self) -> Dict[str, str]:
        """Get headers with authentication token"""
        if not self.token:
            raise Exception("No authentication token available")
        return {"Authorization": f"Bearer {self.token}"}

    def test_health_endpoints(self):
        """Test health and root endpoints"""
        print("\n🔍 Testing Health Endpoints...")
        
        # Test root endpoint
        try:
            response = requests.get(f"{self.base_url}/", timeout=10)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Root Endpoint", True, f"API Status: {data.get('status')}")
            else:
                self.log_test("Root Endpoint", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Root Endpoint", False, f"Error: {str(e)}")

        # Test health endpoint
        try:
            response = requests.get(f"{self.base_url}/health", timeout=10)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Health Check", True, f"Database: {data.get('database')}")
            else:
                self.log_test("Health Check", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Health Check", False, f"Error: {str(e)}")

    def test_authentication(self):
        """Test authentication endpoints"""
        print("\n🔐 Testing Authentication...")
        
        # Test login
        try:
            data = {"username": ADMIN_USERNAME, "password": ADMIN_PASSWORD}
            response = requests.post(f"{self.base_url}/api/auth/login", data=data, timeout=10)
            if response.status_code == 200:
                token_data = response.json()
                self.token = token_data["access_token"]
                self.log_test("Login", True, f"Token received: {self.token[:20]}...")
            else:
                self.log_test("Login", False, f"Status code: {response.status_code}, Response: {response.text}")
                return False
        except Exception as e:
            self.log_test("Login", False, f"Error: {str(e)}")
            return False

        # Test get current user
        if self.token:
            try:
                headers = self.get_headers()
                response = requests.get(f"{self.base_url}/api/auth/me", headers=headers, timeout=10)
                if response.status_code == 200:
                    user_data = response.json()
                    self.log_test("Get Current User", True, f"User: {user_data['username']} ({user_data['role']})")
                else:
                    self.log_test("Get Current User", False, f"Status code: {response.status_code}")
            except Exception as e:
                self.log_test("Get Current User", False, f"Error: {str(e)}")

        return self.token is not None

    def test_admin_club_management(self):
        """Test admin club management endpoints"""
        print("\n🏛️ Testing Admin Club Management...")
        
        if not self.token:
            self.log_test("Admin Club Management", False, "No authentication token")
            return

        headers = self.get_headers()

        # Test list clubs
        try:
            response = requests.get(f"{self.base_url}/api/admin/clubs", headers=headers, timeout=10)
            if response.status_code == 200:
                clubs = response.json()
                self.log_test("List Clubs", True, f"Found {len(clubs)} clubs")
            else:
                self.log_test("List Clubs", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("List Clubs", False, f"Error: {str(e)}")

        # Test create club
        try:
            club_data = {
                "name": f"Test Club {int(time.time())}",
                "description": "Simple test club",
                "email": "test@example.com",
                "phone": "1234567890"
            }
            response = requests.post(f"{self.base_url}/api/admin/clubs", 
                                   headers=headers, json=club_data, timeout=10)
            if response.status_code == 200:
                club = response.json()
                self.test_data['club_id'] = club['id']
                self.created_resources.append(('club', club['id']))
                self.log_test("Create Club", True, f"Created club ID: {club['id']}")
            else:
                self.log_test("Create Club", False, f"Status code: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Create Club", False, f"Error: {str(e)}")

        # Test update club
        if self.test_data['club_id']:
            try:
                update_data = {
                    "description": "Updated test club description",
                    "phone": "0987654321"
                }
                response = requests.put(f"{self.base_url}/api/admin/clubs/{self.test_data['club_id']}", 
                                      headers=headers, json=update_data, timeout=10)
                if response.status_code == 200:
                    self.log_test("Update Club", True, "Club updated successfully")
                else:
                    self.log_test("Update Club", False, f"Status code: {response.status_code}")
            except Exception as e:
                self.log_test("Update Club", False, f"Error: {str(e)}")

    def test_admin_user_management(self):
        """Test admin user management endpoints"""
        print("\n👥 Testing Admin User Management...")
        
        if not self.token:
            self.log_test("Admin User Management", False, "No authentication token")
            return

        headers = self.get_headers()

        # Test list users
        try:
            response = requests.get(f"{self.base_url}/api/admin/users", headers=headers, timeout=10)
            if response.status_code == 200:
                users = response.json()
                self.log_test("List Users", True, f"Found {len(users)} users")
            else:
                self.log_test("List Users", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("List Users", False, f"Error: {str(e)}")

        # Test create user
        try:
            user_data = {
                "username": f"testuser{int(time.time())}",
                "email": f"testuser{int(time.time())}@example.com",
                "password": "testpass123",
                "full_name": "Test User",
                "club_id": self.test_data['club_id'],
                "role": "organizer"
            }
            response = requests.post(f"{self.base_url}/api/admin/users", 
                                   headers=headers, json=user_data, timeout=10)
            if response.status_code == 200:
                user = response.json()
                self.test_data['user_id'] = user['id']
                self.created_resources.append(('user', user['id']))
                self.log_test("Create User", True, f"Created user ID: {user['id']}")
            else:
                self.log_test("Create User", False, f"Status code: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Create User", False, f"Error: {str(e)}")

    def test_event_management(self):
        """Test event management endpoints"""
        print("\n📅 Testing Event Management...")
        
        if not self.token:
            self.log_test("Event Management", False, "No authentication token")
            return

        headers = self.get_headers()

        # Test create event
        try:
            event_data = {
                "name": f"Simple Test Event {int(time.time())}",
                "description": "Simple test event for API testing",
                "date": (datetime.now() + timedelta(days=30)).isoformat(),
                "venue": "Test Venue"
            }
            response = requests.post(f"{self.base_url}/api/events", 
                                   headers=headers, json=event_data, timeout=10)
            if response.status_code == 200:
                event = response.json()
                self.test_data['event_id'] = event['id']
                self.created_resources.append(('event', event['id']))
                self.log_test("Create Event", True, f"Created event ID: {event['id']}")
            else:
                self.log_test("Create Event", False, f"Status code: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Create Event", False, f"Error: {str(e)}")

        # Test list events
        try:
            response = requests.get(f"{self.base_url}/api/events", headers=headers, timeout=10)
            if response.status_code == 200:
                events = response.json()
                self.log_test("List Events", True, f"Found {len(events)} events")
            else:
                self.log_test("List Events", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("List Events", False, f"Error: {str(e)}")

        # Test get specific event
        if self.test_data['event_id']:
            try:
                response = requests.get(f"{self.base_url}/api/events/{self.test_data['event_id']}", 
                                      headers=headers, timeout=10)
                if response.status_code == 200:
                    event = response.json()
                    self.log_test("Get Event", True, f"Event: {event['name']}")
                else:
                    self.log_test("Get Event", False, f"Status code: {response.status_code}")
            except Exception as e:
                self.log_test("Get Event", False, f"Error: {str(e)}")

    def test_attendee_management(self):
        """Test attendee management endpoints"""
        print("\n👥 Testing Attendee Management...")
        
        if not self.token or not self.test_data['event_id']:
            self.log_test("Attendee Management", False, "Missing token or event ID")
            return

        headers = self.get_headers()

        # Test download template
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.test_data['event_id']}/attendees/template", 
                                  headers=headers, timeout=10)
            if response.status_code == 200:
                self.log_test("Download Template", True, "Template downloaded successfully")
            else:
                self.log_test("Download Template", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Download Template", False, f"Error: {str(e)}")

        # Test list attendees (should be empty initially)
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.test_data['event_id']}/attendees", 
                                  headers=headers, timeout=10)
            if response.status_code == 200:
                attendees = response.json()
                self.log_test("List Attendees", True, f"Found {len(attendees)} attendees")
            else:
                self.log_test("List Attendees", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("List Attendees", False, f"Error: {str(e)}")

        # Test CSV upload
        try:
            # Create test CSV data
            csv_data = [
                ['name', 'email', 'roll_number', 'branch', 'year', 'section', 'phone', 'gender'],
                ['John Doe', 'john@example.com', '21BCE001', 'CSE', '3', 'A', '9876543210', 'Male'],
                ['Jane Smith', 'jane@example.com', '21BCE002', 'ECE', '2', 'B', '9876543211', 'Female']
            ]
            
            # Convert to CSV string
            csv_buffer = io.StringIO()
            writer = csv.writer(csv_buffer)
            writer.writerows(csv_data)
            csv_content = csv_buffer.getvalue()
            
            # Create file-like object
            files = {'file': ('test_attendees.csv', csv_content, 'text/csv')}
            
            response = requests.post(f"{self.base_url}/api/events/{self.test_data['event_id']}/attendees/upload", 
                                   headers=headers, files=files, timeout=30)
            if response.status_code == 200:
                result = response.json()
                self.log_test("CSV Upload", True, f"Uploaded {result.get('added', 0)} attendees")
            else:
                self.log_test("CSV Upload", False, f"Status code: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("CSV Upload", False, f"Error: {str(e)}")

        # Test list attendees after upload
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.test_data['event_id']}/attendees", 
                                  headers=headers, timeout=10)
            if response.status_code == 200:
                attendees = response.json()
                if attendees:
                    self.test_data['attendee_id'] = attendees[0]['id']
                    self.created_resources.append(('attendee', attendees[0]['id']))
                self.log_test("List Attendees After Upload", True, f"Found {len(attendees)} attendees")
            else:
                self.log_test("List Attendees After Upload", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("List Attendees After Upload", False, f"Error: {str(e)}")

    def test_qr_code_generation(self):
        """Test QR code generation and email system"""
        print("\n📱 Testing QR Code Generation...")
        
        if not self.token or not self.test_data['event_id']:
            self.log_test("QR Code Generation", False, "Missing token or event ID")
            return

        headers = self.get_headers()

        # Test bulk QR code generation
        try:
            response = requests.post(f"{self.base_url}/api/events/{self.test_data['event_id']}/generate-qr", 
                                   headers=headers, timeout=30)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Generate QR Codes", True, 
                            f"Processed: {data.get('total', 0)} attendees, Success: {data.get('success', 0)}")
            else:
                self.log_test("Generate QR Codes", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Generate QR Codes", False, f"Error: {str(e)}")

    def test_checkin_system(self):
        """Test check-in system"""
        print("\n✅ Testing Check-in System...")
        
        if not self.token:
            self.log_test("Check-in System", False, "No authentication token")
            return

        headers = self.get_headers()

        # Test QR scan with invalid token
        try:
            scan_data = {"qr_token": "invalid_token_for_testing"}
            response = requests.post(f"{self.base_url}/api/checkin/scan", 
                                   headers=headers, json=scan_data, timeout=10)
            if response.status_code == 200:
                data = response.json()
                if not data.get('success'):
                    self.log_test("QR Scan (Invalid Token)", True, 
                                f"Correctly rejected: {data.get('message')}")
                else:
                    self.log_test("QR Scan (Invalid Token)", False, "Should have rejected invalid token")
            else:
                self.log_test("QR Scan (Invalid Token)", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("QR Scan (Invalid Token)", False, f"Error: {str(e)}")

        # Test manual check-in
        if self.test_data['attendee_id']:
            try:
                response = requests.post(f"{self.base_url}/api/attendees/{self.test_data['attendee_id']}/checkin-manual", 
                                       headers=headers, timeout=10)
                if response.status_code == 200:
                    self.log_test("Manual Check-in", True, "Attendee checked in successfully")
                else:
                    self.log_test("Manual Check-in", False, f"Status code: {response.status_code}")
            except Exception as e:
                self.log_test("Manual Check-in", False, f"Error: {str(e)}")

    def test_dashboard_and_export(self):
        """Test dashboard and export functionality"""
        print("\n📊 Testing Dashboard and Export...")
        
        if not self.token or not self.test_data['event_id']:
            self.log_test("Dashboard/Export", False, "Missing token or event ID")
            return

        headers = self.get_headers()

        # Test event dashboard
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.test_data['event_id']}/dashboard", 
                                  headers=headers, timeout=10)
            if response.status_code == 200:
                data = response.json()
                stats = data.get('stats', {})
                self.log_test("Event Dashboard", True, 
                            f"Stats: {stats.get('total_attendees', 0)} attendees, {stats.get('checked_in', 0)} checked in")
            else:
                self.log_test("Event Dashboard", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Event Dashboard", False, f"Error: {str(e)}")

        # Test CSV export
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.test_data['event_id']}/export", 
                                  headers=headers, timeout=10)
            if response.status_code == 200:
                self.log_test("CSV Export", True, "Export successful")
            else:
                self.log_test("CSV Export", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("CSV Export", False, f"Error: {str(e)}")

    def test_payment_management(self):
        """Test payment management endpoints"""
        print("\n💳 Testing Payment Management...")
        
        if not self.token:
            self.log_test("Payment Management", False, "No authentication token")
            return

        headers = self.get_headers()

        # Test manual payment sync
        try:
            response = requests.post(f"{self.base_url}/api/payments/sync", headers=headers, timeout=30)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Manual Payment Sync", True, f"Sync completed: {data.get('message')}")
            else:
                self.log_test("Manual Payment Sync", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Manual Payment Sync", False, f"Error: {str(e)}")

        # Test create payment
        if self.test_data['event_id']:
            try:
                payment_data = {
                    "event_id": self.test_data['event_id'],
                    "razorpay_payment_id": f"pay_test_{int(time.time())}",
                    "amount": 10000,  # ₹100 in paise
                    "currency": "INR",
                    "customer_name": "Test Customer",
                    "customer_email": "test@example.com",
                    "customer_phone": "9876543210",
                    "status": "captured"
                }
                response = requests.post(f"{self.base_url}/api/payments", 
                                       headers=headers, json=payment_data, timeout=10)
                if response.status_code == 200:
                    payment = response.json()
                    self.test_data['payment_id'] = payment['id']
                    self.created_resources.append(('payment', payment['id']))
                    self.log_test("Create Payment", True, f"Created payment ID: {payment['id']}")
                else:
                    self.log_test("Create Payment", False, f"Status code: {response.status_code}, Response: {response.text}")
            except Exception as e:
                self.log_test("Create Payment", False, f"Error: {str(e)}")

    def test_security_and_permissions(self):
        """Test security and permission controls"""
        print("\n🔒 Testing Security and Permissions...")
        
        # Test unauthorized access
        try:
            response = requests.get(f"{self.base_url}/api/admin/clubs", timeout=10)
            if response.status_code == 401:
                self.log_test("Unauthorized Access", True, "Correctly requires authentication")
            else:
                self.log_test("Unauthorized Access", False, f"Should return 401, got {response.status_code}")
        except Exception as e:
            self.log_test("Unauthorized Access", False, f"Error: {str(e)}")

        # Test invalid token
        try:
            headers = {"Authorization": "Bearer invalid_token"}
            response = requests.get(f"{self.base_url}/api/auth/me", headers=headers, timeout=10)
            if response.status_code == 401:
                self.log_test("Invalid Token", True, "Correctly rejected invalid token")
            else:
                self.log_test("Invalid Token", False, f"Should return 401, got {response.status_code}")
        except Exception as e:
            self.log_test("Invalid Token", False, f"Error: {str(e)}")

    def test_error_handling(self):
        """Test error handling and edge cases"""
        print("\n⚠️ Testing Error Handling...")
        
        if not self.token:
            self.log_test("Error Handling", False, "No authentication token")
            return

        headers = self.get_headers()

        # Test invalid event ID
        try:
            response = requests.get(f"{self.base_url}/api/events/99999", headers=headers, timeout=10)
            if response.status_code == 404:
                self.log_test("Invalid Event ID", True, "Correctly returned 404")
            else:
                self.log_test("Invalid Event ID", False, f"Should return 404, got {response.status_code}")
        except Exception as e:
            self.log_test("Invalid Event ID", False, f"Error: {str(e)}")

        # Test invalid attendee ID
        try:
            response = requests.post(f"{self.base_url}/api/attendees/99999/checkin-manual", headers=headers, timeout=10)
            if response.status_code == 404:
                self.log_test("Invalid Attendee ID", True, "Correctly returned 404")
            else:
                self.log_test("Invalid Attendee ID", False, f"Should return 404, got {response.status_code}")
        except Exception as e:
            self.log_test("Invalid Attendee ID", False, f"Error: {str(e)}")

    def test_performance(self):
        """Test basic performance metrics"""
        print("\n⚡ Testing Performance...")
        
        if not self.token:
            self.log_test("Performance", False, "No authentication token")
            return

        headers = self.get_headers()

        # Test response times for key endpoints
        endpoints = [
            ("/", "Root endpoint"),
            ("/health", "Health check"),
            ("/api/auth/me", "Current user"),
            ("/api/admin/clubs", "List clubs"),
            ("/api/events", "List events")
        ]

        for endpoint, description in endpoints:
            try:
                start_time = time.time()
                response = requests.get(f"{self.base_url}{endpoint}", headers=headers, timeout=10)
                end_time = time.time()
                response_time = (end_time - start_time) * 1000  # Convert to milliseconds
                
                if response.status_code == 200:
                    self.log_test(f"Performance - {description}", True, 
                                f"Response time: {response_time:.2f}ms")
                else:
                    self.log_test(f"Performance - {description}", False, 
                                f"Status code: {response.status_code}")
            except Exception as e:
                self.log_test(f"Performance - {description}", False, f"Error: {str(e)}")

    def cleanup_resources(self):
        """Clean up created test resources"""
        print("\n🧹 Cleaning up test resources...")
        
        if not self.token:
            return

        headers = self.get_headers()

        # Clean up in reverse order of creation
        for resource_type, resource_id in reversed(self.created_resources):
            try:
                if resource_type == 'attendee':
                    response = requests.delete(f"{self.base_url}/api/attendees/{resource_id}", 
                                            headers=headers, timeout=10)
                elif resource_type == 'event':
                    response = requests.delete(f"{self.base_url}/api/events/{resource_id}", 
                                             headers=headers, timeout=10)
                elif resource_type == 'user':
                    response = requests.delete(f"{self.base_url}/api/admin/users/{resource_id}", 
                                             headers=headers, timeout=10)
                elif resource_type == 'club':
                    response = requests.delete(f"{self.base_url}/api/admin/clubs/{resource_id}", 
                                             headers=headers, timeout=10)
                elif resource_type == 'payment':
                    # Payments are usually not deleted, just marked as inactive
                    pass
                
                print(f"   Cleaned up {resource_type} ID: {resource_id}")
            except Exception as e:
                print(f"   Failed to clean up {resource_type} ID: {resource_id} - {str(e)}")

    def generate_report(self):
        """Generate comprehensive test report"""
        print("\n" + "=" * 80)
        print("📊 SIMPLE API TEST REPORT")
        print("=" * 80)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result['success'])
        failed_tests = total_tests - passed_tests
        success_rate = (passed_tests/total_tests)*100 if total_tests > 0 else 0
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests} ✅")
        print(f"Failed: {failed_tests} ❌")
        print(f"Success Rate: {success_rate:.1f}%")
        
        print("\n📋 Detailed Results:")
        for result in self.test_results:
            status = "✅" if result['success'] else "❌"
            print(f"{status} {result['test']}")
            if result['message']:
                print(f"    {result['message']}")
        
        print("\n🎯 API Readiness Assessment:")
        if success_rate == 100:
            print("🟢 EXCELLENT - All tests passed! API is production-ready.")
        elif success_rate >= 95:
            print("🟡 GOOD - Minor issues found. Review failed tests before production.")
        elif success_rate >= 80:
            print("🟠 NEEDS ATTENTION - Some issues found. Fix before production.")
        else:
            print("🔴 CRITICAL - Multiple issues found. Major fixes required before production.")
        
        print(f"\n📅 Test completed at: {datetime.now().isoformat()}")
        
        # Save detailed report to file
        report_file = f"simple_test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(self.test_results, f, indent=2)
        print(f"📄 Detailed report saved to: {report_file}")
        
        return success_rate == 100

    def run_all_tests(self):
        """Run all simple tests"""
        print("🚀 Starting Simple API Test Suite")
        print("=" * 80)
        
        try:
            # Run all test categories
            self.test_health_endpoints()
            if not self.test_authentication():
                print("❌ Authentication failed. Cannot proceed with other tests.")
                return False
            
            self.test_admin_club_management()
            self.test_admin_user_management()
            self.test_event_management()
            self.test_attendee_management()
            self.test_qr_code_generation()
            self.test_checkin_system()
            self.test_dashboard_and_export()
            self.test_payment_management()
            self.test_security_and_permissions()
            self.test_error_handling()
            self.test_performance()
            
            # Generate final report
            success = self.generate_report()
            
            # Clean up resources
            self.cleanup_resources()
            
            return success
            
        except Exception as e:
            print(f"❌ Test suite failed with error: {str(e)}")
            return False

def main():
    """Main function"""
    print("🔧 QRFlow Backend - Simple API Test Suite")
    print("Testing all endpoints to achieve 100% pass rate")
    print("=" * 80)
    
    # Check if application is running
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=5)
        if response.status_code != 200:
            print("❌ Application is not running or not healthy.")
            print("Please start the application first:")
            print("   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload")
            sys.exit(1)
    except requests.exceptions.RequestException:
        print("❌ Cannot connect to application.")
        print("Please start the application first:")
        print("   uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload")
        sys.exit(1)
    
    # Run all tests
    tester = SimpleAPITester()
    success = tester.run_all_tests()
    
    if success:
        print("\n🎉 ALL TESTS PASSED! API is ready for production.")
        sys.exit(0)
    else:
        print("\n⚠️ Some tests failed. Please review the report and fix issues.")
        sys.exit(1)

if __name__ == "__main__":
    main()

