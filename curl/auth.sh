#!/usr/bin/env bash
# DataMammoth API v2 — Authentication examples
#
# Usage:
#   export DM_API_KEY="dm_live_..."
#   bash auth.sh

set -euo pipefail

API_KEY="${DM_API_KEY:?Error: Set the DM_API_KEY environment variable}"
BASE_URL="${DM_BASE_URL:-https://app.datamammoth.com/api/v2}"

echo "=== Test authentication ==="
echo ""

# 1. Verify credentials by calling /me
echo "1. GET /me — verify your API key"
curl -s -w "\n  HTTP %{http_code}\n" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Accept: application/json" \
  "${BASE_URL}/me" | jq '{ id: .data.id, email: .data.email, name: .data.name }'

echo ""

# 2. List your API keys
echo "2. GET /me/api-keys — list API keys"
curl -s -w "\n  HTTP %{http_code}\n" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Accept: application/json" \
  "${BASE_URL}/me/api-keys" | jq '.data[] | { id, name, scopes, created_at }'

echo ""

# 3. Create a new scoped API key
echo "3. POST /me/api-keys — create a read-only key"
curl -s -w "\n  HTTP %{http_code}\n" \
  -X POST \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "name": "read-only-key",
    "scopes": ["servers.read", "products.read"]
  }' \
  "${BASE_URL}/me/api-keys" | jq '{ id: .data.id, key: .data.key, scopes: .data.scopes }'

echo ""
echo "=== Done ==="
