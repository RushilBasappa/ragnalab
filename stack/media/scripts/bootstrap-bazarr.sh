#!/bin/bash
set -e

# Bazarr stores API key in config.yaml, not config.xml
API_KEY=$(docker exec bazarr grep -m1 "apikey:" /config/config/config.yaml 2>/dev/null | sed 's/.*apikey:\s*//' | tr -d '[:space:]')

if [ -z "$API_KEY" ]; then
  echo "Bazarr not ready yet (no API key found)"
  exit 0
fi

# Get Sonarr API key and configure connection (enable integration + connection settings)
# Note: Bazarr API requires lowercase 'true'/'false' for boolean settings
SONARR_KEY=$(docker exec sonarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)
if [ -n "$SONARR_KEY" ]; then
  docker exec bazarr curl -s -X POST "http://localhost:6767/api/system/settings" \
    -H "X-API-KEY: $API_KEY" \
    -d "settings-general-use_sonarr=true" \
    -d "settings-sonarr-ip=sonarr" \
    -d "settings-sonarr-port=8989" \
    -d "settings-sonarr-apikey=$SONARR_KEY" \
    -d "settings-sonarr-base_url=" > /dev/null 2>&1 || true
fi

# Get Radarr API key and configure connection (enable integration + connection settings)
RADARR_KEY=$(docker exec radarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)
if [ -n "$RADARR_KEY" ]; then
  docker exec bazarr curl -s -X POST "http://localhost:6767/api/system/settings" \
    -H "X-API-KEY: $API_KEY" \
    -d "settings-general-use_radarr=true" \
    -d "settings-radarr-ip=radarr" \
    -d "settings-radarr-port=7878" \
    -d "settings-radarr-apikey=$RADARR_KEY" \
    -d "settings-radarr-base_url=" > /dev/null 2>&1 || true
fi

# Save API key to .env
sed -i "s/^BAZARR_API_KEY=.*/BAZARR_API_KEY=$API_KEY/" "$(dirname "$0")/../.env"


echo "Bazarr configured. API key saved to .env"
