# RagnaLab

Private homelab platform running on Raspberry Pi 5 with Traefik reverse proxy, automatic HTTPS, and Tailscale VPN access.

## Quick Start

**First time setup?** See the [Documentation](docs/index.md) for complete installation guide.

**Already installed?**
```bash
make up      # Start all services
make down    # Stop all services
make ps      # Show running containers
```

## Services

| URL | Service | Description |
|-----|---------|-------------|
| https://traefik.ragnalab.xyz | Traefik | Reverse proxy dashboard |
| https://status.ragnalab.xyz | Uptime Kuma | Service monitoring |
| https://home.ragnalab.xyz | Homepage | Dashboard |
| https://vault.ragnalab.xyz | Vaultwarden | Password manager |
| https://pihole.ragnalab.xyz | Pi-hole | DNS ad blocking |
| https://prowlarr.ragnalab.xyz | Prowlarr | Indexer management |
| https://sonarr.ragnalab.xyz | Sonarr | TV automation |
| https://radarr.ragnalab.xyz | Radarr | Movie automation |
| https://bazarr.ragnalab.xyz | Bazarr | Subtitles |
| https://jellyfin.ragnalab.xyz | Jellyfin | Media server |
| https://requests.ragnalab.xyz | Jellyseerr | Media requests |

## Project Structure

```
ragnalab/
├── docs/               # Documentation
│   ├── getting-started/    # Prerequisites, setup
│   ├── infrastructure/     # Traefik, monitoring, backup
│   ├── apps/               # Homepage, Vaultwarden, Pi-hole
│   └── media/              # Media automation stack
├── proxy/              # Traefik reverse proxy
├── apps/               # Application stacks
│   ├── homepage/
│   ├── uptime-kuma/
│   ├── vaultwarden/
│   ├── backup/
│   ├── pihole/
│   └── media/          # Media automation (9 services)
├── backups/            # Backup archives
└── Makefile            # Service management
```

## Commands

| Command | Description |
|---------|-------------|
| `make up` | Start all infrastructure |
| `make down` | Stop all infrastructure |
| `make ps` | Show running containers |
| `make backup` | Trigger manual backup |
| `make restore SERVICE=name` | Restore a service |

## Documentation

| Document | Description |
|----------|-------------|
| [docs/index.md](docs/index.md) | Documentation home |
| [docs/getting-started/](docs/getting-started/) | Installation prerequisites |
| [docs/infrastructure/](docs/infrastructure/) | Core services (Traefik, monitoring) |
| [docs/apps/](docs/apps/) | Applications |
| [docs/media/](docs/media/) | Media automation stack |

## Adding New Services

1. Create directory: `apps/my-service/`
2. Add `docker-compose.yml` with Traefik labels
3. Run `docker compose -f apps/my-service/docker-compose.yml up -d`

Services are auto-discovered by Traefik via Docker labels. See [docs/index.md](docs/index.md#adding-new-apps) for template.
