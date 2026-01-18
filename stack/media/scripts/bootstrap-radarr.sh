#!/bin/bash
set -e

# Get API key from config
API_KEY=$(docker exec radarr sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/config.xml)

# Configure auth
docker exec radarr curl -s "http://localhost:7878/api/v3/config/host" -H "X-Api-Key: $API_KEY" | \
  jq '.authenticationMethod="Forms" | .username="admin" | .password="safehaven" | .passwordConfirmation="safehaven" | .authenticationRequired="Enabled"' | \
  docker exec -i radarr curl -s -X PUT "http://localhost:7878/api/v3/config/host" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d @-

# Add qBittorrent download client
docker exec radarr curl -s -X POST "http://localhost:7878/api/v3/downloadclient" \
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
      {"name": "movieCategory", "value": "movies"}
    ]
  }' > /dev/null 2>&1 || true

# Add root folder
docker exec radarr curl -s -X POST "http://localhost:7878/api/v3/rootfolder" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"path": "/media/library/movies"}' > /dev/null 2>&1 || true

# Save API key to .env
sed -i "s/^RADARR_API_KEY=.*/RADARR_API_KEY=$API_KEY/" "$(dirname "$0")/../.env"

echo "Radarr configured. API key saved to .env"
