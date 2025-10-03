# QrFlow Backend - Event Management System

FastAPI backend for QR code-based event management system.

## Features

- JWT Authentication
- Event Management
- QR Code Generation & Email
- Real-time Check-in Dashboard
- Activity Logging
- Multi-club Support

## Tech Stack

- **Framework**: FastAPI
- **Database**: PostgreSQL
- **Authentication**: JWT
- **Email**: SMTP (Gmail)
- **QR Codes**: python-qrcode

## Quick Start (Docker)

### Prerequisites

- Docker & Docker Compose
- Git

### Installation

1. **Clone the repository**

git clone https://github.com/yourusername/qrflow-backend.git
cd qrflow-backend



2. **Configure environment**

cp .env.example .env
nano .env # Update with your settings



3. **Start services**

docker-compose up -d



4. **Initialize database**

./init_db.sh



5. **Access the application**
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Health: http://localhost:8000/health

### Default Credentials

- Username: `admin`
- Password: `admin123`

**⚠️ Change immediately in production!**

## AWS EC2 Deployment

### 1. Launch EC2 Instance

- AMI: Ubuntu 22.04 LTS
- Instance Type: t2.micro (Free Tier)
- Security Group: Open ports 22, 80, 443, 8000

### 2. Connect to EC2

ssh -i your-key.pem ubuntu@your-ec2-ip



### 3. Install Docker

Update system

sudo apt update && sudo apt upgrade -y
Install Docker

curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
Install Docker Compose

sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
Add user to docker group

sudo usermod -aG docker ubuntu
newgrp docker



### 4. Clone & Deploy

Clone repository

git clone https://github.com/yourusername/qrflow-backend.git
cd qrflow-backend
Configure environment

cp .env.example .env
nano .env
Generate secure secret key

python3 -c "import secrets; print(secrets.token_urlsafe(32))"
Copy output to SECRET_KEY in .env
Start services

docker-compose up -d
Initialize database

./init_db.sh
Check logs

docker-compose logs -f



### 5. Setup Nginx (Optional)

sudo apt install nginx -y
Create Nginx config

sudo nano /etc/nginx/sites-available/qrflow



Paste:

server {
listen 80;
server_name your-domain.com;


location / {
    proxy_pass http://localhost:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}

}



Enable:

sudo ln -s /etc/nginx/sites-available/qrflow /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx



## API Endpoints

### Authentication
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Current user

### Admin
- `GET/POST /api/admin/clubs` - Manage clubs
- `GET/POST /api/admin/users` - Manage users
- `GET /api/admin/logs` - Activity logs

### Events
- `GET/POST /api/events` - List/Create events
- `GET/PUT/DELETE /api/events/{id}` - Event operations
- `GET /api/events/{id}/attendees` - List attendees
- `POST /api/events/{id}/attendees/upload` - Upload CSV

### Check-in
- `POST /api/checkin/scan` - Scan QR code
- `GET /api/events/{id}/dashboard` - Real-time stats

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| POSTGRES_DB | Database name | qrflow_db |
| POSTGRES_USER | Database user | qrflow_user |
| POSTGRES_PASSWORD | Database password | - |
| SECRET_KEY | JWT secret | - |
| SMTP_HOST | Email server | smtp.gmail.com |
| SMTP_USERNAME | Email username | - |
| SMTP_PASSWORD | Email password | - |

## Useful Commands

View logs

docker-compose logs -f
Restart services

docker-compose restart
Stop services

docker-compose down
Backup database

docker-compose exec db pg_dump -U qrflow_user qrflow_db > backup.sql
Restore database

docker-compose exec -T db psql -U qrflow_user qrflow_db < backup.sql



## Troubleshooting

### Database Connection Issues

docker-compose logs db
docker-compose exec db psql -U qrflow_user -d qrflow_db



### Backend Not Starting

docker-compose logs backend
docker-compose exec backend python init_db.py



## License

MIT

## Support

For issues and questions, contact: your@email.com
