#!/bin/bash
set -e

# Get API keys
PROWLARR_KEY=$(docker exec prowlarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)
SONARR_KEY=$(docker exec sonarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)
RADARR_KEY=$(docker exec radarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)

# Add Sonarr to Prowlarr
docker exec prowlarr curl -s -X POST "http://localhost:9696/api/v1/applications" \
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
      {\"name\": \"apiKey\", \"value\": \"$SONARR_KEY\"},
      {\"name\": \"syncCategories\", \"value\": [5000,5010,5020,5030,5040,5045,5050]}
    ]
  }" > /dev/null 2>&1 || true

# Add Radarr to Prowlarr
docker exec prowlarr curl -s -X POST "http://localhost:9696/api/v1/applications" \
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
      {\"name\": \"apiKey\", \"value\": \"$RADARR_KEY\"},
      {\"name\": \"syncCategories\", \"value\": [2000,2010,2020,2030,2040,2045,2050,2060]}
    ]
  }" > /dev/null 2>&1 || true

echo "Prowlarr sync configured"
