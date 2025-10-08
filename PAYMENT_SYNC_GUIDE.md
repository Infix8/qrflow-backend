# 🔄 Payment Sync System

## Overview

The QRFlow backend now uses an automated payment sync system that runs every 30 minutes to fetch payment data from Razorpay and automatically create attendee QR codes.

## How It Works

### 1. Automatic Background Sync
- **Frequency**: Every 30 minutes
- **Process**: 
  1. Fetches recent payments from Razorpay API (last 24 hours)
  2. Filters for QR flow payments (payments with student details)
  3. Creates/updates payment records in database
  4. For captured payments with student details:
     - Creates attendee records
     - Generates QR tokens
     - Sends QR codes via email

### 2. Manual Sync Endpoint
- **Endpoint**: `POST /api/payments/sync`
- **Access**: Admin only
- **Purpose**: Trigger immediate sync without waiting for scheduled run

## API Endpoints

### Payment Sync
```bash
# Manual sync (Admin only)
POST /api/payments/sync
Authorization: Bearer <admin_jwt_token>
```

### Payment Management
```bash
# Get all payments for an event
GET /api/events/{event_id}/payments

# Get specific payment
GET /api/payments/{payment_id}

# Check Razorpay payment status
GET /api/payments/razorpay-status?payment_id=<razorpay_payment_id>
```

## Payment Data Flow

1. **Student makes payment** via Razorpay QR flow
2. **Payment includes student details** in notes:
   - `name`: Student name
   - `roll_number`: Student roll number
   - `college_name`: College name
   - `department`: Department/Branch
   - `phone`: Contact number
   - `emergency_contact_number`: Emergency contact

3. **Background sync** (every 30 minutes):
   - Fetches payment from Razorpay
   - Creates payment record in database
   - If payment is captured and has student details:
     - Creates attendee record
     - Generates QR token
     - Sends QR code via email

4. **Attendee receives**:
   - QR code image via email
   - Event details
   - Check-in instructions

## Configuration

### Environment Variables
```env
# Razorpay API credentials
RAZORPAY_KEY_ID=your_key_id
RAZORPAY_KEY_SECRET=your_key_secret

# Email configuration (for QR code emails)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password
```

### Database Tables
- **payments**: Stores payment information from Razorpay
- **attendees**: Stores attendee information and QR tokens
- **events**: Event details
- **activity_logs**: Audit trail of all operations

## Monitoring

### Check Sync Status
```bash
# View recent activity logs
GET /api/admin/logs

# Check payment records
GET /api/events/{event_id}/payments
```

### Logs
The system logs all sync activities:
- Payment fetch attempts
- Payment creation/updates
- Attendee creation
- QR code generation
- Email sending results

## Troubleshooting

### Common Issues

1. **No payments synced**
   - Check Razorpay API credentials
   - Verify payments exist in Razorpay dashboard
   - Check if payments have correct student details in notes

2. **QR codes not generated**
   - Verify payment status is "captured"
   - Check if student details are present in payment notes
   - Verify email configuration

3. **Emails not sent**
   - Check SMTP configuration
   - Verify email addresses are valid
   - Check email error logs in database

### Manual Testing
```bash
# Test manual sync
curl -X POST "http://localhost:8000/api/payments/sync" \
  -H "Authorization: Bearer <admin_token>"

# Check sync results
curl -X GET "http://localhost:8000/api/events/1/payments" \
  -H "Authorization: Bearer <admin_token>"
```

## Benefits

1. **Automated**: No manual intervention required
2. **Real-time**: Syncs every 30 minutes
3. **Reliable**: Handles errors gracefully
4. **Auditable**: All operations are logged
5. **Scalable**: Can handle large volumes of payments

## Security

- All API endpoints require authentication
- Admin-only access for manual sync
- Secure Razorpay API integration
- Encrypted email delivery
- Audit trail for all operations
