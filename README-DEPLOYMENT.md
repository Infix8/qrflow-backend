# QrFlow Backend - Deployment Guide

## Quick Start

### 1. Prerequisites
- Docker and Docker Compose installed
- Git repository access
- Environment variables configured

### 2. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit with your production values
nano .env
```

**Required Environment Variables:**
```env
# Database
POSTGRES_PASSWORD=your_secure_password
DATABASE_URL=postgresql://qrflow_admin:your_secure_password@db:5432/qrflow_db

# JWT
SECRET_KEY=your-super-secret-jwt-key

# Email (Optional)
SMTP_HOST=smtp.gmail.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### 3. Deploy

```bash
# Run deployment script
./deploy.sh

# Or manually
docker-compose up -d --build
```

### 4. Verify Deployment

```bash
# Check health
curl http://localhost:8000/health

# Check API docs
curl http://localhost:8000/docs
```

## AWS EC2 Deployment

### 1. Launch EC2 Instance
- AMI: Ubuntu Server 22.04 LTS
- Instance Type: t2.micro (Free Tier)
- Security Group: Allow ports 22, 80, 443, 8000

### 2. Connect and Setup

```bash
# Connect to EC2
ssh -i your-key.pem ubuntu@YOUR_EC2_IP

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 3. Deploy Application

```bash
# Clone repository
git clone https://github.com/yourusername/qrflow-backend.git
cd qrflow-backend

# Configure environment
cp .env.example .env
nano .env

# Deploy
./deploy.sh
```

### 4. Configure Nginx (Optional)

```bash
# Install Nginx
sudo apt install nginx -y

# Create site configuration
sudo nano /etc/nginx/sites-available/qrflow
```

**Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name your-domain.com;

    client_max_body_size 10M;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/qrflow /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## GitHub Actions Deployment

### 1. Repository Secrets
Add these secrets to your GitHub repository:

- `EC2_HOST`: Your EC2 public IP
- `EC2_USERNAME`: ubuntu
- `EC2_SSH_KEY`: Your private SSH key content

### 2. Automatic Deployment
Push to main branch triggers automatic deployment:

```bash
git add .
git commit -m "Deploy to production"
git push origin main
```

## Monitoring and Maintenance

### Check Status
```bash
# Container status
docker-compose ps

# Logs
docker-compose logs -f

# Health check
curl http://localhost:8000/health
```

### Update Application
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Backup Database
```bash
# Create backup
docker-compose exec db pg_dump -U qrflow_admin qrflow_db > backup.sql

# Restore backup
docker-compose exec -T db psql -U qrflow_admin qrflow_db < backup.sql
```

## Troubleshooting

### Common Issues

1. **Port 8000 already in use**
   ```bash
   sudo lsof -i :8000
   sudo kill -9 PID
   ```

2. **Database connection failed**
   ```bash
   docker-compose logs db
   docker-compose restart db
   ```

3. **Container won't start**
   ```bash
   docker-compose logs
   docker-compose down -v
   docker-compose up -d
   ```

### Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f db
```

## Security Checklist

- [ ] Change default passwords
- [ ] Use strong SECRET_KEY
- [ ] Configure firewall (UFW)
- [ ] Enable SSL/HTTPS
- [ ] Regular backups
- [ ] Monitor logs
- [ ] Update dependencies

## Support

For issues and support:
- Check logs: `docker-compose logs`
- Health check: `curl http://localhost:8000/health`
- API docs: `http://localhost:8000/docs`
