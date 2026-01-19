#!/bin/bash
set -e

# Jellyfin bootstrap - complete wizard, get API key, add libraries

ADMIN_USER="${JELLYFIN_ADMIN_USER:-admin}"
ADMIN_PASS="${JELLYFIN_ADMIN_PASSWORD:-safehaven}"
ENV_FILE="$(dirname "$0")/../.env"

api() {
  local method=$1 endpoint=$2 data=$3 header=$4
  docker exec jellyfin curl -sf -X "$method" "http://localhost:8096$endpoint" \
    -H "Content-Type: application/json" \
    ${data:+-d "$data"} ${header:+-H "$header"} 2>/dev/null
}

# Wait for Jellyfin to be ready
for i in {1..30}; do api GET /System/Info/Public > /dev/null && break || sleep 1; done

# Exit if already configured
if [ "$(api GET /System/Info/Public | jq -r '.StartupWizardCompleted')" = "true" ]; then
  echo "Jellyfin already configured, skipping"
  exit 0
fi

echo "Completing setup wizard..."
AUTH='X-Emby-Authorization: MediaBrowser Client="Bootstrap", Device="CLI", DeviceId="bootstrap", Version="1.0"'

# Wait for startup wizard to be ready
for i in {1..30}; do api GET /Startup/User "" "$AUTH" > /dev/null && break || sleep 1; done

# Wizard steps
api POST /Startup/Configuration '{"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}' "$AUTH" > /dev/null
api POST /Startup/User "{\"Name\":\"$ADMIN_USER\",\"Password\":\"$ADMIN_PASS\"}" "$AUTH" > /dev/null
api POST /Startup/Complete "" "$AUTH" > /dev/null

# Authenticate and create API key
TOKEN=$(api POST /Users/AuthenticateByName "{\"Username\":\"$ADMIN_USER\",\"Pw\":\"$ADMIN_PASS\"}" "$AUTH" | jq -r '.AccessToken')
api POST "/Auth/Keys?app=RagnaLab" "" "X-Emby-Token: $TOKEN" > /dev/null
API_KEY=$(api GET /Auth/Keys "" "X-Emby-Token: $TOKEN" | jq -r '.Items[-1].AccessToken')

# Add libraries
echo "Adding libraries..."
AUTH_HEADER="X-Emby-Token: $API_KEY"
api POST "/Library/VirtualFolders?name=Movies&collectionType=movies&paths=%2Fdata%2Fmedia%2Fmovies&refreshLibrary=false" "" "$AUTH_HEADER" > /dev/null 2>&1 || true
api POST "/Library/VirtualFolders?name=TV%20Shows&collectionType=tvshows&paths=%2Fdata%2Fmedia%2Ftv&refreshLibrary=false" "" "$AUTH_HEADER" > /dev/null 2>&1 || true

# Save to .env
[ -f "$ENV_FILE" ] && sed -i "s/^#\?JELLYFIN_API_KEY=.*/JELLYFIN_API_KEY=$API_KEY/" "$ENV_FILE"

echo "Jellyfin configured."