"""
Utility functions - QR code generation and email sending
"""
import qrcode
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from datetime import datetime, timedelta, timezone
from jose import jwt
from .config import settings
from typing import Optional
import io


def generate_qr_token(event_id: int, attendee_id: int, email: str, roll_number: str, event_date: datetime) -> str:
    """
    Generate a secure JWT token for QR code
    """
    # Token expires 1 day after event
    expire = event_date + timedelta(days=1)
    
    payload = {
        "event_id": event_id,
        "attendee_id": attendee_id,
        "email": email,
        "roll_number": roll_number,
        "issued_at": datetime.now(timezone.utc).isoformat(),
        "exp": expire
    }
    
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return token


def verify_qr_token(token: str) -> dict:
    """
    Verify and decode QR token
    Returns payload if valid, raises exception if invalid
    """
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        return payload
    except Exception as e:
        raise ValueError(f"Invalid QR token: {str(e)}")


def generate_qr_code(token: str, attendee_name: str, event_name: str) -> bytes:
    """
    Generate QR code image from token
    Returns QR code image as bytes
    """
    # Create QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_H,
        box_size=10,
        border=4,
    )
    
    qr.add_data(token)
    qr.make(fit=True)
    
    # Create image
    img = qr.make_image(fill_color="black", back_color="white")
    
    # Convert to bytes
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='PNG')
    img_bytes.seek(0)
    
    return img_bytes.getvalue()


def send_qr_email(
    to_email: str,
    attendee_name: str,
    event_name: str,
    event_date: datetime,
    event_venue: str,
    qr_code_bytes: bytes
) -> tuple[bool, Optional[str]]:
    """
    Send QR code via email
    Returns (success: bool, error_message: Optional[str])
    """
    try:
        # Create message
        msg = MIMEMultipart('related')
        msg['Subject'] = f"Event Registration: {event_name}"
        msg['From'] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL}>"
        msg['To'] = to_email
        
        # Email body
        html_body = f"""
        <html>
            <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                <div style="max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
                    <h2 style="color: #2c3e50;">Event Registration Confirmed!</h2>
                    
                    <p>Dear <strong>{attendee_name}</strong>,</p>
                    
                    <p>Your registration for the following event has been confirmed:</p>
                    
                    <div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px; margin: 20px 0;">
                        <h3 style="margin-top: 0; color: #2c3e50;">{event_name}</h3>
                        <p style="margin: 5px 0;"><strong>Date:</strong> {event_date.strftime('%B %d, %Y at %I:%M %p')}</p>
                        <p style="margin: 5px 0;"><strong>Venue:</strong> {event_venue}</p>
                    </div>
                    
                    <h3 style="color: #2c3e50;">Your Entry QR Code</h3>
                    <p>Please present this QR code at the event entrance for check-in:</p>
                    
                    <div style="text-align: center; margin: 20px 0;">
                        <img src="cid:qrcode" alt="QR Code" style="max-width: 300px; border: 2px solid #2c3e50; padding: 10px;">
                    </div>
                    
                    <div style="background-color: #fff3cd; padding: 15px; border-radius: 5px; margin: 20px 0;">
                        <p style="margin: 0;"><strong>Important:</strong></p>
                        <ul style="margin: 10px 0;">
                            <li>Save this QR code on your phone or print it</li>
                            <li>Arrive 15 minutes early for check-in</li>
                            <li>This QR code is unique to you - do not share</li>
                        </ul>
                    </div>
                    
                    <p>We look forward to seeing you at the event!</p>
                    
                    <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                    
                    <p style="font-size: 12px; color: #888;">
                        This is an automated email. Please do not reply.<br>
                        {settings.APP_NAME}
                    </p>
                </div>
            </body>
        </html>
        """
        
        # Attach HTML body
        msg_alternative = MIMEMultipart('alternative')
        msg.attach(msg_alternative)
        msg_alternative.attach(MIMEText(html_body, 'html'))
        
        # Attach QR code image
        qr_image = MIMEImage(qr_code_bytes)
        qr_image.add_header('Content-ID', '<qrcode>')
        msg.attach(qr_image)
        
        # Send email
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.starttls()
            server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            server.send_message(msg)
        
        return True, None
    
    except Exception as e:
        error_message = f"Failed to send email: {str(e)}"
        print(f"Email error for {to_email}: {error_message}")
        return False, error_message


def save_qr_code(qr_code_bytes: bytes, filename: str) -> str:
    """
    Save QR code to static folder (optional - for debugging)
    Returns file path
    """
    static_dir = "app/static/qr_codes"
    os.makedirs(static_dir, exist_ok=True)
    
    filepath = os.path.join(static_dir, filename)
    
    with open(filepath, 'wb') as f:
        f.write(qr_code_bytes)
    
    return filepath
