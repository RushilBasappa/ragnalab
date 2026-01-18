#!/bin/bash
# Add Sonarr and Radarr to Prowlarr for indexer sync
set -e
source "$(dirname "$0")/common.sh"

wait_for prowlarr 9696

PROWLARR_KEY="${PROWLARR_API_KEY:-$(get_api_key prowlarr)}"
SONARR_KEY="${SONARR_API_KEY:-$(get_api_key sonarr)}"
RADARR_KEY="${RADARR_API_KEY:-$(get_api_key radarr)}"

echo "Adding Sonarr to Prowlarr..."
docker exec prowlarr curl -sf -X POST http://localhost:9696/api/v1/applications \
    -H "X-Api-Key: $PROWLARR_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Sonarr\",
        \"syncLevel\": \"fullSync\",
        \"implementation\": \"Sonarr\",
        \"configContract\": \"SonarrSettings\",
        \"fields\": [
            {\"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\"},
            {\"name\": \"baseUrl\", \"value\": \"http://sonarr:8989\"},
            {\"name\": \"apiKey\", \"value\": \"$SONARR_KEY\"}
        ]
    }" > /dev/null 2>&1 || echo "(may already exist)"

echo "Adding Radarr to Prowlarr..."
docker exec prowlarr curl -sf -X POST http://localhost:9696/api/v1/applications \
    -H "X-Api-Key: $PROWLARR_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"name\": \"Radarr\",
        \"syncLevel\": \"fullSync\",
        \"implementation\": \"Radarr\",
        \"configContract\": \"RadarrSettings\",
        \"fields\": [
            {\"name\": \"prowlarrUrl\", \"value\": \"http://prowlarr:9696\"},
            {\"name\": \"baseUrl\", \"value\": \"http://radarr:7878\"},
            {\"name\": \"apiKey\", \"value\": \"$RADARR_KEY\"}
        ]
    }" > /dev/null 2>&1 || echo "(may already exist)"

echo "Prowlarr sync configured."
