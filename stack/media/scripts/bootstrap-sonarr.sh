#!/bin/bash
set -e

# Get API key from config
API_KEY=$(docker exec sonarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)

# Configure auth
docker exec sonarr curl -s "http://localhost:8989/api/v3/config/host" -H "X-Api-Key: $API_KEY" | \
  jq '.authenticationMethod="Forms" | .username="admin" | .password="safehaven" | .passwordConfirmation="safehaven" | .authenticationRequired="Enabled"' | \
  docker exec -i sonarr curl -s -X PUT "http://localhost:8989/api/v3/config/host" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d @-

# Add qBittorrent download client
docker exec sonarr curl -s -X POST "http://localhost:8989/api/v3/downloadclient" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "qBittorrent",
    "implementation": "QBittorrent",
    "configContract": "QBittorrentSettings",
    "enable": true,
    "protocol": "torrent",
    "priority": 1,
    "fields": [
      {"name": "host", "value": "gluetun"},
      {"name": "port", "value": 8080},
      {"name": "username", "value": "admin"},
      {"name": "password", "value": "safehaven"},
      {"name": "tvCategory", "value": "tv"}
    ]
  }' > /dev/null 2>&1 || true

# Add root folder
docker exec sonarr curl -s -X POST "http://localhost:8989/api/v3/rootfolder" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"path": "/media/library/tv"}' > /dev/null 2>&1 || true

# Add Jellyfin notification to trigger library scan on import
source "$(dirname "$0")/../.env"
if [ -n "$JELLYFIN_API_KEY" ]; then
  docker exec sonarr curl -s -X POST "http://localhost:8989/api/v3/notification" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"name\": \"Jellyfin\",
      \"implementation\": \"MediaBrowser\",
      \"configContract\": \"MediaBrowserSettings\",
      \"onDownload\": true,
      \"onUpgrade\": true,
      \"onRename\": true,
      \"onSeriesDelete\": true,
      \"onEpisodeFileDelete\": true,
      \"onEpisodeFileDeleteForUpgrade\": true,
      \"fields\": [
        {\"name\": \"host\", \"value\": \"jellyfin\"},
        {\"name\": \"port\", \"value\": 8096},
        {\"name\": \"useSsl\", \"value\": false},
        {\"name\": \"apiKey\", \"value\": \"$JELLYFIN_API_KEY\"},
        {\"name\": \"updateLibrary\", \"value\": true},
        {\"name\": \"mapFrom\", \"value\": \"/media\"},
        {\"name\": \"mapTo\", \"value\": \"/data/media\"}
      ]
    }" > /dev/null 2>&1 || true
fi

# Save API key to .env
sed -i "s/^SONARR_API_KEY=.*/SONARR_API_KEY=$API_KEY/" "$(dirname "$0")/../.env"

echo "Sonarr configured. API key saved to .env"
