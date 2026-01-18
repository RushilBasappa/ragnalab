#!/bin/bash
# Configure Prowlarr authentication
set -e
source "$(dirname "$0")/common.sh"

URL="http://localhost:9696"
wait_for "$URL"

API_KEY="${PROWLARR_API_KEY:-$(get_api_key prowlarr)}"
[ -z "$API_KEY" ] && echo "No API key found" && exit 1

echo "Configuring Prowlarr auth..."
CONFIG=$(curl -ks "$URL/api/v1/config/host" -H "X-Api-Key: $API_KEY")

echo "$CONFIG" | jq '.authenticationMethod = "Forms" | .username = "admin" | .password = "Ragnalab2026" | .authenticationRequired = "Enabled"' | \
curl -ks -X PUT "$URL/api/v1/config/host" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d @- > /dev/null

echo "Prowlarr configured. Credentials: admin / Ragnalab2026"
