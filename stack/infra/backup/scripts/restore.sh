#!/bin/bash
# restore.sh - Restore Docker volume from backup
# Usage: ./restore.sh <service-name> [backup-filename]
# Example: ./restore.sh uptime-kuma
# Example: ./restore.sh uptime-kuma backup-2026-01-17T03-00-00.tar.gz

set -euo pipefail

# Configuration
RAGNALAB_ROOT="/home/rushil/workspace/ragnalab"
BACKUP_DIR="${RAGNALAB_ROOT}/backups"
STACK_DIR="${RAGNALAB_ROOT}/stack"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Service to compose path mapping
# Format: service-name:compose-path:volume-name:backup-dir-name
# volume-name: Docker volume name (without project prefix)
# backup-dir-name: Directory name in backup archive
get_service_config() {
    local service="$1"
    case "$service" in
        # Infrastructure services
        uptime-kuma)
            echo "stack/infra/uptime-kuma/docker-compose.yml:uptime-kuma_uptime-kuma-data:uptime-kuma"
            ;;
        homepage)
            echo "stack/infra/homepage/docker-compose.yml:homepage_homepage-config:homepage"
            ;;
        traefik-acme)
            # Special case: bind mount restore
            echo "BIND_MOUNT:${STACK_DIR}/infra/traefik/config/acme:traefik-acme"
            ;;
        pihole)
            # Special case: bind mount restore
            echo "BIND_MOUNT:${STACK_DIR}/infra/pihole/etc-pihole:pihole"
            ;;
        glances)
            echo "stack/infra/glances/docker-compose.yml:NONE:glances"
            ;;
        # App services
        vaultwarden)
            echo "stack/apps/vaultwarden/docker-compose.yml:vaultwarden_vaultwarden-data:vaultwarden"
            ;;
        rustdesk)
            echo "stack/apps/rustdesk/docker-compose.yml:rustdesk_rustdesk-data:rustdesk"
            ;;
        # Media services
        prowlarr)
            echo "stack/media/prowlarr/docker-compose.yml:prowlarr_prowlarr-config:prowlarr"
            ;;
        sonarr)
            echo "stack/media/sonarr/docker-compose.yml:sonarr_sonarr-config:sonarr"
            ;;
        radarr)
            echo "stack/media/radarr/docker-compose.yml:radarr_radarr-config:radarr"
            ;;
        bazarr)
            echo "stack/media/bazarr/docker-compose.yml:bazarr_bazarr-config:bazarr"
            ;;
        jellyfin)
            echo "stack/media/jellyfin/docker-compose.yml:jellyfin_jellyfin-config:jellyfin"
            ;;
        jellyseerr)
            echo "stack/media/jellyseerr/docker-compose.yml:jellyseerr_jellyseerr-config:jellyseerr"
            ;;
        qbittorrent)
            echo "stack/media/qbittorrent/docker-compose.yml:qbittorrent_qbittorrent-config:qbittorrent"
            ;;
        gluetun)
            echo "stack/media/gluetun/docker-compose.yml:gluetun_gluetun-data:gluetun"
            ;;
        *)
            echo ""
            ;;
    esac
}

show_usage() {
    echo "Usage: $0 <service-name> [backup-filename]"
    echo ""
    echo "Arguments:"
    echo "  service-name    Name of the service to restore"
    echo "  backup-filename Optional specific backup file (defaults to latest)"
    echo ""
    echo "Available services:"
    echo "  Infrastructure: uptime-kuma, homepage, traefik-acme, pihole, glances"
    echo "  Apps:           vaultwarden, rustdesk"
    echo "  Media:          prowlarr, sonarr, radarr, bazarr, jellyfin, jellyseerr, qbittorrent, gluetun"
    echo ""
    echo "Available backups:"
    ls -1 "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | xargs -n1 basename || echo "  (none found)"
}

# Validate arguments
SERVICE_NAME="${1:-}"
BACKUP_FILE="${2:-}"

if [[ -z "$SERVICE_NAME" ]]; then
    show_usage
    exit 1
fi

# Get service configuration
SERVICE_CONFIG=$(get_service_config "$SERVICE_NAME")
if [[ -z "$SERVICE_CONFIG" ]]; then
    log_error "Unknown service: ${SERVICE_NAME}"
    echo ""
    show_usage
    exit 1
fi

# Parse service config
IFS=':' read -r COMPOSE_PATH VOLUME_NAME BACKUP_DIR_NAME <<< "$SERVICE_CONFIG"

# Determine backup file to use
if [[ -z "$BACKUP_FILE" ]]; then
    # Use latest symlink if available, otherwise newest file
    if [[ -L "${BACKUP_DIR}/backup-latest.tar.gz" ]]; then
        BACKUP_PATH="${BACKUP_DIR}/backup-latest.tar.gz"
        log_info "Using latest backup (symlink)"
    else
        BACKUP_PATH=$(ls -t "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | head -1)
        if [[ -z "$BACKUP_PATH" ]]; then
            log_error "No backup files found in ${BACKUP_DIR}"
            exit 1
        fi
        log_info "Using newest backup file"
    fi
else
    BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
fi

if [[ ! -f "$BACKUP_PATH" ]]; then
    log_error "Backup file not found: ${BACKUP_PATH}"
    exit 1
fi

log_info "Restoring ${SERVICE_NAME} from $(basename ${BACKUP_PATH})"
echo ""

# Confirm before proceeding
read -p "This will OVERWRITE existing data for ${SERVICE_NAME}. Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_warn "Restore cancelled"
    exit 0
fi

# Handle bind mount restore (no Docker volume)
if [[ "$COMPOSE_PATH" == "BIND_MOUNT" ]]; then
    BIND_MOUNT_PATH="$VOLUME_NAME"  # In bind mount mode, VOLUME_NAME holds the path

    log_info "Restoring bind mount to: ${BIND_MOUNT_PATH}"

    # Extract backup to temp location
    TEMP_DIR=$(mktemp -d)
    log_info "Extracting backup to ${TEMP_DIR}..."
    tar -xzf "$BACKUP_PATH" -C "$TEMP_DIR"

    # Find the extracted data
    EXTRACTED_DATA="${TEMP_DIR}/backup/${BACKUP_DIR_NAME}"
    if [[ ! -d "$EXTRACTED_DATA" ]]; then
        log_error "Service data not found in backup: ${EXTRACTED_DATA}"
        log_info "Backup contains:"
        ls -la "${TEMP_DIR}/backup/" 2>/dev/null || ls -la "${TEMP_DIR}/"
        rm -rf "$TEMP_DIR"
        exit 1
    fi

    # Restore to bind mount location
    log_info "Restoring data to ${BIND_MOUNT_PATH}..."
    mkdir -p "$BIND_MOUNT_PATH"
    rm -rf "${BIND_MOUNT_PATH:?}"/*
    cp -a "${EXTRACTED_DATA}/." "$BIND_MOUNT_PATH/"

    # Cleanup
    rm -rf "$TEMP_DIR"

    log_info "=== Bind mount restore complete ==="
    log_info "No service restart needed for: ${SERVICE_NAME}"
    exit 0
fi

# Handle services with no persistent data
if [[ "$VOLUME_NAME" == "NONE" ]]; then
    log_warn "Service ${SERVICE_NAME} has no persistent data to restore"
    exit 0
fi

# Docker volume restore flow
COMPOSE_FULL_PATH="${RAGNALAB_ROOT}/${COMPOSE_PATH}"
if [[ ! -f "$COMPOSE_FULL_PATH" ]]; then
    log_error "Compose file not found: ${COMPOSE_FULL_PATH}"
    exit 1
fi

# Step 1: Stop the service
log_info "Stopping ${SERVICE_NAME}..."
docker compose -f "${COMPOSE_FULL_PATH}" down || true

# Step 2: Extract backup to temp location
TEMP_DIR=$(mktemp -d)
log_info "Extracting backup to ${TEMP_DIR}..."
tar -xzf "$BACKUP_PATH" -C "$TEMP_DIR"

# Step 3: Find the extracted data for this service
EXTRACTED_DATA="${TEMP_DIR}/backup/${BACKUP_DIR_NAME}"
if [[ ! -d "$EXTRACTED_DATA" ]]; then
    log_error "Service data not found in backup: ${EXTRACTED_DATA}"
    log_info "Backup contains:"
    ls -la "${TEMP_DIR}/backup/" 2>/dev/null || ls -la "${TEMP_DIR}/"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 4: Verify volume exists
if ! docker volume inspect "$VOLUME_NAME" &>/dev/null; then
    log_warn "Volume ${VOLUME_NAME} does not exist. Creating..."
    docker volume create "$VOLUME_NAME"
fi
log_info "Target volume: ${VOLUME_NAME}"

# Step 5: Restore data to volume
log_info "Restoring data to volume..."
docker run --rm \
    -v "${VOLUME_NAME}:/restore" \
    -v "${EXTRACTED_DATA}:/backup:ro" \
    alpine sh -c "rm -rf /restore/* && cp -a /backup/. /restore/"

# Step 6: Cleanup temp directory
rm -rf "$TEMP_DIR"

# Step 7: Restart service
log_info "Restarting ${SERVICE_NAME}..."
docker compose -f "${COMPOSE_FULL_PATH}" up -d

# Step 8: Verify service is running
sleep 5
if docker ps --filter "name=${SERVICE_NAME}" --format "{{.Status}}" | grep -q "Up"; then
    log_info "Service ${SERVICE_NAME} is running"
else
    log_warn "Service may not have started correctly. Check: docker logs ${SERVICE_NAME}"
fi

echo ""
log_info "=== Restore complete ==="
log_info "Verify the service at its URL and check data integrity"
