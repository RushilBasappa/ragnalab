# RagnaLab Documentation

Self-hosted homelab on Raspberry Pi 5 with secure reverse proxy, automated backups, and media automation.

---

## Quick Start

1. [Prerequisites](getting-started/prerequisites.md) — hardware, accounts, domain
2. [Cloudflare Setup](getting-started/cloudflare.md) — DNS and API token
3. [Host Setup](getting-started/host-setup.md) — Pi configuration, Docker, Tailscale
4. [Deploy Traefik](infrastructure/traefik.md) — reverse proxy with SSL

---

## Documentation

### Getting Started

| Document | Description |
|----------|-------------|
| [Prerequisites](getting-started/prerequisites.md) | Hardware, accounts, and domain requirements |
| [Cloudflare Setup](getting-started/cloudflare.md) | DNS configuration and API token |
| [Host Setup](getting-started/host-setup.md) | Raspberry Pi configuration |

### Infrastructure

Deploy in this order:

| Document | Service | URL |
|----------|---------|-----|
| [Traefik](infrastructure/traefik.md) | Reverse proxy + SSL | traefik.ragnalab.xyz |
| [Uptime Kuma](infrastructure/uptime-kuma.md) | Monitoring | status.ragnalab.xyz |
| [Backup](infrastructure/backup.md) | Automated backups | — |

### Applications

| Document | Service | URL |
|----------|---------|-----|
| [Homepage](apps/homepage.md) | Dashboard | home.ragnalab.xyz |
| [Vaultwarden](apps/vaultwarden.md) | Password manager | vault.ragnalab.xyz |
| [Pi-hole](apps/pihole.md) | DNS ad blocking | pihole.ragnalab.xyz |

### Media Stack

Complete media automation — see [Media Stack Overview](media/index.md) for deployment order.

| Document | Service | URL |
|----------|---------|-----|
| [Overview](media/index.md) | Stack orchestration | — |
| [Gluetun](media/gluetun.md) | VPN tunnel | — |
| [qBittorrent](media/qbittorrent.md) | Torrent client | localhost:8080 |
| [Prowlarr](media/prowlarr.md) | Indexer manager | prowlarr.ragnalab.xyz |
| [Sonarr](media/sonarr.md) | TV automation | sonarr.ragnalab.xyz |
| [Radarr](media/radarr.md) | Movie automation | radarr.ragnalab.xyz |
| [Bazarr](media/bazarr.md) | Subtitles | bazarr.ragnalab.xyz |
| [Unpackerr](media/unpackerr.md) | Archive extraction | — |
| [Jellyfin](media/jellyfin.md) | Media server | jellyfin.ragnalab.xyz |
| [Jellyseerr](media/jellyseerr.md) | Request portal | requests.ragnalab.xyz |

---

## Services Overview

| Service | URL | Purpose |
|---------|-----|---------|
| Traefik | traefik.ragnalab.xyz | Reverse proxy dashboard |
| Uptime Kuma | status.ragnalab.xyz | Service monitoring |
| Homepage | home.ragnalab.xyz | Dashboard |
| Vaultwarden | vault.ragnalab.xyz | Password manager |
| Pi-hole | pihole.ragnalab.xyz | DNS ad blocking |
| Prowlarr | prowlarr.ragnalab.xyz | Indexer management |
| Sonarr | sonarr.ragnalab.xyz | TV automation |
| Radarr | radarr.ragnalab.xyz | Movie automation |
| Bazarr | bazarr.ragnalab.xyz | Subtitles |
| Jellyfin | jellyfin.ragnalab.xyz | Media streaming |
| Jellyseerr | requests.ragnalab.xyz | Media requests |

---

## Quick Commands

```bash
# Start all infrastructure
make up

# Stop all infrastructure
make down

# View running containers
make ps

# Trigger backup
make backup

# Restore a service
make restore SERVICE=vaultwarden
```

---

## Adding New Apps

See `apps/whoami/docker-compose.yml` in the repository for the template pattern.

Key labels for auto-discovery:

```yaml
labels:
  # Traefik routing
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.ragnalab.xyz`)"
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"

  # Homepage dashboard
  - "homepage.group=Applications"
  - "homepage.name=My App"
  - "homepage.href=https://myapp.ragnalab.xyz"
```
