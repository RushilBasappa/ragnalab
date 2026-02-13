# RagnaLab v2

Fully automated Raspberry Pi homelab with 34 self-hosted services.

## Features

- **One-command deployment** from bare Pi to production (`make deploy-all`)
- **34 services:** Jellyfin, *arr suite, Vaultwarden, Paperless, Pi-hole, and more
- **Security-first:** Traefik + Authelia SSO, Docker socket proxy, VPN-protected torrents
- **Monitoring:** Uptime Kuma, Dozzle, Watchtower, Homepage dashboard

## Quick Start

```bash
git clone git@github.com:RushilBasappa/ragnalab.git
cd ragnalab
make fix-locale && make install-ansible
# Set up .vault_pass and secrets (see SETUP.md)
make bootstrap
make init
make deploy-all
```

See [SETUP.md](SETUP.md) for the complete deployment guide.

## Architecture

| Layer | Stack |
|-------|-------|
| Platform | Raspberry Pi 5 (ARM64) |
| OS | Raspberry Pi OS 64-bit (Bookworm) |
| Automation | Ansible + Docker Compose |
| Networking | Tailscale VPN + Traefik reverse proxy |
| Auth | Authelia SSO with forward auth |
| DNS | Cloudflare + Pi-hole |
| Secrets | Ansible Vault with pre-commit encryption |

## Make Targets

```
make help             # Show all targets
make bootstrap        # Full system setup
make init             # Decrypt secrets
make deploy-all       # Deploy everything
make deploy-infra     # Infrastructure only
make deploy-media     # Media stack only
make deploy-apps      # Utility apps only
make service TAGS=x   # Deploy specific service
make status           # System health check
make teardown APP=x   # Remove a service
make rename-domain NEW=example.com  # Change domain
```

## Documentation

- **[SETUP.md](SETUP.md)** -- Complete deployment guide
- **[TOOLS.md](TOOLS.md)** -- Service catalog and descriptions
