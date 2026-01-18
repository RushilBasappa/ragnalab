#!/bin/bash
# Configure Jellyfin - requires browser setup wizard
set -e
source "$(dirname "$0")/common.sh"

URL="http://localhost:8096"
wait_for "$URL"

echo ""
echo "Jellyfin requires browser setup:"
echo "  1. Open http://localhost:8096"
echo "  2. Complete setup wizard"
echo "  3. Create admin user"
echo "  4. Add libraries:"
echo "     - Movies: /data/media/movies"
echo "     - TV Shows: /data/media/tv"
echo "  5. Dashboard -> Playback -> Disable transcoding (Pi 5)"
echo "  6. Dashboard -> API Keys -> Create key for Homepage"
echo ""
