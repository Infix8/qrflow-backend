# 🚀 QRFlow Backend - Quick Start Guide

## ✅ Current Status

Your QRFlow backend application is **successfully running**! Here's what's been set up:

### 🟢 What's Working
- ✅ **FastAPI application running on `http://localhost:8000`**
- ✅ **SQLite database initialized**
- ✅ **Admin user created**: `admin` / `admin123`
- ✅ **All dependencies installed**
- ✅ **API endpoints tested and working**
- ✅ **Automated payment sync system** (every 30 minutes)
- ✅ **Automatic attendee QR code generation**

### 🟡 What Needs Setup
- ⚠️ **Razorpay credentials** (for payment processing)

## 🚀 Quick Commands

### Start the Application
```bash
cd /home/infix/qrflow-backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Test the API
```bash
python3 test_api.py
```

### Test Payment Sync
```bash
# Manual payment sync (Admin only)
curl -X POST "http://localhost:8000/api/payments/sync" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 📊 API Endpoints

### Authentication
- `POST /api/auth/login` - Login with username/password
- `GET /api/auth/me` - Get current user info
- `POST /api/auth/logout` - Logout

### Admin Functions
- `GET /api/admin/clubs` - List all clubs
- `POST /api/admin/clubs` - Create new club
- `GET /api/admin/users` - List all users
- `POST /api/admin/users` - Create new user

### Event Management
- `GET /api/events` - List events
- `POST /api/events` - Create event
- `GET /api/events/{id}` - Get event details
- `PUT /api/events/{id}` - Update event
- `DELETE /api/events/{id}` - Delete event

### Attendee Management
- `GET /api/events/{id}/attendees` - List attendees
- `POST /api/events/{id}/attendees/upload` - Upload CSV
- `GET /api/events/{id}/attendees/template` - Download template

### QR Code & Check-in
- `POST /api/events/{id}/generate-qr` - Generate QR codes
- `POST /api/checkin/scan` - Scan QR for check-in
- `POST /api/attendees/{id}/checkin-manual` - Manual check-in

### Payment Sync
- `POST /api/payments/sync` - Manual payment sync (Admin only)
- `GET /api/events/{id}/payments` - Get event payments
- `GET /api/payments/razorpay-status` - Check Razorpay payment status

## 🔧 Environment Configuration

Your `.env` file is configured with:
```env
DATABASE_URL=sqlite:///./qrflow.db
SECRET_KEY=your_super_secret_key_change_this_in_production
# ... other settings
```

## 🧪 Testing Examples

### 1. Login and Get Token
```bash
curl -X POST "http://localhost:8000/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin&password=admin123"
```

### 2. Create a Club
```bash
curl -X POST "http://localhost:8000/api/admin/clubs" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "My Club", "description": "Test club"}'
```

### 3. Create an Event
```bash
curl -X POST "http://localhost:8000/api/events" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Event",
    "description": "Test event",
    "date": "2024-12-31T10:00:00",
    "venue": "Test Venue"
  }'
```

## 🔄 Payment Sync System

### How It Works
The system automatically syncs payments every 30 minutes:
1. **Fetches payments** from Razorpay API (last 24 hours)
2. **Filters QR flow payments** with student details
3. **Creates payment records** in database
4. **Creates attendee records** for captured payments
5. **Generates QR codes** and sends via email

### Manual Sync
```bash
# Trigger immediate sync (Admin only)
curl -X POST "http://localhost:8000/api/payments/sync" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Environment Setup
```bash
# Edit .env file
nano .env
```

Add your Razorpay credentials:
```env
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_razorpay_secret
```

## 📖 Documentation

- **API Docs**: `http://localhost:8000/docs` (Interactive Swagger UI)
- **Health Check**: `http://localhost:8000/health`
- **Payment Sync Guide**: See `PAYMENT_SYNC_GUIDE.md`
- **Razorpay Integration**: See `RAZORPAY_INTEGRATION.md`

## 🚨 Troubleshooting

### Application Not Starting
```bash
# Check if port 8000 is free
lsof -i :8000

# Kill existing processes
pkill -f uvicorn

# Start fresh
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Database Issues
```bash
# Recreate database
rm qrflow.db
python3 init_db.py
python3 create_admin.py
```

### Payment Sync Issues
```bash
# Check payment sync logs
tail -f app.log

# Test manual sync
curl -X POST "http://localhost:8000/api/payments/sync" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🎯 Next Steps

1. **Configure Razorpay credentials** in `.env` file
2. **Test payment sync** with manual trigger
3. **Test the complete flow** with real payments
4. **Deploy to production** when ready

## 📞 Support

- Check `PAYMENT_SYNC_GUIDE.md` for detailed payment sync setup
- Run `python3 test_api.py` to test all endpoints
- Check application logs for any errors
- Verify all environment variables are set correctly

---

**🎉 Your QRFlow backend is ready to use!**

**Current Status**: Application running on `http://localhost:8000`  
**Admin Login**: `admin` / `admin123`  
**Payment Sync**: Automatic every 30 minutes  
**Next Action**: Configure Razorpay credentials for payment processing
