#!/usr/bin/env npx ts-node
/**
 * Create a new VPS server and wait for provisioning to complete.
 *
 * Usage:
 *   export DM_API_KEY="dm_live_..."
 *   npx ts-node create_server.ts
 */

import { DataMammoth } from "@datamammoth/sdk";

async function main() {
  const apiKey = process.env.DM_API_KEY;
  if (!apiKey) {
    console.error("Error: Set the DM_API_KEY environment variable");
    process.exit(1);
  }

  const dm = new DataMammoth(apiKey);

  // Step 1: Browse available products
  console.log("Available products:");
  const { data: products } = await dm.products.list({ per_page: 5 });
  for (const p of products) {
    console.log(`  ${p.id}: ${p.name} (${p.type})`);
  }

  // Step 2: Get zones and images
  const { data: zones } = await dm.zones.list();
  const zone = zones[0];
  console.log(`\nUsing zone: ${zone.name} (${zone.id})`);

  const { data: images } = await dm.zones.images(zone.id);
  const image = images[0];
  console.log(`Using image: ${image.name} (${image.id})`);

  // Step 3: Create the server (202 Accepted with task ID)
  console.log("\nProvisioning server...");
  const result = await dm.servers.create({
    product_id: products[0].id,
    zone_id: zone.id,
    image_id: image.id,
    hostname: "demo-server.example.com",
    label: "Demo Server",
  });

  const taskId = result.task_id;
  console.log(`Task created: ${taskId}`);

  // Step 4: Poll the task until it completes
  console.log("Waiting for provisioning...");
  const task = await dm.tasks.await(taskId, {
    interval: 3000,
    timeout: 300_000,
  });

  if (task.status === "completed") {
    const { server_id, ip_address } = task.result;
    console.log(`\nServer provisioned successfully!`);
    console.log(`  Server ID: ${server_id}`);
    console.log(`  IP Address: ${ip_address}`);

    // Step 5: Get full server details
    const { data: server } = await dm.servers.get(server_id);
    console.log(`  Hostname: ${server.hostname}`);
    console.log(`  Status:   ${server.status}`);
  } else {
    console.error(`\nProvisioning failed: ${task.error}`);
    process.exit(1);
  }
}

main().catch(console.error);
