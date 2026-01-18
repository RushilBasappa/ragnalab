#!/bin/bash
# Bootstrap Prowlarr - Configure authentication
#
# This script:
# 1. Waits for Prowlarr to be ready
# 2. Extracts API key from config.xml
# 3. Enables Forms authentication via API
# 4. Saves API key to .env

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"
PROWLARR_URL="${PROWLARR_URL:-http://localhost:9696}"

main() {
    log_info "=== Bootstrapping Prowlarr ==="

    # Wait for Prowlarr to be ready
    wait_for_service "Prowlarr" "$PROWLARR_URL" || exit 1

    # Get API key (from .env or extract from config)
    api_key=$(get_env "PROWLARR_API_KEY")
    if [ -z "$api_key" ]; then
        log_info "Extracting API key from config..."
        api_key=$(get_arr_api_key "prowlarr")
        if [ -z "$api_key" ]; then
            log_error "Could not extract Prowlarr API key"
            exit 1
        fi
        update_env "PROWLARR_API_KEY" "$api_key"
    else
        log_info "Using existing API key from .env"
    fi

    # Check current auth settings
    current_auth=$(curl -ks "$PROWLARR_URL/api/v1/config/host" \
        -H "X-Api-Key: $api_key" | jq -r '.authenticationMethod // "None"')

    if [ "$current_auth" = "Forms" ]; then
        log_success "Prowlarr already configured with Forms authentication"
        return 0
    fi

    log_info "Configuring Forms authentication..."

    # Get current host config
    config=$(curl -ks "$PROWLARR_URL/api/v1/config/host" -H "X-Api-Key: $api_key")

    # Update with Forms auth
    updated_config=$(echo "$config" | jq \
        --arg user "$DEFAULT_USERNAME" \
        --arg pass "$DEFAULT_PASSWORD" \
        '.authenticationMethod = "Forms" |
         .username = $user |
         .password = $pass |
         .authenticationRequired = "Enabled"')

    # Apply the config
    result=$(curl -ks -X PUT "$PROWLARR_URL/api/v1/config/host" \
        -H "X-Api-Key: $api_key" \
        -H "Content-Type: application/json" \
        -d "$updated_config" \
        -o /dev/null -w "%{http_code}")

    if [ "$result" = "202" ] || [ "$result" = "200" ]; then
        log_success "Prowlarr Forms authentication enabled"
        log_info "Credentials: $DEFAULT_USERNAME / $DEFAULT_PASSWORD"
    else
        log_error "Failed to configure authentication (HTTP $result)"
        exit 1
    fi
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
