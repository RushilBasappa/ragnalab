# Media Automation Stack Installation

Complete media automation system: request → download → organize → watch.

---

## Overview

```
┌─────────────┐     ┌──────────┐     ┌─────────────┐     ┌──────────┐
│ Jellyseerr  │────▶│  Sonarr  │────▶│ qBittorrent │────▶│ Jellyfin │
│ (requests)  │     │  Radarr  │     │   (VPN)     │     │ (watch)  │
└─────────────┘     └────┬─────┘     └──────┬──────┘     └──────────┘
                         │                  │
                    ┌────▼─────┐      ┌─────▼─────┐
                    │ Prowlarr │      │  Gluetun  │
                    │(indexers)│      │  (VPN)    │
                    └──────────┘      └───────────┘
```

| Service | Purpose | URL |
|---------|---------|-----|
| Gluetun | VPN tunnel for torrent privacy | (internal) |
| qBittorrent | Torrent download client | localhost:8080 |
| Prowlarr | Indexer management | prowlarr.ragnalab.xyz |
| Sonarr | TV show automation | sonarr.ragnalab.xyz |
| Radarr | Movie automation | radarr.ragnalab.xyz |
| Bazarr | Subtitle automation | bazarr.ragnalab.xyz |
| Unpackerr | Archive extraction | (headless) |
| Jellyfin | Media server | jellyfin.ragnalab.xyz |
| Jellyseerr | Request portal | requests.ragnalab.xyz |

---

## Prerequisites

- Traefik running (see [proxy/INSTALL.md](../../proxy/INSTALL.md))
- **VPN account with WireGuard support** (ProtonVPN, Mullvad, etc.)

---

## Quick Start

```bash
# 1. Configure VPN credentials
cp apps/media/.env.example apps/media/.env
nano apps/media/.env

# 2. Deploy all services (order matters!)
./apps/media/deploy.sh

# Or manually in order:
docker compose -f apps/media/gluetun/docker-compose.yml up -d
docker compose -f apps/media/qbittorrent/docker-compose.yml up -d
docker compose -f apps/media/prowlarr/docker-compose.yml up -d
docker compose -f apps/media/sonarr/docker-compose.yml up -d
docker compose -f apps/media/radarr/docker-compose.yml up -d
docker compose -f apps/media/bazarr/docker-compose.yml up -d
docker compose -f apps/media/unpackerr/docker-compose.yml up -d
docker compose -f apps/media/jellyfin/docker-compose.yml up -d
docker compose -f apps/media/jellyseerr/docker-compose.yml up -d
```

---

## Installation (Step by Step)

### Step 1: Configure VPN Credentials

```bash
cp apps/media/.env.example apps/media/.env
nano apps/media/.env
```

**For ProtonVPN:**
1. Go to https://account.protonvpn.com/downloads
2. Click "WireGuard configuration"
3. Select a server (e.g., US)
4. Copy credentials into .env:

```
VPN_SERVICE_PROVIDER=protonvpn
WIREGUARD_PRIVATE_KEY=your-private-key-here
WIREGUARD_ADDRESSES=10.2.0.2/32
SERVER_COUNTRIES=United States
```

### Step 2: Deploy Services in Order

**Order matters!** Services depend on each other.

| Order | Service | Install Guide | Depends On |
|-------|---------|---------------|------------|
| 1 | Gluetun | [gluetun/INSTALL.md](gluetun/INSTALL.md) | VPN credentials |
| 2 | qBittorrent | [qbittorrent/INSTALL.md](qbittorrent/INSTALL.md) | Gluetun |
| 3 | Prowlarr | [prowlarr/INSTALL.md](prowlarr/INSTALL.md) | — |
| 4 | Sonarr | [sonarr/INSTALL.md](sonarr/INSTALL.md) | qBittorrent, Prowlarr |
| 5 | Radarr | [radarr/INSTALL.md](radarr/INSTALL.md) | qBittorrent, Prowlarr |
| 6 | Bazarr | [bazarr/INSTALL.md](bazarr/INSTALL.md) | Sonarr, Radarr |
| 7 | Unpackerr | [unpackerr/INSTALL.md](unpackerr/INSTALL.md) | Sonarr, Radarr |
| 8 | Jellyfin | [jellyfin/INSTALL.md](jellyfin/INSTALL.md) | — |
| 9 | Jellyseerr | [jellyseerr/INSTALL.md](jellyseerr/INSTALL.md) | Jellyfin, Sonarr, Radarr |

### Step 3: Manual Configuration Required

After deployment, these services need browser setup:

| Service | What to Configure |
|---------|-------------------|
| **Prowlarr** | Add indexers (YTS, EZTV, TorrentGalaxy) |
| **Jellyfin** | Complete setup wizard, create admin account |
| **Jellyseerr** | Connect to Jellyfin, Sonarr, Radarr |

See individual INSTALL.md files for detailed steps.

---

## Verify Installation

### Check VPN Protection (Critical!)

```bash
# Get VPN IP (should NOT be your home IP)
docker exec qbittorrent curl -s ifconfig.me

# Compare with your home IP
curl -s ifconfig.me

# These should be DIFFERENT!
```

### Check All Services Running

```bash
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "gluetun|qbittorrent|prowlarr|sonarr|radarr|bazarr|unpackerr|jellyfin|jellyseerr"
```

### Check HTTPS Access

```bash
curl -I https://prowlarr.ragnalab.xyz
curl -I https://sonarr.ragnalab.xyz
curl -I https://radarr.ragnalab.xyz
curl -I https://jellyfin.ragnalab.xyz
curl -I https://requests.ragnalab.xyz
```

---

## Default Credentials

All arr apps are configured with default credentials:

| Service | Username | Password |
|---------|----------|----------|
| Prowlarr | admin | Ragnalab2026 |
| Sonarr | admin | Ragnalab2026 |
| Radarr | admin | Ragnalab2026 |
| Bazarr | (no auth by default) | — |
| Jellyfin | abc | Ragnalab2026 |

**Change these after setup!**

---

## Directory Structure

```
/media/
├── downloads/           # Active downloads
│   ├── tv/             # TV show downloads
│   └── movies/         # Movie downloads
├── incomplete/         # In-progress downloads
└── library/            # Organized media
    ├── tv/             # TV shows (Sonarr manages)
    └── movies/         # Movies (Radarr manages)
```

All services mount `/media` to enable hardlinks between downloads and library.

---

## How It Works

1. **User requests** a show/movie in Jellyseerr
2. **Jellyseerr** sends request to Sonarr (TV) or Radarr (movies)
3. **Sonarr/Radarr** searches Prowlarr indexers for releases
4. **qBittorrent** downloads via VPN (traffic encrypted through Gluetun)
5. **Sonarr/Radarr** moves completed files to library (hardlink)
6. **Bazarr** downloads subtitles automatically
7. **Jellyfin** detects new media and makes it available
8. **User watches** in Jellyfin

---

## Uptime Kuma Monitors

Add these monitors to https://status.ragnalab.xyz:

**HTTP(s) Monitors:**

| Name | URL |
|------|-----|
| Prowlarr | https://prowlarr.ragnalab.xyz |
| Sonarr | https://sonarr.ragnalab.xyz |
| Radarr | https://radarr.ragnalab.xyz |
| Bazarr | https://bazarr.ragnalab.xyz |
| Jellyfin | https://jellyfin.ragnalab.xyz |
| Jellyseerr | https://requests.ragnalab.xyz |

**Docker Container Monitors:**

| Name | Container |
|------|-----------|
| gluetun | gluetun |
| qbittorrent | qbittorrent |
| prowlarr | prowlarr |
| sonarr | sonarr |
| radarr | radarr |
| bazarr | bazarr |
| unpackerr | unpackerr |
| jellyfin | jellyfin |
| jellyseerr | jellyseerr |

---

## Troubleshooting

### VPN not connecting

```bash
docker logs gluetun
```

Check credentials in `apps/media/.env`.

### qBittorrent showing home IP

qBittorrent must use Gluetun's network:
```bash
docker inspect qbittorrent --format='{{.HostConfig.NetworkMode}}'
# Should show: container:gluetun
```

### Sonarr/Radarr can't connect to qBittorrent

Check they're on the same network:
```bash
docker network inspect media
```

### Downloads not moving to library

Verify `/media` mount is the same across all containers:
```bash
docker inspect sonarr --format='{{json .Mounts}}' | jq '.[] | select(.Destination=="/media")'
```

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/.env` | VPN credentials, API keys |
| `apps/media/.env.example` | Template for .env |
| `apps/media/*/docker-compose.yml` | Service configurations |

---

*See individual service INSTALL.md files for detailed configuration.*
