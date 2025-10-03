from sqlalchemy import create_engine
from dotenv import load_dotenv
import os

load_dotenv()

# Test database connection
db_url = os.getenv("DATABASE_URL")
print(f"Testing connection to: {db_url}")

try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        print("✅ Database connection successful!")
except Exception as e:
    print(f"❌ Database connection failed: {e}")
