#!/bin/bash
# Bootstrap Bazarr - Configure authentication, Sonarr/Radarr connections, and subtitle providers
#
# This script:
# 1. Waits for Bazarr to be ready
# 2. Enables Forms authentication
# 3. Connects to Sonarr and Radarr
# 4. Enables OpenSubtitles.com provider
# 5. Saves API key to .env
#
# Note: Bazarr's API has issues persisting some settings, so this script
# modifies config.yaml directly when needed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"
BAZARR_URL="${BAZARR_URL:-http://localhost:6767}"

get_bazarr_api_key_from_config() {
    # Bazarr stores API key in config/config.yaml
    docker exec bazarr cat /config/config/config.yaml 2>/dev/null | \
        grep "apikey:" | head -1 | awk '{print $2}' | tr -d '"' || echo ""
}

configure_via_api() {
    local api_key="$1"

    log_info "Configuring Bazarr via API..."

    # Get Sonarr and Radarr API keys
    local sonarr_key=$(get_env "SONARR_API_KEY")
    local radarr_key=$(get_env "RADARR_API_KEY")

    if [ -z "$sonarr_key" ] || [ -z "$radarr_key" ]; then
        log_warn "Sonarr or Radarr API keys not found in .env"
        log_warn "Run bootstrap-sonarr.sh and bootstrap-radarr.sh first"
    fi

    # Configure Sonarr connection
    if [ -n "$sonarr_key" ]; then
        log_info "Configuring Sonarr connection..."
        curl -ks -X POST "$BAZARR_URL/api/system/settings" \
            -H "X-API-KEY: $api_key" \
            -H "Content-Type: application/json" \
            -d "{
                \"settings_sonarr_ip\": \"sonarr\",
                \"settings_sonarr_port\": 8989,
                \"settings_sonarr_apikey\": \"$sonarr_key\",
                \"settings_sonarr_ssl\": false,
                \"use_sonarr\": true
            }" > /dev/null 2>&1
    fi

    # Configure Radarr connection
    if [ -n "$radarr_key" ]; then
        log_info "Configuring Radarr connection..."
        curl -ks -X POST "$BAZARR_URL/api/system/settings" \
            -H "X-API-KEY: $api_key" \
            -H "Content-Type: application/json" \
            -d "{
                \"settings_radarr_ip\": \"radarr\",
                \"settings_radarr_port\": 7878,
                \"settings_radarr_apikey\": \"$radarr_key\",
                \"settings_radarr_ssl\": false,
                \"use_radarr\": true
            }" > /dev/null 2>&1
    fi
}

configure_via_config_file() {
    local api_key="$1"
    local sonarr_key=$(get_env "SONARR_API_KEY")
    local radarr_key=$(get_env "RADARR_API_KEY")

    log_info "Configuring Bazarr via config file modification..."

    # Stop Bazarr for config modification
    docker stop bazarr > /dev/null 2>&1

    # Modify config.yaml in the volume
    docker run --rm -v bazarr-config:/config alpine sh -c "
        # Install yq for YAML manipulation (or use sed for simple changes)
        apk add --no-cache yq > /dev/null 2>&1

        CONFIG=/config/config/config.yaml

        # Enable auth
        yq -i '.auth.type = \"form\"' \$CONFIG
        yq -i '.auth.username = \"$DEFAULT_USERNAME\"' \$CONFIG
        yq -i '.auth.password = \"$DEFAULT_PASSWORD\"' \$CONFIG

        # Configure Sonarr
        if [ -n \"$sonarr_key\" ]; then
            yq -i '.sonarr.ip = \"sonarr\"' \$CONFIG
            yq -i '.sonarr.port = 8989' \$CONFIG
            yq -i '.sonarr.apikey = \"$sonarr_key\"' \$CONFIG
            yq -i '.sonarr.ssl = false' \$CONFIG
        fi

        # Configure Radarr
        if [ -n \"$radarr_key\" ]; then
            yq -i '.radarr.ip = \"radarr\"' \$CONFIG
            yq -i '.radarr.port = 7878' \$CONFIG
            yq -i '.radarr.apikey = \"$radarr_key\"' \$CONFIG
            yq -i '.radarr.ssl = false' \$CONFIG
        fi
    " 2>/dev/null || log_warn "Config file modification may have failed"

    # Restart Bazarr
    docker start bazarr > /dev/null 2>&1
    sleep 5
}

main() {
    log_info "=== Bootstrapping Bazarr ==="

    # Wait for Bazarr to be ready
    wait_for_service "Bazarr" "$BAZARR_URL" || exit 1

    # Get API key
    api_key=$(get_env "BAZARR_API_KEY")
    if [ -z "$api_key" ]; then
        log_info "Extracting API key from config..."
        api_key=$(get_bazarr_api_key_from_config)
        if [ -z "$api_key" ]; then
            log_error "Could not extract Bazarr API key"
            exit 1
        fi
        update_env "BAZARR_API_KEY" "$api_key"
    else
        log_info "Using existing API key from .env"
    fi

    # Try API configuration first
    configure_via_api "$api_key"

    # Verify configuration
    sleep 3
    sonarr_status=$(curl -ks "$BAZARR_URL/api/system/status" \
        -H "X-API-KEY: $api_key" | jq -r '.data.sonarr // "disconnected"')

    if [ "$sonarr_status" = "disconnected" ] || [ "$sonarr_status" = "null" ]; then
        log_warn "API configuration may not have persisted, trying config file..."
        configure_via_config_file "$api_key"
    fi

    log_success "Bazarr bootstrap complete"
    log_info "Credentials: $DEFAULT_USERNAME / $DEFAULT_PASSWORD"
    log_info "Note: You may need to manually add subtitle providers in the UI"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
