# RagnaLab

Private homelab platform running on Raspberry Pi 5 with Traefik reverse proxy, automatic HTTPS, and Tailscale VPN access.

## Quick Start

**First time setup?** See [INSTALL.md](INSTALL.md) for complete installation guide.

**Already installed?**
```bash
make up      # Start all services
make down    # Stop all services
make ps      # Show running containers
```

## Services

| URL | Service | Description |
|-----|---------|-------------|
| https://traefik.ragnalab.xyz | Traefik Dashboard | Reverse proxy routing |
| https://status.ragnalab.xyz | Uptime Kuma | Service monitoring |
| https://whoami.ragnalab.xyz | whoami | Test service |

## Project Structure

```
ragnalab/
├── proxy/              # Traefik reverse proxy + socket proxy
├── apps/               # Application stacks
│   ├── whoami/         # Test service
│   ├── uptime-kuma/    # Monitoring dashboard
│   └── backup/         # Automated backups
├── backups/            # Backup archives (7-day retention)
├── Makefile            # Service management
├── INSTALL.md          # Complete installation guide
└── .planning/          # GSD planning docs
```

## Commands

| Command | Description |
|---------|-------------|
| `make up` | Start all services |
| `make down` | Stop all services |
| `make restart` | Restart all services |
| `make ps` | Show running containers |
| `make logs` | View Traefik logs |
| `make backup` | Trigger manual backup |
| `make restore SERVICE=name` | Restore a service from backup |

## Backup & Restore

**Daily automated backups** run at 3 AM with 7-day retention.

```bash
# Manual backup
make backup

# Restore a service
make restore SERVICE=uptime-kuma

# Restore from specific backup
make restore SERVICE=uptime-kuma BACKUP=backup-2026-01-17.tar.gz

# List backups
ls -la backups/
```

See [RESTORE-PROCEDURE.md](.planning/phases/03-operational-infrastructure/RESTORE-PROCEDURE.md) for disaster recovery.

## Adding New Services

1. Create directory: `apps/my-service/`
2. Add `docker-compose.yml` with Traefik labels
3. Run `make up`

Services are auto-discovered by Traefik via Docker labels.

## Documentation

| File | Purpose |
|------|---------|
| [README.md](README.md) | Project overview, quick reference |
| [INSTALL.md](INSTALL.md) | Complete fresh installation guide |
| [RESTORE-PROCEDURE.md](.planning/phases/03-operational-infrastructure/RESTORE-PROCEDURE.md) | Disaster recovery |
