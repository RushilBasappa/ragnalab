# RagnaLab Operations
# Services managed via: docker compose --profile {infra|media|apps} up -d

.PHONY: backup restore status

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
