#!/usr/bin/env npx ts-node
/**
 * List all servers with filtering and pagination.
 *
 * Usage:
 *   export DM_API_KEY="dm_live_..."
 *   npx ts-node list_servers.ts
 */

import { DataMammoth } from "@datamammoth/sdk";

async function main() {
  const apiKey = process.env.DM_API_KEY;
  if (!apiKey) {
    console.error("Error: Set the DM_API_KEY environment variable");
    process.exit(1);
  }

  const dm = new DataMammoth(apiKey);

  // List servers with optional filters
  const response = await dm.servers.list({
    status: "running",
    sort: "-created_at",
    per_page: 20,
  });

  const { data: servers, meta } = response;

  console.log(
    `Servers (page ${meta.page}/${meta.total_pages}, total: ${meta.total}):\n`
  );

  for (const server of servers) {
    const icon =
      {
        running: "[OK]",
        stopped: "[--]",
        provisioning: "[..]",
        terminated: "[XX]",
      }[server.status] ?? "[??]";

    console.log(`  ${icon} ${server.id}`);
    console.log(`      Hostname: ${server.hostname ?? "(none)"}`);
    console.log(`      IP:       ${server.ip_address ?? "pending"}`);
    console.log(`      Region:   ${server.region}`);
    console.log(`      Plan:     ${server.plan}`);
    console.log();
  }

  // Auto-paginate through all servers
  console.log("--- All servers (all pages) ---");
  for await (const server of dm.servers.listAll({ status: "running" })) {
    console.log(`  ${server.id}: ${server.hostname} (${server.status})`);
  }
}

main().catch(console.error);
