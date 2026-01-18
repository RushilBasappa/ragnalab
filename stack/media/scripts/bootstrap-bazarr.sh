#!/bin/bash
set -e

# Bazarr stores API key in config.yaml, not config.xml
API_KEY=$(docker exec bazarr sed -n 's/.*apikey:\s*\([a-f0-9]*\).*/\1/p' /config/config/config.yaml 2>/dev/null)

if [ -z "$API_KEY" ]; then
  echo "Bazarr not ready yet (no API key found)"
  exit 0
fi

# Enable Sonarr and Radarr integrations (API doesn't support this, use sed)
docker exec bazarr /bin/sed -i 's/use_sonarr: false/use_sonarr: true/' /config/config/config.yaml
docker exec bazarr /bin/sed -i 's/use_radarr: false/use_radarr: true/' /config/config/config.yaml

# Get Sonarr API key and configure connection
SONARR_KEY=$(docker exec sonarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)
if [ -n "$SONARR_KEY" ]; then
  docker exec bazarr curl -s -X POST "http://localhost:6767/api/system/settings" \
    -H "X-API-KEY: $API_KEY" \
    -d "settings-sonarr-ip=sonarr" \
    -d "settings-sonarr-port=8989" \
    -d "settings-sonarr-apikey=$SONARR_KEY" \
    -d "settings-sonarr-base_url=" > /dev/null 2>&1 || true
fi

# Get Radarr API key and configure connection
RADARR_KEY=$(docker exec radarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)
if [ -n "$RADARR_KEY" ]; then
  docker exec bazarr curl -s -X POST "http://localhost:6767/api/system/settings" \
    -H "X-API-KEY: $API_KEY" \
    -d "settings-radarr-ip=radarr" \
    -d "settings-radarr-port=7878" \
    -d "settings-radarr-apikey=$RADARR_KEY" \
    -d "settings-radarr-base_url=" > /dev/null 2>&1 || true
fi

# Save API key to .env
sed -i "s/^#\?BAZARR_API_KEY=.*/BAZARR_API_KEY=$API_KEY/" "$(dirname "$0")/../.env"

# Restart to apply config changes
docker restart bazarr > /dev/null 2>&1

echo "Bazarr configured. API key saved to .env"
