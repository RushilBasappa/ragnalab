# RagnaLab

**Fully automated, production-grade homelab on Raspberry Pi 5**

A self-hosted infrastructure stack with 34 services deployed via Ansible automation and Docker Compose. One command takes you from bare metal to a complete homelab with media automation, document management, password vaults, monitoring, and more.

## Features

- **One-command deployment** - Bootstrap from bare Pi to production in minutes
- **34 containerized services** - Media automation, productivity tools, monitoring, and infrastructure
- **Security-first architecture** - Traefik reverse proxy, Authelia SSO, VPN-protected torrents, Docker socket isolation
- **Fully automated provisioning** - Ansible handles everything from system setup to service configuration
- **Zero-touch service integration** - *arr apps, Jellyfin, qBittorrent auto-configured and connected
- **Portable and idempotent** - Deploy on any ARM64/x86_64 system, run playbooks repeatedly without side effects

## Architecture

| Layer | Technology |
|-------|------------|
| Platform | Raspberry Pi 5 (ARM64) |
| OS | Raspberry Pi OS 64-bit (Bookworm) |
| Automation | Ansible + Docker Compose |
| Networking | Tailscale VPN + Traefik reverse proxy |
| Authentication | Authelia SSO with forward auth |
| DNS | Cloudflare (external) + Pi-hole (internal) |
| SSL | Let's Encrypt wildcard certificates via DNS challenge |
| Secrets | Ansible Vault with pre-commit encryption |

## Quick Start

```bash
git clone https://github.com/RushilBasappa/ragnalab.git
cd ragnalab

# Install prerequisites
make fix-locale && make install-ansible

# Set up vault password
echo 'your-vault-password' > .vault_pass
chmod 600 .vault_pass

# Configure environment secrets
cp compose/.env.example compose/.env
nano compose/.env                        # Fill in all values
make sync                                # Encrypt .env to Ansible Vault

# Bootstrap system (installs Docker, Tailscale, SSH keys, Zsh)
make bootstrap

# Deploy everything
make deploy-all
```

> **Existing deployment?** If you already have an encrypted `ansible/vars/secrets.yml`, skip the `.env` steps above and run `make init` to decrypt it instead.

See [docs/setup.md](docs/setup.md) for the complete deployment guide.

## Service Catalog

**Infrastructure** (4): Traefik, Authelia, Pi-hole, Docker Socket Proxy
**Media Stack** (7): Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, Jellyseerr, qBittorrent + Gluetun
**Productivity** (11): Vaultwarden, Paperless-ngx, Tandoor, FreshRSS, Actual Budget, Obsidian LiveSync, Syncthing, FileBrowser, Ntfy, Backrest, Home Assistant
**Monitoring** (5): Uptime Kuma, Dozzle, Beszel, Speedtest Tracker, Homepage Dashboard
**Other** (2): RustDesk

See [docs/services.md](docs/services.md) for detailed service descriptions.

## Repository Structure

```
ragnalab/
├── ansible/                   # Infrastructure as Code
│   ├── inventory/             # Host configuration
│   ├── roles/                 # Reusable Ansible roles
│   ├── tasks/                 # Service deployment tasks
│   │   ├── apps/              # Per-app provisioning
│   │   ├── infra/             # Infrastructure services
│   │   ├── media/             # Media stack
│   │   └── shared/            # Shared utilities and helpers
│   ├── vars/                  # Variables and encrypted secrets
│   ├── bootstrap.yml          # System bootstrap playbook
│   ├── deploy-all.yml         # Full deployment orchestration
│   ├── deploy-infrastructure.yml
│   ├── deploy-media.yml
│   ├── site.yml               # Tag-based deployment
│   └── status.yml             # System health check
├── compose/                   # Docker Compose configurations
│   ├── apps/                  # Application-specific compose files
│   ├── infra/                 # Infrastructure services
│   ├── media/                 # Media stack
│   ├── services/              # Service config directories
│   ├── docker-compose.yml     # Master compose file
│   ├── .env                   # Environment secrets (gitignored)
│   └── .env.example           # Environment template
├── docs/                      # Documentation
│   ├── setup.md               # Complete deployment guide
│   └── services.md            # Service catalog and architecture
├── hooks/                     # Git pre-commit hooks
│   └── pre-commit             # Auto-encrypt .env to Ansible Vault
├── Makefile                   # Operational commands
└── README.md                  # This file
```

## Make Targets

**Setup**
- `make install-ansible` - Install Ansible on the Pi
- `make init` - Decrypt secrets from Ansible Vault to .env
- `make sync` - Encrypt .env back to Ansible Vault
- `make hooks` - Install git pre-commit hooks

**Deployment**
- `make bootstrap` - Full system bootstrap (Docker, Tailscale, SSH, Zsh)
- `make deploy-all` - Deploy everything (infrastructure → media → apps)
- `make deploy-infra` - Deploy core infrastructure only
- `make deploy-media` - Deploy media stack only
- `make deploy-apps` - Deploy utility apps only
- `make service TAGS=sonarr` - Deploy/update a specific service

**Operations**
- `make status` - System health check (containers, memory, disk)
- `make keys` - Extract API keys from *arr apps
- `make teardown APP=ntfy` - Remove a specific service
- `make rename-domain NEW=example.com` - Change domain across all configs
- `make backup` - Trigger manual backup via Backrest
- `make restore APP=... VOL=...` - Restore service from backup

Run `make help` for the complete list.

## Documentation

- **[docs/setup.md](docs/setup.md)** - Complete deployment guide from bare Pi to production
- **[docs/services.md](docs/services.md)** - Service catalog, architecture, and resource allocation

## Security & Best Practices

- All secrets encrypted with Ansible Vault (AES-256)
- Pre-commit hooks prevent unencrypted secrets from being committed
- Docker socket isolated behind read-only proxy
- Torrent traffic routed through VPN (Gluetun + ProtonVPN)
- SSO authentication via Authelia for all sensitive services
- Wildcard SSL certificates with automatic renewal
- Memory limits enforced on all containers

## Requirements

**Hardware:**
- Raspberry Pi 5 (4GB+ RAM recommended) or any ARM64/x86_64 Linux system
- MicroSD card (64GB+ recommended)
- Stable internet connection

**External Services:**
- Cloudflare account (for DNS and SSL certificate challenge)
- ProtonVPN account (or other WireGuard VPN provider)
- Tailscale account (for VPN mesh networking)

## License

This is a personal homelab setup. Feel free to use, modify, and adapt to your needs. No warranty or support provided.

## Acknowledgments

Built with open-source tools from the homelab and self-hosting community. Special thanks to the maintainers of Traefik, Authelia, LinuxServer.io containers, and the *arr ecosystem.
