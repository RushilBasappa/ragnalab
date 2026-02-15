# RagnaLab Tools & Services

**Total Services:** 34 containers across 29 applications
**Architecture:** Raspberry Pi 5 (ARM64) running Docker Compose + Ansible automation

---

## Infrastructure Services (4)

### Socket Proxy
- **Image:** `tecnativa/docker-socket-proxy:latest`
- **Purpose:** Secure Docker socket access for Traefik and monitoring tools
- **Network:** `socket_proxy` (isolated)
- **Security:** Read-only socket mount, dangerous operations disabled
- **Memory Limit:** 64M

### Traefik
- **Image:** `traefik:v3`
- **Purpose:** Reverse proxy with automatic SSL via Let's Encrypt DNS challenge
- **Ports:** 80 (HTTP), 443 (HTTPS)
- **URL:** https://traefik.ragnalab.xyz
- **Features:**
  - Wildcard SSL certificate for `*.ragnalab.xyz`
  - Cloudflare DNS challenge
  - Docker provider with socket proxy integration
  - Automatic HTTP→HTTPS redirect
  - Dashboard protected by Authelia
- **Memory Limit:** 256M

### Authelia
- **Image:** `authelia/authelia:latest`
- **Purpose:** Single Sign-On (SSO) and forward authentication
- **URL:** https://auth.ragnalab.xyz
- **Features:**
  - File-based user database
  - Session management (7d expiration, 1d inactivity, 1M remember-me)
  - SQLite storage backend
  - Selective bypass rules for vault, ntfy, jellyfin, etc.
- **Memory Limit:** 256M

### Pi-hole
- **Image:** `pihole/pihole:latest`
- **Purpose:** Network-wide DNS and ad blocking
- **Ports:** 53/tcp, 53/udp
- **URL:** https://pihole.ragnalab.xyz
- **Memory Limit:** 256M
- **Security Note:** DNS ports currently exposed on `0.0.0.0` (all interfaces)

---

## Media Stack (9 containers, 7 applications)

### Gluetun + qBittorrent
- **Images:** `qmcgaw/gluetun:latest` + `linuxserver/qbittorrent:latest`
- **Purpose:** VPN-protected torrent client
- **URL:** https://qbit.ragnalab.xyz
- **VPN:** ProtonVPN WireGuard with port forwarding
- **Features:**
  - qBittorrent runs in Gluetun's network namespace
  - All torrent traffic encrypted through VPN
  - Port forwarding for better peer connectivity
- **Memory Limits:** Gluetun 128M, qBittorrent 512M

### Sonarr
- **Image:** `linuxserver/sonarr:latest`
- **Purpose:** TV show automation and library management
- **URL:** https://sonarr.ragnalab.xyz
- **Auto-configured:**
  - qBittorrent download client
  - Root folder: `/data/media/tv`
  - 4K Minimal quality profile (prefers x265)
  - Jellyfin library update notifications
  - External auth via Authelia
- **Memory Limit:** 512M

### Radarr
- **Image:** `linuxserver/radarr:latest`
- **Purpose:** Movie automation and library management
- **URL:** https://radarr.ragnalab.xyz
- **Auto-configured:**
  - qBittorrent download client
  - Root folder: `/data/media/movies`
  - 4K Minimal quality profile (prefers x265)
  - Jellyfin library update notifications
  - External auth via Authelia
- **Memory Limit:** 512M

### Prowlarr
- **Image:** `linuxserver/prowlarr:latest`
- **Purpose:** Indexer manager for Sonarr/Radarr
- **URL:** https://prowlarr.ragnalab.xyz
- **Auto-configured:**
  - Sonarr and Radarr app connections
  - Sync indexers to both apps automatically
- **Memory Limit:** 512M

### Bazarr
- **Image:** `linuxserver/bazarr:latest`
- **Purpose:** Subtitle downloader for Sonarr/Radarr
- **URL:** https://bazarr.ragnalab.xyz
- **Auto-configured:**
  - Sonarr and Radarr connections
  - External auth via Authelia
- **Memory Limit:** 512M

### Jellyfin
- **Image:** `jellyfin/jellyfin:latest`
- **Purpose:** Media streaming server
- **URL:** https://jellyfin.ragnalab.xyz
- **Ports:** 8096 (also proxied via Traefik)
- **Hardware:** `/dev/video19` for hardware transcoding (Pi 5)
- **Memory Limit:** 512M
- **Note:** Requires manual setup wizard on first run

### Jellyseerr
- **Image:** `fallenbagel/jellyseerr:latest`
- **Purpose:** Media request and discovery portal
- **URL:** https://requests.ragnalab.xyz
- **Features:**
  - User-friendly interface for requesting content
  - Integration with Jellyfin, Sonarr, and Radarr
  - Manual configuration required after deployment
- **Memory Limit:** 256M

---

## Productivity & Utilities (11)

### Vaultwarden
- **Image:** `vaultwarden/server:latest`
- **Purpose:** Self-hosted Bitwarden password manager
- **URL:** https://vault.ragnalab.xyz
- **Features:**
  - Main vault bypasses Authelia (API/extension compatibility)
  - Admin panel protected by Authelia
  - Signups disabled
- **Memory Limit:** 128M

### Paperless-ngx (2 containers)
- **Images:** `ghcr.io/paperless-ngx/paperless-ngx:latest` + `redis:7-alpine`
- **Purpose:** Document management system with OCR
- **URL:** https://paperless.ragnalab.xyz
- **Features:**
  - Full-text search
  - Automatic OCR
  - Tag and correspondent management
  - Authelia SSO integration
- **Memory Limits:** Paperless 512M, Redis 128M

### Tandoor (2 containers)
- **Images:** `vabene1111/recipes:latest` + `postgres:16-alpine`
- **Purpose:** Recipe manager and meal planner
- **URL:** https://recipes.ragnalab.xyz
- **Memory Limits:** App 256M, DB 128M

### FreshRSS
- **Image:** `lscr.io/linuxserver/freshrss:latest`
- **Purpose:** RSS feed reader
- **URL:** https://rss.ragnalab.xyz
- **Memory Limit:** 128M

### Actual Budget
- **Image:** `actualbudget/actual-server:latest`
- **Purpose:** Personal budgeting and finance tracker
- **URL:** https://budget.ragnalab.xyz
- **Memory Limit:** 128M

### Obsidian LiveSync
- **Image:** `couchdb:3.3`
- **Purpose:** CouchDB backend for Obsidian self-hosted sync
- **URL:** https://obsidian.ragnalab.xyz
- **Memory Limit:** 256M

### Syncthing
- **Image:** `lscr.io/linuxserver/syncthing:latest`
- **Purpose:** Continuous file synchronization
- **URL:** https://sync.ragnalab.xyz
- **Memory Limit:** 256M

### FileBrowser
- **Image:** `filebrowser/filebrowser:latest`
- **Purpose:** Web-based file manager
- **URL:** https://files.ragnalab.xyz
- **Memory Limit:** 128M

### Ntfy
- **Image:** `binwiederhier/ntfy:latest`
- **Purpose:** Push notification service
- **URL:** https://ntfy.ragnalab.xyz
- **Features:** Push notification service
- **Memory Limit:** 64M

### Backrest
- **Image:** `garethgeorge/backrest:latest`
- **Purpose:** Backup management UI (restic frontend)
- **URL:** https://backups.ragnalab.xyz
- **Features:**
  - Mounts `/var/lib/docker/volumes` read-only
  - Web UI for restic backup management
- **Memory Limit:** 256M
- **Status:** Deployed but not configured

---

## Monitoring & Maintenance (6 containers, 5 applications)

### Uptime Kuma + Autokuma (2 containers)
- **Images:** `louislam/uptime-kuma:2` + `ghcr.io/bigboot/autokuma:latest`
- **Purpose:** Uptime monitoring with automatic service discovery
- **URL:** https://uptime.ragnalab.xyz
- **Features:**
  - Autokuma auto-discovers containers via Docker labels
  - HTTP/HTTPS monitoring
  - Custom status pages
- **Memory Limits:** Kuma 256M, Autokuma 128M

### Dozzle
- **Image:** `amir20/dozzle:latest`
- **Purpose:** Real-time Docker log viewer
- **URL:** https://logs.ragnalab.xyz
- **Features:**
  - Multi-container log streaming
  - Search and filter
  - No log persistence
- **Memory Limit:** 64M

### Beszel
- **Image:** `henrygd/beszel:latest`
- **Purpose:** Lightweight server monitoring dashboard
- **URL:** https://beszel.ragnalab.xyz
- **Features:**
  - CPU, memory, disk, network metrics
  - Authelia SSO integration
- **Memory Limit:** 128M

### Speedtest Tracker
- **Image:** `lscr.io/linuxserver/speedtest-tracker:latest`
- **Purpose:** Internet speed test logging
- **URL:** https://speed.ragnalab.xyz
- **Features:**
  - Automated speed tests
  - Historical graphs
- **Memory Limit:** 256M

---

## Other Services (3)

### Homepage
- **Image:** `ghcr.io/gethomepage/homepage:latest`
- **Purpose:** Homelab dashboard
- **URL:** https://home.ragnalab.xyz
- **Features:**
  - Service widgets with live stats
  - Docker integration
  - System resource monitoring
  - Organized by category (Media, Infrastructure, Productivity, Monitoring)
- **Memory Limit:** 256M

### Home Assistant
- **Image:** `ghcr.io/home-assistant/home-assistant:stable`
- **Purpose:** Home automation platform
- **URL:** https://ha.ragnalab.xyz
- **Memory Limit:** 256M

### RustDesk (2 containers)
- **Image:** `rustdesk/rustdesk-server:latest` (hbbs + hbbr)
- **Purpose:** Self-hosted remote desktop relay server
- **Network:** Host mode (bypasses Docker networking)
- **Memory Limit:** 64M per container
- **Security Note:** Host networking exposes all ports

---

## Network Architecture

### Networks
- **traefik_public:** Main application network, all web services
- **socket_proxy:** Isolated network for Docker socket access

### Security Layers
1. **Traefik:** All HTTP/HTTPS traffic, SSL termination
2. **Authelia:** SSO for sensitive services (excluded: vault, jellyfin, ntfy, requests)
3. **Socket Proxy:** Read-only Docker API access
4. **Gluetun VPN:** All torrent traffic encrypted

### DNS Flow
- External DNS → Cloudflare → Traefik (443)
- Internal DNS → Pi-hole (53) → upstream resolvers

---

## Storage Architecture

### Docker Volumes
- **All named volumes** (all `external: true`)
- Location: `/var/lib/docker/volumes/`
- Naming: `<service>_data` (unified naming - e.g., `sonarr_data`, `jellyfin_data`)
- Multi-service apps use subdirectories (e.g., `tandoor_data/postgres`, `paperless_data/redis`)

### Media Storage
- **Bind mount:** `/srv` on host → `/data` in containers
- **Structure:**
  ```
  /srv/
  ├── media/
  │   ├── movies/
  │   └── tv/
  └── torrents/
      ├── incomplete/
      ├── movies/
      └── tv/
  ```

---

## Automation & Configuration

### Ansible Playbooks
- **bootstrap.yml:** System preparation (Docker, Tailscale, SSH, Zsh)
- **deploy-all.yml:** Complete stack deployment
- **deploy-infrastructure.yml:** Core services (socket-proxy, authelia, traefik, pihole)
- **deploy-media.yml:** Media stack in dependency order
- **site.yml:** Tag-based single service deployment

### Auto-Configuration
Services with fully automated setup via Ansible:
- Sonarr, Radarr, Prowlarr, Bazarr (quality profiles, download clients, root folders, notifications)
- qBittorrent (webui settings, authentication)
- Homepage (API keys automatically injected)
- Uptime Kuma (via Autokuma Docker labels)

### Secrets Management
- **Ansible Vault:** `ansible/vars/secrets.yml` (AES-256 encrypted)
- **Pre-commit hook:** Auto-encrypts `compose/.env` changes
- **Vault password:** `.vault_pass` (gitignored, 600 permissions)

---

## Resource Allocation

### Memory Limits Summary
- **Heavy (512M):** Sonarr, Radarr, Prowlarr, Bazarr, Jellyfin, Paperless-ngx, qBittorrent
- **Medium (256M):** Traefik, Authelia, Pi-hole, Homepage, Uptime Kuma, Home Assistant, Tandoor, Syncthing, Obsidian LiveSync, Backrest, Beszel, Speedtest Tracker, Jellyseerr
- **Light (128M):** Gluetun, Vaultwarden, FreshRSS, FileBrowser, Autokuma, Actual Budget, Paperless Redis, Tandoor DB
- **Minimal (64M):** Socket Proxy, Ntfy, Dozzle, RustDesk (x2)

**Total Allocation:** ~8.8GB
**Typical Usage:** ~4-6GB (services don't reach limits under normal load)

---

## Image Tag Strategy

**Current State:** Most images use `:latest` tag
**Exception:** `uptime-kuma:2` (major version pinned)

**Recommendation:** Pin all images to specific versions for reproducibility

---

## Deployment Commands

```bash
# First-time setup
make bootstrap              # System prep (requires reboot after Docker)
make init                   # Decrypt secrets from Ansible Vault

# Full deployment
make deploy-all             # Deploy everything in order

# Partial deployment
make deploy-infra           # Infrastructure only
make deploy-media           # Media stack only
make deploy-apps            # All utility apps

# Single service
make service TAGS=sonarr    # Deploy/update one service

# Utilities
make status                 # System status check
make keys                   # Extract *arr API keys
make teardown APP=ntfy      # Remove a service
```

---

## External Dependencies

### Required External Services
- **Cloudflare:** DNS hosting and API for Let's Encrypt DNS challenge
- **ProtonVPN:** WireGuard credentials for Gluetun
- **GitHub:** SSH access for repository (optional)

### Required Local Services
- **Tailscale:** VPN mesh network (installed via bootstrap)
- **Docker:** Container runtime (installed via bootstrap)

---

## Known Limitations & Future Work

### Current Gaps
- No centralized metrics (Prometheus/Grafana)
- No automated backup execution (Backrest deployed but unconfigured)
- No firewall configuration (UFW not managed)
- No image version pinning (all use `:latest`)
- Pi-hole DNS exposed on all interfaces
- RustDesk uses host networking
- Hardcoded domain across all configs

### Planned Improvements
See [audit.md](audit.md) for detailed recommendations and improvement roadmap.
