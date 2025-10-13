# AWS EC2 Deployment Guide - Payment Sync Fixes

## 🚀 Quick Deployment Steps

### Step 1: Connect to your AWS EC2 Instance
```bash
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### Step 2: Navigate to your project directory
```bash
cd /path/to/your/qrflow-backend
# or wherever your project is located
```

### Step 3: Pull the latest changes from GitHub
```bash
git pull origin main
```

### Step 4: Rebuild and restart the backend container
```bash
# If using Docker Compose (recommended)
docker-compose down
docker-compose build backend
docker-compose up -d

# Alternative: If using separate Docker commands
docker stop qrflow-backend
docker rm qrflow-backend
docker build -t qrflow-backend .
docker run -d --name qrflow-backend -p 8000:8000 qrflow-backend
```

### Step 5: Verify deployment
```bash
# Check if container is running
docker ps

# Check logs
docker-compose logs -f backend

# Test health endpoint
curl http://localhost:8000/health
```

### Step 6: Fix existing attendee data (Important!)
After deployment, run the fix endpoint to update existing attendees:

```bash
# Get admin token first (replace with your admin credentials)
ADMIN_TOKEN=$(curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123" | jq -r '.access_token')

# Run the fix endpoint
curl -X POST "http://localhost:8000/api/payments/fix-attendee-details" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json"

# Expected response:
# {
#   "success": true,
#   "message": "Fixed attendee details for X attendees",
#   "updated_count": X,
#   "errors": [],
#   "timestamp": "2025-01-XX..."
# }
```

## 🔍 Verification Steps

### 1. Test New Payment Sync
- Make a test payment with Roman numerals or text in year field
- Verify the attendee is created with correct year/section

### 2. Test Get Attendees Endpoint
```bash
# Test the enhanced endpoint
curl -X GET "http://localhost:8000/api/events/1/attendees" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

### 3. Check Application Logs
```bash
# Monitor logs for any errors
docker-compose logs -f backend | grep -E "(ERROR|WARN|✅|❌)"
```

## 📊 What's Fixed

### Before:
- All attendees had `year=1` and `section="A"`
- Get attendees didn't show payment details
- Roman numerals like "II", "III" were ignored

### After:
- Correct year extraction: "II" → 2, "III" → 3, "IV" → 4
- Text formats: "second" → 2, "third" → 3
- Mixed formats: "II semester" → 2, "3rd year" → 3
- Complete payment details in get attendees response
- Existing data can be fixed without loss

## 🛡️ Safety Features

- **No database migration required**
- **No data loss risk**
- **Backward compatible**
- **Easy rollback** (just restore previous container)
- **Safe to run fix endpoint multiple times**

## 🚨 Troubleshooting

### If deployment fails:
```bash
# Check container logs
docker-compose logs backend

# Check if port is available
sudo netstat -tlnp | grep :8000

# Restart with fresh build
docker-compose down
docker-compose build --no-cache backend
docker-compose up -d
```

### If fix endpoint fails:
```bash
# Check database connection
docker-compose exec backend python -c "from app.database import engine; print('DB OK')"

# Check payment data format
docker-compose exec backend python -c "
from app.database import SessionLocal
from app.models import Payment
db = SessionLocal()
payments = db.query(Payment).limit(1).all()
print(payments[0].form_data if payments else 'No payments')
"
```

## 📈 Expected Results

After successful deployment:
- ✅ New payments create attendees with correct year/section
- ✅ Roman numerals (II, III, IV) are properly parsed
- ✅ Text formats (second, third) are converted to numbers
- ✅ Get attendees shows complete payment information
- ✅ Existing attendees updated with correct data
- ✅ No data loss or corruption

## 🎯 Success Confirmation

You'll know the deployment is successful when:
1. Container starts without errors
2. Health endpoint returns "healthy"
3. Fix endpoint reports updated attendees
4. New test payments create correct year/section
5. Get attendees endpoint shows payment details

---

**Deployment Date**: $(date)
**Version**: Payment Sync Fixes v1.0 with Roman Numerals Support
**Status**: Ready for AWS EC2 Deployment
