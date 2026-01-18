#!/bin/bash
# restore.sh - Restore Docker volume from backup
# Usage: ./restore.sh <service-name> [backup-filename]
# Example: ./restore.sh uptime-kuma
# Example: ./restore.sh uptime-kuma backup-2026-01-17T03-00-00.tar.gz

set -euo pipefail

# Configuration
RAGNALAB_ROOT="/home/rushil/workspace/ragnalab"
BACKUP_DIR="${RAGNALAB_ROOT}/backups"
APPS_DIR="${RAGNALAB_ROOT}/apps"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Validate arguments
SERVICE_NAME="${1:-}"
BACKUP_FILE="${2:-}"

if [[ -z "$SERVICE_NAME" ]]; then
    echo "Usage: $0 <service-name> [backup-filename]"
    echo ""
    echo "Arguments:"
    echo "  service-name    Name of the service to restore (e.g., uptime-kuma)"
    echo "  backup-filename Optional specific backup file (defaults to latest)"
    echo ""
    echo "Available services:"
    ls -1 "${APPS_DIR}" 2>/dev/null | grep -v backup || echo "  (none found)"
    echo ""
    echo "Available backups:"
    ls -1 "${BACKUP_DIR}"/*.tar.gz 2>/dev/null | xargs -n1 basename || echo "  (none found)"
    exit 1
fi

# Validate service exists
SERVICE_DIR="${APPS_DIR}/${SERVICE_NAME}"
if [[ ! -d "$SERVICE_DIR" ]]; then
    log_error "Service directory not found: ${SERVICE_DIR}"
    exit 1
fi

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

# Step 1: Stop the service
log_info "Stopping ${SERVICE_NAME}..."
docker compose -f "${SERVICE_DIR}/docker-compose.yml" down || true

# Step 2: Extract backup to temp location
TEMP_DIR=$(mktemp -d)
log_info "Extracting backup to ${TEMP_DIR}..."
tar -xzf "$BACKUP_PATH" -C "$TEMP_DIR"

# Step 3: Find the extracted data for this service
EXTRACTED_DATA="${TEMP_DIR}/backup/${SERVICE_NAME}"
if [[ ! -d "$EXTRACTED_DATA" ]]; then
    log_error "Service data not found in backup: ${EXTRACTED_DATA}"
    log_info "Backup contains:"
    ls -la "${TEMP_DIR}/backup/" 2>/dev/null || ls -la "${TEMP_DIR}/"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Step 4: Determine volume name
# Convention: <stack>_<service>-data or <service>-data
VOLUME_NAME="${SERVICE_NAME}_${SERVICE_NAME}-data"
if ! docker volume inspect "$VOLUME_NAME" &>/dev/null; then
    VOLUME_NAME="${SERVICE_NAME}-data"
    if ! docker volume inspect "$VOLUME_NAME" &>/dev/null; then
        log_error "Could not find volume for ${SERVICE_NAME}"
        log_info "Tried: ${SERVICE_NAME}_${SERVICE_NAME}-data, ${SERVICE_NAME}-data"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
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
docker compose -f "${SERVICE_DIR}/docker-compose.yml" up -d

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
