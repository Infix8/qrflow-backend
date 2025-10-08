#!/bin/bash

# Test script for Razorpay API integration
# Make sure your server is running on localhost:8000

echo "🚀 Testing Razorpay API Integration"
echo "=================================="

# Configuration
BASE_URL="http://localhost:8000"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin123"

echo "🔐 Step 1: Login to get access token"
echo "------------------------------------"

# Login and get token
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=$ADMIN_USERNAME&password=$ADMIN_PASSWORD")

echo "Login response: $LOGIN_RESPONSE"

# Extract token (simple approach - in production use jq)
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✅ Login successful! Token: ${TOKEN:0:20}..."
echo ""

echo "🔄 Step 2: Sync payments from Razorpay"
echo "-------------------------------------"

# Sync recent payments
SYNC_RESPONSE=$(curl -s -X GET "$BASE_URL/api/payments/sync-from-razorpay?count=10" \
  -H "Authorization: Bearer $TOKEN")

echo "Sync response: $SYNC_RESPONSE"
echo ""

echo "🔍 Step 3: Check specific payment status"
echo "---------------------------------------"

# Check the specific payment IDs from your example
PAYMENT_IDS=("pay_RQf7P6MmPiaDcH" "pay_RQUmJx0pTRTqYc")

for PAYMENT_ID in "${PAYMENT_IDS[@]}"; do
  echo "Checking payment: $PAYMENT_ID"
  
  STATUS_RESPONSE=$(curl -s -X GET "$BASE_URL/api/payments/razorpay-status?payment_id=$PAYMENT_ID" \
    -H "Authorization: Bearer $TOKEN")
  
  echo "Status response: $STATUS_RESPONSE"
  echo ""
done

echo "✅ Test completed!"
echo ""
echo "📝 Next steps:"
echo "1. Check your database for synced payments"
echo "2. Verify the payment records are created correctly"
echo "3. Test with different date ranges and parameters"
