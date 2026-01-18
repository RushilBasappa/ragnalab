#!/bin/bash
# Configure Jellyseerr - requires browser setup wizard
set -e
source "$(dirname "$0")/common.sh"

URL="http://localhost:5055"
wait_for "$URL"

echo ""
echo "Jellyseerr requires browser setup:"
echo "  1. Open http://localhost:5055"
echo "  2. Sign in with Jellyfin (http://jellyfin:8096)"
echo "  3. Add Radarr: radarr:7878 with API key"
echo "  4. Add Sonarr: sonarr:8989 with API key"
echo ""
echo "API Keys from .env:"
echo "  SONARR: $SONARR_API_KEY"
echo "  RADARR: $RADARR_API_KEY"
echo ""
