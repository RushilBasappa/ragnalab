#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")/scripts"

echo "=== Media Stack Bootstrap ==="

sleep 5 # Wait for gluetun to be ready

echo "1/9 qBittorrent..."
$SCRIPT_DIR/bootstrap-qbittorrent.sh

sleep 5 # Wait for qbittorrent to be ready
echo "2/9 Prowlarr..."
$SCRIPT_DIR/bootstrap-prowlarr.sh

sleep 5 # Wait for prowlarr to be ready
echo "3/9 Sonarr..."
$SCRIPT_DIR/bootstrap-sonarr.sh

sleep 5 # Wait for sonarr to be ready
echo "4/9 Radarr..."
$SCRIPT_DIR/bootstrap-radarr.sh

sleep 5 # Wait for radarr to be ready
echo "5/9 Prowlarr sync..."
$SCRIPT_DIR/bootstrap-prowlarr-sync.sh

sleep 5 # Wait for prowlarr sync to be ready
echo "6/9 Bazarr..."
$SCRIPT_DIR/bootstrap-bazarr.sh

sleep 5 # Wait for bazarr to be ready
echo "7/9 Jellyfin..."
$SCRIPT_DIR/bootstrap-jellyfin.sh

sleep 5 # Wait for jellyfin to be ready
echo "8/9 Jellyseerr..."
$SCRIPT_DIR/bootstrap-jellyseerr.sh

sleep 5 # Wait for jellyseerr to be ready
echo "9/9 Recyclarr..."
$SCRIPT_DIR/bootstrap-recyclarr.sh

echo "=== Done ==="
echo ""
echo "Manual setup required:"
echo "  - Plex: https://plex.ragnalab.xyz (get claim token from https://plex.tv/claim)"
echo "  - Maintainerr: https://maintainerr.ragnalab.xyz (configure cleanup rules)"
