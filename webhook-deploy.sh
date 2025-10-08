#!/bin/bash

# GitHub Webhook Deployment Script
# This script is triggered by GitHub webhooks for automatic deployment

set -e

# Configuration
PROJECT_DIR="$(pwd)"
WEBHOOK_SECRET="your_webhook_secret_here"  # Change this to a secure secret
LOG_FILE="$(pwd)/logs/webhook.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> $LOG_FILE
}

log_message "Webhook triggered - starting deployment"

# Change to project directory
cd $PROJECT_DIR

# Run the deployment script
./deploy-auto.sh

log_message "Webhook deployment completed"
