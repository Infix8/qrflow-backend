#!/bin/bash

# QRFlow Backend Production Deployment Script
# Complete setup with Docker, PostgreSQL, Nginx, and SSL certificates
# Domain: nyxgenai.com

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="nyxgenai.com"
EMAIL="admin@nyxgenai.com"  # Change this to your email
PROJECT_DIR="/home/smec/qrflow-backend"

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
    echo -e "${BLUE}[SETUP]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

print_header "🚀 Starting QRFlow Backend Production Deployment"
print_header "Domain: $DOMAIN"
print_header "Project Directory: $PROJECT_DIR"

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required system packages
print_status "Installing system dependencies..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    fail2ban

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_status "Docker installed successfully"
else
    print_status "Docker is already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_status "Docker Compose installed successfully"
else
    print_status "Docker Compose is already installed"
fi

# Create environment file if it doesn't exist
print_status "Setting up environment configuration..."
if [ ! -f "$PROJECT_DIR/.env" ]; then
    print_warning "Creating .env file from template..."
    cat > "$PROJECT_DIR/.env" << EOF
# Database Configuration
POSTGRES_DB=qrflow_db
POSTGRES_USER=qrflow_user
POSTGRES_PASSWORD=$(openssl rand -base64 32)

# JWT Configuration
SECRET_KEY=$(openssl rand -base64 32)
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# Email Configuration (Update with your SMTP settings)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_FROM_EMAIL=your-email@gmail.com
SMTP_FROM_NAME=QRFlow System

# Razorpay Configuration (Update with your credentials)
RAZORPAY_KEY_ID=your-razorpay-key-id
RAZORPAY_KEY_SECRET=your-razorpay-key-secret
RAZORPAY_WEBHOOK_SECRET=your-webhook-secret
RAZORPAY_WEBHOOK_URL=https://$DOMAIN/api/payments/webhook

# Application Configuration
APP_NAME=QRFlow Event Management
ENVIRONMENT=production
DOMAIN=$DOMAIN
EOF
    print_warning "Please edit $PROJECT_DIR/.env with your actual credentials before continuing!"
    print_warning "Press Enter to continue after updating the .env file..."
    read -r
else
    print_status "Environment file already exists"
fi

# Configure firewall
print_status "Configuring firewall..."
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8000  # For initial testing
print_status "Firewall configured"

# Configure fail2ban
print_status "Configuring fail2ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
print_status "Fail2ban configured"

# Stop and remove existing containers
print_status "Stopping existing containers..."
cd "$PROJECT_DIR"
docker-compose down --remove-orphans || true

# Build and start services
print_status "Building and starting Docker services..."
docker-compose -f docker-compose.production.yml up -d --build

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check if services are running
if docker-compose -f docker-compose.production.yml ps | grep -q "Up"; then
    print_status "Docker services are running successfully!"
    
    # Initialize database
    print_status "Initializing database..."
    docker-compose -f docker-compose.production.yml exec -T backend python init_db.py || print_warning "Database initialization may have failed"
    
    # Create admin user
    print_status "Creating admin user..."
    docker-compose -f docker-compose.production.yml exec -T backend python create_admin.py || print_warning "Admin user creation may have failed"
    
    # Health check
    print_status "Performing health check..."
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        print_status "✅ Backend health check passed!"
    else
        print_error "Backend health check failed. Check logs with: docker-compose -f docker-compose.production.yml logs"
        exit 1
    fi
else
    print_error "Docker services failed to start. Check logs with: docker-compose -f docker-compose.production.yml logs"
    exit 1
fi

# Configure Nginx
print_status "Configuring Nginx..."
sudo tee /etc/nginx/sites-available/qrflow > /dev/null << EOF
# Upstream backend
upstream qrflow_backend {
    server 127.0.0.1:8000;
}

# Rate limiting
limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;

# Main server block
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Rate limiting
    limit_req zone=api burst=20 nodelay;
    
    # Proxy to backend
    location / {
        proxy_pass http://qrflow_backend;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # Static files
    location /static/ {
        alias $PROJECT_DIR/app/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://qrflow_backend/health;
        access_log off;
    }
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
}
EOF

# Enable the site
sudo ln -sf /etc/nginx/sites-available/qrflow /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_status "Testing Nginx configuration..."
sudo nginx -t

# Start and enable Nginx
print_status "Starting Nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx
print_status "Nginx configured and started"

# Obtain SSL certificate
print_status "Obtaining SSL certificate from Let's Encrypt..."
print_warning "Make sure your domain $DOMAIN points to this server's IP address!"
print_warning "Press Enter to continue with SSL certificate setup..."
read -r

# Get SSL certificate
sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $EMAIL --agree-tos --non-interactive

# Setup automatic certificate renewal
print_status "Setting up automatic certificate renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Create systemd service for auto-start
print_status "Creating systemd service for auto-start..."
sudo tee /etc/systemd/system/qrflow.service > /dev/null << EOF
[Unit]
Description=QRFlow Backend Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$PROJECT_DIR
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable qrflow.service
print_status "Systemd service created and enabled"

# Create backup script
print_status "Creating backup script..."
sudo tee /usr/local/bin/qrflow-backup.sh > /dev/null << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/qrflow-backups"
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="/home/smec/qrflow-backend"

mkdir -p $BACKUP_DIR

# Backup database
docker-compose -f $PROJECT_DIR/docker-compose.production.yml exec -T db pg_dump -U qrflow_user qrflow_db > $BACKUP_DIR/db_backup_$DATE.sql

# Backup application files
tar -czf $BACKUP_DIR/app_backup_$DATE.tar.gz -C $PROJECT_DIR .

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

sudo chmod +x /usr/local/bin/qrflow-backup.sh

# Setup daily backup cron job
print_status "Setting up daily backup..."
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/qrflow-backup.sh") | crontab -

# Create monitoring script
print_status "Creating monitoring script..."
sudo tee /usr/local/bin/qrflow-monitor.sh > /dev/null << 'EOF'
#!/bin/bash
PROJECT_DIR="/home/smec/qrflow-backend"
LOG_FILE="/var/log/qrflow-monitor.log"

# Check if services are running
if ! docker-compose -f $PROJECT_DIR/docker-compose.production.yml ps | grep -q "Up"; then
    echo "$(date): Services down, restarting..." >> $LOG_FILE
    cd $PROJECT_DIR
    docker-compose -f docker-compose.production.yml up -d
fi

# Check disk space
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ $DISK_USAGE -gt 80 ]; then
    echo "$(date): Disk usage high: ${DISK_USAGE}%" >> $LOG_FILE
fi
EOF

sudo chmod +x /usr/local/bin/qrflow-monitor.sh

# Setup monitoring cron job
print_status "Setting up monitoring..."
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/qrflow-monitor.sh") | crontab -

# Final health check
print_status "Performing final health check..."
sleep 10

if curl -f https://$DOMAIN/health > /dev/null 2>&1; then
    print_status "✅ SSL health check passed!"
    print_status "🎉 Deployment completed successfully!"
    print_status ""
    print_status "🌐 Your application is now available at:"
    print_status "   https://$DOMAIN"
    print_status "   https://$DOMAIN/docs (API Documentation)"
    print_status ""
    print_status "📊 Useful commands:"
    print_status "   View logs: docker-compose -f docker-compose.production.yml logs -f"
    print_status "   Restart: sudo systemctl restart qrflow"
    print_status "   Backup: /usr/local/bin/qrflow-backup.sh"
    print_status "   Monitor: tail -f /var/log/qrflow-monitor.log"
    print_status ""
    print_status "🔐 Default admin credentials:"
    print_status "   Username: admin"
    print_status "   Password: admin123"
    print_warning "⚠️  Please change the default admin password immediately!"
else
    print_error "Final health check failed. Please check the configuration."
    print_status "You can check logs with: docker-compose -f docker-compose.production.yml logs"
fi

print_status "Deployment script completed! 🚀"
