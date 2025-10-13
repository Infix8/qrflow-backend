"""
Main FastAPI Application - All API endpoints
"""
from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, timedelta
import pandas as pd
import json
import io
import os
import razorpay
import threading
import time

from . import models, schemas, security, utils
from .database import engine, get_db
from .security import (
    get_password_hash,
    authenticate_user,
    create_access_token,
    get_current_user,
    require_admin,
    require_organizer,
    BLACKLIST_TOKENS
)
from .config import settings

# Create database tables (only if not in testing mode)
if os.getenv("ENVIRONMENT", "development") != "testing":
    models.Base.metadata.create_all(bind=engine)

# Initialize Razorpay client (lazy initialization)
def get_razorpay_client():
    """Get Razorpay client with proper error handling"""
    if not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
        raise HTTPException(
            status_code=500, 
            detail="Razorpay credentials not configured"
        )
    return razorpay.Client(
        auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
    )

# Initialize FastAPI app
app = FastAPI(
    title="Event Management System API",
    description="API for managing events, attendees, and QR code check-ins",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8080",
        "http://127.0.0.1:8080",
        "http://localhost:3000",  # Vite dev server
        "https://qrflow-frontend-gcv0w3nm2-infix8s-projects.vercel.app",  # Vercel domain
        "https://qrflow-frontend.vercel.app",           # Custom domain
        "https://*.vercel.app",                   # All Vercel domains
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============= Helper Functions =============

def normalize_year(year_str: str) -> int:
    """
    Normalize year string to integer (1-4) - Enhanced version
    Handles: "1", "2nd", "3rd", "4th", "II", "III", "IV", "first", "second", etc.
    """
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
    
    print(f"⚠️ Could not normalize year: '{year_str}', using default 1")
    return 1


def normalize_section(section_str: str) -> str:
    """
    Normalize section string to single letter (A-Z)
    """
    import re
    
    if not section_str:
        return "A"
        
    section_str = str(section_str).strip().upper()
    
    # Handle patterns like "CSM A", "CSM c", "SECTION B"
    # Extract the last letter from the string
    letter_match = re.search(r'([A-Z])$', section_str)
    if letter_match:
        return letter_match.group(1)
    
    # If it's just a single letter
    if len(section_str) == 1 and section_str.isalpha():
        return section_str
    
    print(f"⚠️ Could not normalize section: '{section_str}', using default A")
    return "A"


def parse_year_from_string(year_str: str) -> int:
    """
    Legacy function for backward compatibility
    """
    return normalize_year(year_str)

def log_activity(
    db: Session,
    user_id: int,
    action: str,
    entity_type: str,
    entity_id: Optional[int] = None,
    description: str = "",
    details: Optional[dict] = None
):
    """
    Log user activity for audit trail
    """
    # Get user name
    user = db.query(models.User).filter(models.User.id == user_id).first()
    user_name = user.username if user else "Unknown"
    
    log_entry = models.ActivityLog(
        user_id=user_id,
        action_type=action,
        entity_type=entity_type,
        entity_id=entity_id,
        description=description,
        changes_json=json.dumps(details) if details else None
    )
    db.add(log_entry)
    db.commit()


# ============= Background Scheduler =============

def sync_payments_and_create_attendees():
    """
    Background task to sync payments from Razorpay and create attendee QR codes
    This function runs every 30 minutes
    """
    try:
        from datetime import datetime, timedelta
        import pytz
        
        # Use IST timezone
        ist = pytz.timezone('Asia/Kolkata')
        current_time = datetime.now(ist)
        print(f"🔄 Starting payment sync at {current_time.strftime('%Y-%m-%d %H:%M:%S IST')}")
        
        # Get database session
        from .database import SessionLocal
        db = SessionLocal()
        
        try:
            # Get Razorpay client
            razorpay_client = get_razorpay_client()
            
            # Fetch recent payments from Razorpay (last 24 hours)
            yesterday = datetime.now(ist) - timedelta(days=1)
            params = {
                "count": 100,
                "from": int(yesterday.timestamp())
            }
            
            print(f"🔍 Fetching payments from Razorpay with params: {params}")
            payments_response = razorpay_client.payment.all(params)
            payments = payments_response.get("items", [])
            print(f"📊 Found {len(payments)} payments from Razorpay")
            
            # Filter for QR flow payments
            qr_flow_payments = []
            for payment in payments:
                # Check if this is a QR flow payment
                is_qr_flow = (
                    payment.get("description") == "QRv2 Payment" or
                    (payment.get("notes") and 
                     isinstance(payment.get("notes"), dict) and
                     any(key in payment.get("notes", {}) for key in ["college_name", "department", "roll_number", "name", "phone"]))
                )
                
                if is_qr_flow:
                    qr_flow_payments.append(payment)
                    print(f"✅ QR Flow payment found: {payment.get('id')} - {payment.get('description')}")
            
            print(f"🎯 Filtered {len(qr_flow_payments)} QR flow payments")
            
            # Process each QR flow payment
            synced_count = 0
            created_count = 0
            updated_count = 0
            attendees_created = 0
            
            for payment in qr_flow_payments:
                try:
                    payment_id = payment.get("id")
                    amount = payment.get("amount", 0)
                    currency = payment.get("currency", "INR")
                    status = payment.get("status", "pending")
                    email = payment.get("email", "")
                    contact = payment.get("contact", "")
                    notes = payment.get("notes", {})
                    
                    # Extract student information from notes
                    student_name = notes.get("name", "Unknown")
                    college_name = notes.get("college_name", "")
                    department = notes.get("department", "")
                    roll_number = notes.get("roll_number", "")
                    phone = notes.get("phone", contact)
                    emergency_contact = notes.get("emergency_contact_number", "")
                    
                    # Check if payment already exists
                    existing_payment = db.query(models.Payment).filter(
                        models.Payment.razorpay_payment_id == payment_id
                    ).first()
                    
                    if existing_payment:
                        # Update existing payment
                        existing_payment.amount = amount
                        existing_payment.currency = currency
                        existing_payment.status = status
                        existing_payment.customer_name = student_name
                        existing_payment.customer_email = email
                        existing_payment.customer_phone = phone
                        existing_payment.payment_captured_at = datetime.now(ist) if status == "captured" else None
                        db.commit()
                        updated_count += 1
                        print(f"🔄 Updated payment: {payment_id}")
                    else:
                        # Create new payment record
                        # Try to determine event_id from notes or use default
                        event_id = notes.get("event_id", 1)  # Default to event 1
                        
                        new_payment = models.Payment(
                            event_id=event_id,
                            razorpay_payment_id=payment_id,
                            amount=amount,
                            currency=currency,
                            status=status,
                            customer_name=student_name,
                            customer_email=email,
                            customer_phone=phone,
                            payment_captured_at=datetime.now(ist) if status == "captured" else None,
                            razorpay_signature="",  # Not available from API
                            form_data=json.dumps({
                                "college_name": college_name,
                                "department": department,
                                "roll_number": roll_number,
                                "emergency_contact": emergency_contact,
                                "original_notes": notes
                            })
                        )
                        
                        db.add(new_payment)
                        db.commit()
                        db.refresh(new_payment)
                        created_count += 1
                        print(f"➕ Created payment: {payment_id}")
                        
                        # Create attendee if payment is captured and we have student details
                        if status == "captured" and student_name != "Unknown" and roll_number:
                            try:
                                # Check if attendee already exists (prevent duplicates)
                                existing_attendee = db.query(models.Attendee).filter(
                                    models.Attendee.event_id == event_id,
                                    (models.Attendee.email == email) | (models.Attendee.roll_number == roll_number)
                                ).first()
                                
                                if existing_attendee:
                                    print(f"⚠️ Attendee already exists: {student_name} ({email}) - skipping duplicate creation")
                                    continue
                                
                                # Extract year and section from form data
                                year = 1  # Default year
                                section = "A"  # Default section
                                
                                # Parse year and section from original_notes using enhanced parsing
                                try:
                                    if isinstance(notes, dict):
                                        # Extract year from year_of_study field
                                        year_str = notes.get("year_of_study", "1")
                                        year = normalize_year(year_str)
                                        
                                        # Extract section
                                        section_str = notes.get("section", "A")
                                        section = normalize_section(section_str)
                                        
                                        print(f"✅ Parsed year/section for {student_name}: Year={year}, Section={section}")
                                except Exception as e:
                                    print(f"⚠️ Error parsing year/section for {student_name}: {str(e)}")
                                    # Use defaults
                                    year = 1
                                    section = "A"
                                
                                # Create new attendee
                                attendee = models.Attendee(
                                    event_id=event_id,
                                    name=student_name,
                                    email=email,
                                    roll_number=roll_number,
                                    branch=department.upper() if department else "UNKNOWN",
                                    year=year,
                                    section=section,
                                    phone=phone,
                                    gender="Not Specified"
                                )
                                
                                db.add(attendee)
                                db.commit()
                                db.refresh(attendee)
                                attendees_created += 1
                                
                                # Generate QR token only (no email sent automatically)
                                try:
                                    # Get event details
                                    event = db.query(models.Event).filter(models.Event.id == event_id).first()
                                    if event:
                                        # Check if QR token already exists (to prevent conflicts)
                                        if not attendee.qr_token:
                                            # Generate QR token
                                            qr_token = utils.generate_qr_token(
                                                event_id=event.id,
                                                attendee_id=attendee.id,
                                                email=attendee.email,
                                                roll_number=attendee.roll_number,
                                                event_date=event.date
                                            )
                                            attendee.qr_token = qr_token
                                            attendee.qr_generated = True
                                            attendee.qr_generated_at = datetime.now(ist)
                                        
                                        # Generate QR code image
                                        qr_code_bytes = utils.generate_qr_code(
                                            token=attendee.qr_token,
                                            attendee_name=attendee.name,
                                            event_name=event.name
                                        )
                                        
                                        # Save QR code to static folder
                                        qr_filename = f"attendee_{attendee.id}_{event.id}.png"
                                        qr_filepath = utils.save_qr_code(qr_code_bytes, qr_filename)
                                        print(f"💾 QR code saved to: {qr_filepath}")
                                        
                                        # Note: Email will be sent manually via "Send All" or individual send
                                        print(f"✅ QR code generated for: {attendee.email} (email not sent automatically)")
                                        
                                        db.commit()
                                
                                except Exception as e:
                                    print(f"❌ Error creating QR for {attendee.email}: {str(e)}")
                                    attendee.email_error = str(e)
                                    db.commit()
                                
                            except Exception as e:
                                print(f"❌ Error creating attendee for {student_name}: {str(e)}")
                    
                    synced_count += 1
                    
                except Exception as e:
                    print(f"❌ Error processing payment {payment.get('id', 'unknown')}: {str(e)}")
            
            print(f"✅ Sync completed: {synced_count} payments processed, {created_count} created, {updated_count} updated, {attendees_created} attendees created")
            
        except Exception as e:
            print(f"❌ Payment sync error: {str(e)}")
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Background sync error: {str(e)}")


def start_background_scheduler():
    """
    Start the background scheduler that runs every 30 minutes
    """
    def scheduler_loop():
        while True:
            try:
                sync_payments_and_create_attendees()
            except Exception as e:
                print(f"❌ Scheduler error: {str(e)}")
            
            # Wait 30 minutes (1800 seconds)
            time.sleep(1800)
    
    # Start scheduler in a separate thread
    scheduler_thread = threading.Thread(target=scheduler_loop, daemon=True)
    scheduler_thread.start()
    print("🔄 Background payment sync scheduler started (every 30 minutes)")


# Start the background scheduler when the app starts (only in production/development, not during testing)
if os.getenv("ENVIRONMENT", "development") != "testing":
    start_background_scheduler()



# ============= Authentication Endpoints =============

@app.post("/api/auth/login", response_model=schemas.Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """
    Login endpoint - Returns JWT token
    """
    user = authenticate_user(db, form_data.username, form_data.password)
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Update last login
    import pytz
    ist = pytz.timezone('Asia/Kolkata')
    user.last_login = datetime.now(ist)
    db.commit()
    
    # Create access token
    access_token_expires = timedelta(minutes=security.settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username},
        expires_delta=access_token_expires
    )
    
    # Log activity
    log_activity(db, user.id, "login", "user", user.id, f"User {user.username} logged in")
    
    return {"access_token": access_token, "token_type": "bearer"}


@app.post("/api/auth/logout")
async def logout(
    token: str = Depends(security.oauth2_scheme),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Logout endpoint - Blacklist token
    """
    BLACKLIST_TOKENS.add(token)
    
    # Log activity
    log_activity(db, current_user.id, "logout", "user", current_user.id, f"User {current_user.username} logged out")
    
    return {"message": "Successfully logged out"}


@app.get("/api/auth/me", response_model=schemas.UserWithClub)
async def get_me(
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Get current user information
    """
    return current_user


# Continue to next message for more endpoints...

# ============= Admin - Club Management =============

@app.post("/api/admin/clubs", response_model=schemas.Club)
async def create_club(
    club: schemas.ClubCreate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Create a new club
    """
    # Check if club name already exists
    existing = db.query(models.Club).filter(models.Club.name == club.name).first()
    if existing:
        raise HTTPException(status_code=400, detail="Club name already exists")
    
    db_club = models.Club(**club.dict())
    db.add(db_club)
    db.commit()
    db.refresh(db_club)
    
    # Log activity
    log_activity(db, current_user.id, "create_club", "club", db_club.id, f"Created club: {db_club.name}")
    
    return db_club


@app.get("/api/admin/clubs", response_model=List[schemas.Club])
async def list_clubs(
    include_disabled: bool = False,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: List clubs (active only by default, include disabled if requested)
    """
    query = db.query(models.Club)
    if not include_disabled:
        query = query.filter(models.Club.active == True)
    clubs = query.order_by(models.Club.name).all()
    return clubs


@app.put("/api/admin/clubs/{club_id}", response_model=schemas.Club)
async def update_club(
    club_id: int,
    club_update: schemas.ClubUpdate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Update club details
    """
    db_club = db.query(models.Club).filter(models.Club.id == club_id).first()
    if not db_club:
        raise HTTPException(status_code=404, detail="Club not found")
    
    # Track changes
    changes = {}
    update_data = club_update.dict(exclude_unset=True)
    
    for key, value in update_data.items():
        old_value = getattr(db_club, key)
        if old_value != value:
            changes[key] = {"old": str(old_value), "new": str(value)}
            setattr(db_club, key, value)
    
    db.commit()
    db.refresh(db_club)
    
    # Log activity
    log_activity(
        db, current_user.id, "update_club", "club", db_club.id,
        f"Updated club: {db_club.name}",
        changes
    )
    
    return db_club


@app.delete("/api/admin/clubs/{club_id}")
async def delete_club(
    club_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Delete/disable a club
    """
    db_club = db.query(models.Club).filter(models.Club.id == club_id).first()
    if not db_club:
        raise HTTPException(status_code=404, detail="Club not found")
    
    db_club.active = False
    db.commit()
    
    # Log activity
    log_activity(db, current_user.id, "delete_club", "club", db_club.id, f"Disabled club: {db_club.name}")
    
    return {"message": f"Club {db_club.name} has been disabled"}


@app.post("/api/admin/clubs/{club_id}/enable")
async def enable_club(
    club_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Re-enable a disabled club
    """
    db_club = db.query(models.Club).filter(models.Club.id == club_id).first()
    if not db_club:
        raise HTTPException(status_code=404, detail="Club not found")
    
    db_club.active = True
    db.commit()
    
    # Log activity
    log_activity(db, current_user.id, "enable_club", "club", db_club.id, f"Re-enabled club: {db_club.name}")
    
    return {"message": f"Club {db_club.name} has been re-enabled"}


# ============= Admin - User Management =============

@app.post("/api/admin/users", response_model=schemas.User)
async def create_user(
    user: schemas.UserCreate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Create a new user (club member)
    """
    # Check if username exists
    existing_user = db.query(models.User).filter(models.User.username == user.username).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="Username already exists")
    
    # Check if email exists
    existing_email = db.query(models.User).filter(models.User.email == user.email).first()
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already exists")
    
    # Validate club_id if organizer
    if user.role == "organizer" and user.club_id:
        club = db.query(models.Club).filter(models.Club.id == user.club_id).first()
        if not club:
            raise HTTPException(status_code=400, detail="Club not found")
    
    # Create user
    hashed_password = get_password_hash(user.password)
    db_user = models.User(
        username=user.username,
        email=user.email,
        password_hash=hashed_password,
        full_name=user.full_name,
        club_id=user.club_id,
        role=user.role
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # Log activity
    log_activity(db, current_user.id, "create_user", "user", db_user.id, f"Created user: {db_user.username} (Role: {db_user.role})")
    
    return db_user


@app.get("/api/admin/users", response_model=List[schemas.UserWithClub])
async def list_users(
    include_disabled: bool = False,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: List users (active only by default, include disabled if requested)
    """
    query = db.query(models.User)
    if not include_disabled:
        query = query.filter(models.User.disabled == False)
    users = query.order_by(models.User.username).all()
    return users


@app.get("/api/admin/clubs/{club_id}/users", response_model=List[schemas.User])
async def list_club_users(
    club_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Get all users of a specific club
    """
    users = db.query(models.User).filter(models.User.club_id == club_id).all()
    return users


@app.put("/api/admin/users/{user_id}", response_model=schemas.User)
async def update_user(
    user_id: int,
    user_update: schemas.UserUpdate,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Update user details
    """
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Track changes
    changes = {}
    update_data = user_update.dict(exclude_unset=True)
    
    for key, value in update_data.items():
        if key == "password" and value:
            # Hash new password
            db_user.password_hash = get_password_hash(value)
            changes["password"] = {"old": "****", "new": "****"}
        else:
            old_value = getattr(db_user, key)
            if old_value != value:
                changes[key] = {"old": str(old_value), "new": str(value)}
                setattr(db_user, key, value)
    
    db.commit()
    db.refresh(db_user)
    
    # Log activity
    log_activity(
        db, current_user.id, "update_user", "user", db_user.id,
        f"Updated user: {db_user.username}",
        changes
    )
    
    return db_user


@app.delete("/api/admin/users/{user_id}")
async def delete_user(
    user_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Disable a user
    """
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    if db_user.id == current_user.id:
        raise HTTPException(status_code=400, detail="Cannot disable yourself")
    
    db_user.disabled = True
    db.commit()
    
    # Log activity
    log_activity(db, current_user.id, "delete_user", "user", db_user.id, f"Disabled user: {db_user.username}")
    
    return {"message": f"User {db_user.username} has been disabled"}


@app.post("/api/admin/users/{user_id}/enable")
async def enable_user(
    user_id: int,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Re-enable a disabled user
    """
    db_user = db.query(models.User).filter(models.User.id == user_id).first()
    if not db_user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db_user.disabled = False
    db.commit()
    
    # Log activity
    log_activity(db, current_user.id, "enable_user", "user", db_user.id, f"Re-enabled user: {db_user.username}")
    
    return {"message": f"User {db_user.username} has been re-enabled"}


# ============= Admin - Activity Logs =============

@app.get("/api/admin/logs", response_model=List[schemas.ActivityLogWithDetails])
async def get_all_logs(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Get all activity logs
    """
    logs = db.query(models.ActivityLog).order_by(models.ActivityLog.timestamp.desc()).offset(skip).limit(limit).all()
    return logs


@app.get("/api/admin/clubs/{club_id}/logs", response_model=List[schemas.ActivityLogWithDetails])
async def get_club_logs(
    club_id: int,
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Admin: Get activity logs for a specific club
    """
    logs = db.query(models.ActivityLog).filter(
        models.ActivityLog.club_id == club_id
    ).order_by(models.ActivityLog.timestamp.desc()).offset(skip).limit(limit).all()
    return logs


# Continue to next message for Event and Attendee endpoints...

# ============= Club Member - Dashboard =============

@app.get("/api/club/info", response_model=schemas.Club)
async def get_club_info(
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get current user's club information
    """
    if not current_user.club_id:
        raise HTTPException(status_code=404, detail="User not assigned to any club")
    
    club = db.query(models.Club).filter(models.Club.id == current_user.club_id).first()
    if not club:
        raise HTTPException(status_code=404, detail="Club not found")
    
    return club


@app.get("/api/club/members", response_model=List[schemas.User])
async def get_club_members(
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get all members of current user's club
    """
    if not current_user.club_id:
        raise HTTPException(status_code=404, detail="User not assigned to any club")
    
    members = db.query(models.User).filter(models.User.club_id == current_user.club_id).all()
    return members


@app.get("/api/club/events", response_model=List[schemas.EventWithDetails])
async def get_club_events(
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get all events of current user's club
    """
    if not current_user.club_id:
        raise HTTPException(status_code=404, detail="User not assigned to any club")
    
    events = db.query(models.Event).filter(models.Event.club_id == current_user.club_id).all()
    
    # Add statistics to each event
    for event in events:
        event.total_attendees = db.query(models.Attendee).filter(models.Attendee.event_id == event.id).count()
        event.checked_in_count = db.query(models.Attendee).filter(
            models.Attendee.event_id == event.id,
            models.Attendee.checked_in == True
        ).count()
    
    return events


# ============= Events Management =============

@app.post("/api/events", response_model=schemas.Event)
async def create_event(
    event: schemas.EventCreate,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Create a new event (club members only)
    """
    # For admins, allow creating events without club assignment
    # For organizers, require club assignment
    if current_user.role == "organizer" and not current_user.club_id:
        raise HTTPException(status_code=400, detail="User must be assigned to a club to create events")
    
    # Use club_id from user, or default to 1 for admins
    club_id = current_user.club_id if current_user.club_id else 1
    
    db_event = models.Event(
        club_id=club_id,
        created_by=current_user.id,
        **event.dict()
    )
    
    db.add(db_event)
    db.commit()
    db.refresh(db_event)
    
    # Log activity
    log_activity(db, current_user.id, "create_event", "event", db_event.id, f"Created event: {db_event.name}")
    
    return db_event


@app.get("/api/events", response_model=List[schemas.EventWithDetails])
async def list_events(
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    List events (filtered by club for organizers, all for admin)
    """
    if current_user.role == "admin":
        events = db.query(models.Event).all()
    else:
        if not current_user.club_id:
            return []
        events = db.query(models.Event).filter(models.Event.club_id == current_user.club_id).all()
    
    # Add statistics
    for event in events:
        event.total_attendees = db.query(models.Attendee).filter(models.Attendee.event_id == event.id).count()
        event.checked_in_count = db.query(models.Attendee).filter(
            models.Attendee.event_id == event.id,
            models.Attendee.checked_in == True
        ).count()
    
    return events


@app.get("/api/events/{event_id}", response_model=schemas.EventWithDetails)
async def get_event(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get event details
    """
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check access
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Add statistics
    event.total_attendees = db.query(models.Attendee).filter(models.Attendee.event_id == event.id).count()
    event.checked_in_count = db.query(models.Attendee).filter(
        models.Attendee.event_id == event.id,
        models.Attendee.checked_in == True
    ).count()
    
    return event


@app.put("/api/events/{event_id}", response_model=schemas.Event)
async def update_event(
    event_id: int,
    event_update: schemas.EventUpdate,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Update event details
    """
    db_event = db.query(models.Event).filter(models.Event.id == event_id).first()
    
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check access
    if current_user.role != "admin" and db_event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Track changes
    changes = {}
    update_data = event_update.dict(exclude_unset=True)
    
    for key, value in update_data.items():
        old_value = getattr(db_event, key)
        if old_value != value:
            changes[key] = {"old": str(old_value), "new": str(value)}
            setattr(db_event, key, value)
    
    db.commit()
    db.refresh(db_event)
    
    # Log activity
    log_activity(
        db, current_user.id, "update_event", "event", db_event.id,
        f"Updated event: {db_event.name}",
        changes
    )
    
    return db_event


@app.delete("/api/events/{event_id}")
async def delete_event(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Delete an event
    """
    db_event = db.query(models.Event).filter(models.Event.id == event_id).first()
    
    if not db_event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    # Check access
    if current_user.role != "admin" and db_event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Log activity before deletion
    log_activity(db, current_user.id, "delete_event", "event", db_event.id, f"Deleted event: {db_event.name}")
    
    db.delete(db_event)
    db.commit()
    
    return {"message": f"Event {db_event.name} has been deleted"}


# Continue to next message for Attendee management endpoints...

# ============= Attendee Management =============

@app.get("/api/events/{event_id}/attendees")
async def get_event_attendees(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get all attendees for an event with payment details
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    attendees = db.query(models.Attendee).filter(models.Attendee.event_id == event_id).all()
    
    # Enrich attendees with payment information
    enriched_attendees = []
    for attendee in attendees:
        # Get payment information for this attendee
        payment = db.query(models.Payment).filter(
            models.Payment.event_id == event_id,
            (models.Payment.customer_email == attendee.email) | 
            (models.Payment.customer_phone == attendee.phone)
        ).first()
        
        # Create enriched attendee data
        attendee_data = {
            "id": attendee.id,
            "name": attendee.name,
            "email": attendee.email,
            "roll_number": attendee.roll_number,
            "branch": attendee.branch,
            "year": attendee.year,
            "section": attendee.section,
            "phone": attendee.phone,
            "gender": attendee.gender,
            "qr_generated": attendee.qr_generated,
            "qr_generated_at": attendee.qr_generated_at.isoformat() if attendee.qr_generated_at else None,
            "email_sent": attendee.email_sent,
            "email_sent_at": attendee.email_sent_at.isoformat() if attendee.email_sent_at else None,
            "email_error": attendee.email_error,
            "checked_in": attendee.checked_in,
            "checkin_time": attendee.checkin_time.isoformat() if attendee.checkin_time else None,
            "checked_by": attendee.checked_by,
            "checker_name": attendee.checker.username if attendee.checker else None,
            "created_at": attendee.created_at.isoformat(),
            "updated_at": attendee.updated_at.isoformat(),
            "payment": None
        }
        
        # Add payment details if available
        if payment:
            attendee_data["payment"] = {
                "id": payment.id,
                "razorpay_payment_id": payment.razorpay_payment_id,
                "amount": payment.amount,
                "currency": payment.currency,
                "status": payment.status,
                "customer_name": payment.customer_name,
                "customer_email": payment.customer_email,
                "customer_phone": payment.customer_phone,
                "form_data": payment.form_data,
                "created_at": payment.created_at.isoformat(),
                "updated_at": payment.updated_at.isoformat(),
                "payment_captured_at": payment.payment_captured_at.isoformat() if payment.payment_captured_at else None
            }
        
        enriched_attendees.append(attendee_data)
    
    return enriched_attendees


@app.get("/api/events/{event_id}/attendees/template")
async def download_template(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Download CSV template for attendee upload
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Create template CSV
    template_data = {
        'name': ['John Doe', 'Jane Smith'],
        'email': ['john@example.com', 'jane@example.com'],
        'roll_number': ['21BCE001', '21BCE002'],
        'branch': ['CSE', 'ECE'],
        'year': [3, 2],
        'section': ['A', 'B'],
        'phone': ['9876543210', '9876543211'],
        'gender': ['Male', 'Female']
    }
    
    df = pd.DataFrame(template_data)
    
    # Convert to CSV
    csv_buffer = io.StringIO()
    df.to_csv(csv_buffer, index=False)
    csv_buffer.seek(0)
    
    return StreamingResponse(
        io.BytesIO(csv_buffer.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=attendee_template.csv"}
    )


@app.post("/api/events/{event_id}/attendees/upload")
async def upload_attendees_csv(
    event_id: int,
    file: UploadFile = File(...),
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Bulk upload attendees via CSV
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Validate file type
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="Only CSV files are allowed")
    
    try:
        # Read CSV
        contents = await file.read()
        df = pd.read_csv(io.BytesIO(contents))
        
        # Validate required columns
        required_columns = ['name', 'email', 'roll_number', 'branch', 'year', 'section']
        missing_columns = [col for col in required_columns if col not in df.columns]
        
        if missing_columns:
            raise HTTPException(
                status_code=400,
                detail=f"Missing required columns: {', '.join(missing_columns)}"
            )
        
        # Process each row
        added_count = 0
        skipped_count = 0
        errors = []
        
        for index, row in df.iterrows():
            try:
                # Check if attendee already exists (by roll_number only)
                existing = db.query(models.Attendee).filter(
                    models.Attendee.event_id == event_id,
                    models.Attendee.roll_number == row['roll_number']
                ).first()
                
                if existing:
                    skipped_count += 1
                    errors.append({
                        "row": index + 2,
                        "email": row['email'],
                        "error": "Attendee already exists"
                    })
                    continue
                
                # Create attendee
                attendee = models.Attendee(
                    event_id=event_id,
                    name=str(row['name']).strip(),
                    email=str(row['email']).strip().lower(),
                    roll_number=str(row['roll_number']).strip().upper(),
                    branch=str(row['branch']).strip().upper(),
                    year=int(row['year']),
                    section=str(row['section']).strip().upper(),
                    phone=str(row.get('phone', '')).strip() if pd.notna(row.get('phone')) else None,
                    gender=str(row.get('gender', 'Not Specified')).strip() if pd.notna(row.get('gender')) else 'Not Specified'
                )
                
                db.add(attendee)
                added_count += 1
            
            except Exception as e:
                errors.append({
                    "row": index + 2,
                    "email": row.get('email', 'N/A'),
                    "error": str(e)
                })
                skipped_count += 1
        
        db.commit()
        
        # Generate QR codes for all uploaded attendees
        if added_count > 0:
            print(f"🔄 Generating QR codes for {added_count} uploaded attendees...")
            qr_generated_count = 0
            
            # Get all attendees that were just uploaded (without QR tokens)
            uploaded_attendees = db.query(models.Attendee).filter(
                models.Attendee.event_id == event_id,
                models.Attendee.qr_token.is_(None)
            ).all()
            
            for attendee in uploaded_attendees:
                try:
                    # Generate QR token
                    qr_token = utils.generate_qr_token(
                        event_id=event.id,
                        attendee_id=attendee.id,
                        email=attendee.email,
                        roll_number=attendee.roll_number,
                        event_date=event.date
                    )
                    attendee.qr_token = qr_token
                    attendee.qr_generated = True
                    attendee.qr_generated_at = datetime.now()
                    
                    # Generate QR code image
                    qr_code_bytes = utils.generate_qr_code(
                        token=attendee.qr_token,
                        attendee_name=attendee.name,
                        event_name=event.name
                    )
                    
                    # Save QR code to static folder
                    qr_filename = f"attendee_{attendee.id}_{event.id}.png"
                    qr_filepath = utils.save_qr_code(qr_code_bytes, qr_filename)
                    qr_generated_count += 1
                    
                except Exception as e:
                    print(f"❌ Error generating QR for {attendee.email}: {str(e)}")
                    attendee.email_error = str(e)
            
            db.commit()
            print(f"✅ Generated QR codes for {qr_generated_count} attendees (emails not sent automatically)")
        
        # Log activity
        log_activity(
            db, current_user.id, "upload_attendees", "event", event_id,
            f"Uploaded {added_count} attendees to event: {event.name}"
        )
        
        return {
            "message": f"Upload complete: {added_count} added, {skipped_count} skipped",
            "added": added_count,
            "skipped": skipped_count,
            "errors": errors[:20]  # Return first 20 errors only
        }
    
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error processing CSV: {str(e)}")


@app.post("/api/events/{event_id}/attendees", response_model=schemas.Attendee)
async def create_attendee(
    event_id: int,
    attendee_data: schemas.AttendeeBase,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Create a new attendee for an event
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Check if attendee already exists (by roll number only)
    existing = db.query(models.Attendee).filter(
        models.Attendee.event_id == event_id,
        models.Attendee.roll_number == attendee_data.roll_number
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Attendee already exists with this roll number")
    
    # Create attendee
    attendee = models.Attendee(
        event_id=event_id,
        name=attendee_data.name,
        email=attendee_data.email,
        roll_number=attendee_data.roll_number,
        branch=attendee_data.branch,
        year=attendee_data.year,
        section=attendee_data.section,
        phone=attendee_data.phone,
        gender=attendee_data.gender
    )
    
    db.add(attendee)
    db.commit()
    db.refresh(attendee)
    
    # Generate QR token for the attendee (if not already exists)
    try:
        if not attendee.qr_token:
            qr_token = utils.generate_qr_token(
                event_id=event.id,
                attendee_id=attendee.id,
                email=attendee.email,
                roll_number=attendee.roll_number,
                event_date=event.date
            )
            attendee.qr_token = qr_token
            attendee.qr_generated = True
            attendee.qr_generated_at = datetime.now()
        
        # Generate QR code image
        qr_code_bytes = utils.generate_qr_code(
            token=attendee.qr_token,
            attendee_name=attendee.name,
            event_name=event.name
        )
        
        # Save QR code to static folder
        qr_filename = f"attendee_{attendee.id}_{event.id}.png"
        qr_filepath = utils.save_qr_code(qr_code_bytes, qr_filename)
        print(f"💾 QR code saved to: {qr_filepath}")
        
        db.commit()
        print(f"✅ QR code generated for: {attendee.email} (email not sent automatically)")
        
    except Exception as e:
        print(f"❌ Error generating QR for {attendee.email}: {str(e)}")
        attendee.email_error = str(e)
        db.commit()
    
    # Log activity
    log_activity(
        db, current_user.id, "create_attendee", "attendee", attendee.id,
        f"Created attendee: {attendee.name} ({attendee.roll_number}) for event: {event.name}"
    )
    
    return attendee


@app.get("/api/attendees/{attendee_id}", response_model=schemas.Attendee)
async def get_attendee(
    attendee_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get attendee details by ID
    """
    attendee = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
    if not attendee:
        raise HTTPException(status_code=404, detail="Attendee not found")
    
    # Check access
    if current_user.role != "admin" and attendee.event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return attendee


@app.put("/api/attendees/{attendee_id}", response_model=schemas.Attendee)
async def update_attendee(
    attendee_id: int,
    attendee_update: schemas.AttendeeUpdate,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Update attendee details
    """
    attendee = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
    
    if not attendee:
        raise HTTPException(status_code=404, detail="Attendee not found")
    
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == attendee.event_id).first()
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Track changes
    changes = {}
    update_data = attendee_update.dict(exclude_unset=True)
    
    for key, value in update_data.items():
        old_value = getattr(attendee, key)
        if old_value != value:
            changes[key] = {"old": str(old_value), "new": str(value)}
            setattr(attendee, key, value)
    
    db.commit()
    db.refresh(attendee)
    
    # Log activity
    log_activity(
        db, current_user.id, "update_attendee", "attendee", attendee.id,
        f"Updated attendee: {attendee.name} ({attendee.email})",
        changes
    )
    
    return attendee


@app.delete("/api/attendees/{attendee_id}")
async def delete_attendee(
    attendee_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Delete an attendee
    """
    attendee = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
    
    if not attendee:
        raise HTTPException(status_code=404, detail="Attendee not found")
    
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == attendee.event_id).first()
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Log activity
    log_activity(
        db, current_user.id, "delete_attendee", "attendee", attendee.id,
        f"Deleted attendee: {attendee.name} ({attendee.email})"
    )
    
    db.delete(attendee)
    db.commit()
    
    return {"message": "Attendee deleted successfully"}


# Continue to next message for QR generation and check-in endpoints...

# ============= QR Code Generation & Email =============

@app.post("/api/events/{event_id}/generate-qr-codes", response_model=schemas.BulkQRGenerateResponse)
async def generate_qr_codes_for_attendees(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Generate QR codes for all attendees who don't have them yet
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Get attendees that don't have QR codes generated yet
    attendees = db.query(models.Attendee).filter(
        models.Attendee.event_id == event_id,
        models.Attendee.qr_token.is_(None)
    ).all()
    
    if not attendees:
        return {
            "total": 0,
            "success": 0,
            "failed": 0,
            "errors": []
        }
    
    total = len(attendees)
    success = 0
    failed = 0
    errors = []
    
    for attendee in attendees:
        try:
            # Generate QR token
            qr_token = utils.generate_qr_token(
                event_id=event.id,
                attendee_id=attendee.id,
                email=attendee.email,
                roll_number=attendee.roll_number,
                event_date=event.date
            )
            attendee.qr_token = qr_token
            attendee.qr_generated = True
            attendee.qr_generated_at = datetime.now()
            
            # Generate QR code image
            qr_code_bytes = utils.generate_qr_code(
                token=attendee.qr_token,
                attendee_name=attendee.name,
                event_name=event.name
            )
            
            # Save QR code to static folder
            qr_filename = f"attendee_{attendee.id}_{event.id}.png"
            qr_filepath = utils.save_qr_code(qr_code_bytes, qr_filename)
            
            success += 1
            print(f"✅ QR code generated for: {attendee.email}")
            
            db.commit()
        
        except Exception as e:
            failed += 1
            error_msg = str(e)
            attendee.email_error = error_msg
            db.commit()
            
            errors.append({
                "attendee_id": attendee.id,
                "name": attendee.name,
                "email": attendee.email,
                "error": error_msg
            })
            print(f"❌ Error generating QR for {attendee.email}: {error_msg}")
    
    # Log activity
    log_activity(
        db, current_user.id, "generate_qr_codes", "event", event_id,
        f"Generated QR codes for {success} attendees in event: {event.name}"
    )
    
    return {
        "total": total,
        "success": success,
        "failed": failed,
        "errors": errors[:20]  # Return first 20 errors
    }


@app.post("/api/events/{event_id}/send-emails", response_model=schemas.BulkQRGenerateResponse)
async def send_all_emails(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Send QR code emails to all attendees who have QR codes generated but emails not sent
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Get attendees that have QR codes generated but emails not sent
    attendees = db.query(models.Attendee).filter(
        models.Attendee.event_id == event_id,
        models.Attendee.qr_generated == True,
        models.Attendee.qr_token.isnot(None),
        models.Attendee.email_sent == False
    ).all()
    
    if not attendees:
        return {
            "total": 0,
            "success": 0,
            "failed": 0,
            "errors": []
        }
    
    total = len(attendees)
    success = 0
    failed = 0
    errors = []
    
    for attendee in attendees:
        try:
            # Generate QR code image (using existing QR token)
            qr_code_bytes = utils.generate_qr_code(
                token=attendee.qr_token,
                attendee_name=attendee.name,
                event_name=event.name
            )
            
            # Send email
            email_success, error_msg = utils.send_qr_email(
                to_email=attendee.email,
                attendee_name=attendee.name,
                event_name=event.name,
                event_date=event.date,
                event_venue=event.venue or "TBA",
                qr_code_bytes=qr_code_bytes
            )
            
            if email_success:
                attendee.email_sent = True
                import pytz
                ist = pytz.timezone('Asia/Kolkata')
                attendee.email_sent_at = datetime.now(ist)
                attendee.email_error = None
                success += 1
                print(f"📧 Email sent to: {attendee.email}")
            else:
                attendee.email_error = error_msg
                failed += 1
                errors.append({
                    "attendee_id": attendee.id,
                    "name": attendee.name,
                    "email": attendee.email,
                    "error": error_msg
                })
                print(f"❌ Email failed for {attendee.email}: {error_msg}")
            
            db.commit()
        
        except Exception as e:
            failed += 1
            error_msg = str(e)
            attendee.email_error = error_msg
            db.commit()
            
            errors.append({
                "attendee_id": attendee.id,
                "name": attendee.name,
                "email": attendee.email,
                "error": error_msg
            })
    
    # Log activity
    log_activity(
        db, current_user.id, "send_emails", "event", event_id,
        f"Sent QR code emails to {success} attendees in event: {event.name}"
    )
    
    return {
        "total": total,
        "success": success,
        "failed": failed,
        "errors": errors[:20]  # Return first 20 errors
    }


@app.post("/api/attendees/{attendee_id}/send-email")
async def send_email_to_attendee(
    attendee_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Send QR code email to a specific attendee (uses existing QR token for consistency)
    """
    attendee = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
    
    if not attendee:
        raise HTTPException(status_code=404, detail="Attendee not found")
    
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == attendee.event_id).first()
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    try:
        import pytz
        ist = pytz.timezone('Asia/Kolkata')
        
        # Generate QR token if not exists
        if not attendee.qr_token:
            qr_token = utils.generate_qr_token(
                event_id=event.id,
                attendee_id=attendee.id,
                email=attendee.email,
                roll_number=attendee.roll_number,
                event_date=event.date
            )
            attendee.qr_token = qr_token
            attendee.qr_generated = True
            attendee.qr_generated_at = datetime.now(ist)
        
        # Generate QR code image
        qr_code_bytes = utils.generate_qr_code(
            token=attendee.qr_token,
            attendee_name=attendee.name,
            event_name=event.name
        )
        
        # Send email
        email_success, error_msg = utils.send_qr_email(
            to_email=attendee.email,
            attendee_name=attendee.name,
            event_name=event.name,
            event_date=event.date,
            event_venue=event.venue or "TBA",
            qr_code_bytes=qr_code_bytes
        )
        
        if email_success:
            attendee.email_sent = True
            attendee.email_sent_at = datetime.now(ist)
            attendee.email_error = None
            db.commit()
            
            # Log activity
            log_activity(
                db, current_user.id, "send_email", "attendee", attendee_id,
                f"Sent QR code email to: {attendee.name} ({attendee.email})"
            )
            
            return {"message": "QR code sent successfully", "success": True}
        else:
            attendee.email_error = error_msg
            db.commit()
            raise HTTPException(status_code=500, detail=f"Failed to send email: {error_msg}")
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ============= Check-in Endpoints =============

@app.post("/api/checkin/status")
async def check_attendee_status(
    checkin_request: schemas.CheckInRequest,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Check if attendee is already checked in without performing check-in
    Useful for status checking before actual check-in
    """
    try:
        # Verify QR token
        payload = utils.verify_qr_token(checkin_request.qr_token)
        
        event_id = payload.get("event_id")
        attendee_id = payload.get("attendee_id")
        
        # Validate payload
        if not event_id or not attendee_id:
            return {
                "success": False,
                "message": "Invalid QR code - Missing event or attendee information",
                "attendee": None,
                "is_checked_in": False
            }
        
        # Get attendee
        attendee = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
        if not attendee:
            return {
                "success": False,
                "message": "Attendee not found - Please contact organizer",
                "attendee": None,
                "is_checked_in": False
            }
        
        # Check access
        event = db.query(models.Event).filter(models.Event.id == event_id).first()
        if not event:
            return {
                "success": False,
                "message": "Event not found - Please contact organizer",
                "attendee": None,
                "is_checked_in": False
            }
        
        if current_user.role != "admin" and event.club_id != current_user.club_id:
            return {
                "success": False,
                "message": "Access denied - You are not authorized for this event",
                "attendee": None,
                "is_checked_in": False
            }
        
        # Return status
        if attendee.checked_in:
            import pytz
            ist = pytz.timezone('Asia/Kolkata')
            checkin_time_str = attendee.checkin_time.astimezone(ist).strftime('%I:%M %p on %d %b %Y')
            return {
                "success": True,
                "message": f"✅ {attendee.name} (Roll: {attendee.roll_number}) is already checked in at {checkin_time_str}",
                "attendee": attendee,
                "is_checked_in": True,
                "checkin_time": attendee.checkin_time.isoformat() if attendee.checkin_time else None
            }
        else:
            return {
                "success": True,
                "message": f"✅ {attendee.name} (Roll: {attendee.roll_number}) is ready for check-in",
                "attendee": attendee,
                "is_checked_in": False,
                "checkin_time": None
            }
    
    except ValueError as e:
        error_msg = str(e)
        if "expired" in error_msg.lower():
            return {
                "success": False,
                "message": "❌ QR code has expired - Please request a new QR code",
                "attendee": None,
                "is_checked_in": False
            }
        elif "invalid" in error_msg.lower():
            return {
                "success": False,
                "message": "❌ Invalid QR code - Please scan a valid QR code",
                "attendee": None,
                "is_checked_in": False
            }
        else:
            return {
                "success": False,
                "message": f"❌ QR code error: {error_msg}",
                "attendee": None,
                "is_checked_in": False
            }
    except Exception as e:
        return {
            "success": False,
            "message": f"❌ An unexpected error occurred: {str(e)}",
            "attendee": None,
            "is_checked_in": False
        }

@app.post("/api/checkin/validate")
async def validate_qr_token(
    checkin_request: schemas.CheckInRequest,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Validate QR token and return attendee information without checking in
    Useful for pre-validation or testing
    """
    try:
        # Verify QR token
        payload = utils.verify_qr_token(checkin_request.qr_token)
        
        event_id = payload.get("event_id")
        attendee_id = payload.get("attendee_id")
        
        # Validate payload
        if not event_id or not attendee_id:
            return {
                "success": False,
                "message": "Invalid QR code - Missing event or attendee information",
                "attendee": None,
                "event": None
            }
        
        # Get event
        event = db.query(models.Event).filter(models.Event.id == event_id).first()
        if not event:
            return {
                "success": False,
                "message": "Event not found - Please contact organizer",
                "attendee": None,
                "event": None
            }
        
        # Check access
        if current_user.role != "admin" and event.club_id != current_user.club_id:
            return {
                "success": False,
                "message": "Access denied - You are not authorized for this event",
                "attendee": None,
                "event": None
            }
        
        # Get attendee
        attendee = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
        if not attendee:
            return {
                "success": False,
                "message": "Attendee not found - Please contact organizer",
                "attendee": None,
                "event": None
            }
        
        # Check if already checked in
        if attendee.checked_in:
            import pytz
            ist = pytz.timezone('Asia/Kolkata')
            checkin_time_str = attendee.checkin_time.astimezone(ist).strftime('%I:%M %p on %d %b %Y')
            return {
                "success": False,
                "message": f"✅ {attendee.name} (Roll: {attendee.roll_number}) is already checked in at {checkin_time_str}",
                "attendee": attendee
            }
        
        # Return attendee and event information for valid QR
        return {
            "success": True,
            "message": f"✅ Valid QR code for {attendee.name} (Roll: {attendee.roll_number}) - Ready for check-in",
            "attendee": attendee
        }
    
    except ValueError as e:
        error_msg = str(e)
        if "expired" in error_msg.lower():
            return {
                "success": False,
                "message": "❌ QR code has expired - Please request a new QR code",
                "attendee": None,
                "event": None
            }
        elif "invalid" in error_msg.lower():
            return {
                "success": False,
                "message": "❌ Invalid QR code - Please scan a valid QR code",
                "attendee": None,
                "event": None
            }
        else:
            return {
                "success": False,
                "message": f"❌ QR code error: {error_msg}",
                "attendee": None,
                "event": None
            }
    except Exception as e:
        return {
            "success": False,
            "message": f"❌ An unexpected error occurred: {str(e)}",
            "attendee": None,
            "event": None
        }

@app.post("/api/checkin/scan", response_model=schemas.CheckInResponse)
async def scan_qr_checkin(
    checkin_request: schemas.CheckInRequest,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Scan QR code and check-in attendee with race condition handling
    """
    try:
        # Verify QR token
        payload = utils.verify_qr_token(checkin_request.qr_token)
        
        event_id = payload.get("event_id")
        attendee_id = payload.get("attendee_id")
        
        # Validate payload
        if not event_id or not attendee_id:
            return {
                "success": False,
                "message": "Invalid QR code - Missing event or attendee information",
                "attendee": None
            }
        
        # Get event with lock to prevent race conditions
        event = db.query(models.Event).filter(models.Event.id == event_id).first()
        if not event:
            return {
                "success": False,
                "message": "Event not found - Please contact organizer",
                "attendee": None
            }
        
        # Check access
        if current_user.role != "admin" and event.club_id != current_user.club_id:
            return {
                "success": False,
                "message": "Access denied - You are not authorized for this event",
                "attendee": None
            }
        
        # Get attendee with row-level lock to prevent race conditions
        from sqlalchemy import text
        attendee = db.execute(
            text("SELECT * FROM attendees WHERE id = :attendee_id FOR UPDATE"),
            {"attendee_id": attendee_id}
        ).fetchone()
        
        if not attendee:
            return {
                "success": False,
                "message": "Attendee not found - Please contact organizer",
                "attendee": None
            }
        
        # Convert row to model for easier handling
        attendee_model = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
        
        # Check if already checked in (double-check after lock)
        if attendee_model.checked_in:
            import pytz
            ist = pytz.timezone('Asia/Kolkata')
            checkin_time_str = attendee_model.checkin_time.astimezone(ist).strftime('%I:%M %p on %d %b %Y')
            return {
                "success": False,
                "message": f"✅ {attendee_model.name} (Roll: {attendee_model.roll_number}) is already checked in at {checkin_time_str}",
                "attendee": attendee_model
            }
        
        # Check-in with timestamp
        import pytz
        ist = pytz.timezone('Asia/Kolkata')
        current_time = datetime.now(ist)
        
        attendee_model.checked_in = True
        attendee_model.checkin_time = current_time
        attendee_model.checked_by = current_user.id
        
        try:
            db.commit()
            db.refresh(attendee_model)
            
            # Log activity
            log_activity(
                db, current_user.id, "checkin_scan", "attendee", attendee_model.id,
                f"Checked in: {attendee_model.name} ({attendee_model.roll_number}) via QR scan"
            )
            
            # Format success message with person's details
            checkin_time_str = current_time.strftime('%I:%M %p on %d %b %Y')
            success_message = f"✅ Check-in successful!\n\n👤 Name: {attendee_model.name}\n🎓 Roll Number: {attendee_model.roll_number}\n🏫 Branch: {attendee_model.branch}\n📅 Checked in at: {checkin_time_str}"
            
            return {
                "success": True,
                "message": success_message,
                "attendee": attendee_model
            }
            
        except Exception as db_error:
            db.rollback()
            return {
                "success": False,
                "message": f"Database error during check-in: {str(db_error)}",
                "attendee": None
            }
    
    except ValueError as e:
        error_msg = str(e)
        if "expired" in error_msg.lower():
            return {
                "success": False,
                "message": "❌ QR code has expired - Please request a new QR code",
                "attendee": None
            }
        elif "invalid" in error_msg.lower():
            return {
                "success": False,
                "message": "❌ Invalid QR code - Please scan a valid QR code",
                "attendee": None
            }
        else:
            return {
                "success": False,
                "message": f"❌ QR code error: {error_msg}",
                "attendee": None
            }
    except Exception as e:
        # Log unexpected errors
        print(f"❌ Unexpected error in QR scan: {str(e)}")
        return {
            "success": False,
            "message": "❌ An unexpected error occurred. Please try again or contact support.",
            "attendee": None
        }


@app.post("/api/attendees/{attendee_id}/checkin-manual")
async def manual_checkin(
    attendee_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Manual check-in for an attendee with race condition handling
    """
    # Get attendee with row-level lock to prevent race conditions
    from sqlalchemy import text
    attendee_row = db.execute(
        text("SELECT * FROM attendees WHERE id = :attendee_id FOR UPDATE"),
        {"attendee_id": attendee_id}
    ).fetchone()
    
    if not attendee_row:
        raise HTTPException(status_code=404, detail="Attendee not found")
    
    # Get attendee model for easier handling
    attendee = db.query(models.Attendee).filter(models.Attendee.id == attendee_id).first()
    
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == attendee.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Check if already checked in (double-check after lock)
    if attendee.checked_in:
        import pytz
        ist = pytz.timezone('Asia/Kolkata')
        checkin_time_str = attendee.checkin_time.astimezone(ist).strftime('%I:%M %p on %d %b %Y')
        raise HTTPException(
            status_code=400,
            detail=f"✅ {attendee.name} (Roll: {attendee.roll_number}) is already checked in at {checkin_time_str}"
        )
    
    try:
        # Check-in with timestamp
        import pytz
        ist = pytz.timezone('Asia/Kolkata')
        current_time = datetime.now(ist)
        
        attendee.checked_in = True
        attendee.checkin_time = current_time
        attendee.checked_by = current_user.id
        db.commit()
        
        # Log activity
        log_activity(
            db, current_user.id, "checkin_manual", "attendee", attendee.id,
            f"Manually checked in: {attendee.name} ({attendee.roll_number})"
        )
        
        # Format success message with person's details
        checkin_time_str = current_time.strftime('%I:%M %p on %d %b %Y')
        success_message = f"✅ Manual check-in successful!\n\n👤 Name: {attendee.name}\n🎓 Roll Number: {attendee.roll_number}\n🏫 Branch: {attendee.branch}\n📅 Checked in at: {checkin_time_str}"
        
        return {"message": success_message}
        
    except Exception as db_error:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error during check-in: {str(db_error)}")


# Continue to next message for Dashboard and Export endpoints...

# ============= Dashboard with Segregation =============

@app.get("/api/events/{event_id}/dashboard")
async def get_event_dashboard(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get event dashboard with segregated attendee data (Branch -> Year -> Section)
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Get all attendees
    attendees = db.query(models.Attendee).filter(models.Attendee.event_id == event_id).all()
    
    # Calculate overall stats
    total_attendees = len(attendees)
    checked_in = sum(1 for a in attendees if a.checked_in)
    not_checked_in = total_attendees - checked_in
    qr_generated = sum(1 for a in attendees if a.qr_generated)
    qr_pending = total_attendees - qr_generated
    email_sent = sum(1 for a in attendees if a.email_sent)
    email_failed = sum(1 for a in attendees if a.email_error)
    
    stats = {
        "total_attendees": total_attendees,
        "checked_in": checked_in,
        "not_checked_in": not_checked_in,
        "qr_generated": qr_generated,
        "qr_pending": qr_pending,
        "email_sent": email_sent,
        "email_failed": email_failed
    }
    
    # Segregate by Branch -> Year -> Section
    groups = {}
    
    for attendee in attendees:
        branch = attendee.branch
        year = str(attendee.year)
        section = attendee.section
        
        # Initialize branch if not exists
        if branch not in groups:
            groups[branch] = {
                "total": 0,
                "checked_in": 0,
                "years": {}
            }
        
        # Initialize year if not exists
        if year not in groups[branch]["years"]:
            groups[branch]["years"][year] = {
                "total": 0,
                "checked_in": 0,
                "sections": {}
            }
        
        # Initialize section if not exists
        if section not in groups[branch]["years"][year]["sections"]:
            groups[branch]["years"][year]["sections"][section] = {
                "total": 0,
                "checked_in": 0,
                "attendees": []
            }
        
        # Add attendee to section
        attendee_data = {
            "id": attendee.id,
            "name": attendee.name,
            "email": attendee.email,
            "roll_number": attendee.roll_number,
            "phone": attendee.phone,
            "gender": attendee.gender,
            "checked_in": attendee.checked_in,
            "checkin_time": attendee.checkin_time.isoformat() if attendee.checkin_time else None,
            "checked_by": attendee.checked_by,
            "checker_name": attendee.checker.username if attendee.checker else None,
            "qr_generated": attendee.qr_generated,
            "email_sent": attendee.email_sent,
            "email_error": attendee.email_error
        }
        
        groups[branch]["years"][year]["sections"][section]["attendees"].append(attendee_data)
        
        # Update counts
        groups[branch]["total"] += 1
        groups[branch]["years"][year]["total"] += 1
        groups[branch]["years"][year]["sections"][section]["total"] += 1
        
        if attendee.checked_in:
            groups[branch]["checked_in"] += 1
            groups[branch]["years"][year]["checked_in"] += 1
            groups[branch]["years"][year]["sections"][section]["checked_in"] += 1
    
    return {
        "event": {
            "id": event.id,
            "name": event.name,
            "date": event.date.isoformat(),
            "venue": event.venue
        },
        "stats": stats,
        "groups": groups
    }


# ============= Export CSV =============

@app.get("/api/events/{event_id}/export")
async def export_attendees_csv(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Export all attendees as CSV with check-in details
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Get all attendees with checker info
    attendees = db.query(models.Attendee).filter(models.Attendee.event_id == event_id).all()
    
    # Prepare data for CSV
    csv_data = []
    for attendee in attendees:
        csv_data.append({
            'Name': attendee.name,
            'Email': attendee.email,
            'Roll Number': attendee.roll_number,
            'Branch': attendee.branch,
            'Year': attendee.year,
            'Section': attendee.section,
            'Phone': attendee.phone or '',
            'Gender': attendee.gender,
            'Checked In': 'Yes' if attendee.checked_in else 'No',
            'Check-in Time': attendee.checkin_time.strftime('%Y-%m-%d %I:%M %p') if attendee.checkin_time else '',
            'Checked By': attendee.checker.username if attendee.checker else '',
            'QR Generated': 'Yes' if attendee.qr_generated else 'No',
            'Email Sent': 'Yes' if attendee.email_sent else 'No',
            'Email Error': attendee.email_error or ''
        })
    
    # Create DataFrame
    df = pd.DataFrame(csv_data)
    
    # Sort by branch, year, section, name
    df = df.sort_values(['Branch', 'Year', 'Section', 'Name'])
    
    # Convert to CSV
    csv_buffer = io.StringIO()
    df.to_csv(csv_buffer, index=False)
    csv_buffer.seek(0)
    
    # Log activity
    log_activity(
        db, current_user.id, "export_csv", "event", event_id,
        f"Exported attendees for event: {event.name}"
    )
    
    # Return CSV file
    return StreamingResponse(
        io.BytesIO(csv_buffer.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename={event.name.replace(' ', '_')}_attendees.csv"}
    )


# ============= Payment Sync Endpoint =============

@app.post("/api/payments/sync")
async def manual_sync_payments(
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Manual payment sync endpoint - triggers immediate sync from Razorpay
    """
    try:
        print(f"🔄 Manual payment sync triggered by {current_user.username}")
        
        # Run the sync function
        sync_payments_and_create_attendees()
        
        # Log activity
        log_activity(
            db, current_user.id, "manual_sync", "payment", None,
            f"Manual payment sync triggered by {current_user.username}"
        )
        
        import pytz
        ist = pytz.timezone('Asia/Kolkata')
        return {
            "success": True,
            "message": "Payment sync completed successfully",
            "timestamp": datetime.now(ist).isoformat()
        }
        
    except Exception as e:
        print(f"❌ Manual sync error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Manual sync failed: {str(e)}")


@app.post("/api/payments/fix-attendee-details")
async def fix_attendee_details_from_payments(
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Fix attendee year and section details from existing payment form_data using enhanced parsing
    This endpoint updates existing attendees with correct year and section from payment data
    """
    try:
        print(f"🔧 Fixing attendee details from payments triggered by {current_user.username}")
        
        # Get all payments with form_data
        payments = db.query(models.Payment).filter(
            models.Payment.form_data.isnot(None),
            models.Payment.status == "captured"
        ).all()
        
        updated_count = 0
        errors = []
        processed_count = 0
        
        for payment in payments:
            try:
                processed_count += 1
                print(f"📋 Processing payment {processed_count}/{len(payments)} (ID: {payment.id})")
                
                # Parse form_data
                import json
                form_data = json.loads(payment.form_data)
                original_notes = form_data.get("original_notes", {})
                
                if not original_notes:
                    print(f"    ⚠️ No original_notes in payment {payment.id}")
                    continue
                
                # Extract year and section using enhanced parsing
                year_str = original_notes.get("year_of_study", "1")
                section_str = original_notes.get("section", "A")
                
                year = normalize_year(year_str)
                section = normalize_section(section_str)
                
                # Find matching attendee by multiple methods
                attendee = None
                
                # Try by email from original_notes first
                email_from_notes = original_notes.get("email", "")
                if email_from_notes:
                    attendee = db.query(models.Attendee).filter(
                        models.Attendee.event_id == payment.event_id,
                        models.Attendee.email == email_from_notes
                    ).first()
                
                # Try by roll_number from original_notes
                if not attendee:
                    roll_number = original_notes.get("roll_number", "")
                    if roll_number:
                        attendee = db.query(models.Attendee).filter(
                            models.Attendee.event_id == payment.event_id,
                            models.Attendee.roll_number == roll_number
                        ).first()
                
                # Try by customer_email as fallback
                if not attendee and payment.customer_email:
                    attendee = db.query(models.Attendee).filter(
                        models.Attendee.event_id == payment.event_id,
                        models.Attendee.email == payment.customer_email
                    ).first()
                
                if not attendee:
                    print(f"    ⚠️ No attendee found for email: {email_from_notes} or roll: {original_notes.get('roll_number', 'N/A')}")
                    continue
                
                # Check if update is needed
                needs_update = False
                updates = {}
                
                if attendee.year != year:
                    updates['year'] = year
                    needs_update = True
                
                if attendee.section != section:
                    updates['section'] = section
                    needs_update = True
                
                if not needs_update:
                    print(f"    ✅ Attendee {attendee.id} ({attendee.name}) already has correct data")
                    continue
                
                # Show what will be updated
                print(f"    👤 Attendee: {attendee.name} (ID: {attendee.id})")
                print(f"    📧 Email: {attendee.email}")
                print(f"    🎓 Roll: {attendee.roll_number}")
                print(f"    📝 Payment form data: {original_notes}")
                print(f"    📊 Current: Year={attendee.year}, Section={attendee.section}")
                print(f"    🆕 New: {updates}")
                
                # Apply updates
                for field, value in updates.items():
                    setattr(attendee, field, value)
                
                db.commit()
                updated_count += 1
                print(f"    ✅ Updated attendee {attendee.id}: {updates}")
                
            except Exception as e:
                error_msg = f"Error processing payment {payment.id}: {str(e)}"
                errors.append(error_msg)
                print(f"    ❌ {error_msg}")
        
        # Log activity
        log_activity(
            db, current_user.id, "fix_attendee_details", "payment", None,
            f"Fixed attendee details for {updated_count} attendees from payment data"
        )
        
        import pytz
        ist = pytz.timezone('Asia/Kolkata')
        return {
            "success": True,
            "message": f"Fixed attendee details for {updated_count} attendees",
            "processed_payments": processed_count,
            "updated_count": updated_count,
            "errors": errors[:10],  # Return first 10 errors
            "timestamp": datetime.now(ist).isoformat()
        }
        
    except Exception as e:
        print(f"❌ Fix attendee details error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Fix attendee details failed: {str(e)}")


# ============= Payment Management =============

@app.post("/api/payments", response_model=schemas.Payment)
async def create_payment(
    payment: schemas.PaymentCreate,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Create a new payment record
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == payment.event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Check if payment already exists
    existing_payment = db.query(models.Payment).filter(
        models.Payment.razorpay_payment_id == payment.razorpay_payment_id
    ).first()
    
    if existing_payment:
        raise HTTPException(status_code=400, detail="Payment already exists")
    
    # Create payment record
    db_payment = models.Payment(**payment.dict())
    db.add(db_payment)
    db.commit()
    db.refresh(db_payment)
    
    # Log activity
    log_activity(
        db, current_user.id, "create_payment", "payment", db_payment.id,
        f"Created payment: {db_payment.customer_name} ({db_payment.customer_email}) - ₹{db_payment.amount/100}"
    )
    
    return db_payment


@app.get("/api/events/{event_id}/payments", response_model=List[schemas.PaymentWithDetails])
async def get_event_payments(
    event_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get all payments for an event
    """
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == event_id).first()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    payments = db.query(models.Payment).filter(models.Payment.event_id == event_id).all()
    return payments


@app.get("/api/payments/{payment_id}", response_model=schemas.PaymentWithDetails)
async def get_payment(
    payment_id: int,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Get payment details
    """
    payment = db.query(models.Payment).filter(models.Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == payment.event_id).first()
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    return payment


@app.put("/api/payments/{payment_id}", response_model=schemas.Payment)
async def update_payment(
    payment_id: int,
    payment_update: schemas.PaymentUpdate,
    current_user: models.User = Depends(require_organizer),
    db: Session = Depends(get_db)
):
    """
    Update payment status
    """
    payment = db.query(models.Payment).filter(models.Payment.id == payment_id).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    
    # Check event access
    event = db.query(models.Event).filter(models.Event.id == payment.event_id).first()
    if current_user.role != "admin" and event.club_id != current_user.club_id:
        raise HTTPException(status_code=403, detail="Access denied")
    
    # Update payment
    update_data = payment_update.dict(exclude_unset=True)
    for key, value in update_data.items():
        setattr(payment, key, value)
    
    db.commit()
    db.refresh(payment)
    
    # Log activity
    log_activity(
        db, current_user.id, "update_payment", "payment", payment.id,
        f"Updated payment: {payment.customer_name} - Status: {payment.status}"
    )
    
    return payment


# ============= Razorpay Status Check =============

@app.get("/api/payments/razorpay-status")
async def get_razorpay_payment_status(
    payment_id: str,
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    Get payment status from Razorpay API for a specific payment
    """
    try:
        # Get Razorpay client
        razorpay_client = get_razorpay_client()
        
        # Fetch payment details from Razorpay
        payment = razorpay_client.payment.fetch(payment_id)
        
        return {
            "success": True,
            "payment": {
                "id": payment.get("id"),
                "amount": payment.get("amount"),
                "currency": payment.get("currency"),
                "status": payment.get("status"),
                "method": payment.get("method"),
                "description": payment.get("description"),
                "email": payment.get("email"),
                "contact": payment.get("contact"),
                "notes": payment.get("notes"),
                "created_at": payment.get("created_at"),
                "captured": payment.get("captured")
            }
        }
        
    except Exception as e:
        print(f"❌ Razorpay payment fetch error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch payment: {str(e)}")


# ============= Health Check =============

@app.get("/")
async def root():
    """
    Health check endpoint
    """
    return {
        "message": "Event Management System API",
        "status": "running",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    """
    Health check with database connection test
    """
    try:
        # Test database connection using SQLAlchemy 2.0 syntax
        from sqlalchemy import text
        db.execute(text("SELECT 1"))
        return {
            "status": "healthy",
            "database": "connected"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "database": "disconnected",
            "error": str(e)
        }


@app.get("/api/system/status")
async def system_status(
    current_user: models.User = Depends(require_admin),
    db: Session = Depends(get_db)
):
    """
    System status check - identifies potential issues and edge cases
    """
    try:
        issues = []
        warnings = []
        
        # Check for attendees without QR codes
        attendees_without_qr = db.query(models.Attendee).filter(
            models.Attendee.qr_token.is_(None)
        ).count()
        
        if attendees_without_qr > 0:
            warnings.append(f"{attendees_without_qr} attendees without QR codes")
        
        # Check for attendees with QR but no email sent
        attendees_without_email = db.query(models.Attendee).filter(
            models.Attendee.qr_generated == True,
            models.Attendee.email_sent == False
        ).count()
        
        if attendees_without_email > 0:
            warnings.append(f"{attendees_without_email} attendees with QR codes but emails not sent")
        
        # Check for duplicate attendees (same email or roll number in same event)
        from sqlalchemy import func
        duplicate_emails = db.query(
            models.Attendee.event_id,
            models.Attendee.email,
            func.count(models.Attendee.id).label('count')
        ).group_by(
            models.Attendee.event_id,
            models.Attendee.email
        ).having(func.count(models.Attendee.id) > 1).all()
        
        if duplicate_emails:
            issues.append(f"{len(duplicate_emails)} events have duplicate attendees by email")
        
        duplicate_rolls = db.query(
            models.Attendee.event_id,
            models.Attendee.roll_number,
            func.count(models.Attendee.id).label('count')
        ).group_by(
            models.Attendee.event_id,
            models.Attendee.roll_number
        ).having(func.count(models.Attendee.id) > 1).all()
        
        if duplicate_rolls:
            issues.append(f"{len(duplicate_rolls)} events have duplicate attendees by roll number")
        
        # Check for payments without corresponding attendees
        payments_without_attendees = db.query(models.Payment).filter(
            models.Payment.status == "captured",
            models.Payment.attendee_id.is_(None)
        ).count()
        
        if payments_without_attendees > 0:
            warnings.append(f"{payments_without_attendees} captured payments without corresponding attendees")
        
        # Check for email failures
        email_failures = db.query(models.Attendee).filter(
            models.Attendee.email_error.isnot(None)
        ).count()
        
        if email_failures > 0:
            warnings.append(f"{email_failures} attendees with email sending errors")
        
        # Check for attendees with invalid year/section
        invalid_years = db.query(models.Attendee).filter(
            (models.Attendee.year < 1) | (models.Attendee.year > 4)
        ).count()
        
        if invalid_years > 0:
            issues.append(f"{invalid_years} attendees with invalid year values")
        
        invalid_sections = db.query(models.Attendee).filter(
            ~models.Attendee.section.in_(['A', 'B', 'C', 'D'])
        ).count()
        
        if invalid_sections > 0:
            issues.append(f"{invalid_sections} attendees with invalid section values")
        
        # Overall status
        status = "healthy"
        if issues:
            status = "issues_found"
        elif warnings:
            status = "warnings_found"
        
        return {
            "status": status,
            "issues": issues,
            "warnings": warnings,
            "summary": {
                "attendees_without_qr": attendees_without_qr,
                "attendees_without_email": attendees_without_email,
                "duplicate_emails": len(duplicate_emails),
                "duplicate_rolls": len(duplicate_rolls),
                "payments_without_attendees": payments_without_attendees,
                "email_failures": email_failures,
                "invalid_years": invalid_years,
                "invalid_sections": invalid_sections
            }
        }
        
    except Exception as e:
        return {
            "status": "error",
            "error": str(e)
        }
