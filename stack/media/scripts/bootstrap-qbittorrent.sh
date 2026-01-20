#!/bin/bash
set -e

PASSWORD="safehaven"

# Get temporary password from logs
TEMP_PASS=$(docker logs qbittorrent 2>&1 | grep "temporary password" | sed 's/.*: //')

if [ -z "$TEMP_PASS" ]; then
  echo "No temp password found, may already be configured"
  exit 0
fi

echo "Found temp password, changing to: $PASSWORD"

# Login with temp password
SID=$(docker exec qbittorrent curl -s -c - "http://localhost:8080/api/v2/auth/login" \
  -d "username=admin&password=$TEMP_PASS" | grep SID | awk '{print $NF}')

# Change password and set download path
docker exec qbittorrent curl -s "http://localhost:8080/api/v2/app/setPreferences" \
  -b "SID=$SID" \
  -d 'json={"web_ui_password":"'"$PASSWORD"'","save_path":"/media/downloads/torrents","temp_path_enabled":false}'

echo "qBittorrent configured (password + download path: /media/downloads/torrents)"
echo ""
echo "=== IMPORTANT: One-time VPN interface binding ==="
echo "To fix 'firewalled' status with VPN port forwarding:"
echo "  1. Open https://qbit.ragnalab.xyz"
echo "  2. Go to Settings → Advanced"
echo "  3. Set 'Optional IP address to bind to' to the tun0 IP (e.g., 10.2.0.2)"
echo "     (Find it with: docker exec qbittorrent ip -4 addr show tun0 | grep inet)"
echo "  4. Leave 'Network Interface' as 'Any interface'"
echo "  5. Click Apply"
echo ""
echo "NOTE: Setting interface to 'tun0' by name does NOT work."
echo "      You must use the IP address. Setting persists, only needed once."
