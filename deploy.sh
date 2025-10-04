#!/bin/bash

# QrFlow Backend Deployment Script
# This script handles the deployment process for AWS EC2

set -e

echo "🚀 Starting QrFlow Backend Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed."
    exit 1
fi

# Check if .env file exists
if [ ! -f .env ]; then
    print_warning ".env file not found. Creating from .env.example..."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_warning "Please edit .env file with your production values before continuing."
        exit 1
    else
        print_error ".env.example file not found. Please create environment configuration."
        exit 1
    fi
fi

print_status "Stopping existing containers..."
docker-compose down

print_status "Pulling latest images..."
docker-compose pull

print_status "Building and starting services..."
docker-compose up -d --build

print_status "Waiting for services to be healthy..."
sleep 30

# Check if services are running
if docker-compose ps | grep -q "Up"; then
    print_status "Services are running successfully!"
    
    # Initialize database if needed
    print_status "Initializing database..."
    docker-compose exec -T backend python init_db.py || print_warning "Database initialization may have failed"
    
    # Create admin user if needed
    print_status "Creating admin user..."
    docker-compose exec -T backend python create_admin.py || print_warning "Admin user creation may have failed"
    
    # Health check
    print_status "Performing health check..."
    if curl -f http://localhost:8000/health > /dev/null 2>&1; then
        print_status "✅ Health check passed!"
        print_status "🚀 Deployment completed successfully!"
        print_status "API is available at: http://localhost:8000"
        print_status "API Documentation: http://localhost:8000/docs"
    else
        print_error "Health check failed. Check logs with: docker-compose logs"
        exit 1
    fi
else
    print_error "Services failed to start. Check logs with: docker-compose logs"
    exit 1
fi

print_status "Deployment completed! 🎉"
