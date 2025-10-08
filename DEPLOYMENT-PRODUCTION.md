# 🚀 QRFlow Backend - Production Deployment Guide

Complete production deployment setup for QRFlow Backend with Docker, PostgreSQL, Nginx, and SSL certificates for the domain `nyxgenai.com`.

## 📋 Prerequisites

- Ubuntu 20.04+ or similar Linux distribution
- Domain name pointing to your server's IP address
- Root or sudo access
- At least 2GB RAM and 20GB disk space

## 🎯 Quick Start

### 1. Clone and Setup

```bash
# Clone the repository (if not already done)
git clone <your-repo-url>
cd qrflow-backend

# Make scripts executable
chmod +x *.sh
```

### 2. Configure Environment

```bash
# Copy environment template
cp env.template .env

# Edit with your actual values
nano .env
```

**Important Environment Variables to Update:**

```bash
# Database
POSTGRES_PASSWORD=your_secure_database_password

# JWT Secret (generate a secure one)
SECRET_KEY=your_super_secret_jwt_key_here_minimum_32_characters

# Email (for notifications)
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-specific-password
SMTP_FROM_EMAIL=your-email@gmail.com

# Razorpay (for payments)
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret

# Domain
DOMAIN=nyxgenai.com
```

### 3. Run Production Deployment

```bash
# Run the complete deployment script
./deploy-production.sh
```

This script will:
- ✅ Install Docker and Docker Compose
- ✅ Install Nginx and Certbot
- ✅ Configure firewall and security
- ✅ Build and start all services
- ✅ Setup SSL certificates
- ✅ Configure automatic backups
- ✅ Setup monitoring

### 4. Install System Services

```bash
# Install systemd services for auto-start
./install-service.sh
```

## 🔧 Manual Setup (Alternative)

If you prefer to run components separately:

### 1. Setup SSL Certificates

```bash
./setup-ssl.sh
```

### 2. Start Services

```bash
# Start with production compose file
docker-compose -f docker-compose.production.yml up -d
```

### 3. Initialize Database

```bash
# Initialize database and create admin user
docker-compose -f docker-compose.production.yml exec backend python init_db.py
docker-compose -f docker-compose.production.yml exec backend python create_admin.py
```

## 📊 Service Management

### Quick Commands

```bash
# Service management
qrflow-manage start      # Start all services
qrflow-manage stop       # Stop all services
qrflow-manage restart    # Restart all services
qrflow-manage status     # Check service status
qrflow-manage logs       # View service logs
qrflow-manage backup     # Run manual backup
qrflow-manage update     # Update and restart

# Health check
qrflow-health            # Comprehensive health check
```

### Manual Service Control

```bash
# Systemd services
sudo systemctl start qrflow.service
sudo systemctl stop qrflow.service
sudo systemctl restart qrflow.service
sudo systemctl status qrflow.service

# View logs
sudo journalctl -u qrflow.service -f
sudo journalctl -u qrflow-monitor.service -f
```

## 🌐 Access Points

After successful deployment:

- **Main Application**: https://nyxgenai.com
- **API Documentation**: https://nyxgenai.com/docs
- **Health Check**: https://nyxgenai.com/health
- **Admin Panel**: https://nyxgenai.com/admin (if implemented)

## 🔐 Default Credentials

- **Username**: `admin`
- **Password**: `admin123`

⚠️ **Change these immediately in production!**

## 📁 File Structure

```
qrflow-backend/
├── deploy-production.sh          # Main deployment script
├── docker-compose.production.yml # Production Docker setup
├── setup-ssl.sh                 # SSL certificate setup
├── install-service.sh            # System service installation
├── env.template                 # Environment configuration template
├── nginx/                       # Nginx configuration
│   ├── nginx.conf
│   └── conf.d/
│       └── nyxgenai.com.conf
├── app/                         # Application code
├── logs/                        # Application logs
└── backups/                     # Database backups
```

## 🔄 Automatic Tasks

### Daily Backups
- **Schedule**: 2:00 AM daily
- **Location**: `/opt/qrflow-backups/`
- **Retention**: 7 days
- **Service**: `qrflow-backup.timer`

### SSL Certificate Renewal
- **Schedule**: Weekly check
- **Auto-renewal**: 30 days before expiry
- **Service**: `qrflow-ssl-renew.timer`

### Service Monitoring
- **Frequency**: Every 5 minutes
- **Service**: `qrflow-monitor.service`
- **Logs**: `/var/log/qrflow-monitor.log`

## 🛠️ Troubleshooting

### Check Service Status

```bash
# Overall health check
qrflow-health

# Individual service status
sudo systemctl status qrflow.service
sudo systemctl status qrflow-monitor.service
sudo systemctl status nginx.service
```

### View Logs

```bash
# Application logs
docker-compose -f docker-compose.production.yml logs -f

# System service logs
sudo journalctl -u qrflow.service -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Monitor logs
tail -f /var/log/qrflow-monitor.log
```

### Common Issues

#### 1. Services Won't Start
```bash
# Check Docker status
sudo systemctl status docker

# Check disk space
df -h

# Check memory usage
free -h

# Restart Docker
sudo systemctl restart docker
```

#### 2. SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Test certificate renewal
sudo certbot renew --dry-run

# Manual certificate renewal
sudo certbot renew
```

#### 3. Database Connection Issues
```bash
# Check database container
docker-compose -f docker-compose.production.yml ps db

# Check database logs
docker-compose -f docker-compose.production.yml logs db

# Connect to database
docker-compose -f docker-compose.production.yml exec db psql -U qrflow_user -d qrflow_db
```

#### 4. Nginx Issues
```bash
# Test Nginx configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx

# Check Nginx status
sudo systemctl status nginx
```

## 🔒 Security Features

### Firewall Configuration
- SSH (port 22)
- HTTP (port 80)
- HTTPS (port 443)
- Internal services only

### SSL/TLS Security
- TLS 1.2+ only
- Strong cipher suites
- HSTS headers
- Security headers (XSS, CSRF protection)

### Rate Limiting
- API rate limiting: 10 requests/second
- Login rate limiting: 5 requests/minute
- Burst protection

### Monitoring
- Fail2ban for intrusion prevention
- Service health monitoring
- Automatic service restart on failure

## 📈 Performance Optimization

### Resource Limits
- **Backend**: 512MB RAM limit, 256MB reserved
- **Database**: Optimized PostgreSQL settings
- **Nginx**: Gzip compression, caching headers

### Caching
- Static file caching (1 year)
- Database connection pooling
- Redis for session storage

## 🔄 Updates and Maintenance

### Application Updates
```bash
# Update application
git pull
qrflow-manage update

# Or manually
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml up -d --build
```

### System Updates
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Restart services if needed
qrflow-manage restart
```

### Database Backups
```bash
# Manual backup
qrflow-manage backup

# Check backup status
sudo systemctl status qrflow-backup.service
```

## 📞 Support

### Log Locations
- **Application**: `./logs/`
- **System Services**: `sudo journalctl -u qrflow.service`
- **Nginx**: `/var/log/nginx/`
- **Monitor**: `/var/log/qrflow-monitor.log`

### Health Monitoring
```bash
# Quick health check
curl -f https://nyxgenai.com/health

# Detailed health check
qrflow-health
```

## 🎉 Success!

If everything is working correctly, you should see:

- ✅ https://nyxgenai.com loads with SSL certificate
- ✅ https://nyxgenai.com/docs shows API documentation
- ✅ https://nyxgenai.com/health returns 200 OK
- ✅ All services running: `qrflow-manage status`
- ✅ SSL certificate valid: `sudo certbot certificates`

Your QRFlow Backend is now fully deployed and secured! 🚀
