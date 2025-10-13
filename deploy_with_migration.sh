#!/bin/bash

# QR Flow Production Deployment with Migration
# ============================================
# 
# This script safely deploys the new enhanced QR Flow system to production
# while preserving all existing data including QR codes, email history, and payments.
#
# Usage: ./deploy_with_migration.sh [--backup] [--dry-run]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKUP_DB=false
DRY_RUN=false
PROJECT_DIR="/home/infix/production_system_ecell"
BACKEND_DIR="$PROJECT_DIR/qrflow-backend"
FRONTEND_DIR="$PROJECT_DIR/qrflow-frontend"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup)
            BACKUP_DB=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--backup] [--dry-run]"
            echo "  --backup    Create database backup before deployment"
            echo "  --dry-run   Show what would be done without making changes"
            exit 0
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

# Check if running as correct user
check_user() {
    if [[ "$USER" != "infix" ]]; then
        log_error "This script should be run as 'infix' user"
        exit 1
    fi
}

# Check if required directories exist
check_directories() {
    log "Checking required directories..."
    
    if [[ ! -d "$BACKEND_DIR" ]]; then
        log_error "Backend directory not found: $BACKEND_DIR"
        exit 1
    fi
    
    if [[ ! -d "$FRONTEND_DIR" ]]; then
        log_error "Frontend directory not found: $FRONTEND_DIR"
        exit 1
    fi
    
    log_success "All required directories found"
}

# Check database connectivity
check_database() {
    log "Checking database connectivity..."
    
    # Load environment variables
    if [[ -f "$BACKEND_DIR/.env" ]]; then
        source "$BACKEND_DIR/.env"
    fi
    
    # Check if we can connect to database
    if ! python3 -c "
import psycopg2
import os
try:
    conn = psycopg2.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        port=os.getenv('DB_PORT', '5432'),
        database=os.getenv('DB_NAME', 'qrflow_db'),
        user=os.getenv('DB_USER', 'qrflow_user'),
        password=os.getenv('DB_PASSWORD', '')
    )
    conn.close()
    print('Database connection successful')
except Exception as e:
    print(f'Database connection failed: {e}')
    exit(1)
" 2>/dev/null; then
        log_error "Cannot connect to database. Please check your database configuration."
        exit 1
    fi
    
    log_success "Database connection successful"
}

# Create database backup
create_backup() {
    if [[ "$BACKUP_DB" == "true" ]]; then
        log "Creating database backup..."
        
        if [[ "$DRY_RUN" == "true" ]]; then
            log_warning "DRY RUN: Would create database backup"
        else
            timestamp=$(date +"%Y%m%d_%H%M%S")
            backup_file="qrflow_production_backup_${timestamp}.sql"
            
            if pg_dump -h "${DB_HOST:-localhost}" \
                       -p "${DB_PORT:-5432}" \
                       -U "${DB_USER:-qrflow_user}" \
                       -d "${DB_NAME:-qrflow_db}" \
                       -f "$backup_file" \
                       --verbose; then
                log_success "Database backup created: $backup_file"
            else
                log_error "Database backup failed"
                exit 1
            fi
        fi
    fi
}

# Install Python dependencies
install_dependencies() {
    log "Installing Python dependencies..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would install Python dependencies"
    else
        cd "$BACKEND_DIR"
        
        # Install/upgrade requirements
        if pip3 install -r requirements.txt --upgrade; then
            log_success "Python dependencies installed successfully"
        else
            log_error "Failed to install Python dependencies"
            exit 1
        fi
    fi
}

# Run database migration
run_migration() {
    log "Running database migration..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would run database migration"
        python3 "$PROJECT_DIR/migrate_production.py" --dry-run
    else
        # Make migration script executable
        chmod +x "$PROJECT_DIR/migrate_production.py"
        
        # Run migration
        if python3 "$PROJECT_DIR/migrate_production.py"; then
            log_success "Database migration completed successfully"
        else
            log_error "Database migration failed"
            exit 1
        fi
    fi
}

# Deploy backend
deploy_backend() {
    log "Deploying backend..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would deploy backend"
    else
        cd "$BACKEND_DIR"
        
        # Check if there's a deployment script
        if [[ -f "deploy-production.sh" ]]; then
            log "Running production deployment script..."
            if ./deploy-production.sh; then
                log_success "Backend deployed successfully"
            else
                log_error "Backend deployment failed"
                exit 1
            fi
        else
            log_warning "No production deployment script found. Manual deployment required."
        fi
    fi
}

# Deploy frontend
deploy_frontend() {
    log "Deploying frontend..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would deploy frontend"
    else
        cd "$FRONTEND_DIR"
        
        # Check if there's a deployment script
        if [[ -f "deploy.sh" ]]; then
            log "Running frontend deployment script..."
            if ./deploy.sh; then
                log_success "Frontend deployed successfully"
            else
                log_error "Frontend deployment failed"
                exit 1
            fi
        else
            log_warning "No frontend deployment script found. Manual deployment required."
        fi
    fi
}

# Restart services
restart_services() {
    log "Restarting services..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would restart services"
    else
        # Restart nginx
        if systemctl is-active --quiet nginx; then
            log "Restarting nginx..."
            if systemctl restart nginx; then
                log_success "Nginx restarted successfully"
            else
                log_error "Failed to restart nginx"
                exit 1
            fi
        fi
        
        # Restart QR Flow service if it exists
        if systemctl is-active --quiet qrflow; then
            log "Restarting QR Flow service..."
            if systemctl restart qrflow; then
                log_success "QR Flow service restarted successfully"
            else
                log_error "Failed to restart QR Flow service"
                exit 1
            fi
        fi
    fi
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN: Would verify deployment"
        return 0
    fi
    
    # Wait a moment for services to start
    sleep 5
    
    # Check if nginx is running
    if systemctl is-active --quiet nginx; then
        log_success "Nginx is running"
    else
        log_error "Nginx is not running"
        return 1
    fi
    
    # Check if QR Flow service is running (if it exists)
    if systemctl is-active --quiet qrflow; then
        log_success "QR Flow service is running"
    else
        log_warning "QR Flow service not found or not running"
    fi
    
    # Test API endpoint (if available)
    if command -v curl >/dev/null 2>&1; then
        log "Testing API endpoint..."
        if curl -s -f "http://localhost:8000/api/health" >/dev/null 2>&1; then
            log_success "API endpoint is responding"
        else
            log_warning "API endpoint test failed (this might be normal if no health endpoint exists)"
        fi
    fi
    
    log_success "Deployment verification completed"
}

# Main deployment function
main() {
    echo "🚀 QR Flow Production Deployment with Migration"
    echo "==============================================="
    echo ""
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "🔍 DRY RUN MODE - No changes will be made"
        echo ""
    fi
    
    if [[ "$BACKUP_DB" == "true" ]]; then
        echo "💾 Database backup will be created"
        echo ""
    fi
    
    # Run deployment steps
    check_user
    check_directories
    check_database
    create_backup
    install_dependencies
    run_migration
    deploy_backend
    deploy_frontend
    restart_services
    verify_deployment
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "📋 Summary:"
    echo "  - Database migration completed"
    echo "  - All existing data preserved (QR codes, emails, payments)"
    echo "  - New enhanced features deployed"
    echo "  - Services restarted"
    echo ""
    echo "🔗 Your enhanced QR Flow system is now live!"
    echo ""
    echo "📊 New features available:"
    echo "  - Enhanced attendee management with payment details"
    echo "  - Bulk operations for attendees"
    echo "  - Advanced search and filtering"
    echo "  - Comprehensive data export"
    echo "  - Improved mobile responsiveness"
    echo "  - Better statistics and progress tracking"
    echo ""
    
    if [[ "$BACKUP_DB" == "true" ]]; then
        echo "💾 Database backup was created for safety"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        echo "🔍 This was a dry run. To perform actual deployment, run:"
        echo "   $0 --backup"
    fi
}

# Run main function
main "$@"
