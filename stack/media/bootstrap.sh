#!/bin/bash
set -e

SCRIPT_DIR="$(dirname "$0")/scripts"

echo "=== Media Stack Bootstrap ==="

sleep 5 # Wait for gluetun to be ready

echo "1/8 qBittorrent..."
$SCRIPT_DIR/bootstrap-qbittorrent.sh

sleep 5 # Wait for qbittorrent to be ready
echo "2/8 Prowlarr..."
$SCRIPT_DIR/bootstrap-prowlarr.sh

sleep 5 # Wait for prowlarr to be ready
echo "3/8 Sonarr..."
$SCRIPT_DIR/bootstrap-sonarr.sh

sleep 5 # Wait for sonarr to be ready
echo "4/8 Radarr..."
$SCRIPT_DIR/bootstrap-radarr.sh

sleep 5 # Wait for radarr to be ready
echo "5/8 Prowlarr sync..."
$SCRIPT_DIR/bootstrap-prowlarr-sync.sh

sleep 5 # Wait for prowlarr sync to be ready
echo "6/8 Bazarr..."
$SCRIPT_DIR/bootstrap-bazarr.sh

# sleep 5 # Wait for bazarr to be ready
# echo "7/8 Jellyfin..."
# $SCRIPT_DIR/bootstrap-jellyfin.sh

# sleep 5 # Wait for jellyfin to be ready
# echo "8/8 Jellyseerr..."
# $SCRIPT_DIR/bootstrap-jellyseerr.sh

echo "=== Done ==="
