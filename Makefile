# RagnaLab Service Management
# Usage: make up | make down | make ps | make logs | make backup | make restore SERVICE=name

APPS := $(wildcard apps/*/docker-compose.yml)

.PHONY: up down restart ps logs networks backup restore

networks:
	@docker network create proxy 2>/dev/null || true
	@docker network create socket_proxy_network 2>/dev/null || true

up: networks
	@docker compose -f proxy/docker-compose.yml up -d
	@for f in $(APPS); do docker compose -f $$f up -d; done
	@echo "\nAll services started."

down:
	@for f in $(APPS); do docker compose -f $$f down; done
	@docker compose -f proxy/docker-compose.yml down
	@echo "\nAll services stopped."

restart: down up

ps:
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

logs:
	@docker compose -f proxy/docker-compose.yml logs -f

backup:
	@echo "Triggering manual backup..."
	@docker kill --signal=SIGUSR1 backup
	@sleep 10
	@echo "\nBackup complete. Archives:"
	@ls -lh backups/*.tar.gz 2>/dev/null | tail -3

restore:
ifndef SERVICE
	@echo "Usage: make restore SERVICE=<service-name>"
	@echo "\nAvailable services:"
	@ls -1 apps/ | grep -v backup
	@echo "\nAvailable backups:"
	@ls -1 backups/*.tar.gz 2>/dev/null | xargs -n1 basename || echo "(none)"
else
	@./apps/backup/scripts/restore.sh $(SERVICE) $(BACKUP)
endif
