# QrFlow Backend - AWS EC2 Deployment Guide

Complete guide to deploy QrFlow backend on AWS EC2 Free Tier using Docker.

## Prerequisites

- AWS Account
- GitHub Account
- Domain name (optional, but recommended)

## Part 1: AWS EC2 Setup

### 1.1 Launch EC2 Instance

1. **Login to AWS Console** → EC2 Dashboard
2. **Launch Instance**:
   - Name: `qrflow-backend`
   - AMI: **Ubuntu Server 22.04 LTS**
   - Instance type: **t2.micro** (Free Tier eligible)
   - Key pair: Create new or use existing
   - Storage: 20 GB (Free Tier includes 30 GB)

3. **Configure Security Group**:
   - SSH (22): Your IP
   - HTTP (80): 0.0.0.0/0
   - HTTPS (443): 0.0.0.0/0
   - Custom TCP (8000): 0.0.0.0/0

4. **Launch Instance** and note the Public IP

### 1.2 Connect to EC2

Download your .pem key file

chmod 400 your-key.pem
Connect

ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP

text

### 1.3 Install Docker & Docker Compose

Update system

sudo apt update && sudo apt upgrade -y
Install Docker

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
Add user to docker group

sudo usermod -aG docker ubuntu
Install Docker Compose

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
Verify installation

docker --version
docker-compose --version
Logout and login again for group changes

exit

text

Reconnect:

ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP

text

## Part 2: Deploy Application

### 2.1 Clone Repository

Clone from GitHub

git clone https://github.com/YOUR_USERNAME/qrflow-backend.git
cd qrflow-backend

text

### 2.2 Configure Environment

Copy example env file

cp .env.example .env
Edit environment variables

nano .env

text

**Important configurations:**

Database - Use strong passwords!

POSTGRES_DB=qrflow_db
POSTGRES_USER=qrflow_admin
POSTGRES_PASSWORD=YOUR_SECURE_PASSWORD_HERE
JWT Secret - Generate secure key

SECRET_KEY=YOUR_SECURE_SECRET_KEY_HERE
Email (Gmail example)

SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_gmail_app_password
SMTP_FROM_EMAIL=your_email@gmail.com
SMTP_FROM_NAME=QrFlow
Environment

ENVIRONMENT=production

text

**Generate secure SECRET_KEY:**

python3 -c "import secrets; print(secrets.token_urlsafe(32))"

text

### 2.3 Start Services

Start Docker containers

docker-compose up -d
Check status

docker-compose ps
View logs

docker-compose logs -f
Wait for services to be healthy (30-60 seconds)

text

### 2.4 Initialize Database

Run database initialization

docker-compose exec backend python init_db.py
Create admin user

docker-compose exec backend python create_admin.py

text

### 2.5 Test API

Health check

curl http://localhost:8000/health
Should return:
{"status":"healthy","database":"connected"}
Test from outside (use your EC2 public IP)

curl http://YOUR_EC2_PUBLIC_IP:8000/health

text

## Part 3: Configure Nginx (Production)

### 3.1 Install Nginx

sudo apt install nginx -y

text

### 3.2 Configure Nginx

sudo nano /etc/nginx/sites-available/qrflow

text

**Paste this configuration:**

server {
listen 80;
server_name YOUR_DOMAIN_OR_IP;

text
client_max_body_size 10M;

location / {
    proxy_pass http://localhost:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}

}

text

### 3.3 Enable Site

Create symbolic link

sudo ln -s /etc/nginx/sites-available/qrflow /etc/nginx/sites-enabled/
Test configuration

sudo nginx -t
Restart Nginx

sudo systemctl restart nginx
Enable on boot

sudo systemctl enable nginx

text

Now API is accessible at: `http://YOUR_DOMAIN_OR_IP`

## Part 4: SSL/HTTPS (Optional but Recommended)

### 4.1 Install Certbot

sudo apt install certbot python3-certbot-nginx -y

text

### 4.2 Obtain SSL Certificate

Replace with your domain

sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
Follow prompts
Email: your_email@domain.com
Agree to terms: Y
Redirect HTTP to HTTPS: 2 (recommended)

text

### 4.3 Auto-renewal

Test renewal

sudo certbot renew --dry-run
Certbot auto-renewal is already set up via systemd

text

## Part 5: Maintenance & Updates

### 5.1 Update Application

cd ~/qrflow-backend
Pull latest changes

git pull origin main
Rebuild and restart

docker-compose down
docker-compose up -d --build
Check logs

docker-compose logs -f

text

### 5.2 Backup Database

Create backup directory

mkdir -p ~/backups
Backup database

docker-compose exec db pg_dump -U postgres postgres > ~/backups/qrflow_backup_$(date +%Y%m%d_%H%M%S).sql
List backups

ls -lh ~/backups/

text

### 5.3 Restore Database

Restore from backup

docker-compose exec -T db psql -U postgres postgres < ~/backups/qrflow_backup_YYYYMMDD_HHMMSS.sql

text

### 5.4 View Logs

All logs

docker-compose logs -f
Specific service

docker-compose logs -f backend
docker-compose logs -f db
Last 100 lines

docker-compose logs --tail=100

text

### 5.5 Restart Services

Restart all

docker-compose restart
Restart specific service

docker-compose restart backend

text

## Part 6: Monitoring

### 6.1 Check Service Status

Docker containers

docker-compose ps
System resources

htop
df -h
free -h

text

### 6.2 Check API Health

Local

curl http://localhost:8000/health
External

curl http://YOUR_DOMAIN/health

text

## Part 7: Security Best Practices

### 7.1 Update System Regularly

sudo apt update && sudo apt upgrade -y

text

### 7.2 Configure Firewall (UFW)

Enable UFW

sudo ufw enable
Allow SSH

sudo ufw allow 22
Allow HTTP/HTTPS

sudo ufw allow 80
sudo ufw allow 443
Check status

sudo ufw status

text

### 7.3 Change Default Passwords

After first login, change admin password via API

curl -X PUT http://YOUR_DOMAIN/api/admin/users/1
-H "Authorization: Bearer YOUR_TOKEN"
-H "Content-Type: application/json"
-d '{"password": "NEW_SECURE_PASSWORD"}'

text

## Troubleshooting

### Issue: Containers not starting

Check logs

docker-compose logs
Check disk space

df -h
Restart

docker-compose down
docker-compose up -d

text

### Issue: Database connection failed

Check database logs

docker-compose logs db
Test connection

docker-compose exec db psql -U postgres -c "SELECT version();"
Restart database

docker-compose restart db

text

### Issue: Port 8000 already in use

Find process

sudo lsof -i :8000
Kill process

sudo kill -9 PID

text

## Useful Commands Cheat Sheet

Start services

docker-compose up -d
Stop services

docker-compose down
Restart services

docker-compose restart
View logs

docker-compose logs -f
Update app

git pull && docker-compose up -d --build
Backup database

docker-compose exec db pg_dump -U postgres postgres > backup.sql
Check health

curl http://localhost:8000/health
Access database

docker-compose exec db psql -U postgres
Remove all containers and volumes

docker-compose down -v

text

## Support

For issues, contact: support@yourdomain.com
