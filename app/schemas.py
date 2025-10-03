"""
Pydantic Schemas - API request/response models
"""
from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List, Dict, Any
from datetime import datetime


# ============= Club Schemas =============
class ClubBase(BaseModel):
    name: str
    description: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None

class ClubCreate(ClubBase):
    pass

class ClubUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    active: Optional[bool] = None

class Club(ClubBase):
    id: int
    created_at: datetime
    active: bool

    class Config:
        from_attributes = True


# ============= User Schemas =============
class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str
    club_id: Optional[int] = None
    role: str = "organizer"  # 'admin' or 'organizer'

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    club_id: Optional[int] = None
    password: Optional[str] = None
    disabled: Optional[bool] = None

class User(UserBase):
    id: int
    club_id: Optional[int] = None
    role: str
    created_at: datetime
    last_login: Optional[datetime] = None
    disabled: bool

    class Config:
        from_attributes = True

class UserWithClub(User):
    club: Optional[Club] = None


# ============= Authentication Schemas =============
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None


# ============= Event Schemas =============
class EventBase(BaseModel):
    name: str
    description: Optional[str] = None
    date: datetime
    venue: Optional[str] = None

class EventCreate(EventBase):
    pass

class EventUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    date: Optional[datetime] = None
    venue: Optional[str] = None

class Event(EventBase):
    id: int
    club_id: int
    created_by: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class EventWithDetails(Event):
    club: Club
    creator: User
    total_attendees: Optional[int] = 0
    checked_in_count: Optional[int] = 0


# ============= Attendee Schemas =============
class AttendeeBase(BaseModel):
    name: str
    email: EmailStr
    roll_number: str
    branch: str
    year: int
    section: str
    phone: Optional[str] = None
    gender: Optional[str] = "Not Specified"

    @validator('year')
    def validate_year(cls, v):
        if v < 1 or v > 5:
            raise ValueError('Year must be between 1 and 5')
        return v

class AttendeeCreate(AttendeeBase):
    event_id: int

class AttendeeUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[EmailStr] = None
    roll_number: Optional[str] = None
    branch: Optional[str] = None
    year: Optional[int] = None
    section: Optional[str] = None
    phone: Optional[str] = None
    gender: Optional[str] = None

class Attendee(AttendeeBase):
    id: int
    event_id: int
    qr_generated: bool
    qr_generated_at: Optional[datetime] = None
    email_sent: bool
    email_sent_at: Optional[datetime] = None
    email_error: Optional[str] = None
    checked_in: bool
    checkin_time: Optional[datetime] = None
    checked_by: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class AttendeeWithChecker(Attendee):
    checker: Optional[User] = None


# ============= Dashboard Schemas =============
class EventStats(BaseModel):
    total_attendees: int
    checked_in: int
    not_checked_in: int
    qr_generated: int
    qr_pending: int
    email_sent: int
    email_failed: int

class AttendeeGroup(BaseModel):
    total: int
    checked_in: int
    attendees: List[AttendeeWithChecker]

class DashboardResponse(BaseModel):
    event: Event
    stats: EventStats
    groups: Dict[str, Any]  # Hierarchical structure: Branch -> Year -> Section


# ============= Activity Log Schemas =============
class ActivityLogBase(BaseModel):
    action_type: str
    entity_type: str
    entity_id: Optional[int] = None
    description: str
    changes_json: Optional[str] = None
    ip_address: Optional[str] = None

class ActivityLog(ActivityLogBase):
    id: int
    user_id: int
    club_id: Optional[int] = None
    timestamp: datetime

    class Config:
        from_attributes = True

class ActivityLogWithDetails(ActivityLog):
    user: User
    club: Optional[Club] = None


# ============= Bulk Operations Schemas =============
class BulkQRGenerateResponse(BaseModel):
    total: int
    success: int
    failed: int
    errors: List[Dict[str, Any]]

class CheckInRequest(BaseModel):
    qr_token: str

class CheckInResponse(BaseModel):
    success: bool
    message: str
    attendee: Optional[AttendeeWithChecker] = None
