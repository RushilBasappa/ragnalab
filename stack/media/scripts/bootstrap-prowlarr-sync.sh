#!/bin/bash
# Bootstrap Prowlarr App Sync - Connect Prowlarr to Sonarr and Radarr
#
# This script runs AFTER Sonarr and Radarr are configured.
# It adds them as applications in Prowlarr so indexers sync automatically.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"
PROWLARR_URL="${PROWLARR_URL:-http://localhost:9696}"

add_application() {
    local prowlarr_key="$1"
    local app_name="$2"
    local app_type="$3"
    local app_url="$4"
    local app_key="$5"

    # Check if application already exists
    local existing=$(curl -ks "$PROWLARR_URL/api/v1/applications" \
        -H "X-Api-Key: $prowlarr_key" | jq -r ".[] | select(.name == \"$app_name\") | .id")

    if [ -n "$existing" ]; then
        log_success "$app_name already configured in Prowlarr"
        return 0
    fi

    log_info "Adding $app_name to Prowlarr..."

    local app_config=$(cat <<EOF
{
    "name": "$app_name",
    "syncLevel": "fullSync",
    "implementation": "$app_type",
    "configContract": "${app_type}Settings",
    "fields": [
        {"name": "prowlarrUrl", "value": "http://prowlarr:9696"},
        {"name": "baseUrl", "value": "$app_url"},
        {"name": "apiKey", "value": "$app_key"},
        {"name": "syncCategories", "value": []}
    ],
    "tags": []
}
EOF
)

    result=$(curl -ks -X POST "$PROWLARR_URL/api/v1/applications" \
        -H "X-Api-Key: $prowlarr_key" \
        -H "Content-Type: application/json" \
        -d "$app_config" \
        -o /dev/null -w "%{http_code}")

    if [ "$result" = "201" ] || [ "$result" = "200" ]; then
        log_success "$app_name added to Prowlarr"
    else
        log_warn "Failed to add $app_name (HTTP $result)"
    fi
}

main() {
    log_info "=== Configuring Prowlarr Application Sync ==="

    # Get API keys
    prowlarr_key=$(get_env "PROWLARR_API_KEY")
    sonarr_key=$(get_env "SONARR_API_KEY")
    radarr_key=$(get_env "RADARR_API_KEY")

    if [ -z "$prowlarr_key" ]; then
        log_error "PROWLARR_API_KEY not found in .env"
        exit 1
    fi

    # Wait for Prowlarr
    wait_for_service "Prowlarr" "$PROWLARR_URL" || exit 1

    # Add Sonarr
    if [ -n "$sonarr_key" ]; then
        add_application "$prowlarr_key" "Sonarr" "Sonarr" "http://sonarr:8989" "$sonarr_key"
    else
        log_warn "SONARR_API_KEY not found, skipping Sonarr sync"
    fi

    # Add Radarr
    if [ -n "$radarr_key" ]; then
        add_application "$prowlarr_key" "Radarr" "Radarr" "http://radarr:7878" "$radarr_key"
    else
        log_warn "RADARR_API_KEY not found, skipping Radarr sync"
    fi

    log_success "Prowlarr sync configuration complete"
    log_info "Note: Indexers must be added manually in Prowlarr UI"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
