#!/bin/bash

echo "🔗 Testing Panel-Wings Connection..."

# Test panel accessibility
echo "🌐 Testing Panel..."
if curl -f "https://${CODESPACE_NAME}-80.app.github.dev" > /dev/null 2>&1; then
    echo "✅ Panel is accessible"
else
    echo "❌ Panel is not accessible"
fi

# Test wings API
echo "🖥️ Testing Wings API..."
if curl -f "https://${CODESPACE_NAME}-8080.app.github.dev/api/system" > /dev/null 2>&1; then
    echo "✅ Wings API is accessible"
else
    echo "❌ Wings API is not accessible"
fi

# Check node status in panel
echo "📊 Checking node status..."
docker-compose exec -T panel php artisan tinker --execute="
    try {
        \$node = \Pterodactyl\Models\Node::find(1);
        if (\$node) {
            echo '✅ Node found: ' . \$node->name . PHP_EOL;
            echo '   FQDN: ' . \$node->fqdn . PHP_EOL;
            echo '   Memory: ' . \$node->memory . 'MB' . PHP_EOL;
            echo '   Disk: ' . \$node->disk . 'MB' . PHP_EOL;
        } else {
            echo '❌ Node not found' . PHP_EOL;
        }
    } catch (Exception \$e) {
        echo '❌ Error checking node: ' . \$e->getMessage() . PHP_EOL;
    }
"
