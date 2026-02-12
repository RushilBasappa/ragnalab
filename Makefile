PLAYBOOK = ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml
ENV_FILE = compose/.env
SECRETS_FILE = ansible/vars/secrets.yml
VAULT = --vault-password-file .vault_pass

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

# Apps
rustdesk:
	$(PLAYBOOK) --tags rustdesk

homepage:
	$(PLAYBOOK) --tags homepage

uptime-kuma:
	$(PLAYBOOK) --tags uptime-kuma

vaultwarden:
	$(PLAYBOOK) --tags vaultwarden

paperless-ngx:
	$(PLAYBOOK) --tags paperless-ngx

ntfy:
	$(PLAYBOOK) --tags ntfy

tandoor:
	$(PLAYBOOK) --tags tandoor
