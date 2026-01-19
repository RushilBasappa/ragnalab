#!/bin/bash
set -e

# Minimal Jellyfin bootstrap - completes wizard, outputs API key and admin credentials

JELLYFIN_URL="http://localhost:8096"
ADMIN_USER="${JELLYFIN_ADMIN_USER:-admin}"
ADMIN_PASS="${JELLYFIN_ADMIN_PASSWORD:-safehaven}"
ENV_FILE="$(dirname "$0")/../.env"

api() {
  docker exec jellyfin curl -sf -X "$1" "${JELLYFIN_URL}$2" \
    -H "Content-Type: application/json" \
    ${3:+-d "$3"} ${4:+-H "$4"} 2>/dev/null
}

# Check if already set up
if [ "$(api GET /System/Info/Public | jq -r '.StartupWizardCompleted')" = "true" ]; then
  echo "Jellyfin already configured"
  API_KEY=$(docker exec jellyfin sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' /config/data/system.xml 2>/dev/null || true)
else
  echo "Running setup wizard..."
  AUTH='X-Emby-Authorization: MediaBrowser Client="Bootstrap", Device="CLI", DeviceId="bootstrap", Version="1.0"'

  # Wait for init
  for i in {1..30}; do api GET /Startup/User && break || sleep 1; done

  # Complete wizard
  api POST /Startup/Configuration '{"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}' "$AUTH"
  api POST /Startup/User "{\"Name\":\"$ADMIN_USER\",\"Password\":\"$ADMIN_PASS\"}" "$AUTH"
  api POST /Startup/Complete "" "$AUTH"

  # Get token and create API key
  TOKEN=$(api POST /Users/AuthenticateByName "{\"Username\":\"$ADMIN_USER\",\"Pw\":\"$ADMIN_PASS\"}" "$AUTH" | jq -r '.AccessToken')
  api POST "/Auth/Keys?app=Bootstrap" "" "X-Emby-Token: $TOKEN"
  API_KEY=$(api GET /Auth/Keys "" "X-Emby-Token: $TOKEN" | jq -r '.Items[-1].AccessToken')
fi

# Save to .env if exists
[ -f "$ENV_FILE" ] && sed -i "s/^#\?JELLYFIN_API_KEY=.*/JELLYFIN_API_KEY=$API_KEY/" "$ENV_FILE"

echo "Admin: $ADMIN_USER / $ADMIN_PASS"
echo "API Key: $API_KEY"
