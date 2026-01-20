#!/bin/bash
set -e

# Get API key from config
API_KEY=$(docker exec prowlarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)

# Configure auth
docker exec prowlarr curl -s "http://localhost:9696/api/v1/config/host" -H "X-Api-Key: $API_KEY" | \
  jq '.authenticationMethod="Forms" | .username="admin" | .password="safehaven" | .passwordConfirmation="safehaven" | .authenticationRequired="Enabled"' | \
  docker exec -i prowlarr curl -s -X PUT "http://localhost:9696/api/v1/config/host" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d @-

# Save API key to .env
sed -i "s/^PROWLARR_API_KEY=.*/PROWLARR_API_KEY=$API_KEY/" "$(dirname "$0")/../.env"

echo "Prowlarr configured. API key saved to .env"
echo "REMINDER: Add indexers in Prowlarr UI (Indexers → Add Indexer):"
echo "  - YTS (movies, small files)"
echo "  - EZTV (TV shows)"
echo "  - Nyaa (anime)"
