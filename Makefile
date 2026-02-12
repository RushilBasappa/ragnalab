PLAYBOOK = ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml
ENV_FILE = compose/.env
SECRETS_FILE = ansible/vars/secrets.yml
VAULT = --vault-password-file .vault_pass

# app(tag, containers, volumes) - deploy or tear down with v=1
define app
$(if $(v),docker rm -f $(2)$(if $(3), && docker volume rm $(3),),$(PLAYBOOK) --tags $(1))
endef

# Secrets
sync:
	ansible-vault encrypt $(ENV_FILE) --output $(SECRETS_FILE) $(VAULT)

init:
	ansible-vault decrypt $(SECRETS_FILE) --output $(ENV_FILE) $(VAULT)

hooks:
	ln -sf ../../hooks/pre-commit .git/hooks/pre-commit

# First-time setup
fix-locale:
	sudo locale-gen en_US.UTF-8

install-ansible: fix-locale
	sudo apt update && sudo apt install -y ansible

# Bootstrap
system-update:
	$(PLAYBOOK) --tags system-update

github-ssh:
	$(PLAYBOOK) --tags github-ssh

tailscale:
	$(PLAYBOOK) --tags tailscale

docker:
	$(PLAYBOOK) --tags docker

zsh:
	$(PLAYBOOK) --tags zsh

# Services
socket-proxy:
	$(PLAYBOOK) --tags socket-proxy

authelia:
	$(PLAYBOOK) --tags authelia

traefik:
	$(PLAYBOOK) --tags traefik

pihole:
	$(PLAYBOOK) --tags pihole

# Apps — pass v=1 to tear down and delete volumes (e.g. make ntfy v=1)
rustdesk:
	$(call app,rustdesk,rustdesk-hbbs rustdesk-hbbr,rustdesk_data)

homepage:
	$(call app,homepage,homepage,)

uptime-kuma:
	$(call app,uptime-kuma,uptime-kuma autokuma,uptime_kuma_data)

vaultwarden:
	$(call app,vaultwarden,vaultwarden,vaultwarden_data)

paperless-ngx:
	$(call app,paperless-ngx,paperless-ngx paperless-redis,paperless_data paperless_media paperless_export paperless_consume paperless_redis_data)

ntfy:
	$(call app,ntfy,ntfy,ntfy_cache)

tandoor:
	$(call app,tandoor,tandoor tandoor-db,tandoor_postgres_data tandoor_static tandoor_media)

dozzle:
	$(call app,dozzle,dozzle,)
