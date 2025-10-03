#!/bin/bash

echo "🚀 QrFlow Backend - Quick Start"
echo "================================"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "📝 Creating from .env.example..."
    cp .env.example .env
    echo "⚠️  Please edit .env with your configuration:"
    echo "   nano .env"
    echo ""
    echo "Important: Set secure passwords and secret keys!"
    exit 1
fi

echo "✓ Environment file found"
echo ""

echo "🐳 Starting Docker containers..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 15

echo ""
echo "🗄️  Initializing database..."
docker-compose exec backend python init_db.py

echo ""
echo "👤 Creating admin user..."
docker-compose exec backend python create_admin.py

echo ""
echo "✅ QrFlow Backend is ready!"
echo ""
echo "📍 API: http://localhost:8000"
echo "📚 Docs: http://localhost:8000/docs"
echo "🏥 Health: http://localhost:8000/health"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "⚠️  IMPORTANT: Change admin password immediately!"
echo ""
echo "Useful commands:"
echo "  docker-compose logs -f    # View logs"
echo "  docker-compose ps         # Check status"
echo "  docker-compose down       # Stop services"
