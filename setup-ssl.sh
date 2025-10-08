#!/bin/bash

# SSL Certificate Setup Script for QRFlow Backend
# This script sets up SSL certificates using Let's Encrypt and Certbot

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
    echo -e "${BLUE}[SSL SETUP]${NC} $1"
}

print_header "🔐 Starting SSL Certificate Setup for $DOMAIN"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check if domain is pointing to this server
print_status "Checking if domain $DOMAIN points to this server..."
SERVER_IP=$(curl -s ifconfig.me)
DOMAIN_IP=$(dig +short $DOMAIN | tail -n1)

if [ "$SERVER_IP" != "$DOMAIN_IP" ]; then
    print_warning "Domain $DOMAIN does not point to this server's IP ($SERVER_IP)"
    print_warning "Domain resolves to: $DOMAIN_IP"
    print_warning "Please update your DNS records before continuing."
    print_warning "Press Enter to continue anyway, or Ctrl+C to abort..."
    read -r
else
    print_status "✅ Domain $DOMAIN correctly points to this server ($SERVER_IP)"
fi

# Install Certbot if not already installed
print_status "Installing Certbot..."
sudo apt update
sudo apt install -y certbot python3-certbot-nginx

# Stop Nginx temporarily for certificate generation
print_status "Stopping Nginx for certificate generation..."
sudo systemctl stop nginx || true

# Create webroot directory for ACME challenge
print_status "Creating webroot directory..."
sudo mkdir -p /var/www/certbot

# Generate SSL certificate
print_status "Generating SSL certificate for $DOMAIN..."
sudo certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --non-interactive \
    -d $DOMAIN \
    -d www.$DOMAIN

# Check if certificate was generated successfully
if [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    print_status "✅ SSL certificate generated successfully!"
else
    print_error "Failed to generate SSL certificate"
    exit 1
fi

# Create Nginx configuration with SSL
print_status "Creating Nginx configuration with SSL..."
sudo tee /etc/nginx/sites-available/qrflow-ssl > /dev/null << EOF
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN www.$DOMAIN;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    # SSL security settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;
    
    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req zone=api burst=20 nodelay;
    
    # Proxy to backend
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Port \$server_port;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Static files
    location /static/ {
        alias $PROJECT_DIR/app/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
    }
    
    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:8000/health;
        access_log off;
    }
    
    # API rate limiting for login
    location /api/auth/login {
        limit_req zone=api burst=5 nodelay;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Deny access to sensitive files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    
    location ~ \.(env|log|sql)$ {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

# Enable the SSL site
print_status "Enabling SSL site configuration..."
sudo ln -sf /etc/nginx/sites-available/qrflow-ssl /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
print_status "Testing Nginx configuration..."
sudo nginx -t

# Start Nginx
print_status "Starting Nginx with SSL configuration..."
sudo systemctl enable nginx
sudo systemctl start nginx

# Setup automatic certificate renewal
print_status "Setting up automatic certificate renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# Create renewal script
print_status "Creating certificate renewal script..."
sudo tee /usr/local/bin/renew-ssl.sh > /dev/null << 'EOF'
#!/bin/bash
# Certificate renewal script

echo "Renewing SSL certificates..."
certbot renew --quiet

# Reload Nginx if certificates were renewed
if [ $? -eq 0 ]; then
    echo "Reloading Nginx..."
    systemctl reload nginx
    echo "SSL certificates renewed and Nginx reloaded"
else
    echo "No certificates needed renewal"
fi
EOF

sudo chmod +x /usr/local/bin/renew-ssl.sh

# Add renewal to crontab
print_status "Adding certificate renewal to crontab..."
(crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/renew-ssl.sh") | crontab -

# Test SSL configuration
print_status "Testing SSL configuration..."
sleep 5

if curl -f https://$DOMAIN/health > /dev/null 2>&1; then
    print_status "✅ SSL setup completed successfully!"
    print_status "🌐 Your application is now available at:"
    print_status "   https://$DOMAIN"
    print_status "   https://$DOMAIN/docs (API Documentation)"
    print_status ""
    print_status "🔐 SSL Certificate Details:"
    print_status "   Certificate: /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    print_status "   Private Key: /etc/letsencrypt/live/$DOMAIN/privkey.pem"
    print_status "   Auto-renewal: Enabled"
    print_status ""
    print_status "📊 Useful commands:"
    print_status "   Check certificate: sudo certbot certificates"
    print_status "   Test renewal: sudo certbot renew --dry-run"
    print_status "   View Nginx logs: sudo tail -f /var/log/nginx/error.log"
else
    print_error "SSL setup failed. Please check the configuration."
    print_status "Check Nginx logs: sudo tail -f /var/log/nginx/error.log"
    exit 1
fi

print_status "SSL setup completed! 🎉"
