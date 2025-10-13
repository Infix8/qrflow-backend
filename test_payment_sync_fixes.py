#!/usr/bin/env python3
"""
Test script to verify payment sync fixes
This script tests the year and section extraction logic without affecting production data
"""

import json
import re
from typing import Dict, Any, Tuple

def parse_year_from_string(year_str: str) -> int:
    """
    Parse year from various string formats including Roman numerals and text
    Handles: "1", "2nd", "3rd", "4th", "II", "III", "IV", "first", "second", etc.
    """
    import re
    
    if not year_str:
        return 1
    
    year_str = year_str.strip().lower()
    
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

def extract_year_and_section_from_notes(notes: Dict[str, Any]) -> Tuple[int, str]:
    """
    Extract year and section from payment notes
    This is the same logic used in the updated sync function
    """
    year = 1  # Default year
    section = "A"  # Default section
    
    try:
        if isinstance(notes, dict):
            # Extract year from year_of_study field
            year_str = notes.get("year_of_study", "1")
            if year_str:
                year = parse_year_from_string(str(year_str))
            
            # Extract section
            section_str = notes.get("section", "A")
            if section_str:
                section = str(section_str).strip().upper()
                # Ensure section is valid (single letter or valid section code)
                if not section or len(section) > 2 or section not in ['A', 'B', 'C', 'D']:
                    section = "A"
    except Exception as e:
        print(f"⚠️ Error parsing year/section: {str(e)}")
        # Use defaults
        year = 1
        section = "A"
    
    return year, section

def test_year_section_extraction():
    """
    Test the year and section extraction with sample data from your payments
    """
    print("🧪 Testing Year and Section Extraction Logic")
    print("=" * 50)
    
    # Test cases based on your actual payment data
    test_cases = [
        {
            "name": "Indra - 3rd year, no section",
            "notes": {
                "name": "Indra",
                "email": "indrakshith.reddy@gmail.com",
                "phone": "8019213363",
                "college_name": "St. Martins Engineering college",
                "department": "CSE",
                "roll_number": "23K81A0522",
                "year_of_study": "3"
            },
            "expected_year": 3,
            "expected_section": "A"
        },
        {
            "name": "BANDI NAVYA TEJA - 2nd year, Section B",
            "notes": {
                "name": "BANDI NAVYA TEJA",
                "email": "navyateja.bandi@gmail.com",
                "phone": "8978764113",
                "college_name": "St Martin's Engineering College",
                "department": "CSE AI ML",
                "roll_number": "24K81A6675",
                "section": "B",
                "year_of_study": "2"
            },
            "expected_year": 2,
            "expected_section": "B"
        },
        {
            "name": "Shaik Rafi - 3rd year, Section B",
            "notes": {
                "name": "Shaik Rafi",
                "email": "shaikrafi12387@gmail.com",
                "phone": "9502897006",
                "college_name": "ST MARTIN'S ENGINEERING COLLEGE",
                "department": "CSM",
                "roll_number": "23K81A66B9",
                "section": "B",
                "year_of_study": "3"
            },
            "expected_year": 3,
            "expected_section": "B"
        },
        {
            "name": "Tanish Padala - 3rd year, no section",
            "notes": {
                "name": "Tanish Padala",
                "email": "padalatanish30@gmail.com",
                "phone": "9299559837",
                "college_name": "St. Martin's Engineering College",
                "department": "CSG",
                "roll_number": "23K81A7444",
                "year_of_study": "3"
            },
            "expected_year": 3,
            "expected_section": "A"
        },
        {
            "name": "vrunimahi - 2nd year, Section A",
            "notes": {
                "name": "vrunimahi",
                "email": "vrunimahi@gmail.com",
                "phone": "8309491861",
                "college_name": "St.Martin's engineering college",
                "department": "CSE",
                "roll_number": "24K81A0526",
                "section": "A",
                "year_of_study": "2nd"
            },
            "expected_year": 2,
            "expected_section": "A"
        },
        {
            "name": "Edge case - Invalid year",
            "notes": {
                "name": "Test User",
                "year_of_study": "6",  # Invalid year
                "section": "Z"  # Invalid section
            },
            "expected_year": 1,  # Should default to 1
            "expected_section": "A"  # Should default to A
        },
        {
            "name": "Edge case - Empty values",
            "notes": {
                "name": "Test User",
                "year_of_study": "",
                "section": ""
            },
            "expected_year": 1,
            "expected_section": "A"
        },
        {
            "name": "Roman numerals - II (2nd year)",
            "notes": {
                "name": "Test User",
                "year_of_study": "II",
                "section": "B"
            },
            "expected_year": 2,
            "expected_section": "B"
        },
        {
            "name": "Roman numerals - III (3rd year)",
            "notes": {
                "name": "Test User",
                "year_of_study": "III",
                "section": "C"
            },
            "expected_year": 3,
            "expected_section": "C"
        },
        {
            "name": "Roman numerals - IV (4th year)",
            "notes": {
                "name": "Test User",
                "year_of_study": "IV",
                "section": "D"
            },
            "expected_year": 4,
            "expected_section": "D"
        },
        {
            "name": "Text format - second year",
            "notes": {
                "name": "Test User",
                "year_of_study": "second",
                "section": "A"
            },
            "expected_year": 2,
            "expected_section": "A"
        },
        {
            "name": "Text format - third year",
            "notes": {
                "name": "Test User",
                "year_of_study": "third",
                "section": "B"
            },
            "expected_year": 3,
            "expected_section": "B"
        },
        {
            "name": "Mixed format - II semester",
            "notes": {
                "name": "Test User",
                "year_of_study": "II semester",
                "section": "C"
            },
            "expected_year": 2,
            "expected_section": "C"
        },
        {
            "name": "Mixed format - 3rd year engineering",
            "notes": {
                "name": "Test User",
                "year_of_study": "3rd year engineering",
                "section": "D"
            },
            "expected_year": 3,
            "expected_section": "D"
        }
    ]
    
    passed = 0
    failed = 0
    
    for test_case in test_cases:
        print(f"\n📝 Testing: {test_case['name']}")
        
        # Extract year and section
        year, section = extract_year_and_section_from_notes(test_case['notes'])
        
        # Check results
        year_correct = year == test_case['expected_year']
        section_correct = section == test_case['expected_section']
        
        if year_correct and section_correct:
            print(f"✅ PASS - Year: {year}, Section: {section}")
            passed += 1
        else:
            print(f"❌ FAIL - Expected Year: {test_case['expected_year']}, Section: {test_case['expected_section']}")
            print(f"   Got - Year: {year}, Section: {section}")
            failed += 1
        
        # Show the notes for reference
        print(f"   Notes: {json.dumps(test_case['notes'], indent=2)}")
    
    print(f"\n📊 Test Results: {passed} passed, {failed} failed")
    
    if failed == 0:
        print("🎉 All tests passed! The extraction logic is working correctly.")
    else:
        print("⚠️ Some tests failed. Please review the logic.")
    
    return failed == 0

def test_form_data_parsing():
    """
    Test parsing of the actual form_data structure from your payments
    """
    print("\n🧪 Testing Form Data Parsing")
    print("=" * 50)
    
    # Sample form_data from your actual payment data
    sample_form_data = {
        "college_name": "St Martin's Engineering College",
        "department": "CSE AI ML",
        "roll_number": "24K81A6675",
        "emergency_contact": "",
        "original_notes": {
            "alternative_phone_number": "7287883116",
            "college_name": "St Martin's Engineering College",
            "department": "CSE AI ML",
            "email": "navyateja.bandi@gmail.com",
            "name": "BANDI NAVYA TEJA",
            "phone": "8978764113",
            "roll_number": "24K81A6675",
            "section": "B",
            "year_of_study": "2"
        }
    }
    
    # Parse the form_data
    original_notes = sample_form_data.get("original_notes", {})
    year, section = extract_year_and_section_from_notes(original_notes)
    
    print(f"📝 Sample Form Data:")
    print(json.dumps(sample_form_data, indent=2))
    print(f"\n✅ Extracted - Year: {year}, Section: {section}")
    
    # Verify the extraction
    expected_year = 2
    expected_section = "B"
    
    if year == expected_year and section == expected_section:
        print("🎉 Form data parsing test PASSED!")
        return True
    else:
        print(f"❌ Form data parsing test FAILED! Expected Year: {expected_year}, Section: {expected_section}")
        return False

if __name__ == "__main__":
    print("🚀 Payment Sync Fixes Test Suite")
    print("=" * 60)
    
    # Run tests
    test1_passed = test_year_section_extraction()
    test2_passed = test_form_data_parsing()
    
    print("\n" + "=" * 60)
    print("📋 Test Summary:")
    print(f"   Year/Section Extraction: {'✅ PASSED' if test1_passed else '❌ FAILED'}")
    print(f"   Form Data Parsing: {'✅ PASSED' if test2_passed else '❌ FAILED'}")
    
    if test1_passed and test2_passed:
        print("\n🎉 All tests passed! The fixes are ready for deployment.")
        print("\n📝 Next Steps:")
        print("   1. Deploy the updated code to production")
        print("   2. Run the fix endpoint: POST /api/payments/fix-attendee-details")
        print("   3. Verify the get attendees endpoint shows correct data")
    else:
        print("\n⚠️ Some tests failed. Please review the logic before deploying.")
