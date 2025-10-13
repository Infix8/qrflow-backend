#!/usr/bin/env python3
"""
Script to update attendee year and section details from payment form_data
This script extracts the correct year and section from payment data and updates attendee records
"""

import json
import psycopg2
from psycopg2.extras import RealDictCursor
import re
from datetime import datetime

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'qrflow_db',
    'user': 'qrflow_user',
    'password': 'Indra123'
}

def parse_year_from_string(year_str: str) -> int:
    """
    Parse year from various string formats including Roman numerals and text
    Handles: "1", "2nd", "3rd", "4th", "II", "III", "IV", "first", "second", etc.
    """
    if not year_str:
        return 1
    
    year_str = str(year_str).strip().lower()
    
    # Handle Roman numerals
    roman_to_int = {
        'i': 1, 'ii': 2, 'iii': 3, 'iv': 4, 'v': 5,
        '1': 1, '2': 2, '3': 3, '4': 4, '5': 5
    }
    
    # Handle text formats
    text_to_int = {
        'first': 1, '1st': 1, '1nd': 1, '1rd': 1,
        'second': 2, '2nd': 2, '2st': 2, '2rd': 2,
        'third': 3, '3rd': 3, '3nd': 3, '3st': 3,
        'fourth': 4, '4th': 4, '4nd': 4, '4st': 4, '4rd': 4,
        'fifth': 5, '5th': 5, '5nd': 5, '5st': 5, '5rd': 5
    }
    
    # Try direct mapping first
    if year_str in roman_to_int:
        year = roman_to_int[year_str]
        return year if 1 <= year <= 5 else 1
    
    if year_str in text_to_int:
        year = text_to_int[year_str]
        return year if 1 <= year <= 5 else 1
    
    # Try to extract number from string like "3rd year", "II semester", etc.
    number_match = re.search(r'(\d+)', year_str)
    if number_match:
        year = int(number_match.group(1))
        return year if 1 <= year <= 5 else 1
    
    # Try to extract Roman numeral from string
    roman_match = re.search(r'\b([iv]+)\b', year_str)
    if roman_match:
        roman_num = roman_match.group(1).lower()
        if roman_num in roman_to_int:
            year = roman_to_int[roman_num]
            return year if 1 <= year <= 5 else 1
    
    # Default to 1 if nothing matches
    return 1

def extract_section_from_string(section_str: str) -> str:
    """
    Extract and normalize section from various formats
    """
    if not section_str:
        return "A"
    
    section_str = str(section_str).strip().upper()
    
    # Extract single letter from section string
    # Handle cases like "CSM A", "CSM B", etc.
    letter_match = re.search(r'\b([A-D])\b', section_str)
    if letter_match:
        return letter_match.group(1)
    
    # If it's already a single letter
    if len(section_str) == 1 and section_str in ['A', 'B', 'C', 'D']:
        return section_str
    
    # Default to A
    return "A"

def update_attendee_details():
    """
    Update attendee year and section details from payment form_data
    """
    try:
        # Connect to database
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        print("🔍 Fetching payments with form_data...")
        
        # Get all payments with form_data
        cursor.execute("""
            SELECT id, customer_email, event_id, form_data 
            FROM payments 
            WHERE form_data IS NOT NULL AND status = 'captured'
            ORDER BY id
        """)
        
        payments = cursor.fetchall()
        print(f"📊 Found {len(payments)} payments with form_data")
        
        updated_count = 0
        errors = []
        
        for payment in payments:
            try:
                # Parse form_data
                form_data = json.loads(payment['form_data'])
                original_notes = form_data.get('original_notes', {})
                
                if not original_notes:
                    continue
                
                # Extract year and section
                year_str = original_notes.get('year_of_study', '1')
                year = parse_year_from_string(year_str)
                
                section_str = original_notes.get('section', 'A')
                section = extract_section_from_string(section_str)
                
                # Find matching attendee by email or roll_number
                roll_number = original_notes.get('roll_number', '')
                
                cursor.execute("""
                    SELECT id, name, email, roll_number, year, section 
                    FROM attendees 
                    WHERE event_id = %s AND (email = %s OR roll_number = %s)
                """, (payment['event_id'], payment['customer_email'], roll_number))
                
                attendee = cursor.fetchone()
                
                if attendee:
                    # Check if update is needed
                    needs_update = False
                    updates = []
                    
                    if attendee['year'] != year:
                        updates.append(f"year: {attendee['year']} → {year}")
                        needs_update = True
                    
                    if attendee['section'] != section:
                        updates.append(f"section: {attendee['section']} → {section}")
                        needs_update = True
                    
                    if needs_update:
                        # Update attendee
                        cursor.execute("""
                            UPDATE attendees 
                            SET year = %s, section = %s 
                            WHERE id = %s
                        """, (year, section, attendee['id']))
                        
                        updated_count += 1
                        print(f"✅ Updated {attendee['name']} (ID: {attendee['id']}): {', '.join(updates)}")
                    else:
                        print(f"ℹ️  No update needed for {attendee['name']} (ID: {attendee['id']})")
                else:
                    print(f"⚠️  No attendee found for payment {payment['id']} (email: {payment['customer_email']})")
                    
            except Exception as e:
                error_msg = f"Error processing payment {payment['id']}: {str(e)}"
                errors.append(error_msg)
                print(f"❌ {error_msg}")
        
        # Commit changes
        conn.commit()
        
        print(f"\n🎯 Update Summary:")
        print(f"   📊 Total payments processed: {len(payments)}")
        print(f"   ✅ Attendees updated: {updated_count}")
        print(f"   ❌ Errors: {len(errors)}")
        
        if errors:
            print(f"\n❌ Errors encountered:")
            for error in errors[:10]:  # Show first 10 errors
                print(f"   - {error}")
        
        return updated_count, errors
        
    except Exception as e:
        print(f"❌ Database error: {str(e)}")
        return 0, [str(e)]
    finally:
        if 'conn' in locals():
            conn.close()

def verify_updates():
    """
    Verify the updates by showing some sample data
    """
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        print("\n🔍 Verification - Sample updated attendees:")
        cursor.execute("""
            SELECT id, name, email, roll_number, year, section 
            FROM attendees 
            WHERE year != 1 OR section != 'A'
            ORDER BY id
            LIMIT 10
        """)
        
        updated_attendees = cursor.fetchall()
        
        for attendee in updated_attendees:
            print(f"   {attendee['id']}: {attendee['name']} - Year: {attendee['year']}, Section: {attendee['section']}")
        
        print(f"\n📊 Total attendees with non-default values: {len(updated_attendees)}")
        
    except Exception as e:
        print(f"❌ Verification error: {str(e)}")
    finally:
        if 'conn' in locals():
            conn.close()

if __name__ == "__main__":
    print("🚀 Starting attendee details update from payment data...")
    print(f"⏰ Started at: {datetime.now()}")
    
    updated_count, errors = update_attendee_details()
    
    if updated_count > 0:
        verify_updates()
    
    print(f"\n✅ Update completed at: {datetime.now()}")
