# RagnaLab Operations
# Services managed via: docker compose --profile {infra|media|apps} up -d

.PHONY: init networks volumes volumes-delete backup restore status

# === Setup Targets ===

# First-time setup: create networks and volumes
init: networks volumes
	@echo "RagnaLab initialized. Ready to deploy with:"
	@echo "  docker compose --profile infra --profile media --profile apps up -d"

# Create required Docker networks
networks:
	@echo "Creating networks..."
	@docker network create proxy 2>/dev/null || echo "  proxy (exists)"
	@docker network create socket_proxy_network 2>/dev/null || echo "  socket_proxy_network (exists)"
	@docker network create media 2>/dev/null || echo "  media (exists)"
	@echo "Networks ready."

# Create required Docker volumes
volumes:
	@echo "Creating volumes..."
	@docker volume create ragnalab_uptime-kuma-data 2>/dev/null || echo "  ragnalab_uptime-kuma-data (exists)"
	@docker volume create ragnalab_vaultwarden-data 2>/dev/null || echo "  ragnalab_vaultwarden-data (exists)"
	@docker volume create ragnalab_rustdesk-data 2>/dev/null || echo "  ragnalab_rustdesk-data (exists)"
	@docker volume create ragnalab_prowlarr-config 2>/dev/null || echo "  ragnalab_prowlarr-config (exists)"
	@docker volume create ragnalab_sonarr-config 2>/dev/null || echo "  ragnalab_sonarr-config (exists)"
	@docker volume create ragnalab_radarr-config 2>/dev/null || echo "  ragnalab_radarr-config (exists)"
	@docker volume create ragnalab_bazarr-config 2>/dev/null || echo "  ragnalab_bazarr-config (exists)"
	@docker volume create ragnalab_jellyfin-config 2>/dev/null || echo "  ragnalab_jellyfin-config (exists)"
	@docker volume create ragnalab_jellyseerr-config 2>/dev/null || echo "  ragnalab_jellyseerr-config (exists)"
	@docker volume create ragnalab_qbittorrent-config 2>/dev/null || echo "  ragnalab_qbittorrent-config (exists)"
	@docker volume create ragnalab_gluetun-data 2>/dev/null || echo "  ragnalab_gluetun-data (exists)"
	@echo "Volumes ready."

# Delete all external volumes (WARNING: destroys all data)
volumes-delete:
	@echo "WARNING: This will delete ALL service data!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@echo "Deleting volumes..."
	@docker volume rm ragnalab_uptime-kuma-data 2>/dev/null || echo "  ragnalab_uptime-kuma-data (not found)"
	@docker volume rm ragnalab_vaultwarden-data 2>/dev/null || echo "  ragnalab_vaultwarden-data (not found)"
	@docker volume rm ragnalab_rustdesk-data 2>/dev/null || echo "  ragnalab_rustdesk-data (not found)"
	@docker volume rm ragnalab_prowlarr-config 2>/dev/null || echo "  ragnalab_prowlarr-config (not found)"
	@docker volume rm ragnalab_sonarr-config 2>/dev/null || echo "  ragnalab_sonarr-config (not found)"
	@docker volume rm ragnalab_radarr-config 2>/dev/null || echo "  ragnalab_radarr-config (not found)"
	@docker volume rm ragnalab_bazarr-config 2>/dev/null || echo "  ragnalab_bazarr-config (not found)"
	@docker volume rm ragnalab_jellyfin-config 2>/dev/null || echo "  ragnalab_jellyfin-config (not found)"
	@docker volume rm ragnalab_jellyseerr-config 2>/dev/null || echo "  ragnalab_jellyseerr-config (not found)"
	@docker volume rm ragnalab_qbittorrent-config 2>/dev/null || echo "  ragnalab_qbittorrent-config (not found)"
	@docker volume rm ragnalab_gluetun-data 2>/dev/null || echo "  ragnalab_gluetun-data (not found)"
	@echo "Volumes deleted."

# === Operations Targets ===

# Trigger manual backup
backup:
	@echo "Triggering manual backup..."
	@docker exec backup backup 2>&1 | grep -E "(INFO|ERROR)" || true
	@echo "\nBackup complete. Recent archives:"
	@ls -lht backups/*.tar.gz 2>/dev/null | head -3

# Restore from backup
restore:
ifndef SERVICE
	@echo "Usage: make restore SERVICE=<service-name> [BACKUP=<filename>]"
	@echo "\nAvailable services to restore:"
	@echo "  vaultwarden, uptime-kuma, prowlarr, sonarr, radarr, bazarr"
	@echo "  jellyfin, jellyseerr, qbittorrent, gluetun, pihole, rustdesk, traefik"
	@echo "\nAvailable backups:"
	@ls -1 backups/*.tar.gz 2>/dev/null | xargs -n1 basename | head -10 || echo "(none)"
else
	@./stack/infra/backup/scripts/restore.sh $(SERVICE) $(BACKUP)
endif

# Status overview
status:
ifdef SERVICE
	@echo "=== $(SERVICE) Status ==="
	@docker ps --filter "name=$(SERVICE)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@docker logs --tail 20 $(SERVICE) 2>/dev/null || echo "(no logs)"
else
	@echo "=== Container Status ==="
	@docker ps --format "table {{.Names}}\t{{.Status}}" | head -20
	@echo ""
	@echo "=== Recent Backups ==="
	@ls -lht backups/*.tar.gz 2>/dev/null | head -3 || echo "(no backups)"
	@echo ""
	@echo "=== Disk Usage ==="
	@df -h /home/rushil/workspace/ragnalab | tail -1 | awk '{print "Used: "$$3" / "$$2" ("$$5" full)"}'
	@echo ""
	@echo "Tip: make status SERVICE=<name> for detailed view"
endif
