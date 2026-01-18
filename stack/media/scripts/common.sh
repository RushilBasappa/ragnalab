#!/bin/bash
# Common utilities for bootstrap scripts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-$SCRIPT_DIR/../.env}"

# Load .env file
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
fi

# Wait for service to respond
wait_for() {
    local url="$1"
    local max=30
    echo "Waiting for $url..."
    for i in $(seq 1 $max); do
        if curl -ks -o /dev/null -w "" "$url" 2>/dev/null; then
            echo "Ready."
            return 0
        fi
        sleep 2
    done
    echo "Timeout waiting for $url"
    return 1
}

# Get API key from arr app config.xml
get_api_key() {
    local container="$1"
    docker exec "$container" cat /config/config.xml 2>/dev/null | grep -oP '(?<=<ApiKey>)[^<]+' || echo ""
}
