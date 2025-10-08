#!/bin/bash

# System Service Installation Script for QRFlow Backend
# This script creates and installs systemd services for auto-start

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
    echo -e "${BLUE}[SERVICE SETUP]${NC} $1"
}

print_header "🔧 Installing System Services for QRFlow Backend"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Create QRFlow service
print_status "Creating QRFlow systemd service..."
sudo tee /etc/systemd/system/qrflow.service > /dev/null << EOF
[Unit]
Description=QRFlow Backend Service
Requires=docker.service
After=docker.service network.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
User=$SERVICE_USER
Group=$SERVICE_USER
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
ExecReload=/usr/local/bin/docker-compose -f docker-compose.production.yml restart
TimeoutStartSec=300
TimeoutStopSec=60
Restart=on-failure
RestartSec=10

# Environment
Environment=PATH=/usr/local/bin:/usr/bin:/bin
Environment=HOME=$PROJECT_DIR

[Install]
WantedBy=multi-user.target
EOF

# Create QRFlow monitoring service
print_status "Creating QRFlow monitoring service..."
sudo tee /etc/systemd/system/qrflow-monitor.service > /dev/null << EOF
[Unit]
Description=QRFlow Monitoring Service
After=qrflow.service
Requires=qrflow.service

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/qrflow-monitor.sh
Restart=always
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create QRFlow backup service
print_status "Creating QRFlow backup service..."
sudo tee /etc/systemd/system/qrflow-backup.service > /dev/null << EOF
[Unit]
Description=QRFlow Backup Service
After=qrflow.service
Requires=qrflow.service

[Service]
Type=oneshot
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/qrflow-backup.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create backup timer
print_status "Creating backup timer..."
sudo tee /etc/systemd/system/qrflow-backup.timer > /dev/null << EOF
[Unit]
Description=Daily QRFlow Backup
Requires=qrflow-backup.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=3600

[Install]
WantedBy=timers.target
EOF

# Create SSL renewal service
print_status "Creating SSL renewal service..."
sudo tee /etc/systemd/system/qrflow-ssl-renew.service > /dev/null << EOF
[Unit]
Description=QRFlow SSL Certificate Renewal
After=network.target

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/renew-ssl.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create SSL renewal timer
print_status "Creating SSL renewal timer..."
sudo tee /etc/systemd/system/qrflow-ssl-renew.timer > /dev/null << EOF
[Unit]
Description=Weekly SSL Certificate Check
Requires=qrflow-ssl-renew.service

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=86400

[Install]
WantedBy=timers.target
EOF

# Create log rotation configuration
print_status "Creating log rotation configuration..."
sudo tee /etc/logrotate.d/qrflow > /dev/null << EOF
$PROJECT_DIR/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_USER
    postrotate
        systemctl reload qrflow-monitor.service > /dev/null 2>&1 || true
    endscript
}

/var/log/qrflow-monitor.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $SERVICE_USER $SERVICE_USER
}
EOF

# Create systemd override directory
print_status "Creating systemd override directory..."
sudo mkdir -p /etc/systemd/system/qrflow.service.d

# Create override configuration for resource limits
sudo tee /etc/systemd/system/qrflow.service.d/override.conf > /dev/null << EOF
[Service]
# Resource limits
LimitNOFILE=65536
LimitNPROC=32768

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$PROJECT_DIR

# Environment
Environment=DOCKER_COMPOSE_FILE=docker-compose.production.yml
EOF

# Reload systemd
print_status "Reloading systemd configuration..."
sudo systemctl daemon-reload

# Enable services
print_status "Enabling services..."
sudo systemctl enable qrflow.service
sudo systemctl enable qrflow-monitor.service
sudo systemctl enable qrflow-backup.timer
sudo systemctl enable qrflow-ssl-renew.timer

# Start services
print_status "Starting services..."
sudo systemctl start qrflow.service
sudo systemctl start qrflow-monitor.service
sudo systemctl start qrflow-backup.timer
sudo systemctl start qrflow-ssl-renew.timer

# Create management script
print_status "Creating management script..."
sudo tee /usr/local/bin/qrflow-manage > /dev/null << 'EOF'
#!/bin/bash

# QRFlow Management Script
# Usage: qrflow-manage [start|stop|restart|status|logs|backup|update]

SERVICE_NAME="qrflow"
PROJECT_DIR="/home/smec/qrflow-backend"

case "$1" in
    start)
        echo "Starting QRFlow services..."
        sudo systemctl start $SERVICE_NAME
        sudo systemctl start qrflow-monitor
        ;;
    stop)
        echo "Stopping QRFlow services..."
        sudo systemctl stop qrflow-monitor
        sudo systemctl stop $SERVICE_NAME
        ;;
    restart)
        echo "Restarting QRFlow services..."
        sudo systemctl restart $SERVICE_NAME
        sudo systemctl restart qrflow-monitor
        ;;
    status)
        echo "QRFlow Service Status:"
        sudo systemctl status $SERVICE_NAME --no-pager
        echo ""
        echo "QRFlow Monitor Status:"
        sudo systemctl status qrflow-monitor --no-pager
        echo ""
        echo "Backup Timer Status:"
        sudo systemctl status qrflow-backup.timer --no-pager
        echo ""
        echo "SSL Renewal Timer Status:"
        sudo systemctl status qrflow-ssl-renew.timer --no-pager
        ;;
    logs)
        echo "QRFlow Service Logs:"
        sudo journalctl -u $SERVICE_NAME -f
        ;;
    monitor-logs)
        echo "QRFlow Monitor Logs:"
        sudo journalctl -u qrflow-monitor -f
        ;;
    backup)
        echo "Running manual backup..."
        sudo systemctl start qrflow-backup
        ;;
    update)
        echo "Updating QRFlow..."
        cd $PROJECT_DIR
        git pull
        sudo systemctl restart $SERVICE_NAME
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|monitor-logs|backup|update}"
        exit 1
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/qrflow-manage

# Create health check script
print_status "Creating health check script..."
sudo tee /usr/local/bin/qrflow-health > /dev/null << 'EOF'
#!/bin/bash

# QRFlow Health Check Script
DOMAIN="nyxgenai.com"
PROJECT_DIR="/home/smec/qrflow-backend"

echo "🔍 QRFlow Health Check"
echo "======================"

# Check if services are running
echo "📊 Service Status:"
systemctl is-active qrflow.service > /dev/null && echo "✅ QRFlow Service: Running" || echo "❌ QRFlow Service: Stopped"
systemctl is-active qrflow-monitor.service > /dev/null && echo "✅ Monitor Service: Running" || echo "❌ Monitor Service: Stopped"

# Check Docker containers
echo ""
echo "🐳 Docker Containers:"
cd $PROJECT_DIR
docker-compose -f docker-compose.production.yml ps

# Check HTTP endpoints
echo ""
echo "🌐 HTTP Endpoints:"
curl -f http://localhost:8000/health > /dev/null 2>&1 && echo "✅ Backend Health: OK" || echo "❌ Backend Health: Failed"
curl -f https://$DOMAIN/health > /dev/null 2>&1 && echo "✅ SSL Health: OK" || echo "❌ SSL Health: Failed"

# Check SSL certificate
echo ""
echo "🔐 SSL Certificate:"
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ SSL Certificate: Found"
    openssl x509 -in /etc/letsencrypt/live/$DOMAIN/fullchain.pem -text -noout | grep "Not After" | head -1
else
    echo "❌ SSL Certificate: Not Found"
fi

# Check disk space
echo ""
echo "💾 Disk Usage:"
df -h / | tail -1 | awk '{print "Root partition: " $5 " used (" $3 "/" $2 ")"}'

# Check memory usage
echo ""
echo "🧠 Memory Usage:"
free -h | grep Mem | awk '{print "Memory: " $3 "/" $2 " used (" int($3/$2*100) "%)"}'

echo ""
echo "✅ Health check completed!"
EOF

sudo chmod +x /usr/local/bin/qrflow-health

# Test services
print_status "Testing services..."
sleep 5

if systemctl is-active qrflow.service > /dev/null; then
    print_status "✅ QRFlow service is running"
else
    print_error "❌ QRFlow service failed to start"
    print_status "Check logs with: sudo journalctl -u qrflow.service -f"
fi

if systemctl is-active qrflow-monitor.service > /dev/null; then
    print_status "✅ Monitor service is running"
else
    print_warning "⚠️ Monitor service failed to start"
fi

# Display service information
print_status "Service installation completed! 🎉"
print_status ""
print_status "📊 Service Information:"
print_status "   QRFlow Service: systemctl status qrflow"
print_status "   Monitor Service: systemctl status qrflow-monitor"
print_status "   Backup Timer: systemctl status qrflow-backup.timer"
print_status "   SSL Renewal Timer: systemctl status qrflow-ssl-renew.timer"
print_status ""
print_status "🔧 Management Commands:"
print_status "   Start: qrflow-manage start"
print_status "   Stop: qrflow-manage stop"
print_status "   Restart: qrflow-manage restart"
print_status "   Status: qrflow-manage status"
print_status "   Logs: qrflow-manage logs"
print_status "   Health: qrflow-health"
print_status "   Backup: qrflow-manage backup"
print_status "   Update: qrflow-manage update"
print_status ""
print_status "📝 Log Locations:"
print_status "   Service Logs: sudo journalctl -u qrflow.service -f"
print_status "   Monitor Logs: sudo journalctl -u qrflow-monitor.service -f"
print_status "   Application Logs: $PROJECT_DIR/logs/"
print_status "   Nginx Logs: /var/log/nginx/"
print_status ""
print_status "🔄 Automatic Tasks:"
print_status "   Daily Backups: 2:00 AM"
print_status "   SSL Renewal Check: Weekly"
print_status "   Service Monitoring: Every 5 minutes"
