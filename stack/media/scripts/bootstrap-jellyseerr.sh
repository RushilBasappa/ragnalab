#!/bin/bash
# Bootstrap Jellyseerr - Setup wizard guidance
#
# IMPORTANT: Jellyseerr's setup wizard requires browser interaction.
# This script:
# 1. Waits for Jellyseerr to be ready
# 2. Checks if already initialized
# 3. Provides guidance for manual setup if needed
# 4. Saves API key to .env after setup
#
# Full automation is not possible for Jellyseerr's first-time setup.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"
JELLYSEERR_URL="${JELLYSEERR_URL:-http://localhost:5055}"

check_initialized() {
    # Check if Jellyseerr is already initialized
    local status=$(curl -ks "$JELLYSEERR_URL/api/v1/settings/public" | jq -r '.initialized // false')
    [ "$status" = "true" ]
}

get_api_key_from_settings() {
    # Try to get API key if we can authenticate
    # This requires an existing session, which we may not have
    curl -ks "$JELLYSEERR_URL/api/v1/settings/main" | jq -r '.apiKey // empty' 2>/dev/null
}

main() {
    log_info "=== Bootstrapping Jellyseerr ==="

    # Wait for Jellyseerr to be ready
    wait_for_service "Jellyseerr" "$JELLYSEERR_URL" || exit 1

    if check_initialized; then
        log_success "Jellyseerr is already initialized"

        # Check if we have API key in .env
        api_key=$(get_env "JELLYSEERR_API_KEY")
        if [ -z "$api_key" ]; then
            log_warn "Jellyseerr API key not in .env"
            log_info "To get the API key:"
            log_info "  1. Go to https://requests.ragnalab.xyz/settings"
            log_info "  2. Copy the API Key from General settings"
            log_info "  3. Add to .env: JELLYSEERR_API_KEY=<your-key>"
        else
            log_success "API key found in .env"
        fi

        return 0
    fi

    log_warn "Jellyseerr requires manual setup via browser"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo " MANUAL SETUP REQUIRED"
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""
    echo " 1. Open: https://requests.ragnalab.xyz (or http://localhost:5055)"
    echo ""
    echo " 2. Setup Wizard Steps:"
    echo "    a. Sign in with Jellyfin"
    echo "       - URL: http://jellyfin:8096"
    echo "       - Username: $DEFAULT_USERNAME"
    echo "       - Password: $DEFAULT_PASSWORD"
    echo ""
    echo "    b. Add Radarr (Movies):"
    echo "       - Default Server: Yes"
    echo "       - Server Name: Radarr"
    echo "       - Hostname: radarr"
    echo "       - Port: 7878"
    echo "       - API Key: $(get_env 'RADARR_API_KEY' | head -c 20)..."
    echo "       - Quality Profile: Any"
    echo "       - Root Folder: /media/library/movies"
    echo ""
    echo "    c. Add Sonarr (TV):"
    echo "       - Default Server: Yes"
    echo "       - Server Name: Sonarr"
    echo "       - Hostname: sonarr"
    echo "       - Port: 8989"
    echo "       - API Key: $(get_env 'SONARR_API_KEY' | head -c 20)..."
    echo "       - Quality Profile: Any"
    echo "       - Root Folder: /media/library/tv"
    echo ""
    echo " 3. After setup, get the API key:"
    echo "    Settings -> General -> API Key"
    echo "    Add to .env: JELLYSEERR_API_KEY=<your-key>"
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo ""

    # Wait for user to complete setup
    log_info "Waiting for setup to complete... (Ctrl+C to skip)"
    while ! check_initialized; do
        sleep 5
    done

    log_success "Jellyseerr setup complete!"
    log_info "Don't forget to add the API key to .env"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
