.DEFAULT_GOAL := help
ANSIBLE  := ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory/hosts.yml
VAULT    := --vault-password-file .vault_pass
SITE     := $(ANSIBLE) ansible/site.yml $(VAULT)

.PHONY: help init sync hooks fix-locale install-ansible bootstrap deploy-infra deploy-media deploy-apps deploy-all status keys service teardown teardown-all

# --- Setup ---

help: ## Show this help
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

init: ## Decrypt secrets from Ansible Vault to compose/.env
	ansible-vault decrypt ansible/vars/secrets.yml --output compose/.env $(VAULT)

sync: ## Encrypt compose/.env to Ansible Vault
	ansible-vault encrypt compose/.env --output ansible/vars/secrets.yml $(VAULT)

hooks: ## Install git pre-commit hooks
	ln -sf ../../hooks/pre-commit .git/hooks/pre-commit

# --- First-time (run before Ansible is available) ---

fix-locale: ## Fix locale to en_US.UTF-8
	sudo locale-gen en_US.UTF-8

install-ansible: fix-locale ## Install Ansible
	sudo apt update && sudo apt install -y ansible

# --- Orchestrated Deployments ---

bootstrap: ## Full bootstrap: bare Pi to configured system
	$(ANSIBLE) ansible/bootstrap.yml $(VAULT)

deploy-infra: ## Deploy infrastructure (socket-proxy, authelia, traefik, pihole)
	$(ANSIBLE) ansible/deploy-infrastructure.yml $(VAULT)

deploy-media: ## Deploy media stack in dependency order
	$(ANSIBLE) ansible/deploy-media.yml $(VAULT)

deploy-apps: ## Deploy all utility apps (non-infra, non-media)
	$(SITE) --tags apps

deploy-all: ## Deploy everything (infrastructure + media + apps)
	$(ANSIBLE) ansible/deploy-all.yml $(VAULT)

# --- Granular Control ---

service: ## Deploy one or more services: make service TAGS=sonarr,radarr
	$(SITE) --tags $(TAGS)

teardown: ## Tear down an app: make teardown APP=ntfy
	$(SITE) --tags $(APP) -e app_state=absent

teardown-all: ## Stop all containers and delete all volumes
	@echo "This will STOP all containers and DELETE all Docker volumes."
	@echo ""
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || (echo "Aborted."; exit 1)
	cd compose && docker compose down --remove-orphans --volumes
	@docker volume ls -q | xargs -r docker volume rm 2>/dev/null || true
	@echo "Done. Run 'make deploy-all' to rebuild."

# --- Utilities ---

status: ## Show running containers, memory, disk
	$(ANSIBLE) ansible/status.yml $(VAULT)

keys: ## Extract API keys from *arr apps
	@for app in sonarr radarr prowlarr; do \
		vol="/var/lib/docker/volumes/$${app}_config/_data/config.xml"; \
		key=$$(sudo sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "$$vol" 2>/dev/null); \
		printf "%-10s %s\n" "$$app" "$${key:-not deployed}"; \
	done
