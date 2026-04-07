#!/usr/bin/env bash
# DataMammoth API v2 — List servers with curl
#
# Usage:
#   export DM_API_KEY="dm_live_..."
#   bash list_servers.sh
#   bash list_servers.sh --status running --region EU

set -euo pipefail

API_KEY="${DM_API_KEY:?Error: Set the DM_API_KEY environment variable}"
BASE_URL="${DM_BASE_URL:-https://app.datamammoth.com/api/v2}"

# Parse optional arguments
QUERY=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --status)  QUERY="${QUERY}&status=$2";   shift 2;;
    --region)  QUERY="${QUERY}&region=$2";   shift 2;;
    --search)  QUERY="${QUERY}&search=$2";   shift 2;;
    --page)    QUERY="${QUERY}&page=$2";     shift 2;;
    --per-page) QUERY="${QUERY}&per_page=$2"; shift 2;;
    --sort)    QUERY="${QUERY}&sort=$2";     shift 2;;
    *) echo "Unknown option: $1"; exit 1;;
  esac
done

# Remove leading &
QUERY="${QUERY#&}"

echo "=== List Servers ==="
echo "  URL: ${BASE_URL}/servers?${QUERY}"
echo ""

curl -s \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Accept: application/json" \
  "${BASE_URL}/servers?${QUERY}" | jq '{
    meta: {
      page: .meta.pagination.page,
      total_pages: .meta.pagination.total_pages,
      total: .meta.pagination.total
    },
    servers: [.data[] | {
      id,
      hostname,
      status,
      ip_address,
      region,
      plan
    }]
  }'
