#!/bin/bash
set -e

# Jellyseerr requires interactive setup wizard on first run
# This script just extracts the API key after manual setup

# Check if Jellyseerr is initialized
INITIALIZED=$(docker exec jellyseerr wget -qO- "http://localhost:5055/api/v1/settings/public" 2>/dev/null | jq -r '.initialized // false')

if [ "$INITIALIZED" != "true" ]; then
  echo "Jellyseerr requires manual setup at https://requests.ragnalab.xyz"
  echo "  1. Sign in with Jellyfin"
  echo "  2. Configure Jellyfin server connection"
  echo "  3. Add Sonarr and Radarr servers"
  echo "  4. Re-run bootstrap after setup to save API key"
  exit 0
fi

echo "Jellyseerr initialized."
echo "REMINDER: Copy API key from Settings → General → API Key"
echo "  Then add to .env: JELLYSEERR_API_KEY=<key>"
