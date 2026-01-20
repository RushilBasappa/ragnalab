# RagnaLab Operations
# Services managed via: docker compose --profile {infra|media|apps} up -d

.PHONY: init networks volumes media-dirs volumes-delete backup restore restore-all status bootstrap

# === Setup Targets ===

# First-time setup: create networks, volumes, and directories
init: networks volumes media-dirs
	@echo "RagnaLab initialized. Ready to deploy with:"
	@echo "  docker compose --profile infra --profile media --profile apps up -d"

# Create media directory structure
media-dirs:
	@echo "Creating media directories..."
	@sudo mkdir -p /media/downloads/torrents/movies
	@sudo mkdir -p /media/downloads/torrents/tv
	@sudo mkdir -p /media/library/movies
	@sudo mkdir -p /media/library/tv
	@sudo chown -R 1000:1000 /media
	@echo "Media directories ready."

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
	@docker volume create ragnalab_autokuma-data 2>/dev/null || echo "  ragnalab_autokuma-data (exists)"
	@docker volume create ragnalab_backrest-data 2>/dev/null || echo "  ragnalab_backrest-data (exists)"
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
	@docker volume create ragnalab_recyclarr-config 2>/dev/null || echo "  ragnalab_recyclarr-config (exists)"
	@docker volume create ragnalab_maintainerr-config 2>/dev/null || echo "  ragnalab_maintainerr-config (exists)"
	@docker volume create ragnalab_plex-config 2>/dev/null || echo "  ragnalab_plex-config (exists)"
	@echo "Volumes ready."

# Bootstrap media stack (configure apps after fresh deploy)
bootstrap:
	@./stack/media/bootstrap.sh

# Volume groups by profile
VOLUMES_INFRA := ragnalab_uptime-kuma-data ragnalab_autokuma-data ragnalab_backrest-data
VOLUMES_MEDIA := ragnalab_prowlarr-config ragnalab_sonarr-config ragnalab_radarr-config ragnalab_bazarr-config ragnalab_jellyfin-config ragnalab_jellyseerr-config ragnalab_qbittorrent-config ragnalab_gluetun-data ragnalab_recyclarr-config ragnalab_maintainerr-config ragnalab_plex-config
VOLUMES_APPS := ragnalab_vaultwarden-data ragnalab_rustdesk-data

# Delete volumes (WARNING: destroys data)
# Usage: make volumes-delete [profile=infra|media|apps]
volumes-delete:
ifeq ($(profile),media)
	@echo "WARNING: This will delete media volumes!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@for vol in $(VOLUMES_MEDIA); do docker volume rm $$vol 2>/dev/null && echo "  $$vol (deleted)" || echo "  $$vol (not found)"; done
else ifeq ($(profile),apps)
	@echo "WARNING: This will delete apps volumes!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@for vol in $(VOLUMES_APPS); do docker volume rm $$vol 2>/dev/null && echo "  $$vol (deleted)" || echo "  $$vol (not found)"; done
else ifeq ($(profile),infra)
	@echo "WARNING: This will delete infra volumes!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@for vol in $(VOLUMES_INFRA); do docker volume rm $$vol 2>/dev/null && echo "  $$vol (deleted)" || echo "  $$vol (not found)"; done
else
	@echo "WARNING: This will delete ALL service data!"
	@echo "Press Ctrl+C to cancel, or wait 5 seconds..."
	@sleep 5
	@for vol in $(VOLUMES_INFRA) $(VOLUMES_MEDIA) $(VOLUMES_APPS); do docker volume rm $$vol 2>/dev/null && echo "  $$vol (deleted)" || echo "  $$vol (not found)"; done
endif
	@echo "Done."

# === Operations Targets ===

# Trigger manual backup
backup:
	@echo "Triggering manual backup..."
	@docker exec backup backup 2>&1 | grep -E "(INFO|ERROR)" || true
	@echo "\nBackup complete. Recent archives:"
	@ls -lht backups/*.tar.gz 2>/dev/null | head -3

# Restore from backup (single service)
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

# Services to restore (order matters: infra first, then apps, then media)
RESTORE_SERVICES := uptime-kuma vaultwarden rustdesk pihole traefik-acme prowlarr sonarr radarr bazarr jellyfin jellyseerr qbittorrent gluetun

# Restore all services from backup
# Usage: make restore-all [BACKUP=<filename>]
restore-all:
	@echo "=== Full System Restore ==="
	@echo ""
	@echo "This will restore ALL services from backup:"
	@echo "  $(RESTORE_SERVICES)"
	@echo ""
	@if [ -z "$(BACKUP)" ]; then \
		echo "Using: backup-latest.tar.gz"; \
	else \
		echo "Using: $(BACKUP)"; \
	fi
	@echo ""
	@echo "WARNING: This will OVERWRITE all existing service data!"
	@echo "Press Ctrl+C to cancel, or wait 10 seconds..."
	@sleep 10
	@echo ""
	@echo "Step 1: Stopping all services..."
	@docker compose --profile infra --profile media --profile apps down 2>/dev/null || true
	@echo ""
	@echo "Step 2: Ensuring volumes exist..."
	@$(MAKE) -s volumes
	@echo ""
	@echo "Step 3: Restoring services..."
	@for svc in $(RESTORE_SERVICES); do \
		echo ""; \
		echo "--- Restoring $$svc ---"; \
		echo "y" | ./stack/infra/backup/scripts/restore.sh $$svc $(BACKUP) 2>&1 | grep -v "^$$" || true; \
	done
	@echo ""
	@echo "Step 4: Starting all services..."
	@docker compose --profile infra --profile media --profile apps up -d
	@echo ""
	@echo "=== Restore complete ==="
	@echo "Verify services at their URLs"

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
