#!/bin/bash

set -e

echo "🚀 KevHost Pterodactyl Complete Auto-Setup"
echo "============================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Make scripts executable
chmod +x *.sh

# Create necessary directories
echo "📁 Creating directories..."
sudo mkdir -p /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl
sudo chown -R 998:998 /etc/pterodactyl /var/lib/pterodactyl /var/log/pterodactyl 2>/dev/null || true

# Start services
echo "🐳 Starting Docker containers..."
docker-compose down > /dev/null 2>&1 || true
docker-compose up -d

# Wait for services
echo "⏳ Waiting for services to be ready (this may take 3-5 minutes)..."
sleep 30

# Initialize database
echo "🗃️ Initializing database..."
./init-database.sh

# Setup panel
echo "🔄 Setting up panel..."
./setup-panel.sh

# Create admin user
echo "👤 Creating admin user..."
./create-admin.sh

# Setup node and configure Wings
echo "🖥️ Setting up node and Wings configuration..."
./configure-wings.sh

# Final check
echo "🔍 Final health check..."
if curl -f http://localhost:80 > /dev/null 2>&1; then
    echo "🎉 KevHost Pterodactyl is fully ready!"
    echo ""
    echo "🌐 Panel URL: https://${CODESPACE_NAME}-80.app.github.dev"
    echo "👤 Username: kevhost" 
    echo "🔑 Password: kevhost@kev.store!"
    echo ""
    echo "🖥️ Node Information:"
    echo "   Name: KevHost-Codespace"
    echo "   Location: KevHost Main Datacenter" 
    echo "   Memory: 8GB | Disk: 50GB"
    echo "   Wings API: https://${CODESPACE_NAME}-8080.app.github.dev"
    echo ""
    echo "🎮 Game ports ready: 25565 (Minecraft), 7777 (Rust), 27015 (CS:GO), etc."
    echo ""
    echo "🛠️ Management Commands:"
    echo "   docker-compose logs -f panel     # View panel logs"
    echo "   docker-compose logs -f wings     # View wings logs" 
    echo "   ./health-check.sh                # System status"
else
    echo "❌ Setup completed but panel is not accessible. Check logs with: docker-compose logs panel"
    exit 1
fi
