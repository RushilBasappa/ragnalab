#!/bin/bash
# Bootstrap Radarr - Configure authentication, download client, and root folder
#
# This script:
# 1. Waits for Radarr to be ready
# 2. Extracts API key from config.xml
# 3. Enables Forms authentication via API
# 4. Adds qBittorrent download client
# 5. Adds Movies root folder
# 6. Saves API key to .env

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"
RADARR_URL="${RADARR_URL:-http://localhost:7878}"

configure_auth() {
    local api_key="$1"

    # Check current auth settings
    current_auth=$(curl -ks "$RADARR_URL/api/v3/config/host" \
        -H "X-Api-Key: $api_key" | jq -r '.authenticationMethod // "None"')

    if [ "$current_auth" = "Forms" ]; then
        log_success "Radarr already configured with Forms authentication"
        return 0
    fi

    log_info "Configuring Forms authentication..."

    config=$(curl -ks "$RADARR_URL/api/v3/config/host" -H "X-Api-Key: $api_key")

    updated_config=$(echo "$config" | jq \
        --arg user "$DEFAULT_USERNAME" \
        --arg pass "$DEFAULT_PASSWORD" \
        '.authenticationMethod = "Forms" |
         .username = $user |
         .password = $pass |
         .authenticationRequired = "Enabled"')

    result=$(curl -ks -X PUT "$RADARR_URL/api/v3/config/host" \
        -H "X-Api-Key: $api_key" \
        -H "Content-Type: application/json" \
        -d "$updated_config" \
        -o /dev/null -w "%{http_code}")

    if [ "$result" = "202" ] || [ "$result" = "200" ]; then
        log_success "Radarr Forms authentication enabled"
    else
        log_error "Failed to configure authentication (HTTP $result)"
        return 1
    fi
}

add_download_client() {
    local api_key="$1"

    # Check if qBittorrent already exists
    existing=$(curl -ks "$RADARR_URL/api/v3/downloadclient" \
        -H "X-Api-Key: $api_key" | jq -r '.[] | select(.name == "qBittorrent") | .id')

    if [ -n "$existing" ]; then
        log_success "qBittorrent download client already configured"
        return 0
    fi

    log_info "Adding qBittorrent download client..."

    client_config=$(cat <<EOF
{
    "enable": true,
    "protocol": "torrent",
    "priority": 1,
    "removeCompletedDownloads": true,
    "removeFailedDownloads": true,
    "name": "qBittorrent",
    "fields": [
        {"name": "host", "value": "$QBIT_HOST"},
        {"name": "port", "value": $QBIT_PORT},
        {"name": "useSsl", "value": false},
        {"name": "username", "value": "$QBIT_USERNAME"},
        {"name": "password", "value": "$QBIT_PASSWORD"},
        {"name": "movieCategory", "value": "movies"},
        {"name": "movieImportedCategory"},
        {"name": "recentMoviePriority", "value": 0},
        {"name": "olderMoviePriority", "value": 0},
        {"name": "initialState", "value": 0},
        {"name": "sequentialOrder", "value": false},
        {"name": "firstAndLast", "value": false}
    ],
    "implementationName": "qBittorrent",
    "implementation": "QBittorrent",
    "configContract": "QBittorrentSettings",
    "tags": []
}
EOF
)

    result=$(curl -ks -X POST "$RADARR_URL/api/v3/downloadclient" \
        -H "X-Api-Key: $api_key" \
        -H "Content-Type: application/json" \
        -d "$client_config" \
        -o /dev/null -w "%{http_code}")

    if [ "$result" = "201" ] || [ "$result" = "200" ]; then
        log_success "qBittorrent download client added"
    else
        log_warn "Failed to add download client (HTTP $result) - may need manual config"
    fi
}

add_root_folder() {
    local api_key="$1"
    local path="/media/library/movies"

    # Check if root folder already exists
    existing=$(curl -ks "$RADARR_URL/api/v3/rootfolder" \
        -H "X-Api-Key: $api_key" | jq -r ".[] | select(.path == \"$path\") | .id")

    if [ -n "$existing" ]; then
        log_success "Root folder $path already configured"
        return 0
    fi

    log_info "Adding root folder $path..."

    result=$(curl -ks -X POST "$RADARR_URL/api/v3/rootfolder" \
        -H "X-Api-Key: $api_key" \
        -H "Content-Type: application/json" \
        -d "{\"path\": \"$path\"}" \
        -o /dev/null -w "%{http_code}")

    if [ "$result" = "201" ] || [ "$result" = "200" ]; then
        log_success "Root folder added"
    else
        log_warn "Failed to add root folder (HTTP $result) - may need manual config"
    fi
}

main() {
    log_info "=== Bootstrapping Radarr ==="

    # Wait for Radarr to be ready
    wait_for_service "Radarr" "$RADARR_URL" || exit 1

    # Get API key (from .env or extract from config)
    api_key=$(get_env "RADARR_API_KEY")
    if [ -z "$api_key" ]; then
        log_info "Extracting API key from config..."
        api_key=$(get_arr_api_key "radarr")
        if [ -z "$api_key" ]; then
            log_error "Could not extract Radarr API key"
            exit 1
        fi
        update_env "RADARR_API_KEY" "$api_key"
    else
        log_info "Using existing API key from .env"
    fi

    configure_auth "$api_key"
    add_download_client "$api_key"
    add_root_folder "$api_key"

    log_success "Radarr bootstrap complete"
    log_info "Credentials: $DEFAULT_USERNAME / $DEFAULT_PASSWORD"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
