#!/bin/bash
# Bootstrap all media stack services
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Media Stack Bootstrap ==="
echo ""

# Arr apps (API-based config)
./scripts/bootstrap-prowlarr.sh
./scripts/bootstrap-sonarr.sh
./scripts/bootstrap-radarr.sh
./scripts/bootstrap-prowlarr-sync.sh

# Manual setup required
./scripts/bootstrap-bazarr.sh
./scripts/bootstrap-jellyfin.sh
./scripts/bootstrap-jellyseerr.sh

echo "=== Bootstrap Complete ==="
echo ""
echo "Credentials: admin / Ragnalab2026"
echo "Change passwords after first login!"
