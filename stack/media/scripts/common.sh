#!/bin/bash
# Common utilities for bootstrap scripts

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Wait for a service to be healthy (HTTP 200 or 401/302 for auth-protected)
wait_for_service() {
    local name="$1"
    local url="$2"
    local max_attempts="${3:-30}"
    local attempt=1

    log_info "Waiting for $name to be ready..."
    while [ $attempt -le $max_attempts ]; do
        status=$(curl -ks -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
        if [[ "$status" =~ ^(200|401|302|303)$ ]]; then
            log_success "$name is ready (HTTP $status)"
            return 0
        fi
        echo -n "."
        sleep 2
        ((attempt++))
    done
    echo ""
    log_error "$name did not become ready after $max_attempts attempts"
    return 1
}

# Extract API key from arr app config.xml (Prowlarr, Sonarr, Radarr)
get_arr_api_key() {
    local container="$1"
    docker exec "$container" cat /config/config.xml 2>/dev/null | grep -oP '(?<=<ApiKey>)[^<]+' || echo ""
}

# Extract API key from Bazarr config.yaml
get_bazarr_api_key() {
    docker exec bazarr cat /config/config/config.yaml 2>/dev/null | grep -A1 "^auth:" | grep "apikey:" | awk '{print $2}' | tr -d '"' || echo ""
}

# Update .env file with a key=value pair
update_env() {
    local key="$1"
    local value="$2"
    local env_file="${ENV_FILE:-.env}"

    if grep -q "^${key}=" "$env_file" 2>/dev/null; then
        # Key exists, update it
        sed -i "s|^${key}=.*|${key}=${value}|" "$env_file"
    else
        # Key doesn't exist, append it
        echo "${key}=${value}" >> "$env_file"
    fi
    log_info "Updated $key in $env_file"
}

# Check if a value is set in .env
get_env() {
    local key="$1"
    local env_file="${ENV_FILE:-.env}"
    grep "^${key}=" "$env_file" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo ""
}

# Default credentials (user should change after setup)
DEFAULT_USERNAME="${BOOTSTRAP_USERNAME:-admin}"
DEFAULT_PASSWORD="${BOOTSTRAP_PASSWORD:-Ragnalab2026}"

# qBittorrent defaults (set by LinuxServer image)
QBIT_USERNAME="${QBIT_USERNAME:-admin}"
QBIT_PASSWORD="${QBIT_PASSWORD:-adminadmin}"
QBIT_HOST="${QBIT_HOST:-gluetun}"
QBIT_PORT="${QBIT_PORT:-8080}"
