#!/bin/bash
# Configure Prowlarr authentication
set -e
source "$(dirname "$0")/common.sh"

wait_for prowlarr 9696

API_KEY="${PROWLARR_API_KEY:-$(get_api_key prowlarr)}"
[ -z "$API_KEY" ] && echo "No API key found" && exit 1

echo "Configuring Prowlarr auth..."
CONFIG=$(api prowlarr http://localhost:9696/api/v1/config/host -H "X-Api-Key: $API_KEY")

echo "$CONFIG" | jq '.authenticationMethod = "Forms" | .username = "admin" | .password = "Ragnalab2026" | .authenticationRequired = "Enabled"' | \
docker exec -i prowlarr curl -sf -X PUT http://localhost:9696/api/v1/config/host \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d @- > /dev/null

echo "Prowlarr configured. Credentials: admin / Ragnalab2026"
