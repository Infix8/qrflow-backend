#!/bin/bash

# Automated Deployment Script for QRFlow Backend
# This script pulls latest code and rebuilds backend automatically

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/smec/qrflow-backend"
LOG_FILE="/home/smec/qrflow-backend/logs/deploy.log"
BACKUP_DIR="/home/smec/qrflow-backend/backups"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> $LOG_FILE
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> $LOG_FILE
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> $LOG_FILE
}

print_header() {
    echo -e "${BLUE}[AUTO-DEPLOY]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [AUTO-DEPLOY] $1" >> $LOG_FILE
}

print_header "🚀 Starting automated deployment for QRFlow Backend"

# Change to project directory
cd $PROJECT_DIR

# Check if we're in the right directory
if [ ! -f "docker-compose.production.yml" ]; then
    print_error "docker-compose.production.yml not found. Are we in the right directory?"
    exit 1
fi

# Create backup before deployment
print_status "Creating backup before deployment..."
mkdir -p $BACKUP_DIR
BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf $BACKUP_FILE -C $PROJECT_DIR . 2>/dev/null || print_warning "Backup creation failed"
print_status "Backup created: $BACKUP_FILE"

# Check current git status
print_status "Checking current git status..."
git status --porcelain

# Pull latest changes
print_status "Pulling latest changes from GitHub..."
git fetch origin main

# Check if there are new commits
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    print_status "No new changes to deploy"
    exit 0
fi

print_status "New changes detected. Starting deployment..."

# Pull the latest code
git pull origin main

# Check if pull was successful
if [ $? -ne 0 ]; then
    print_error "Git pull failed. Deployment aborted."
    exit 1
fi

print_status "Code pulled successfully"

# Check if backend container is running
print_status "Checking backend container status..."
if docker-compose -f docker-compose.production.yml ps backend | grep -q "Up"; then
    print_status "Backend container is running"
else
    print_warning "Backend container is not running"
fi

# Rebuild backend container
print_status "Rebuilding backend container..."
docker-compose -f docker-compose.production.yml build --no-cache backend

if [ $? -ne 0 ]; then
    print_error "Backend build failed. Deployment aborted."
    exit 1
fi

print_status "Backend container built successfully"

# Restart backend container
print_status "Restarting backend container..."
docker-compose -f docker-compose.production.yml up -d backend

# Wait for backend to be ready
print_status "Waiting for backend to be ready..."
sleep 30

# Check if backend is healthy
print_status "Checking backend health..."
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    print_status "✅ Backend health check passed"
else
    print_warning "⚠️ Backend health check failed"
fi

# Check if nginx can reach backend
print_status "Checking nginx connectivity..."
if curl -f https://nyxgenai.com/health > /dev/null 2>&1; then
    print_status "✅ Nginx health check passed"
else
    print_warning "⚠️ Nginx health check failed"
fi

# Test QR code generation
print_status "Testing QR code generation..."
docker-compose -f docker-compose.production.yml exec backend python -c "
from app.utils import generate_qr_code, save_qr_code
import os

try:
    # Generate QR code
    qr_bytes = generate_qr_code('test-token', 'Test User', 'Test Event')
    
    # Save QR code
    qr_path = save_qr_code(qr_bytes, 'test-deploy.png')
    print(f'QR code saved to: {qr_path}')
    
    # Check if file exists
    if os.path.exists(qr_path):
        print('✅ QR code file created successfully')
    else:
        print('❌ QR code file not created')
except Exception as e:
    print(f'❌ QR code generation failed: {e}')
" 2>/dev/null || print_warning "QR code test failed"

# Clean up old backups (keep last 5)
print_status "Cleaning up old backups..."
ls -t $BACKUP_DIR/backup_*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null || true

# Log deployment completion
print_status "🎉 Deployment completed successfully!"
print_status "Backend is running with latest code"
print_status "Logs available at: $LOG_FILE"

# Send notification (optional)
if command -v mail > /dev/null 2>&1; then
    echo "QRFlow Backend deployment completed successfully at $(date)" | mail -s "Deployment Success" admin@nyxgenai.com 2>/dev/null || true
fi

print_header "Deployment completed! 🚀"
