#!/bin/bash

set -e

echo "🔧 Configuring Wings with Panel..."

# Tunggu panel ready
for i in {1..30}; do
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        echo "✅ Panel is ready for Wings configuration"
        break
    fi
    echo "⏳ Waiting for panel... ($i/30)"
    sleep 3
done

# Jalankan script setup node di panel
echo "🖥️ Setting up node configuration..."
docker-compose exec -T panel php /app/setup-node.php

# Dapatkan API key dari output atau generate ulang
echo "🔐 Getting API token..."
API_TOKEN=$(docker-compose exec -T panel php artisan p:user:token --username=kevhost --name=Wings_Auto_Token | grep -o '|[[:space:]]*[a-zA-Z0-9]*[[:space:]]*|' | tr -d '| ' | head -1)

if [ -z "$API_TOKEN" ]; then
    # Alternative method - buat token via artisan
    API_TOKEN=$(docker-compose exec -T panel bash -c "php artisan tinker --execute=\"echo \Pterodactyl\Models\User::where('username', 'kevhost')->first()->tokens()->create(['name' => 'Wings_Auto'])->plainTextToken;\"")
fi

if [ -n "$API_TOKEN" ]; then
    echo "✅ API Token obtained"
    
    # Configure Wings
    echo "⚙️ Configuring Wings..."
    docker-compose exec -T wings wings configure --panel-url "https://${CODESPACE_NAME}-80.app.github.dev" --token "$API_TOKEN" --node-id 1 --override
    
    # Restart Wings
    echo "🔄 Restarting Wings..."
    docker-compose restart wings
    
    echo "✅ Wings configured successfully!"
else
    echo "❌ Failed to get API token"
    exit 1
fi
