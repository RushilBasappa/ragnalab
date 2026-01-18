#!/bin/bash
# Configure Bazarr - requires manual setup due to API limitations
set -e
source "$(dirname "$0")/common.sh"

URL="http://localhost:6767"
wait_for "$URL"

echo ""
echo "Bazarr requires manual configuration:"
echo "  1. Open http://localhost:6767"
echo "  2. Settings -> General -> Security -> Enable Forms auth"
echo "  3. Settings -> Sonarr -> Add sonarr:8989 with API key"
echo "  4. Settings -> Radarr -> Add radarr:7878 with API key"
echo "  5. Settings -> Providers -> Add OpenSubtitles.com"
echo ""
echo "API Keys from .env:"
echo "  SONARR: $SONARR_API_KEY"
echo "  RADARR: $RADARR_API_KEY"
echo ""
