#!/bin/bash

# Install Automatic Deployment System
# This script sets up automatic deployment for QRFlow Backend

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/smec/qrflow-backend"
SERVICE_USER="smec"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[AUTO-DEPLOY SETUP]${NC} $1"
}

print_header "🔧 Setting up automatic deployment system"

# Make scripts executable
print_status "Making scripts executable..."
chmod +x $PROJECT_DIR/deploy-auto.sh
chmod +x $PROJECT_DIR/webhook-deploy.sh

# Create log directory
print_status "Creating log directory..."
sudo mkdir -p /var/log
sudo touch /var/log/qrflow-deploy.log
sudo touch /var/log/qrflow-webhook.log
sudo chown $SERVICE_USER:$SERVICE_USER /var/log/qrflow-deploy.log
sudo chown $SERVICE_USER:$SERVICE_USER /var/log/qrflow-webhook.log

# Create systemd service for periodic deployment check
print_status "Creating systemd service for deployment monitoring..."
sudo tee /etc/systemd/system/qrflow-auto-deploy.service > /dev/null << EOF
[Unit]
Description=QRFlow Auto Deployment Service
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/bin/bash -c 'while true; do sleep 300; if [ -f $PROJECT_DIR/.deploy-trigger ]; then rm $PROJECT_DIR/.deploy-trigger; $PROJECT_DIR/deploy-auto.sh; fi; done'
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create deployment trigger script
print_status "Creating deployment trigger script..."
cat > $PROJECT_DIR/trigger-deploy.sh << 'EOF'
#!/bin/bash
# Trigger deployment by creating a trigger file
touch /home/ubuntu/qrflow-backend/.deploy-trigger
echo "Deployment triggered at $(date)"
EOF

chmod +x $PROJECT_DIR/trigger-deploy.sh

# Create cron job for periodic deployment check
print_status "Setting up cron job for deployment check..."
(crontab -l 2>/dev/null; echo "*/5 * * * * cd $PROJECT_DIR && git fetch origin main && if [ \$(git rev-parse HEAD) != \$(git rev-parse origin/main) ]; then $PROJECT_DIR/deploy-auto.sh; fi") | crontab -

# Create manual deployment script
print_status "Creating manual deployment script..."
cat > $PROJECT_DIR/deploy-now.sh << 'EOF'
#!/bin/bash
# Manual deployment trigger
echo "🚀 Triggering manual deployment..."
cd /home/ubuntu/qrflow-backend
./deploy-auto.sh
EOF

chmod +x $PROJECT_DIR/deploy-now.sh

# Create deployment status script
print_status "Creating deployment status script..."
cat > $PROJECT_DIR/deploy-status.sh << 'EOF'
#!/bin/bash
# Check deployment status
echo "🔍 QRFlow Deployment Status"
echo "=========================="

# Check git status
echo "📊 Git Status:"
cd /home/ubuntu/qrflow-backend
git status --porcelain

# Check if there are new commits
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/main)

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    echo "✅ Repository is up to date"
else
    echo "🔄 New commits available for deployment"
fi

# Check container status
echo ""
echo "🐳 Container Status:"
docker-compose -f docker-compose.production.yml ps

# Check health
echo ""
echo "🏥 Health Checks:"
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend: Healthy"
else
    echo "❌ Backend: Unhealthy"
fi

if curl -f https://nyxgenai.com/health > /dev/null 2>&1; then
    echo "✅ Nginx: Healthy"
else
    echo "❌ Nginx: Unhealthy"
fi

# Check logs
echo ""
echo "📋 Recent Deployment Logs:"
tail -10 /var/log/qrflow-deploy.log 2>/dev/null || echo "No deployment logs found"
EOF

chmod +x $PROJECT_DIR/deploy-status.sh

# Enable and start the service
print_status "Enabling auto-deployment service..."
sudo systemctl daemon-reload
sudo systemctl enable qrflow-auto-deploy.service
sudo systemctl start qrflow-auto-deploy.service

# Test the deployment system
print_status "Testing deployment system..."
$PROJECT_DIR/deploy-status.sh

print_status "🎉 Automatic deployment system installed successfully!"
print_status ""
print_status "📋 Available Commands:"
print_status "   Manual deployment: ./deploy-now.sh"
print_status "   Check status: ./deploy-status.sh"
print_status "   Trigger deployment: ./trigger-deploy.sh"
print_status "   View logs: tail -f /var/log/qrflow-deploy.log"
print_status ""
print_status "🔄 Automatic Deployment:"
print_status "   - Checks for new commits every 5 minutes"
print_status "   - Automatically deploys when new commits are found"
print_status "   - Creates backups before each deployment"
print_status "   - Logs all deployment activities"
print_status ""
print_status "📧 Setup GitHub Webhook (Optional):"
print_status "   1. Go to your GitHub repository settings"
print_status "   2. Add webhook: https://nyxgenai.com/webhook-deploy"
print_status "   3. Set content type to application/json"
print_status "   4. Set secret to your webhook secret"
