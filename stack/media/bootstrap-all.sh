#!/bin/bash
# Bootstrap All Media Stack Services
#
# This script orchestrates the bootstrap of all media stack services.
# Run this after bringing up the stack with `docker compose up -d`.
#
# Usage:
#   ./bootstrap-all.sh              # Bootstrap all services
#   ./bootstrap-all.sh --skip-jellyseerr  # Skip Jellyseerr (requires browser)
#   ./bootstrap-all.sh prowlarr sonarr    # Bootstrap specific services only
#
# Execution Order (respects dependencies):
#   1. Prowlarr     - Indexer manager (needs API key first)
#   2. Sonarr       - TV automation (needs qBittorrent info)
#   3. Radarr       - Movie automation (needs qBittorrent info)
#   4. Prowlarr Sync - Connect Prowlarr to Sonarr/Radarr
#   5. Bazarr       - Subtitle automation (needs Sonarr/Radarr keys)
#   6. Jellyfin     - Media server (independent)
#   7. Jellyseerr   - Request portal (needs all keys, browser required)
#
# Environment Variables:
#   BOOTSTRAP_USERNAME  - Default username (default: admin)
#   BOOTSTRAP_PASSWORD  - Default password (default: Ragnalab2026)
#   QBIT_USERNAME       - qBittorrent username (default: admin)
#   QBIT_PASSWORD       - qBittorrent password (default: adminadmin)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Source common utilities
source "$SCRIPTS_DIR/common.sh"

# Export ENV_FILE for all scripts
export ENV_FILE="$SCRIPT_DIR/.env"

# Parse arguments
SKIP_JELLYSEERR=false
SPECIFIC_SERVICES=()

for arg in "$@"; do
    case $arg in
        --skip-jellyseerr)
            SKIP_JELLYSEERR=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS] [SERVICES...]"
            echo ""
            echo "Options:"
            echo "  --skip-jellyseerr    Skip Jellyseerr (requires browser setup)"
            echo "  --help, -h           Show this help"
            echo ""
            echo "Services: prowlarr, sonarr, radarr, bazarr, jellyfin, jellyseerr"
            echo ""
            echo "Examples:"
            echo "  $0                   # Bootstrap all services"
            echo "  $0 prowlarr sonarr   # Bootstrap specific services"
            echo "  $0 --skip-jellyseerr # Bootstrap all except Jellyseerr"
            exit 0
            ;;
        *)
            SPECIFIC_SERVICES+=("$arg")
            ;;
    esac
done

should_run() {
    local service="$1"
    if [ ${#SPECIFIC_SERVICES[@]} -eq 0 ]; then
        return 0  # Run all if no specific services requested
    fi
    for s in "${SPECIFIC_SERVICES[@]}"; do
        if [ "$s" = "$service" ]; then
            return 0
        fi
    done
    return 1
}

run_bootstrap() {
    local name="$1"
    local script="$2"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Running: $name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ -x "$script" ]; then
        if "$script"; then
            log_success "$name completed"
            return 0
        else
            log_error "$name failed"
            return 1
        fi
    else
        log_error "Script not found or not executable: $script"
        return 1
    fi
}

main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║           MEDIA STACK BOOTSTRAP                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Environment file: $ENV_FILE"
    log_info "Default credentials: ${BOOTSTRAP_USERNAME:-admin} / ${BOOTSTRAP_PASSWORD:-Ragnalab2026}"
    echo ""

    # Check .env exists
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found at $ENV_FILE"
        log_info "Copy .env.example to .env and configure VPN credentials first"
        exit 1
    fi

    # Track failures
    FAILED=()

    # Wave 1: Prowlarr (generates API key needed by others)
    if should_run "prowlarr"; then
        run_bootstrap "Prowlarr" "$SCRIPTS_DIR/bootstrap-prowlarr.sh" || FAILED+=("prowlarr")
    fi

    # Wave 2: Sonarr and Radarr (parallel, independent)
    if should_run "sonarr"; then
        run_bootstrap "Sonarr" "$SCRIPTS_DIR/bootstrap-sonarr.sh" || FAILED+=("sonarr")
    fi

    if should_run "radarr"; then
        run_bootstrap "Radarr" "$SCRIPTS_DIR/bootstrap-radarr.sh" || FAILED+=("radarr")
    fi

    # Wave 3: Prowlarr Sync (after Sonarr/Radarr have keys)
    if should_run "prowlarr" || should_run "sonarr" || should_run "radarr"; then
        run_bootstrap "Prowlarr Sync" "$SCRIPTS_DIR/bootstrap-prowlarr-sync.sh" || FAILED+=("prowlarr-sync")
    fi

    # Wave 4: Bazarr (needs Sonarr/Radarr keys)
    if should_run "bazarr"; then
        run_bootstrap "Bazarr" "$SCRIPTS_DIR/bootstrap-bazarr.sh" || FAILED+=("bazarr")
    fi

    # Wave 5: Jellyfin (independent)
    if should_run "jellyfin"; then
        run_bootstrap "Jellyfin" "$SCRIPTS_DIR/bootstrap-jellyfin.sh" || FAILED+=("jellyfin")
    fi

    # Wave 6: Jellyseerr (needs all keys, browser required)
    if should_run "jellyseerr" && [ "$SKIP_JELLYSEERR" = "false" ]; then
        run_bootstrap "Jellyseerr" "$SCRIPTS_DIR/bootstrap-jellyseerr.sh" || FAILED+=("jellyseerr")
    elif [ "$SKIP_JELLYSEERR" = "true" ]; then
        log_info "Skipping Jellyseerr (--skip-jellyseerr)"
    fi

    # Summary
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║           BOOTSTRAP SUMMARY                                       ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""

    if [ ${#FAILED[@]} -eq 0 ]; then
        log_success "All services bootstrapped successfully!"
    else
        log_error "Some services failed: ${FAILED[*]}"
    fi

    echo ""
    log_info "Default credentials for all services: ${BOOTSTRAP_USERNAME:-admin} / ${BOOTSTRAP_PASSWORD:-Ragnalab2026}"
    log_warn "IMPORTANT: Change these passwords after first login!"
    echo ""
    log_info "Next steps:"
    echo "  1. Add indexers in Prowlarr: https://prowlarr.ragnalab.xyz"
    echo "  2. Complete Jellyseerr setup if skipped: https://requests.ragnalab.xyz"
    echo "  3. Change default passwords in each service"
    echo ""

    if [ ${#FAILED[@]} -gt 0 ]; then
        exit 1
    fi
}

main "$@"
