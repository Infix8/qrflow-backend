#!/usr/bin/env python3
"""
Production-Ready Test Suite for QRFlow Backend
Comprehensive testing of all endpoints including new payment sync system
"""

import requests
import json
import sys
import time
from datetime import datetime, timedelta

# Configuration
BASE_URL = "http://localhost:8000"
ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "admin123"

class QRFlowTester:
    def __init__(self):
        self.base_url = BASE_URL
        self.token = None
        self.test_results = []
        self.club_id = None
        self.event_id = None
        self.attendee_id = None
        self.payment_id = None

    def log_test(self, test_name, success, message="", details=None):
        """Log test results"""
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

    def test_health_endpoints(self):
        """Test health and root endpoints"""
        print("\n🔍 Testing Health Endpoints...")
        
        # Test root endpoint
        try:
            response = requests.get(f"{self.base_url}/")
            if response.status_code == 200:
                data = response.json()
                self.log_test("Root Endpoint", True, f"Status: {data.get('status')}")
            else:
                self.log_test("Root Endpoint", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Root Endpoint", False, f"Error: {str(e)}")

        # Test health endpoint
        try:
            response = requests.get(f"{self.base_url}/health")
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
            response = requests.post(f"{self.base_url}/api/auth/login", data=data)
            if response.status_code == 200:
                token_data = response.json()
                self.token = token_data["access_token"]
                self.log_test("Login", True, f"Token received: {self.token[:20]}...")
            else:
                self.log_test("Login", False, f"Status code: {response.status_code}")
                return False
        except Exception as e:
            self.log_test("Login", False, f"Error: {str(e)}")
            return False

        # Test get current user
        if self.token:
            try:
                headers = {"Authorization": f"Bearer {self.token}"}
                response = requests.get(f"{self.base_url}/api/auth/me", headers=headers)
                if response.status_code == 200:
                    user_data = response.json()
                    self.log_test("Get Current User", True, f"User: {user_data['username']} ({user_data['role']})")
                else:
                    self.log_test("Get Current User", False, f"Status code: {response.status_code}")
            except Exception as e:
                self.log_test("Get Current User", False, f"Error: {str(e)}")

        return self.token is not None

    def test_club_management(self):
        """Test club management endpoints"""
        print("\n🏛️ Testing Club Management...")
        
        if not self.token:
            self.log_test("Club Management", False, "No authentication token")
            return

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test list clubs
        try:
            response = requests.get(f"{self.base_url}/api/admin/clubs", headers=headers)
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
                "description": "Production test club"
            }
            response = requests.post(f"{self.base_url}/api/admin/clubs", 
                                   headers=headers, json=club_data)
            if response.status_code == 200:
                club = response.json()
                self.club_id = club['id']
                self.log_test("Create Club", True, f"Created club ID: {self.club_id}")
            else:
                self.log_test("Create Club", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Create Club", False, f"Error: {str(e)}")

    def test_event_management(self):
        """Test event management endpoints"""
        print("\n📅 Testing Event Management...")
        
        if not self.token:
            self.log_test("Event Management", False, "No authentication token")
            return

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test create event
        try:
            event_data = {
                "name": f"Production Test Event {int(time.time())}",
                "description": "Production test event",
                "date": (datetime.now() + timedelta(days=30)).isoformat(),
                "venue": "Test Venue"
            }
            response = requests.post(f"{self.base_url}/api/events", 
                                   headers=headers, json=event_data)
            if response.status_code == 200:
                event = response.json()
                self.event_id = event['id']
                self.log_test("Create Event", True, f"Created event ID: {self.event_id}")
            else:
                self.log_test("Create Event", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Create Event", False, f"Error: {str(e)}")

        # Test list events
        try:
            response = requests.get(f"{self.base_url}/api/events", headers=headers)
            if response.status_code == 200:
                events = response.json()
                self.log_test("List Events", True, f"Found {len(events)} events")
            else:
                self.log_test("List Events", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("List Events", False, f"Error: {str(e)}")

        # Test get specific event
        if self.event_id:
            try:
                response = requests.get(f"{self.base_url}/api/events/{self.event_id}", headers=headers)
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
        
        if not self.token or not self.event_id:
            self.log_test("Attendee Management", False, "Missing token or event ID")
            return

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test download template
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.event_id}/attendees/template", 
                                  headers=headers)
            if response.status_code == 200:
                self.log_test("Download Template", True, "Template downloaded successfully")
            else:
                self.log_test("Download Template", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Download Template", False, f"Error: {str(e)}")

        # Test list attendees (should be empty initially)
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.event_id}/attendees", 
                                  headers=headers)
            if response.status_code == 200:
                attendees = response.json()
                self.log_test("List Attendees", True, f"Found {len(attendees)} attendees")
            else:
                self.log_test("List Attendees", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("List Attendees", False, f"Error: {str(e)}")

    def test_payment_sync_system(self):
        """Test the new payment sync system"""
        print("\n💳 Testing Payment Sync System...")
        
        if not self.token:
            self.log_test("Payment Sync", False, "No authentication token")
            return

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test manual payment sync
        try:
            response = requests.post(f"{self.base_url}/api/payments/sync", headers=headers)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Manual Payment Sync", True, f"Sync completed: {data.get('message')}")
            else:
                self.log_test("Manual Payment Sync", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Manual Payment Sync", False, f"Error: {str(e)}")

        # Test get event payments (if event exists)
        if self.event_id:
            try:
                response = requests.get(f"{self.base_url}/api/events/{self.event_id}/payments", 
                                      headers=headers)
                if response.status_code == 200:
                    payments = response.json()
                    self.log_test("Get Event Payments", True, f"Found {len(payments)} payments")
                else:
                    self.log_test("Get Event Payments", False, f"Status code: {response.status_code}")
            except Exception as e:
                self.log_test("Get Event Payments", False, f"Error: {str(e)}")

    def test_qr_code_generation(self):
        """Test QR code generation and email system"""
        print("\n📱 Testing QR Code Generation...")
        
        if not self.token or not self.event_id:
            self.log_test("QR Code Generation", False, "Missing token or event ID")
            return

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test QR code generation (will work even with no attendees)
        try:
            response = requests.post(f"{self.base_url}/api/events/{self.event_id}/generate-qr", 
                                   headers=headers)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Generate QR Codes", True, 
                            f"Processed: {data.get('total', 0)} attendees")
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

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test QR scan endpoint (with invalid token)
        try:
            scan_data = {"qr_token": "invalid_token_for_testing"}
            response = requests.post(f"{self.base_url}/api/checkin/scan", 
                                   headers=headers, json=scan_data)
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

    def test_dashboard_and_export(self):
        """Test dashboard and export functionality"""
        print("\n📊 Testing Dashboard and Export...")
        
        if not self.token or not self.event_id:
            self.log_test("Dashboard/Export", False, "Missing token or event ID")
            return

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test event dashboard
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.event_id}/dashboard", 
                                  headers=headers)
            if response.status_code == 200:
                data = response.json()
                self.log_test("Event Dashboard", True, 
                            f"Stats: {data.get('stats', {}).get('total_attendees', 0)} attendees")
            else:
                self.log_test("Event Dashboard", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("Event Dashboard", False, f"Error: {str(e)}")

        # Test CSV export
        try:
            response = requests.get(f"{self.base_url}/api/events/{self.event_id}/export", 
                                  headers=headers)
            if response.status_code == 200:
                self.log_test("CSV Export", True, "Export successful")
            else:
                self.log_test("CSV Export", False, f"Status code: {response.status_code}")
        except Exception as e:
            self.log_test("CSV Export", False, f"Error: {str(e)}")

    def test_security_and_permissions(self):
        """Test security and permission controls"""
        print("\n🔒 Testing Security and Permissions...")
        
        # Test unauthorized access
        try:
            response = requests.get(f"{self.base_url}/api/admin/clubs")
            if response.status_code == 401:
                self.log_test("Unauthorized Access", True, "Correctly requires authentication")
            else:
                self.log_test("Unauthorized Access", False, f"Should return 401, got {response.status_code}")
        except Exception as e:
            self.log_test("Unauthorized Access", False, f"Error: {str(e)}")

        # Test invalid token
        try:
            headers = {"Authorization": "Bearer invalid_token"}
            response = requests.get(f"{self.base_url}/api/auth/me", headers=headers)
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

        headers = {"Authorization": f"Bearer {self.token}"}

        # Test invalid event ID
        try:
            response = requests.get(f"{self.base_url}/api/events/99999", headers=headers)
            if response.status_code == 404:
                self.log_test("Invalid Event ID", True, "Correctly returned 404")
            else:
                self.log_test("Invalid Event ID", False, f"Should return 404, got {response.status_code}")
        except Exception as e:
            self.log_test("Invalid Event ID", False, f"Error: {str(e)}")

        # Test invalid attendee ID (using manual checkin endpoint)
        try:
            response = requests.post(f"{self.base_url}/api/attendees/99999/checkin-manual", headers=headers)
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

        headers = {"Authorization": f"Bearer {self.token}"}

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
                response = requests.get(f"{self.base_url}{endpoint}", headers=headers)
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

    def generate_report(self):
        """Generate comprehensive test report"""
        print("\n" + "=" * 60)
        print("📊 PRODUCTION TEST REPORT")
        print("=" * 60)
        
        total_tests = len(self.test_results)
        passed_tests = sum(1 for result in self.test_results if result['success'])
        failed_tests = total_tests - passed_tests
        
        print(f"Total Tests: {total_tests}")
        print(f"Passed: {passed_tests} ✅")
        print(f"Failed: {failed_tests} ❌")
        print(f"Success Rate: {(passed_tests/total_tests)*100:.1f}%")
        
        print("\n📋 Detailed Results:")
        for result in self.test_results:
            status = "✅" if result['success'] else "❌"
            print(f"{status} {result['test']}")
            if result['message']:
                print(f"    {result['message']}")
        
        print("\n🎯 Production Readiness Assessment:")
        if failed_tests == 0:
            print("🟢 EXCELLENT - All tests passed! System is production-ready.")
        elif failed_tests <= 3:
            print("🟡 GOOD - Minor issues found. Review failed tests before production.")
        else:
            print("🔴 NEEDS ATTENTION - Multiple issues found. Fix before production.")
        
        print(f"\n📅 Test completed at: {datetime.now().isoformat()}")
        
        # Save detailed report to file
        report_file = f"test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(self.test_results, f, indent=2)
        print(f"📄 Detailed report saved to: {report_file}")

    def run_all_tests(self):
        """Run all production tests"""
        print("🚀 Starting Production-Ready Test Suite")
        print("=" * 60)
        
        # Run all test categories
        self.test_health_endpoints()
        if not self.test_authentication():
            print("❌ Authentication failed. Cannot proceed with other tests.")
            return
        
        self.test_club_management()
        self.test_event_management()
        self.test_attendee_management()
        self.test_payment_sync_system()
        self.test_qr_code_generation()
        self.test_checkin_system()
        self.test_dashboard_and_export()
        self.test_security_and_permissions()
        self.test_error_handling()
        self.test_performance()
        
        # Generate final report
        self.generate_report()

def main():
    """Main function"""
    print("🔧 QRFlow Backend - Production Test Suite")
    print("Testing all endpoints including new payment sync system")
    print("=" * 60)
    
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
    tester = QRFlowTester()
    tester.run_all_tests()

if __name__ == "__main__":
    main()
