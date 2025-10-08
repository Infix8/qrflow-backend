# 🚀 Automated Deployment System for QRFlow Backend

This system automatically pulls the latest code from GitHub and rebuilds the backend container whenever you push changes to the main branch.

## 📋 Features

- ✅ **Automatic Code Pulling**: Pulls latest changes from GitHub
- ✅ **Backend Rebuilding**: Rebuilds only the backend container
- ✅ **Health Checks**: Verifies deployment success
- ✅ **Backup Creation**: Creates backups before each deployment
- ✅ **Logging**: Comprehensive logging of all activities
- ✅ **GitHub Webhook Support**: Optional webhook integration
- ✅ **Manual Triggers**: Manual deployment options

## 🛠️ Setup Instructions

### Step 1: Install the Automated Deployment System

```bash
# Run the installation script
./install-auto-deploy.sh
```

This will:
- Create systemd service for monitoring
- Set up cron job for periodic checks
- Create deployment scripts
- Enable automatic deployment

### Step 2: Test the System

```bash
# Check deployment status
./deploy-status.sh

# Trigger manual deployment
./deploy-now.sh
```

## 🔧 Available Commands

### Manual Deployment
```bash
# Deploy immediately
./deploy-now.sh

# Check deployment status
./deploy-status.sh

# Trigger deployment (creates trigger file)
./trigger-deploy.sh
```

### Logs and Monitoring
```bash
# View deployment logs
tail -f /var/log/qrflow-deploy.log

# View webhook logs
tail -f /var/log/qrflow-webhook.log

# Check systemd service status
sudo systemctl status qrflow-auto-deploy.service
```

## 🔄 How It Works

### Automatic Deployment Process

1. **Cron Job** (every 5 minutes):
   - Checks for new commits on GitHub
   - If new commits found, triggers deployment

2. **Deployment Process**:
   - Creates backup of current code
   - Pulls latest changes from GitHub
   - Rebuilds backend container
   - Restarts backend service
   - Performs health checks
   - Logs all activities

3. **Health Checks**:
   - Backend container health
   - Nginx connectivity
   - QR code generation test

## 🌐 GitHub Webhook Integration (Optional)

### Step 1: Start Webhook Server
```bash
# Start webhook server (runs on port 8080)
python3 webhook-server.py &

# Or run as systemd service
sudo systemctl start qrflow-webhook
```

### Step 2: Configure GitHub Webhook
1. Go to your GitHub repository
2. Settings → Webhooks → Add webhook
3. Payload URL: `https://nyxgenai.com:8080/webhook`
4. Content type: `application/json`
5. Secret: `your_webhook_secret_here`
6. Events: Just the push event

### Step 3: Update Nginx Configuration
Add this to your nginx configuration:

```nginx
# Webhook endpoint
location /webhook {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## 📊 Monitoring and Logs

### Log Files
- **Deployment Logs**: `/var/log/qrflow-deploy.log`
- **Webhook Logs**: `/var/log/qrflow-webhook.log`
- **System Logs**: `sudo journalctl -u qrflow-auto-deploy.service`

### Health Checks
```bash
# Check if deployment system is running
sudo systemctl status qrflow-auto-deploy.service

# Check cron job
crontab -l

# Check recent deployments
tail -20 /var/log/qrflow-deploy.log
```

## 🔧 Configuration

### Environment Variables
```bash
# Webhook secret (change this!)
export WEBHOOK_SECRET="your_secure_webhook_secret"

# Project directory
export PROJECT_DIR="/home/ubuntu/qrflow-backend"
```

### Cron Job
The system uses a cron job that runs every 5 minutes:
```bash
*/5 * * * * cd /home/ubuntu/qrflow-backend && git fetch origin main && if [ $(git rev-parse HEAD) != $(git rev-parse origin/main) ]; then /home/ubuntu/qrflow-backend/deploy-auto.sh; fi
```

## 🚨 Troubleshooting

### Common Issues

#### 1. Deployment Fails
```bash
# Check deployment logs
tail -f /var/log/qrflow-deploy.log

# Check git status
cd /home/ubuntu/qrflow-backend
git status

# Manual deployment
./deploy-now.sh
```

#### 2. Webhook Not Working
```bash
# Check webhook server
ps aux | grep webhook-server

# Check webhook logs
tail -f /var/log/qrflow-webhook.log

# Test webhook manually
curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"ref": "refs/heads/main", "repository": {"name": "qrflow-backend"}}'
```

#### 3. Service Not Running
```bash
# Restart service
sudo systemctl restart qrflow-auto-deploy.service

# Check service status
sudo systemctl status qrflow-auto-deploy.service

# View service logs
sudo journalctl -u qrflow-auto-deploy.service -f
```

## 📋 Workflow

### Your Development Workflow

1. **Make changes locally**
2. **Commit and push to GitHub**:
   ```bash
   git add .
   git commit -m "Your changes"
   git push origin main
   ```

3. **Automatic deployment** (within 5 minutes):
   - System detects new commits
   - Pulls latest code
   - Rebuilds backend
   - Verifies deployment

4. **Check deployment status**:
   ```bash
   ./deploy-status.sh
   ```

## 🎯 Benefits

- ✅ **Zero Downtime**: Only rebuilds backend container
- ✅ **Automatic**: No manual intervention required
- ✅ **Safe**: Creates backups before each deployment
- ✅ **Monitored**: Comprehensive logging and health checks
- ✅ **Flexible**: Manual triggers available
- ✅ **Fast**: Deploys within 5 minutes of push

## 🔒 Security

- Webhook signature verification
- Secure secret management
- Backup creation before deployment
- Health checks after deployment
- Comprehensive logging

Your QRFlow backend will now automatically deploy whenever you push changes to GitHub! 🚀
