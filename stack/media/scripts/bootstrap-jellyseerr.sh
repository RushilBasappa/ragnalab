#!/bin/bash
set -e

# Jellyseerr requires interactive setup wizard on first run
# This script just extracts the API key after manual setup

# Check if Jellyseerr is initialized
INITIALIZED=$(docker exec jellyseerr curl -sf "http://localhost:5055/api/v1/settings/public" 2>/dev/null | jq -r '.initialized // false')

if [ "$INITIALIZED" != "true" ]; then
  echo "Jellyseerr requires manual setup at https://requests.ragnalab.xyz"
  echo "  1. Sign in with Jellyfin"
  echo "  2. Configure Jellyfin server connection"
  echo "  3. Add Sonarr and Radarr servers"
  echo "  4. Re-run bootstrap after setup to save API key"
  exit 0
fi

# Get API key from settings
API_KEY=$(docker exec jellyseerr curl -sf "http://localhost:5055/api/v1/settings/main" 2>/dev/null | jq -r '.apiKey // empty')

if [ -z "$API_KEY" ]; then
  echo "Jellyseerr setup complete but couldn't retrieve API key"
  exit 0
fi

# Save API key to .env
sed -i "s/^JELLYSEERR_API_KEY=.*/JELLYSEERR_API_KEY=$API_KEY/" "$(dirname "$0")/../.env"

echo "Jellyseerr API key saved to .env"
