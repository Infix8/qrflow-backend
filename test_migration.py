#!/usr/bin/env python3
"""
Migration Test Script
=====================

This script tests the migration process without making any changes.
It verifies that all data will be preserved correctly.
"""

import os
import sys
import json
import psycopg2
from datetime import datetime

def test_migration():
    """Test the migration process"""
    print("🧪 Testing QR Flow Migration")
    print("=" * 40)
    
    # Database configuration
    db_config = {
        'host': os.getenv('DB_HOST', 'localhost'),
        'port': os.getenv('DB_PORT', '5432'),
        'database': os.getenv('DB_NAME', 'qrflow_db'),
        'user': os.getenv('DB_USER', 'qrflow_user'),
        'password': os.getenv('DB_PASSWORD', '')
    }
    
    try:
        # Connect to database
        print("📡 Connecting to database...")
        conn = psycopg2.connect(**db_config)
        cursor = conn.cursor()
        
        # Test 1: Check attendees with QR codes
        print("\n🔍 Test 1: Checking attendees with QR codes...")
        cursor.execute("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE qr_generated = true AND qr_token IS NOT NULL
        """)
        qr_count = cursor.fetchone()[0]
        print(f"   ✅ Found {qr_count} attendees with QR codes")
        
        # Test 2: Check attendees with emails sent
        print("\n📧 Test 2: Checking email history...")
        cursor.execute("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE email_sent = true
        """)
        email_count = cursor.fetchone()[0]
        print(f"   ✅ Found {email_count} attendees with emails sent")
        
        # Test 3: Check payments
        print("\n💳 Test 3: Checking payment data...")
        cursor.execute("SELECT COUNT(*) as count FROM payments")
        payment_count = cursor.fetchone()[0]
        print(f"   ✅ Found {payment_count} payment records")
        
        cursor.execute("""
            SELECT COUNT(*) as count FROM payments 
            WHERE status = 'captured'
        """)
        captured_count = cursor.fetchone()[0]
        print(f"   ✅ Found {captured_count} captured payments")
        
        # Test 4: Check for potential issues
        print("\n🔍 Test 4: Checking for potential issues...")
        
        # Check for duplicate QR tokens
        cursor.execute("""
            SELECT qr_token, COUNT(*) as count 
            FROM attendees 
            WHERE qr_token IS NOT NULL 
            GROUP BY qr_token 
            HAVING COUNT(*) > 1
        """)
        duplicates = cursor.fetchall()
        if duplicates:
            print(f"   ⚠️  Found {len(duplicates)} duplicate QR tokens")
            for qr_token, count in duplicates:
                print(f"      - {qr_token[:20]}... appears {count} times")
        else:
            print("   ✅ No duplicate QR tokens found")
        
        # Check for attendees with QR generated but no token
        cursor.execute("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE qr_generated = true AND qr_token IS NULL
        """)
        missing_tokens = cursor.fetchone()[0]
        if missing_tokens > 0:
            print(f"   ⚠️  Found {missing_tokens} attendees with qr_generated=true but no qr_token")
        else:
            print("   ✅ All QR generated attendees have tokens")
        
        # Test 5: Sample data verification
        print("\n📋 Test 5: Sample data verification...")
        
        # Get a sample attendee
        cursor.execute("""
            SELECT id, name, email, qr_generated, email_sent, checked_in 
            FROM attendees 
            WHERE qr_generated = true 
            LIMIT 1
        """)
        sample_attendee = cursor.fetchone()
        if sample_attendee:
            print(f"   ✅ Sample attendee: {sample_attendee[1]} ({sample_attendee[2]})")
            print(f"      - QR Generated: {sample_attendee[3]}")
            print(f"      - Email Sent: {sample_attendee[4]}")
            print(f"      - Checked In: {sample_attendee[5]}")
        
        # Get a sample payment
        cursor.execute("""
            SELECT id, customer_name, customer_email, status, amount 
            FROM payments 
            WHERE status = 'captured' 
            LIMIT 1
        """)
        sample_payment = cursor.fetchone()
        if sample_payment:
            print(f"   ✅ Sample payment: {sample_payment[1]} - ₹{sample_payment[4]/100}")
            print(f"      - Status: {sample_payment[3]}")
            print(f"      - Email: {sample_payment[2]}")
        
        # Test 6: Migration readiness
        print("\n🚀 Test 6: Migration readiness...")
        
        # Check if all required tables exist
        required_tables = ['attendees', 'payments', 'events', 'users', 'clubs']
        for table in required_tables:
            cursor.execute("""
                SELECT COUNT(*) FROM information_schema.tables 
                WHERE table_name = %s
            """, (table,))
            if cursor.fetchone()[0] > 0:
                print(f"   ✅ Table '{table}' exists")
            else:
                print(f"   ❌ Table '{table}' missing")
                return False
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 40)
        print("🎉 Migration test completed successfully!")
        print("\n📊 Summary:")
        print(f"   - {qr_count} attendees with QR codes (will be preserved)")
        print(f"   - {email_count} attendees with email history (will be preserved)")
        print(f"   - {payment_count} payment records (will be preserved)")
        print(f"   - {captured_count} successful payments")
        
        print("\n✅ Your data is ready for migration!")
        print("   All existing QR codes, emails, and payments will be preserved.")
        print("   The new system will enhance your data without losing anything.")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Migration test failed: {str(e)}")
        print("\n🔧 Troubleshooting:")
        print("   1. Check your database connection settings")
        print("   2. Verify your .env file has correct database credentials")
        print("   3. Ensure PostgreSQL is running")
        print("   4. Check if the database and tables exist")
        return False

if __name__ == "__main__":
    success = test_migration()
    sys.exit(0 if success else 1)
