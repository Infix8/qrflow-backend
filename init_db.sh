#!/bin/bash

echo "🚀 Initializing QrFlow Database..."

# Wait for database to be ready
echo "⏳ Waiting for database..."
sleep 5

# Run database initialization
docker-compose exec backend python init_db.py

echo "✅ Database tables created!"

# Create admin user
echo "👤 Creating admin user..."
docker-compose exec backend python create_admin.py

echo "🎉 QrFlow Backend is ready!"
echo ""
echo "Admin credentials:"
echo "  Username: admin"
echo "  Password: admin123"
echo ""
echo "API is running at: http://localhost:8000"
echo "API docs: http://localhost:8000/docs"
