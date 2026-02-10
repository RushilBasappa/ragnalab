PLAYBOOK = ansible-playbook ansible/site.yml -i ansible/inventory/hosts.yml

# First-time setup
fix-locale:
	sudo locale-gen en_US.UTF-8

install-ansible: fix-locale
	sudo apt update && sudo apt install -y ansible

# Bootstrap
github-ssh:
	$(PLAYBOOK) --tags github-ssh

tailscale:
	$(PLAYBOOK) --tags tailscale

docker:
	$(PLAYBOOK) --tags docker

# Services
rustdesk:
	$(PLAYBOOK) --tags rustdesk
