<?php
// setup-node.php - Auto configure Node and Wings
echo "🖥️ Starting KevHost Node Auto-Setup...\n";

require __DIR__.'/bootstrap/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

use Pterodactyl\Models\User;
use Pterodactyl\Models\Node;
use Pterodactyl\Models\Location;
use Pterodactyl\Models\Allocation;

try {
    // Generate API Token untuk Wings
    echo "🔐 Generating API token for Wings...\n";
    $user = User::where('username', 'kevhost')->first();
    
    if (!$user) {
        echo "❌ KevHost user not found. Creating one...\n";
        $user = new User();
        $user->email = 'kevhost@kev.store';
        $user->username = 'kevhost';
        $user->name_first = 'Kev';
        $user->name_last = 'Host';
        $user->password = \Pterodactyl\Facades\Hash::make('kevhost@kev.store!');
        $user->root_admin = true;
        $user->save();
    }

    // Buat token API
    $token = $user->tokens()->create([
        'name' => 'Wings Authentication Token - KevHost',
        'abilities' => ['*'],
    ]);

    $apiKey = $token->plainTextToken;
    echo "✅ API Token generated: " . substr($apiKey, 0, 20) . "...\n";

    // Create Location jika belum ada
    $location = Location::firstOrCreate(
        ['short' => 'KEV'],
        [
            'short' => 'KEV',
            'long' => 'KevHost Main Datacenter'
        ]
    );
    echo "📍 Location created: {$location->long}\n";

    // Create atau Update Node
    $node = Node::updateOrCreate(
        ['id' => 1],
        [
            'name' => 'KevHost-Codespace',
            'description' => 'KevHost Main Server - GitHub Codespace',
            'location_id' => $location->id,
            'fqdn' => getenv('CODESPACE_NAME') ? getenv('CODESPACE_NAME') . '-8080.app.github.dev' : 'localhost',
            'scheme' => 'https',
            'behind_proxy' => false,
            'maintenance_mode' => false,
            'memory' => 8000, // 8GB
            'memory_overallocate' => 10, // 10% overallocate
            'disk' => 50000, // 50GB
            'disk_overallocate' => 10, // 10% overallocate
            'upload_size' => 100,
            'daemon_token_id' => 'kevhost-codespace-token',
            'daemon_token' => $apiKey,
            'daemonListen' => 8080,
            'daemonSFTP' => 2022,
            'daemonBase' => '/var/lib/pterodactyl/volumes',
        ]
    );
    echo "🖥️ Node configured: {$node->name}\n";

    // Create allocations untuk node
    $allocations = [
        ['ip' => '0.0.0.0', 'port' => 25565, 'notes' => 'Minecraft Default'],
        ['ip' => '0.0.0.0', 'port' => 25575, 'notes' => 'Minecraft RCON'],
        ['ip' => '0.0.0.0', 'port' => 7777, 'notes' => 'Rust'],
        ['ip' => '0.0.0.0', 'port' => 27015, 'notes' => 'CS:GO'],
        ['ip' => '0.0.0.0', 'port' => 2302, 'notes' => 'SAMP'],
        ['ip' => '0.0.0.0', 'port' => 8211, 'notes' => 'FiveM'],
        ['ip' => '0.0.0.0', 'port' => 16261, 'notes' => 'PocketMine'],
    ];

    foreach ($allocations as $alloc) {
        Allocation::firstOrCreate(
            [
                'node_id' => $node->id,
                'ip' => $alloc['ip'],
                'port' => $alloc['port']
            ],
            [
                'node_id' => $node->id,
                'ip' => $alloc['ip'],
                'port' => $alloc['port'],
                'notes' => $alloc['notes']
            ]
        );
    }
    echo "🔌 Allocations created for various games\n";

    // Update .env wings dengan API key yang benar
    $wingsEnvPath = '/etc/pterodactyl/.env';
    $wingsEnvContent = "
# KevHost Wings Configuration - Auto Generated
APP_URL=https://" . (getenv('CODESPACE_NAME') ?: 'localhost') . "-80.app.github.dev
API_HOST=https://" . (getenv('CODESPACE_NAME') ?: 'localhost') . "-80.app.github.dev
AUTHENTICATION_TOKEN={$apiKey}
NODE_ID=1
";

    file_put_contents($wingsEnvPath, $wingsEnvContent);
    echo "📁 Wings environment file updated\n";

    echo "🎉 Node setup completed successfully!\n";
    echo "📋 Node Info:\n";
    echo "   Name: {$node->name}\n";
    echo "   FQDN: {$node->fqdn}\n";
    echo "   Memory: {$node->memory}MB\n";
    echo "   Disk: {$node->disk}MB\n";
    echo "   Allocations: " . count($allocations) . " ports\n";

} catch (Exception $e) {
    echo "❌ Node setup failed: " . $e->getMessage() . "\n";
    exit(1);
}
?>
