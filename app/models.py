"""
Database Models - SQLAlchemy ORM models for all tables
"""
from sqlalchemy import Boolean, Column, Integer, String, ForeignKey, DateTime, Text, func
from sqlalchemy.orm import relationship
from .database import Base

class Club(Base):
    """
    Clubs table - Organizations that manage events
    """
    __tablename__ = "clubs"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, index=True, nullable=False)
    description = Column(Text, nullable=True)
    email = Column(String(255), nullable=True)
    phone = Column(String(20), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    active = Column(Boolean, default=True)

    # Relationships
    users = relationship("User", back_populates="club")
    events = relationship("Event", back_populates="club")
    activity_logs = relationship("ActivityLog", back_populates="club")


class User(Base):
    """
    Users table - Admin and Club members (organizers)
    """
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(100), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=True)
    club_id = Column(Integer, ForeignKey("clubs.id"), nullable=True)  # NULL for admin
    role = Column(String(50), default="organizer")  # 'admin' or 'organizer'
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)
    disabled = Column(Boolean, default=False)

    # Relationships
    club = relationship("Club", back_populates="users")
    events_created = relationship("Event", back_populates="creator")
    attendees_checked = relationship("Attendee", back_populates="checker")
    activity_logs = relationship("ActivityLog", back_populates="user")


class Event(Base):
    """
    Events table - Events created by clubs
    """
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    club_id = Column(Integer, ForeignKey("clubs.id"), nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String(255), nullable=False, index=True)
    description = Column(Text, nullable=True)
    date = Column(DateTime(timezone=True), nullable=False)
    venue = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    club = relationship("Club", back_populates="events")
    creator = relationship("User", back_populates="events_created")
    attendees = relationship("Attendee", back_populates="event", cascade="all, delete-orphan")
    payments = relationship("Payment", back_populates="event", cascade="all, delete-orphan")


class Attendee(Base):
    """
    Attendees table - People registered for events
    """
    __tablename__ = "attendees"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False)
    
    # Personal details
    name = Column(String(255), nullable=False, index=True)
    email = Column(String(255), nullable=False, index=True)
    roll_number = Column(String(100), nullable=False, index=True)
    branch = Column(String(100), nullable=False, index=True)
    year = Column(Integer, nullable=False, index=True)
    section = Column(String(10), nullable=False, index=True)
    phone = Column(String(20), nullable=True)
    gender = Column(String(20), default="Not Specified")
    
    # QR Code details
    qr_token = Column(String(500), unique=True, index=True, nullable=True)
    qr_generated = Column(Boolean, default=False)
    qr_generated_at = Column(DateTime(timezone=True), nullable=True)
    
    # Email status
    email_sent = Column(Boolean, default=False)
    email_sent_at = Column(DateTime(timezone=True), nullable=True)
    email_error = Column(Text, nullable=True)
    
    # Check-in details
    checked_in = Column(Boolean, default=False)
    checkin_time = Column(DateTime(timezone=True), nullable=True)
    checked_by = Column(Integer, ForeignKey("users.id"), nullable=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    # Relationships
    event = relationship("Event", back_populates="attendees")
    checker = relationship("User", back_populates="attendees_checked")
    payments = relationship("Payment", back_populates="attendee", cascade="all, delete-orphan")


class Payment(Base):
    """
    Payments table - Track Razorpay payment transactions
    """
    __tablename__ = "payments"

    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("events.id"), nullable=False)
    attendee_id = Column(Integer, ForeignKey("attendees.id"), nullable=True)  # Can be null for bulk payments
    
    # Razorpay details
    razorpay_payment_id = Column(String(255), unique=True, index=True, nullable=False)
    razorpay_order_id = Column(String(255), nullable=True)
    razorpay_signature = Column(String(500), nullable=True)
    
    # Payment details
    amount = Column(Integer, nullable=False)  # Amount in paise
    currency = Column(String(10), default="INR")
    status = Column(String(50), nullable=False, index=True)  # 'pending', 'captured', 'failed', 'refunded'
    
    # Customer details (from Razorpay Pages form)
    customer_name = Column(String(255), nullable=False)
    customer_email = Column(String(255), nullable=False, index=True)
    customer_phone = Column(String(20), nullable=True)
    
    # Additional form data from Razorpay Pages
    form_data = Column(Text, nullable=True)  # JSON string of additional form fields
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    payment_captured_at = Column(DateTime(timezone=True), nullable=True)
    
    # Relationships
    event = relationship("Event", back_populates="payments")
    attendee = relationship("Attendee", back_populates="payments")


class ActivityLog(Base):
    """
    Activity Logs table - Track all user actions
    """
    __tablename__ = "activity_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    club_id = Column(Integer, ForeignKey("clubs.id"), nullable=True)
    
    # Action details
    action_type = Column(String(100), nullable=False, index=True)  # e.g., 'create_event', 'edit_attendee'
    entity_type = Column(String(100), nullable=False)  # e.g., 'event', 'attendee'
    entity_id = Column(Integer, nullable=True)  # ID of the affected entity
    description = Column(Text, nullable=False)  # Human-readable description
    changes_json = Column(Text, nullable=True)  # JSON string of before/after changes
    
    # Metadata
    ip_address = Column(String(50), nullable=True)
    timestamp = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    # Relationships
    user = relationship("User", back_populates="activity_logs")
    club = relationship("Club", back_populates="activity_logs")
