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
	@docker volume create vaultwarden_vaultwarden-data 2>/dev/null || echo "  vaultwarden_vaultwarden-data (exists)"
	@docker volume create rustdesk_rustdesk-data 2>/dev/null || echo "  rustdesk_rustdesk-data (exists)"
	@docker volume create prowlarr_prowlarr-config 2>/dev/null || echo "  prowlarr_prowlarr-config (exists)"
	@docker volume create sonarr_sonarr-config 2>/dev/null || echo "  sonarr_sonarr-config (exists)"
	@docker volume create radarr_radarr-config 2>/dev/null || echo "  radarr_radarr-config (exists)"
	@docker volume create bazarr_bazarr-config 2>/dev/null || echo "  bazarr_bazarr-config (exists)"
	@docker volume create jellyfin_jellyfin-config 2>/dev/null || echo "  jellyfin_jellyfin-config (exists)"
	@docker volume create jellyseerr_jellyseerr-config 2>/dev/null || echo "  jellyseerr_jellyseerr-config (exists)"
	@docker volume create qbittorrent_qbittorrent-config 2>/dev/null || echo "  qbittorrent_qbittorrent-config (exists)"
	@docker volume create gluetun_gluetun-data 2>/dev/null || echo "  gluetun_gluetun-data (exists)"
	@echo "Volumes ready."

# Delete all external volumes (WARNING: destroys all data)
volumes-delete:
	@echo "WARNING: This will delete ALL service data!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@echo "Deleting volumes..."
	@docker volume rm ragnalab_uptime-kuma-data 2>/dev/null || echo "  ragnalab_uptime-kuma-data (not found)"
	@docker volume rm vaultwarden_vaultwarden-data 2>/dev/null || echo "  vaultwarden_vaultwarden-data (not found)"
	@docker volume rm rustdesk_rustdesk-data 2>/dev/null || echo "  rustdesk_rustdesk-data (not found)"
	@docker volume rm prowlarr_prowlarr-config 2>/dev/null || echo "  prowlarr_prowlarr-config (not found)"
	@docker volume rm sonarr_sonarr-config 2>/dev/null || echo "  sonarr_sonarr-config (not found)"
	@docker volume rm radarr_radarr-config 2>/dev/null || echo "  radarr_radarr-config (not found)"
	@docker volume rm bazarr_bazarr-config 2>/dev/null || echo "  bazarr_bazarr-config (not found)"
	@docker volume rm jellyfin_jellyfin-config 2>/dev/null || echo "  jellyfin_jellyfin-config (not found)"
	@docker volume rm jellyseerr_jellyseerr-config 2>/dev/null || echo "  jellyseerr_jellyseerr-config (not found)"
	@docker volume rm qbittorrent_qbittorrent-config 2>/dev/null || echo "  qbittorrent_qbittorrent-config (not found)"
	@docker volume rm gluetun_gluetun-data 2>/dev/null || echo "  gluetun_gluetun-data (not found)"
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
