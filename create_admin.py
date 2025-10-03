"""
Create initial admin user
"""
from app.database import SessionLocal
from app import models
from app.security import get_password_hash

db = SessionLocal()

# Check if admin already exists
existing_admin = db.query(models.User).filter(models.User.username == "admin").first()

if existing_admin:
    print("❌ Admin user already exists!")
else:
    # Create admin user
    admin = models.User(
        username="admin",
        email="indrakshith.reddy@gmail.com",
        password_hash=get_password_hash("admin123"),  # Change this password!
        full_name="System Administrator",
        role="admin",
        club_id=None
    )
    
    db.add(admin)
    db.commit()
    
    print("✅ Admin user created successfully!")
    print("Username: admin")
    print("Password: admin123")
    print("⚠️  IMPORTANT: Change this password after first login!")

db.close()
