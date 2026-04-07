#!/usr/bin/env bash
# DataMammoth API v2 — Create a server with curl and poll until ready
#
# Usage:
#   export DM_API_KEY="dm_live_..."
#   bash create_server.sh <product_id> <zone_id> <image_id> [hostname]
#
# Example:
#   bash create_server.sh prod_vps_4core zone_eu_1 ubuntu-24.04 web-1.example.com

set -euo pipefail

API_KEY="${DM_API_KEY:?Error: Set the DM_API_KEY environment variable}"
BASE_URL="${DM_BASE_URL:-https://app.datamammoth.com/api/v2}"

PRODUCT_ID="${1:?Usage: create_server.sh <product_id> <zone_id> <image_id> [hostname]}"
ZONE_ID="${2:?Usage: create_server.sh <product_id> <zone_id> <image_id> [hostname]}"
IMAGE_ID="${3:?Usage: create_server.sh <product_id> <zone_id> <image_id> [hostname]}"
HOSTNAME="${4:-}"

echo "=== Create Server ==="
echo "  Product: ${PRODUCT_ID}"
echo "  Zone:    ${ZONE_ID}"
echo "  Image:   ${IMAGE_ID}"
echo "  Host:    ${HOSTNAME:-'(auto)'}"
echo ""

# Step 1: Create the server (returns 202 with task_id)
BODY=$(jq -n \
  --arg product_id "$PRODUCT_ID" \
  --arg zone_id "$ZONE_ID" \
  --arg image_id "$IMAGE_ID" \
  --arg hostname "$HOSTNAME" \
  '{
    product_id: $product_id,
    zone_id: $zone_id,
    image_id: $image_id
  } + (if $hostname != "" then { hostname: $hostname } else {} end)')

echo "Sending create request..."
RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$BODY" \
  "${BASE_URL}/servers")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY_JSON=$(echo "$RESPONSE" | sed '$d')

echo "  HTTP ${HTTP_CODE}"

if [[ "$HTTP_CODE" != "202" && "$HTTP_CODE" != "201" ]]; then
  echo "Error: Unexpected response"
  echo "$BODY_JSON" | jq .
  exit 1
fi

TASK_ID=$(echo "$BODY_JSON" | jq -r '.data.task_id // .task_id // empty')
echo "  Task ID: ${TASK_ID}"
echo ""

# Step 2: Poll the task until it completes
echo "Polling task status..."
MAX_ATTEMPTS=60
ATTEMPT=0

while [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
  TASK=$(curl -s \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Accept: application/json" \
    "${BASE_URL}/tasks/${TASK_ID}")

  STATUS=$(echo "$TASK" | jq -r '.data.status // "unknown"')
  echo "  [attempt $((ATTEMPT + 1))/${MAX_ATTEMPTS}] Status: ${STATUS}"

  if [[ "$STATUS" == "completed" ]]; then
    echo ""
    echo "=== Server Provisioned ==="
    echo "$TASK" | jq '{
      server_id: .data.result.server_id,
      ip_address: .data.result.ip_address
    }'
    exit 0
  fi

  if [[ "$STATUS" == "failed" ]]; then
    echo ""
    echo "=== Provisioning Failed ==="
    echo "$TASK" | jq '.data.error'
    exit 1
  fi

  ATTEMPT=$((ATTEMPT + 1))
  sleep 5
done

echo "Error: Timed out waiting for provisioning"
exit 1
