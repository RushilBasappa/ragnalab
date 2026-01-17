# RagnaLab Service Management
# Usage: make up | make down | make ps | make logs

APPS := $(wildcard apps/*/docker-compose.yml)

.PHONY: up down restart ps logs

up:
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
