<?php
/**
 * Create a new VPS server and wait for provisioning.
 *
 * Usage:
 *   export DM_API_KEY="dm_live_..."
 *   php create_server.php
 */

require_once __DIR__ . '/../../vendor/autoload.php';

use DataMammoth\DataMammoth;

$apiKey = getenv('DM_API_KEY');
if (!$apiKey) {
    fwrite(STDERR, "Error: Set the DM_API_KEY environment variable\n");
    exit(1);
}

$dm = new DataMammoth($apiKey);

// Step 1: Browse available products
echo "Available products:\n";
$products = $dm->products->list(['per_page' => 5]);
foreach ($products['data'] as $p) {
    echo "  {$p['id']}: {$p['name']} ({$p['type']})\n";
}

// Step 2: Get zones and images
$zones = $dm->zones->list();
$zone = $zones['data'][0];
echo "\nUsing zone: {$zone['name']} ({$zone['id']})\n";

$images = $dm->zones->listImages($zone['id']);
$image = $images['data'][0];
echo "Using image: {$image['name']} ({$image['id']})\n";

// Step 3: Create the server (202 Accepted with task ID)
echo "\nProvisioning server...\n";
$result = $dm->servers->create([
    'product_id' => $products['data'][0]['id'],
    'zone_id' => $zone['id'],
    'image_id' => $image['id'],
    'hostname' => 'demo-server.example.com',
    'label' => 'Demo Server',
]);

$taskId = $result['data']['task_id'] ?? $result['task_id'] ?? '';
echo "Task created: {$taskId}\n";

// Step 4: Poll the task until it completes
echo "Waiting for provisioning...\n";
$task = $dm->tasks->await($taskId, intervalMs: 3000, timeoutMs: 300000);
$taskData = $task['data'] ?? $task;

if (($taskData['status'] ?? '') === 'completed') {
    $serverId = $taskData['result']['server_id'] ?? '';
    $ip = $taskData['result']['ip_address'] ?? '';
    echo "\nServer provisioned successfully!\n";
    echo "  Server ID: {$serverId}\n";
    echo "  IP Address: {$ip}\n";

    // Step 5: Get full server details
    $server = $dm->servers->get($serverId);
    $s = $server['data'];
    echo "  Hostname: {$s['hostname']}\n";
    echo "  Status:   {$s['status']}\n";
} else {
    $error = $taskData['error'] ?? 'Unknown error';
    fwrite(STDERR, "\nProvisioning failed: {$error}\n");
    exit(1);
}
