#!/usr/bin/env python3
"""
Simple webhook server for GitHub integration
This server listens for GitHub webhooks and triggers deployment
"""

import os
import json
import hmac
import hashlib
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
import subprocess
import threading

# Configuration
WEBHOOK_SECRET = "your_webhook_secret_here"  # Change this to a secure secret
PROJECT_DIR = os.getcwd()
LOG_FILE = os.path.join(PROJECT_DIR, "logs", "webhook.log")

def log_message(message):
    """Log message to file"""
    with open(LOG_FILE, "a") as f:
        f.write(f"{message}\n")

def verify_signature(payload, signature):
    """Verify GitHub webhook signature"""
    if not signature:
        return False
    
    # Remove 'sha256=' prefix if present
    if signature.startswith('sha256='):
        signature = signature[7:]
    
    # Create expected signature
    expected_signature = hmac.new(
        WEBHOOK_SECRET.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(signature, expected_signature)

def trigger_deployment():
    """Trigger deployment in background"""
    def deploy():
        try:
            log_message("Starting deployment triggered by webhook")
            result = subprocess.run(
                [f"{PROJECT_DIR}/deploy-auto.sh"],
                cwd=PROJECT_DIR,
                capture_output=True,
                text=True
            )
            log_message(f"Deployment completed with exit code: {result.returncode}")
            if result.stdout:
                log_message(f"Deployment stdout: {result.stdout}")
            if result.stderr:
                log_message(f"Deployment stderr: {result.stderr}")
        except Exception as e:
            log_message(f"Deployment failed: {str(e)}")
    
    # Run deployment in background thread
    thread = threading.Thread(target=deploy)
    thread.daemon = True
    thread.start()

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        """Handle POST requests from GitHub"""
        try:
            # Get content length
            content_length = int(self.headers.get('Content-Length', 0))
            
            # Read payload
            payload = self.rfile.read(content_length)
            
            # Get signature
            signature = self.headers.get('X-Hub-Signature-256', '')
            
            # Verify signature
            if not verify_signature(payload, signature):
                log_message("Invalid webhook signature")
                self.send_response(401)
                self.end_headers()
                self.wfile.write(b'Unauthorized')
                return
            
            # Parse JSON payload
            try:
                data = json.loads(payload.decode('utf-8'))
            except json.JSONDecodeError:
                log_message("Invalid JSON payload")
                self.send_response(400)
                self.end_headers()
                self.wfile.write(b'Invalid JSON')
                return
            
            # Check if it's a push to main branch
            if (data.get('ref') == 'refs/heads/main' and 
                data.get('repository', {}).get('name') == 'qrflow-backend'):
                
                log_message("GitHub webhook received for main branch push")
                trigger_deployment()
                
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'Deployment triggered')
            else:
                log_message("Webhook received but not for main branch")
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b'Webhook received')
                
        except Exception as e:
            log_message(f"Webhook error: {str(e)}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(b'Internal Server Error')
    
    def do_GET(self):
        """Handle GET requests (health check)"""
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'QRFlow Webhook Server is running')
    
    def log_message(self, format, *args):
        """Override to use our custom logging"""
        log_message(f"Webhook: {format % args}")

def main():
    """Start the webhook server"""
    port = 8080
    server = HTTPServer(('0.0.0.0', port), WebhookHandler)
    
    log_message(f"Starting webhook server on port {port}")
    print(f"Webhook server starting on port {port}")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log_message("Webhook server stopped")
        server.shutdown()

if __name__ == '__main__':
    main()
