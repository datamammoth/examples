#!/usr/bin/env python3
"""
List all servers with filtering and pagination.

Usage:
    export DM_API_KEY="dm_live_..."
    python list_servers.py
    python list_servers.py --status running --region EU
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

    # Parse optional CLI filters
    params = {}
    args = sys.argv[1:]
    while args:
        if args[0] == "--status" and len(args) > 1:
            params["status"] = args[1]
            args = args[2:]
        elif args[0] == "--region" and len(args) > 1:
            params["region"] = args[1]
            args = args[2:]
        else:
            args = args[1:]

    # List servers (first page)
    response = dm.servers.list(**params)

    servers = response.data
    meta = response.meta

    print(f"Servers (page {meta.page}/{meta.total_pages}, total: {meta.total}):\n")

    for server in servers:
        status_icon = {
            "running": "[OK]",
            "stopped": "[--]",
            "provisioning": "[..]",
            "terminated": "[XX]",
        }.get(server.status, "[??]")

        print(f"  {status_icon} {server.id}")
        print(f"      Hostname: {server.hostname or '(none)'}")
        print(f"      IP:       {server.ip_address or 'pending'}")
        print(f"      Region:   {server.region}")
        print(f"      Plan:     {server.plan}")
        print()

    # Iterate all pages (auto-pagination)
    print("--- All servers (all pages) ---")
    for server in dm.servers.list_all(**params):
        print(f"  {server.id}: {server.hostname} ({server.status})")


if __name__ == "__main__":
    main()
