#!/bin/bash
set -e

# Jellyfin requires interactive setup wizard on first run
# This script just extracts the API key after manual setup

# Check if Jellyfin has been set up (has users)
SETUP_COMPLETE=$(docker exec jellyfin curl -sf "http://localhost:8096/System/Info/Public" 2>/dev/null | jq -r '.StartupWizardCompleted // false')

if [ "$SETUP_COMPLETE" != "true" ]; then
  echo "Jellyfin requires manual setup at https://jellyfin.ragnalab.xyz"
  echo "  1. Create admin account"
  echo "  2. Add media libraries (/data/media/movies, /data/media/tv)"
  echo "  3. Re-run bootstrap after setup to save API key"
  exit 0
fi

# Try to get API key from system.xml
API_KEY=$(docker exec jellyfin sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/data/system.xml 2>/dev/null)

if [ -z "$API_KEY" ]; then
  echo "Jellyfin setup complete but no API key found"
  echo "  Create one at: Dashboard -> API Keys"
  exit 0
fi

# Save API key to .env
sed -i "s/^#\?JELLYFIN_API_KEY=.*/JELLYFIN_API_KEY=$API_KEY/" "$(dirname "$0")/../.env"

echo "Jellyfin API key saved to .env"
