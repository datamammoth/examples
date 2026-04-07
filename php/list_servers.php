<?php
/**
 * List all servers with the DataMammoth PHP SDK.
 *
 * Usage:
 *   export DM_API_KEY="dm_live_..."
 *   php list_servers.php
 */

require_once __DIR__ . '/../../vendor/autoload.php';
// Or if installed via composer: require_once 'vendor/autoload.php';

use DataMammoth\DataMammoth;

$apiKey = getenv('DM_API_KEY');
if (!$apiKey) {
    fwrite(STDERR, "Error: Set the DM_API_KEY environment variable\n");
    exit(1);
}

$dm = new DataMammoth($apiKey);

// List servers with filters
$response = $dm->servers->list([
    'status' => 'running',
    'sort' => '-created_at',
    'per_page' => 20,
]);

$servers = $response['data'] ?? [];
$meta = $response['meta'] ?? [];
$pagination = $meta['pagination'] ?? $meta;

$page = $pagination['page'] ?? 1;
$totalPages = $pagination['total_pages'] ?? 1;
$total = $pagination['total'] ?? count($servers);

echo "Servers (page {$page}/{$totalPages}, total: {$total}):\n\n";

foreach ($servers as $server) {
    $icon = match ($server['status'] ?? '') {
        'running' => '[OK]',
        'stopped' => '[--]',
        'provisioning' => '[..]',
        'terminated' => '[XX]',
        default => '[??]',
    };

    echo "  {$icon} {$server['id']}\n";
    echo "      Hostname: " . ($server['hostname'] ?? '(none)') . "\n";
    echo "      IP:       " . ($server['ip_address'] ?? 'pending') . "\n";
    echo "      Region:   " . ($server['region'] ?? '') . "\n";
    echo "      Plan:     " . ($server['plan'] ?? '') . "\n\n";
}

// Auto-paginate through all servers
echo "--- All servers (all pages) ---\n";
foreach ($dm->servers->listAll(['status' => 'running']) as $server) {
    $id = $server['id'];
    $hostname = $server['hostname'] ?? '(none)';
    $status = $server['status'] ?? '';
    echo "  {$id}: {$hostname} ({$status})\n";
}
