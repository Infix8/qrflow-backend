# Razorpay API Integration

This document explains how to use the new Razorpay API integration to sync payments instead of relying on webhooks.

## Overview

Instead of using webhooks, you can now fetch payments directly from Razorpay API and filter for QR flow payments. This approach gives you more control and reliability.

## API Endpoints

### 1. Sync Payments from Razorpay

**Endpoint:** `GET /api/payments/sync-from-razorpay`

**Parameters:**
- `from_date` (optional): Start date in ISO format (e.g., "2024-01-01T00:00:00Z")
- `to_date` (optional): End date in ISO format (e.g., "2024-01-31T23:59:59Z")
- `count` (optional): Number of payments to fetch (default: 10)
- `skip` (optional): Number of payments to skip (default: 0)

**Example Request:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/payments/sync-from-razorpay?from_date=2024-01-01T00:00:00Z&count=20"
```

**Response:**
```json
{
  "success": true,
  "message": "Successfully synced 2 QR flow payments",
  "total_fetched": 10,
  "qr_flow_payments": 2,
  "synced": 2,
  "created": 2,
  "updated": 0,
  "errors": []
}
```

### 2. Get Payment Status from Razorpay

**Endpoint:** `GET /api/payments/razorpay-status`

**Parameters:**
- `payment_id`: Razorpay payment ID (e.g., "pay_RQf7P6MmPiaDcH")

**Example Request:**
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" \
  "http://localhost:8000/api/payments/razorpay-status?payment_id=pay_RQf7P6MmPiaDcH"
```

## How It Works

### 1. Payment Filtering

The system automatically filters payments to identify QR flow payments by checking:

- **Description**: Payments with `"description": "QRv2 Payment"`
- **Notes**: Payments with student information in notes (college_name, department, roll_number, etc.)

### 2. Student Information Extraction

From the payment notes, the system extracts:
- Student name
- College name
- Department
- Roll number
- Phone number
- Emergency contact

### 3. Database Sync

- **New payments**: Creates new payment records in the database
- **Existing payments**: Updates existing records with latest information
- **Event mapping**: Maps payments to events (defaults to event ID 1)

## Usage Examples

### Example 1: Sync Recent Payments

```python
import requests

# Login first
response = requests.post("http://localhost:8000/api/auth/login", data={
    "username": "admin",
    "password": "admin123"
})
token = response.json()["access_token"]

# Sync recent payments
response = requests.get(
    "http://localhost:8000/api/payments/sync-from-razorpay",
    headers={"Authorization": f"Bearer {token}"},
    params={"count": 20}
)

result = response.json()
print(f"Synced {result['synced']} payments")
```

### Example 2: Sync Payments for Date Range

```python
from datetime import datetime, timedelta

# Last 30 days
to_date = datetime.now()
from_date = to_date - timedelta(days=30)

response = requests.get(
    "http://localhost:8000/api/payments/sync-from-razorpay",
    headers={"Authorization": f"Bearer {token}"},
    params={
        "from_date": from_date.isoformat(),
        "to_date": to_date.isoformat(),
        "count": 50
    }
)
```

### Example 3: Check Specific Payment

```python
# Check specific payment IDs from your example
payment_ids = ["pay_RQf7P6MmPiaDcH", "pay_RQUmJx0pTRTqYc"]

for payment_id in payment_ids:
    response = requests.get(
        "http://localhost:8000/api/payments/razorpay-status",
        headers={"Authorization": f"Bearer {token}"},
        params={"payment_id": payment_id}
    )
    
    if response.status_code == 200:
        payment = response.json()["payment"]
        print(f"Payment {payment_id}: {payment['status']} - ₹{payment['amount']/100}")
```

## Benefits Over Webhooks

1. **Reliability**: No dependency on webhook delivery
2. **Control**: You decide when to sync
3. **Debugging**: Easy to see what payments are being processed
4. **Flexibility**: Can sync historical payments
5. **Filtering**: Automatically filters for QR flow payments

## Configuration

Make sure your Razorpay credentials are configured in your environment:

```bash
export RAZORPAY_KEY_ID="rzp_live_RQSTsFOw6aIjYU"
export RAZORPAY_KEY_SECRET="KKiRMfMXeaUj1KcepioEb7Rx"
```

## Testing

Use the provided test script:

```bash
python test_razorpay_sync.py
```

This will:
1. Login to the API
2. Sync recent payments
3. Check specific payment IDs
4. Show detailed results

## Monitoring

The sync process logs detailed information:
- Number of payments fetched from Razorpay
- Number of QR flow payments identified
- Number of payments created/updated
- Any errors encountered

Check your application logs to monitor the sync process.
