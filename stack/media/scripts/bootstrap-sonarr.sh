#!/bin/bash
# Configure Sonarr: auth, download client, root folder
set -e
source "$(dirname "$0")/common.sh"

URL="http://localhost:8989"
wait_for "$URL"

API_KEY="${SONARR_API_KEY:-$(get_api_key sonarr)}"
[ -z "$API_KEY" ] && echo "No API key found" && exit 1

echo "Configuring Sonarr auth..."
CONFIG=$(curl -ks "$URL/api/v3/config/host" -H "X-Api-Key: $API_KEY")
echo "$CONFIG" | jq '.authenticationMethod = "Forms" | .username = "admin" | .password = "Ragnalab2026" | .authenticationRequired = "Enabled"' | \
curl -ks -X PUT "$URL/api/v3/config/host" -H "X-Api-Key: $API_KEY" -H "Content-Type: application/json" -d @- > /dev/null

echo "Adding qBittorrent download client..."
curl -ks -X POST "$URL/api/v3/downloadclient" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "enable": true,
        "protocol": "torrent",
        "name": "qBittorrent",
        "implementation": "QBittorrent",
        "configContract": "QBittorrentSettings",
        "fields": [
            {"name": "host", "value": "gluetun"},
            {"name": "port", "value": 8080},
            {"name": "username", "value": "admin"},
            {"name": "password", "value": "adminadmin"},
            {"name": "tvCategory", "value": "tv"}
        ]
    }' > /dev/null 2>&1 || echo "(may already exist)"

echo "Adding root folder..."
curl -ks -X POST "$URL/api/v3/rootfolder" \
    -H "X-Api-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{"path": "/media/library/tv"}' > /dev/null 2>&1 || echo "(may already exist)"

echo "Sonarr configured."
