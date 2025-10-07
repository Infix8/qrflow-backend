# Razorpay Integration Guide

This guide explains how to integrate Razorpay Pages with your QRFlow backend system to automatically capture payment details when users complete payments.

## 🚀 Overview

The integration allows you to:
- Receive payment notifications from Razorpay Pages via webhooks
- Automatically store payment details in your database
- Track payment status (pending, captured, failed, refunded)
- Link payments to specific events and attendees
- View payment history and analytics

## 📋 Prerequisites

1. **Razorpay Account**: Sign up at [razorpay.com](https://razorpay.com)
2. **Razorpay Pages**: Create payment pages in your Razorpay dashboard
3. **Webhook URL**: Your backend URL + `/api/webhooks/razorpay`

## 🔧 Setup Instructions

### 1. Environment Variables

Add these variables to your `.env` file:

```env
# Razorpay Configuration
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret_here
RAZORPAY_WEBHOOK_URL=https://yourdomain.com/api/webhooks/razorpay
```

### 2. Razorpay Dashboard Setup

1. **Get API Keys**:
   - Go to Razorpay Dashboard → Settings → API Keys
   - Copy your Key ID and Key Secret

2. **Create Webhook**:
   - Go to Settings → Webhooks
   - Add webhook URL: `https://yourdomain.com/api/webhooks/razorpay`
   - Select events: `payment.captured`, `payment.failed`
   - Copy the webhook secret

3. **Create Razorpay Pages**:
   - Go to Razorpay Pages → Create New Page
   - Configure your payment form
   - Add custom fields for event_id, attendee_id, etc.

### 3. Database Migration

The Payment model has been added. Run database migration:

```bash
# If using Alembic
alembic revision --autogenerate -m "Add Payment model"
alembic upgrade head

# Or recreate tables (development only)
python init_db.py
```

## 🔄 How It Works

### 1. Payment Flow

```
User fills Razorpay Pages form
         ↓
Razorpay processes payment
         ↓
Razorpay sends webhook to your backend
         ↓
Backend verifies webhook signature
         ↓
Backend stores/updates payment details
         ↓
Payment status updated in database
```

### 2. Webhook Processing

The webhook endpoint (`/api/webhooks/razorpay`) automatically:

- **Verifies webhook signature** for security
- **Handles payment.captured** events
- **Handles payment.failed** events
- **Creates/updates payment records**
- **Logs all payment activities**

### 3. Data Storage

Each payment record includes:
- Razorpay payment ID
- Customer details (name, email, phone)
- Payment amount and currency
- Payment status
- Event and attendee associations
- Timestamps and signatures

## 📊 API Endpoints

### Payment Management

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/payments` | POST | Create payment record |
| `/api/payments/{id}` | GET | Get payment details |
| `/api/payments/{id}` | PUT | Update payment status |
| `/api/events/{id}/payments` | GET | Get all payments for event |

### Webhook

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/webhooks/razorpay` | POST | Razorpay webhook receiver |

## 🔐 Security Features

1. **Webhook Signature Verification**: All webhooks are verified using HMAC-SHA256
2. **Access Control**: Payment endpoints require authentication
3. **Event-based Access**: Users can only access payments for their events
4. **Activity Logging**: All payment activities are logged for audit

## 📝 Usage Examples

### 1. Create Payment Record

```bash
curl -X POST "https://yourdomain.com/api/payments" \
  -H "Authorization: Bearer your_jwt_token" \
  -H "Content-Type: application/json" \
  -d '{
    "event_id": 1,
    "attendee_id": 123,
    "razorpay_payment_id": "pay_1234567890",
    "amount": 50000,
    "currency": "INR",
    "customer_name": "John Doe",
    "customer_email": "john@example.com",
    "customer_phone": "9876543210"
  }'
```

### 2. Get Event Payments

```bash
curl -X GET "https://yourdomain.com/api/events/1/payments" \
  -H "Authorization: Bearer your_jwt_token"
```

### 3. Update Payment Status

```bash
curl -X PUT "https://yourdomain.com/api/payments/1" \
  -H "Authorization: Bearer your_jwt_token" \
  -H "Content-Type: application/json" \
  -d '{
    "status": "refunded"
  }'
```

## 🎯 Razorpay Pages Configuration

### 1. Form Fields

Configure your Razorpay Pages form with these fields:

```html
<!-- Required fields -->
<input name="name" placeholder="Full Name" required>
<input name="email" placeholder="Email" type="email" required>
<input name="phone" placeholder="Phone Number" required>

<!-- Custom fields for your system -->
<input name="event_id" type="hidden" value="1">
<input name="attendee_id" type="hidden" value="123">
<input name="amount" type="hidden" value="50000">
```

### 2. Webhook Configuration

In Razorpay Pages settings:
- **Webhook URL**: `https://yourdomain.com/api/webhooks/razorpay`
- **Events**: `payment.captured`, `payment.failed`
- **Secret**: Use the same secret as in your environment variables

## 🔍 Monitoring & Debugging

### 1. Check Webhook Logs

```bash
# View webhook logs
docker-compose logs -f backend | grep "webhook"

# Check payment records
curl -X GET "https://yourdomain.com/api/events/1/payments" \
  -H "Authorization: Bearer your_jwt_token"
```

### 2. Test Webhook

Use Razorpay's webhook testing tool or ngrok for local testing:

```bash
# Install ngrok
npm install -g ngrok

# Expose local server
ngrok http 8000

# Use ngrok URL in Razorpay webhook settings
# https://abc123.ngrok.io/api/webhooks/razorpay
```

## 🚨 Troubleshooting

### Common Issues

1. **Webhook not receiving data**:
   - Check webhook URL is accessible
   - Verify webhook secret matches
   - Check Razorpay dashboard for webhook logs

2. **Signature verification failed**:
   - Ensure webhook secret is correct
   - Check if webhook URL is HTTPS
   - Verify request body is not modified

3. **Payment not found**:
   - Check if payment ID exists in database
   - Verify event_id and attendee_id associations
   - Check webhook payload structure

### Debug Commands

```bash
# Check database connection
curl -X GET "https://yourdomain.com/health"

# Test webhook endpoint
curl -X POST "https://yourdomain.com/api/webhooks/razorpay" \
  -H "Content-Type: application/json" \
  -d '{"test": "webhook"}'

# View payment statistics
curl -X GET "https://yourdomain.com/api/events/1/payments" \
  -H "Authorization: Bearer your_jwt_token"
```

## 📈 Analytics & Reporting

The system automatically tracks:
- Total payments per event
- Payment success/failure rates
- Customer details and contact information
- Payment timestamps and amounts
- Refund status and history

Access this data through the API endpoints or export to CSV for analysis.

## 🔄 Next Steps

1. **Set up Razorpay Pages** with your payment forms
2. **Configure webhook URL** in Razorpay dashboard
3. **Test payment flow** with small amounts
4. **Monitor webhook logs** for any issues
5. **Set up monitoring** for production use

## 📞 Support

For issues with this integration:
- Check the webhook logs in your backend
- Verify Razorpay dashboard webhook settings
- Test with Razorpay's webhook testing tool
- Contact support with specific error messages

---

**Note**: Always test with small amounts first and ensure your webhook URL is accessible from the internet.
