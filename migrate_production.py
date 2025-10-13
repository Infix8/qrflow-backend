#!/usr/bin/env python3
"""
Production Database Migration Script
====================================

This script safely migrates your existing production database to the new enhanced system
while preserving all existing data including QR codes, email history, and payment records.

IMPORTANT: This script is designed to be run on your production server to preserve
all existing data while upgrading to the new system.

Usage:
    python3 migrate_production.py [--dry-run] [--backup-db]
    
Options:
    --dry-run    : Show what would be done without making changes
    --backup-db  : Create a backup before migration
"""

import os
import sys
import json
import subprocess
import psycopg2
from datetime import datetime
from typing import Dict, List, Any, Optional
import argparse

class ProductionMigrator:
    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run
        self.db_config = self._get_db_config()
        self.migration_log = []
        
    def _get_db_config(self) -> Dict[str, str]:
        """Get database configuration from environment variables"""
        return {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': os.getenv('DB_PORT', '5432'),
            'database': os.getenv('DB_NAME', 'qrflow_db'),
            'user': os.getenv('DB_USER', 'qrflow_user'),
            'password': os.getenv('DB_PASSWORD', '')
        }
    
    def _log(self, message: str, level: str = "INFO"):
        """Log migration steps"""
        timestamp = datetime.now().isoformat()
        log_entry = f"[{timestamp}] {level}: {message}"
        self.migration_log.append(log_entry)
        print(log_entry)
    
    def _execute_sql(self, query: str, params: tuple = None) -> List[Dict]:
        """Execute SQL query and return results"""
        if self.dry_run:
            self._log(f"DRY RUN: Would execute: {query[:100]}...", "DRY_RUN")
            return []
        
        try:
            conn = psycopg2.connect(**self.db_config)
            cursor = conn.cursor()
            cursor.execute(query, params)
            
            if cursor.description:
                columns = [desc[0] for desc in cursor.description]
                results = [dict(zip(columns, row)) for row in cursor.fetchall()]
            else:
                results = []
            
            conn.commit()
            cursor.close()
            conn.close()
            
            return results
        except Exception as e:
            self._log(f"SQL Error: {str(e)}", "ERROR")
            raise
    
    def backup_database(self) -> str:
        """Create a backup of the current database"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = f"qrflow_production_backup_{timestamp}.sql"
        
        self._log(f"Creating database backup: {backup_file}")
        
        if not self.dry_run:
            cmd = [
                'pg_dump',
                '-h', self.db_config['host'],
                '-p', self.db_config['port'],
                '-U', self.db_config['user'],
                '-d', self.db_config['database'],
                '-f', backup_file,
                '--verbose'
            ]
            
            env = os.environ.copy()
            env['PGPASSWORD'] = self.db_config['password']
            
            try:
                subprocess.run(cmd, env=env, check=True)
                self._log(f"Backup created successfully: {backup_file}")
            except subprocess.CalledProcessError as e:
                self._log(f"Backup failed: {str(e)}", "ERROR")
                raise
        else:
            self._log(f"DRY RUN: Would create backup: {backup_file}", "DRY_RUN")
        
        return backup_file
    
    def analyze_current_data(self) -> Dict[str, Any]:
        """Analyze current database state"""
        self._log("Analyzing current database state...")
        
        stats = {}
        
        # Count attendees
        attendees = self._execute_sql("SELECT COUNT(*) as count FROM attendees")
        stats['attendees_count'] = attendees[0]['count'] if attendees else 0
        
        # Count attendees with QR codes
        qr_attendees = self._execute_sql("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE qr_generated = true AND qr_token IS NOT NULL
        """)
        stats['qr_generated_count'] = qr_attendees[0]['count'] if qr_attendees else 0
        
        # Count attendees with emails sent
        email_attendees = self._execute_sql("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE email_sent = true
        """)
        stats['emails_sent_count'] = email_attendees[0]['count'] if email_attendees else 0
        
        # Count checked-in attendees
        checked_in = self._execute_sql("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE checked_in = true
        """)
        stats['checked_in_count'] = checked_in[0]['count'] if checked_in else 0
        
        # Count payments
        payments = self._execute_sql("SELECT COUNT(*) as count FROM payments")
        stats['payments_count'] = payments[0]['count'] if payments else 0
        
        # Count captured payments
        captured_payments = self._execute_sql("""
            SELECT COUNT(*) as count FROM payments 
            WHERE status = 'captured'
        """)
        stats['captured_payments_count'] = captured_payments[0]['count'] if captured_payments else 0
        
        self._log(f"Database Analysis Complete: {json.dumps(stats, indent=2)}")
        return stats
    
    def verify_data_integrity(self) -> bool:
        """Verify that existing data is intact and consistent"""
        self._log("Verifying data integrity...")
        
        issues = []
        
        # Check for duplicate QR tokens
        duplicate_qrs = self._execute_sql("""
            SELECT qr_token, COUNT(*) as count 
            FROM attendees 
            WHERE qr_token IS NOT NULL 
            GROUP BY qr_token 
            HAVING COUNT(*) > 1
        """)
        
        if duplicate_qrs:
            issues.append(f"Found {len(duplicate_qrs)} duplicate QR tokens")
            for dup in duplicate_qrs:
                issues.append(f"  - QR token {dup['qr_token'][:20]}... appears {dup['count']} times")
        
        # Check for attendees with QR generated but no token
        missing_tokens = self._execute_sql("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE qr_generated = true AND qr_token IS NULL
        """)
        
        if missing_tokens[0]['count'] > 0:
            issues.append(f"Found {missing_tokens[0]['count']} attendees with qr_generated=true but no qr_token")
        
        # Check for attendees with email_sent=true but no email_sent_at
        missing_email_times = self._execute_sql("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE email_sent = true AND email_sent_at IS NULL
        """)
        
        if missing_email_times[0]['count'] > 0:
            issues.append(f"Found {missing_email_times[0]['count']} attendees with email_sent=true but no email_sent_at")
        
        # Check for payments without corresponding attendees
        orphaned_payments = self._execute_sql("""
            SELECT COUNT(*) as count FROM payments p
            LEFT JOIN attendees a ON p.customer_email = a.email AND p.event_id = a.event_id
            WHERE p.status = 'captured' AND a.id IS NULL
        """)
        
        if orphaned_payments[0]['count'] > 0:
            issues.append(f"Found {orphaned_payments[0]['count']} captured payments without corresponding attendees")
        
        if issues:
            self._log("Data integrity issues found:", "WARNING")
            for issue in issues:
                self._log(f"  - {issue}", "WARNING")
            return False
        else:
            self._log("Data integrity check passed", "SUCCESS")
            return True
    
    def migrate_payment_attendee_links(self):
        """Link payments to attendees based on email and event"""
        self._log("Linking payments to attendees...")
        
        # Find payments that need to be linked to attendees
        unlinked_payments = self._execute_sql("""
            SELECT p.id as payment_id, p.customer_email, p.event_id, a.id as attendee_id
            FROM payments p
            LEFT JOIN attendees a ON p.customer_email = a.email AND p.event_id = a.event_id
            WHERE p.attendee_id IS NULL AND a.id IS NOT NULL
        """)
        
        if not unlinked_payments:
            self._log("No payments need linking")
            return
        
        self._log(f"Found {len(unlinked_payments)} payments to link")
        
        for payment in unlinked_payments:
            self._execute_sql("""
                UPDATE payments 
                SET attendee_id = %s 
                WHERE id = %s
            """, (payment['attendee_id'], payment['payment_id']))
            
            self._log(f"Linked payment {payment['payment_id']} to attendee {payment['attendee_id']}")
    
    def fix_attendee_details_from_payments(self):
        """Update attendee details using payment form_data"""
        self._log("Fixing attendee details from payment data...")
        
        # Get payments with form_data that have linked attendees
        payments_with_data = self._execute_sql("""
            SELECT p.id, p.attendee_id, p.form_data, a.id as attendee_id
            FROM payments p
            JOIN attendees a ON p.attendee_id = a.id
            WHERE p.form_data IS NOT NULL 
            AND p.status = 'captured'
            AND p.form_data != ''
        """)
        
        if not payments_with_data:
            self._log("No payments with form data found")
            return
        
        updated_count = 0
        
        for payment in payments_with_data:
            try:
                form_data = json.loads(payment['form_data'])
                original_notes = form_data.get('original_notes', {})
                
                if not original_notes:
                    continue
                
                # Extract year and section
                year_str = original_notes.get('year_of_study', '1')
                section_str = original_notes.get('section', 'A')
                
                # Normalize year and section
                year = self._normalize_year(year_str)
                section = self._normalize_section(section_str)
                
                # Update attendee if needed
                attendee = self._execute_sql("""
                    SELECT year, section FROM attendees WHERE id = %s
                """, (payment['attendee_id'],))[0]
                
                needs_update = False
                updates = {}
                
                if attendee['year'] != year:
                    updates['year'] = year
                    needs_update = True
                
                if attendee['section'] != section:
                    updates['section'] = section
                    needs_update = True
                
                if needs_update:
                    update_fields = ', '.join([f"{k} = %s" for k in updates.keys()])
                    update_values = list(updates.values()) + [payment['attendee_id']]
                    
                    self._execute_sql(f"""
                        UPDATE attendees 
                        SET {update_fields}
                        WHERE id = %s
                    """, tuple(update_values))
                    
                    updated_count += 1
                    self._log(f"Updated attendee {payment['attendee_id']}: {updates}")
                
            except Exception as e:
                self._log(f"Error processing payment {payment['id']}: {str(e)}", "ERROR")
        
        self._log(f"Updated {updated_count} attendees with payment data")
    
    def _normalize_year(self, year_str: str) -> int:
        """Normalize year string to integer (1-4)"""
        import re
        
        if not year_str:
            return 1
            
        year_str = str(year_str).strip().upper()
        
        # Handle Roman numerals
        roman_to_num = {'I': 1, 'II': 2, 'III': 3, 'IV': 4}
        if year_str in roman_to_num:
            return roman_to_num[year_str]
        
        # Extract numbers from strings like "3rd", "2ND", "1st"
        number_match = re.search(r'\d+', year_str)
        if number_match:
            year_num = int(number_match.group())
            if 1 <= year_num <= 4:
                return year_num
        
        # Handle common variations
        year_str = year_str.replace('ST', '').replace('ND', '').replace('RD', '').replace('TH', '')
        if year_str.isdigit():
            year_num = int(year_str)
            if 1 <= year_num <= 4:
                return year_num
        
        # Handle text formats
        text_to_int = {
            'FIRST': 1, 'SECOND': 2, 'THIRD': 3, 'FOURTH': 4
        }
        if year_str in text_to_int:
            return text_to_int[year_str]
        
        return 1
    
    def _normalize_section(self, section_str: str) -> str:
        """Normalize section string to single letter (A-Z)"""
        import re
        
        if not section_str:
            return "A"
            
        section_str = str(section_str).strip().upper()
        
        # Extract the last letter from the string
        letter_match = re.search(r'([A-Z])$', section_str)
        if letter_match:
            return letter_match.group(1)
        
        # If it's just a single letter
        if len(section_str) == 1 and section_str.isalpha():
            return section_str
        
        return "A"
    
    def verify_migration(self) -> bool:
        """Verify that migration was successful"""
        self._log("Verifying migration...")
        
        # Re-run data integrity check
        integrity_ok = self.verify_data_integrity()
        
        # Check that all QR codes are preserved
        qr_preserved = self._execute_sql("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE qr_generated = true AND qr_token IS NOT NULL
        """)
        
        self._log(f"QR codes preserved: {qr_preserved[0]['count']}")
        
        # Check that email history is preserved
        email_preserved = self._execute_sql("""
            SELECT COUNT(*) as count FROM attendees 
            WHERE email_sent = true
        """)
        
        self._log(f"Email history preserved: {email_preserved[0]['count']}")
        
        return integrity_ok
    
    def save_migration_log(self):
        """Save migration log to file"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        log_file = f"migration_log_{timestamp}.txt"
        
        with open(log_file, 'w') as f:
            f.write("QR Flow Production Migration Log\n")
            f.write("=" * 50 + "\n")
            f.write(f"Migration Date: {datetime.now().isoformat()}\n")
            f.write(f"Dry Run: {self.dry_run}\n")
            f.write("=" * 50 + "\n\n")
            
            for log_entry in self.migration_log:
                f.write(log_entry + "\n")
        
        self._log(f"Migration log saved to: {log_file}")
    
    def run_migration(self, backup_db: bool = False):
        """Run the complete migration process"""
        try:
            self._log("Starting QR Flow Production Migration")
            self._log("=" * 50)
            
            if backup_db:
                self.backup_database()
            
            # Analyze current state
            stats = self.analyze_current_data()
            
            # Verify data integrity
            if not self.verify_data_integrity():
                self._log("Data integrity issues found. Please resolve before migration.", "ERROR")
                return False
            
            # Perform migrations
            self.migrate_payment_attendee_links()
            self.fix_attendee_details_from_payments()
            
            # Verify migration
            if self.verify_migration():
                self._log("Migration completed successfully!", "SUCCESS")
            else:
                self._log("Migration verification failed!", "ERROR")
                return False
            
            # Save migration log
            self.save_migration_log()
            
            return True
            
        except Exception as e:
            self._log(f"Migration failed: {str(e)}", "ERROR")
            return False

def main():
    parser = argparse.ArgumentParser(description='QR Flow Production Migration')
    parser.add_argument('--dry-run', action='store_true', 
                       help='Show what would be done without making changes')
    parser.add_argument('--backup-db', action='store_true',
                       help='Create a backup before migration')
    
    args = parser.parse_args()
    
    print("QR Flow Production Migration Tool")
    print("=" * 40)
    
    if args.dry_run:
        print("DRY RUN MODE - No changes will be made")
    
    migrator = ProductionMigrator(dry_run=args.dry_run)
    success = migrator.run_migration(backup_db=args.backup_db)
    
    if success:
        print("\n✅ Migration completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Migration failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
