#!/usr/bin/env python3
"""
Create a new VPS server and wait for provisioning to complete.

Usage:
    export DM_API_KEY="dm_live_..."
    python create_server.py
"""

import os
import sys

from datamammoth import DataMammoth

def main():
    api_key = os.environ.get("DM_API_KEY")
    if not api_key:
        print("Error: Set the DM_API_KEY environment variable", file=sys.stderr)
        sys.exit(1)

    dm = DataMammoth(api_key=api_key)

    # Step 1: Browse available products
    print("Available products:")
    products = dm.products.list(per_page=5)
    for p in products.data:
        print(f"  {p.id}: {p.name} ({p.type})")

    # Step 2: Get zones and images
    zones = dm.zones.list()
    zone = zones.data[0]  # Pick first zone
    print(f"\nUsing zone: {zone.name} ({zone.id})")

    images = dm.zones.images(zone.id)
    image = images.data[0]  # Pick first image
    print(f"Using image: {image.name} ({image.id})")

    # Step 3: Create the server (returns 202 Accepted with task ID)
    print("\nProvisioning server...")
    result = dm.servers.create(
        product_id=products.data[0].id,
        zone_id=zone.id,
        image_id=image.id,
        hostname="demo-server.example.com",
        label="Demo Server",
    )

    task_id = result.task_id
    print(f"Task created: {task_id}")

    # Step 4: Poll the task until it completes
    print("Waiting for provisioning...")
    task = dm.tasks.await_task(task_id, interval=3.0, timeout=300.0)

    if task.status == "completed":
        server_id = task.result.get("server_id")
        ip = task.result.get("ip_address")
        print(f"\nServer provisioned successfully!")
        print(f"  Server ID: {server_id}")
        print(f"  IP Address: {ip}")

        # Step 5: Get full server details
        server = dm.servers.get(server_id)
        print(f"  Hostname: {server.data.hostname}")
        print(f"  Status:   {server.data.status}")
    else:
        print(f"\nProvisioning failed: {task.error}")
        sys.exit(1)


if __name__ == "__main__":
    main()
