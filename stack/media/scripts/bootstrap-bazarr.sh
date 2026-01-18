#!/bin/bash
# Configure Bazarr via config.yaml modification
set -e
source "$(dirname "$0")/common.sh"

URL="http://localhost:6767"
wait_for "$URL"

SONARR_KEY="${SONARR_API_KEY:-$(get_api_key sonarr)}"
RADARR_KEY="${RADARR_API_KEY:-$(get_api_key radarr)}"

# Determine volume name (ragnalab_ prefix or not)
VOLUME=$(docker volume ls -q | grep bazarr-config | head -1)
[ -z "$VOLUME" ] && echo "No bazarr volume found" && exit 1

echo "Stopping Bazarr..."
docker stop bazarr > /dev/null 2>&1 || true
sleep 2

echo "Updating config..."
docker run --rm -v "$VOLUME":/config alpine sh -c "
  CONFIG=/config/config/config.yaml

  # Auth settings
  sed -i 's/^  type: null/  type: form/' \$CONFIG
  sed -i 's/^  type: basic/  type: form/' \$CONFIG
  sed -i \"s/^  username: ''/  username: admin/\" \$CONFIG
  sed -i \"s/^  password: ''/  password: Ragnalab2026/\" \$CONFIG

  # Sonarr settings (under sonarr: section)
  sed -i '/^sonarr:/,/^[a-z]/{s/apikey: .*/apikey: $SONARR_KEY/}' \$CONFIG
  sed -i '/^sonarr:/,/^[a-z]/{s/ip: .*/ip: sonarr/}' \$CONFIG

  # Radarr settings (under radarr: section)
  sed -i '/^radarr:/,/^[a-z]/{s/apikey: .*/apikey: $RADARR_KEY/}' \$CONFIG
  sed -i '/^radarr:/,/^[a-z]/{s/ip: .*/ip: radarr/}' \$CONFIG
"

echo "Starting Bazarr..."
docker start bazarr > /dev/null 2>&1

sleep 3
wait_for "$URL"

echo "Bazarr configured. Credentials: admin / Ragnalab2026"
