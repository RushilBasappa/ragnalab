#!/bin/bash
# Bootstrap Jellyfin - Complete setup wizard, create libraries, disable transcoding
#
# This script:
# 1. Waits for Jellyfin to be ready
# 2. Completes the startup wizard via API
# 3. Creates an admin user
# 4. Creates Movies and TV Shows libraries
# 5. Disables transcoding (Pi 5 direct-play only)
# 6. Generates and saves API key to .env

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"
JELLYFIN_URL="${JELLYFIN_URL:-http://localhost:8096}"

check_startup_complete() {
    # Check if startup wizard is already complete
    local status=$(curl -ks "$JELLYFIN_URL/System/Info/Public" | jq -r '.StartupWizardCompleted // false')
    [ "$status" = "true" ]
}

complete_startup_wizard() {
    log_info "Completing Jellyfin startup wizard..."

    # Step 1: Get startup configuration
    curl -ks -X POST "$JELLYFIN_URL/Startup/Configuration" \
        -H "Content-Type: application/json" \
        -d '{
            "UICulture": "en-US",
            "MetadataCountryCode": "US",
            "PreferredMetadataLanguage": "en"
        }' > /dev/null

    # Step 2: Create initial user
    log_info "Creating admin user..."
    curl -ks -X POST "$JELLYFIN_URL/Startup/User" \
        -H "Content-Type: application/json" \
        -d "{
            \"Name\": \"$DEFAULT_USERNAME\",
            \"Password\": \"$DEFAULT_PASSWORD\"
        }" > /dev/null

    # Step 3: Set remote access settings
    curl -ks -X POST "$JELLYFIN_URL/Startup/RemoteAccess" \
        -H "Content-Type: application/json" \
        -d '{
            "EnableRemoteAccess": true,
            "EnableAutomaticPortMapping": false
        }' > /dev/null

    # Step 4: Complete the wizard
    curl -ks -X POST "$JELLYFIN_URL/Startup/Complete" > /dev/null

    log_success "Startup wizard completed"
}

authenticate() {
    # Authenticate and get access token
    local response=$(curl -ks -X POST "$JELLYFIN_URL/Users/AuthenticateByName" \
        -H "Content-Type: application/json" \
        -H "X-Emby-Authorization: MediaBrowser Client=\"Bootstrap\", Device=\"CLI\", DeviceId=\"bootstrap-script\", Version=\"1.0.0\"" \
        -d "{
            \"Username\": \"$DEFAULT_USERNAME\",
            \"Pw\": \"$DEFAULT_PASSWORD\"
        }")

    echo "$response" | jq -r '.AccessToken // empty'
}

get_user_id() {
    local token="$1"
    curl -ks "$JELLYFIN_URL/Users" \
        -H "X-Emby-Token: $token" | jq -r '.[0].Id // empty'
}

create_api_key() {
    local token="$1"

    # Check for existing API key
    local existing=$(curl -ks "$JELLYFIN_URL/Auth/Keys" \
        -H "X-Emby-Token: $token" | jq -r '.Items[] | select(.AppName == "Homepage") | .AccessToken // empty')

    if [ -n "$existing" ]; then
        echo "$existing"
        return
    fi

    # Create new API key
    curl -ks -X POST "$JELLYFIN_URL/Auth/Keys?app=Homepage" \
        -H "X-Emby-Token: $token" > /dev/null

    # Retrieve the created key
    curl -ks "$JELLYFIN_URL/Auth/Keys" \
        -H "X-Emby-Token: $token" | jq -r '.Items[] | select(.AppName == "Homepage") | .AccessToken // empty'
}

create_library() {
    local token="$1"
    local name="$2"
    local path="$3"
    local type="$4"

    # Check if library exists
    local existing=$(curl -ks "$JELLYFIN_URL/Library/VirtualFolders" \
        -H "X-Emby-Token: $token" | jq -r ".[] | select(.Name == \"$name\") | .Name // empty")

    if [ -n "$existing" ]; then
        log_success "Library '$name' already exists"
        return 0
    fi

    log_info "Creating library: $name -> $path"

    curl -ks -X POST "$JELLYFIN_URL/Library/VirtualFolders?name=$name&collectionType=$type&refreshLibrary=false" \
        -H "X-Emby-Token: $token" \
        -H "Content-Type: application/json" \
        -d "{
            \"LibraryOptions\": {
                \"EnablePhotos\": false,
                \"EnableRealtimeMonitor\": true,
                \"EnableChapterImageExtraction\": false,
                \"ExtractChapterImagesDuringLibraryScan\": false,
                \"PathInfos\": [{\"Path\": \"$path\"}],
                \"SaveLocalMetadata\": false,
                \"EnableInternetProviders\": true,
                \"EnableAutomaticSeriesGrouping\": true,
                \"EnableEmbeddedTitles\": false,
                \"EnableEmbeddedEpisodeInfos\": false,
                \"AutomaticRefreshIntervalDays\": 0,
                \"PreferredMetadataLanguage\": \"en\",
                \"MetadataCountryCode\": \"US\",
                \"SeasonZeroDisplayName\": \"Specials\",
                \"AutomaticallyAddToCollection\": false,
                \"EnablePhotos\": false,
                \"SkipSubtitlesIfAudioTrackMatches\": true,
                \"SkipSubtitlesIfEmbeddedSubtitlesPresent\": true,
                \"SaveSubtitlesWithMedia\": true
            }
        }" > /dev/null

    log_success "Library '$name' created"
}

disable_transcoding() {
    local token="$1"

    log_info "Disabling transcoding (Pi 5 direct-play only)..."

    # Get current encoding options
    local config=$(curl -ks "$JELLYFIN_URL/System/Configuration/encoding" \
        -H "X-Emby-Token: $token")

    # Update to disable hardware acceleration
    local updated=$(echo "$config" | jq '
        .HardwareAccelerationType = "none" |
        .EnableHardwareEncoding = false |
        .EnableTonemapping = false |
        .EnableVppTonemapping = false |
        .EnableIntelLowPowerH264HwEncoder = false |
        .EnableIntelLowPowerHevcHwEncoder = false
    ')

    curl -ks -X POST "$JELLYFIN_URL/System/Configuration/encoding" \
        -H "X-Emby-Token: $token" \
        -H "Content-Type: application/json" \
        -d "$updated" > /dev/null

    log_success "Transcoding disabled"
}

main() {
    log_info "=== Bootstrapping Jellyfin ==="

    # Wait for Jellyfin to be ready
    wait_for_service "Jellyfin" "$JELLYFIN_URL" || exit 1

    # Check if already configured
    if ! check_startup_complete; then
        complete_startup_wizard
        sleep 3
    else
        log_success "Jellyfin startup wizard already completed"
    fi

    # Authenticate
    log_info "Authenticating..."
    token=$(authenticate)
    if [ -z "$token" ]; then
        log_error "Failed to authenticate with Jellyfin"
        exit 1
    fi

    # Create libraries
    create_library "$token" "Movies" "/data/media/movies" "movies"
    create_library "$token" "TV Shows" "/data/media/tv" "tvshows"

    # Disable transcoding
    disable_transcoding "$token"

    # Create/get API key
    api_key=$(get_env "JELLYFIN_API_KEY")
    if [ -z "$api_key" ]; then
        log_info "Creating API key..."
        api_key=$(create_api_key "$token")
        if [ -n "$api_key" ]; then
            update_env "JELLYFIN_API_KEY" "$api_key"
        else
            log_warn "Could not create API key"
        fi
    else
        log_info "Using existing API key from .env"
    fi

    log_success "Jellyfin bootstrap complete"
    log_info "Credentials: $DEFAULT_USERNAME / $DEFAULT_PASSWORD"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
