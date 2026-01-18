# Phase 7: Operational Hardening - Research

**Researched:** 2026-01-18
**Domain:** Docker Compose restructuring, Docker socket-proxy, Autokuma monitoring automation, backup system completion
**Confidence:** HIGH

## Summary

Phase 7 consolidates operational concerns: extending backup coverage, securing Docker socket access for all services, deploying Autokuma for automated monitoring, and restructuring Docker Compose files for cleaner management. The research confirms that socket-proxy is already deployed (for Traefik) and can be extended to Homepage and Uptime Kuma with appropriate permission settings.

The Docker Compose `include` directive (available since v2.20.0) is mature and well-suited for the proposed restructuring. Autokuma provides label-based monitor automation that integrates seamlessly with existing Docker Compose workflows. The backup system already covers most services but needs auditing for completeness and the restore script needs updating to handle the new compose structure.

**Primary recommendation:** Execute in order: (1) Compose restructuring first (enables cleaner service management), (2) Socket-proxy migration (security hardening), (3) Backup audit and expansion, (4) Autokuma deployment with labels.

## Standard Stack

The established tools for this phase:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| [Tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy) | latest | Docker API security proxy | Already deployed for Traefik; industry standard for reducing attack surface |
| [BigBoot/AutoKuma](https://github.com/BigBoot/AutoKuma) | master (for Uptime Kuma v2) | Automated monitor creation | Only tool that provides label-based Uptime Kuma automation |
| [offen/docker-volume-backup](https://github.com/offen/docker-volume-backup) | v2 | Automated volume backups | Already deployed; handles stop-during-backup coordination |
| Docker Compose | 2.20.0+ | Service orchestration | Native `include` directive for modular compose files |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| GNU Make | Operational shortcuts | backup, restore, status targets only |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| socket-proxy | linuxserver/socket-proxy | Drop-in replacement with same API; Tecnativa already deployed |
| Autokuma | Manual Uptime Kuma monitors | More control but doesn't scale; can't version control monitors |

## Architecture Patterns

### Recommended Project Structure (Post-Restructuring)
```
ragnalab/
├── docker-compose.yml          # Root: includes all category composes
├── .env                        # Shared secrets (symlinked or sourced)
├── Makefile                    # backup, restore, status only
├── infra/
│   └── docker-compose.yml      # profile=infra: traefik, socket-proxy, uptime-kuma, homepage, backup, autokuma
├── media/
│   └── docker-compose.yml      # profile=media: gluetun, qbittorrent, *arr stack, jellyfin, jellyseerr
├── apps/
│   └── docker-compose.yml      # profile=apps: vaultwarden, pihole, rustdesk, glances, ip-info
└── backups/                    # Backup archives
```

### Pattern 1: Docker Compose Include with Profiles
**What:** Root compose file uses `include` to pull in category composes; each category uses its own profile
**When to use:** Multi-service homelab with logical groupings
**Example:**
```yaml
# Root docker-compose.yml
include:
  - path: infra/docker-compose.yml
  - path: media/docker-compose.yml
  - path: apps/docker-compose.yml
```

```yaml
# infra/docker-compose.yml
services:
  traefik:
    profiles: ["infra"]
    # ... config
  socket-proxy:
    profiles: ["infra"]
    # ... config
```

**Usage:**
```bash
# Bring up infrastructure only
docker compose --profile infra up -d

# Bring up everything
docker compose --profile infra --profile media --profile apps up -d
```

### Pattern 2: Socket-Proxy Shared Access
**What:** Single socket-proxy instance serves multiple consumers via shared network
**When to use:** Multiple services need Docker API access
**Example:**
```yaml
# socket-proxy configuration with permissions for all consumers
socket-proxy:
  image: tecnativa/docker-socket-proxy:latest
  environment:
    # Read-only operations (safe)
    - CONTAINERS=1      # Required: Traefik, Homepage, Uptime Kuma
    - NETWORKS=1        # Required: Traefik
    - IMAGES=1          # Optional: Homepage shows image versions
    - INFO=1            # Optional: System info endpoints
    # Deny all write operations
    - POST=0
    - BUILD=0
    - COMMIT=0
    # ... other denials
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  networks:
    - socket_proxy_network
```

### Pattern 3: Autokuma Label Convention
**What:** Standardized Docker labels for automatic monitor creation
**When to use:** Any service that should be monitored in Uptime Kuma
**Label format:** `kuma.<id>.<type>.<setting>: <value>`

**Example for HTTP monitor:**
```yaml
labels:
  - "kuma.traefik.http.name=Traefik"
  - "kuma.traefik.http.url=https://traefik.ragnalab.xyz"
  - "kuma.traefik.http.parent_name=Infrastructure"
```

**Example for Docker container monitor:**
```yaml
labels:
  - "kuma.traefik.docker.name=Traefik Container"
  - "kuma.traefik.docker.docker_container=traefik"
  - "kuma.traefik.docker.parent_name=Containers"
```

### Anti-Patterns to Avoid
- **Direct docker.sock mounts:** Never mount `/var/run/docker.sock` in application containers (except socket-proxy). Current violators: Uptime Kuma, Homepage, Glances, Backup.
- **Per-service compose profiles:** Don't create a profile per service; use category groupings (infra/media/apps).
- **Mixing include with extends:** The `include` directive copies resources; don't combine with `extends` for the same service.

## Don't Hand-Roll

Problems that have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docker API security | IP allowlists, auth proxies | socket-proxy | Battle-tested, granular permissions, no auth overhead |
| Monitor automation | Scripts to hit Uptime Kuma API | Autokuma | Declarative, survives restarts, version-controllable |
| Compose organization | Shell scripts to run multiple compose files | Docker Compose `include` | Native support, proper path resolution, override support |
| Backup coordination | Custom stop/start scripts | docker-volume-backup labels | Built-in stop-during-backup with labels |

**Key insight:** All operational concerns (monitoring, backup, security) can be solved with labels and environment variables rather than external scripts.

## Common Pitfalls

### Pitfall 1: Socket-Proxy Permission Conflicts
**What goes wrong:** Different services need different Docker API endpoints; one service's needs may conflict with another's security requirements.
**Why it happens:** socket-proxy is a single permission set shared by all consumers.
**How to avoid:** Document minimum required permissions per service; use union of all requirements:
- **Traefik:** CONTAINERS=1, NETWORKS=1
- **Homepage:** CONTAINERS=1, IMAGES=1 (optional)
- **Uptime Kuma:** CONTAINERS=1 (for Docker monitor type)
**Warning signs:** Service logs show "403 Forbidden" when accessing Docker API.

### Pitfall 2: Uptime Kuma Docker Host Configuration
**What goes wrong:** Uptime Kuma doesn't auto-discover socket-proxy; requires UI configuration.
**Why it happens:** Uptime Kuma stores Docker host settings in its database, not environment variables. There is no `DOCKER_HOST` environment variable support.
**How to avoid:** After migrating to socket-proxy:
1. Access Uptime Kuma UI
2. Go to Settings > Docker Hosts
3. Add new host: Name=`my-docker`, Connection Type=`TCP/HTTP`, Host=`socket-proxy`, Port=`2375`
4. Update existing Docker monitors to use the new host
**Warning signs:** Docker container monitors show "Connection refused" or "socket not found".

### Pitfall 3: Include Directive Resource Conflicts
**What goes wrong:** Compose reports error about conflicting resource definitions.
**Why it happens:** Same network or volume defined in multiple included files.
**How to avoid:** Define shared resources (networks, common volumes) in ONE file only (infra/docker-compose.yml), reference as `external: true` in others.
**Warning signs:** Error message "resource X already declared in file Y".

### Pitfall 4: Autokuma Database Migration
**What goes wrong:** Autokuma creates duplicate monitors or loses track of managed monitors.
**Why it happens:** Autokuma needs persistent storage and migration flag on first run.
**How to avoid:**
1. Create named volume for Autokuma: `autokuma-data:/data`
2. First run with `AUTOKUMA__MIGRATE=true` to adopt existing monitors
3. Set `AUTOKUMA__TAG_NAME=autokuma` to tag managed monitors
**Warning signs:** Duplicate monitors in Uptime Kuma, monitors not deleted when labels removed.

### Pitfall 5: Backup Stop Labels Not Working
**What goes wrong:** Services continue running during backup, causing inconsistent database snapshots.
**Why it happens:** The backup container reads labels at runtime; label values must match `BACKUP_STOP_DURING_BACKUP_LABEL` environment variable exactly.
**How to avoid:** Current setup uses comma-separated service names in env var. Switch to label-based: set `BACKUP_STOP_DURING_BACKUP_LABEL=true`, then label containers with `docker-volume-backup.stop-during-backup=true`.
**Warning signs:** Backup logs don't show "stopping container X" messages.

## Code Examples

Verified patterns from official sources:

### Socket-Proxy Extended Configuration (for all consumers)
```yaml
# Source: https://github.com/Tecnativa/docker-socket-proxy
socket-proxy:
  image: tecnativa/docker-socket-proxy:latest
  container_name: socket-proxy
  restart: unless-stopped
  privileged: true
  environment:
    # Required by Traefik for service discovery
    - CONTAINERS=1
    - NETWORKS=1
    # Optional: Homepage shows image info, Uptime Kuma system stats
    - IMAGES=1
    - INFO=1
    # Events for real-time updates (default enabled)
    - EVENTS=1
    # Deny all write operations
    - POST=0
    - BUILD=0
    - COMMIT=0
    - CONFIGS=0
    - SECRETS=0
    - VOLUMES=0
    - AUTH=0
    - EXEC=0
    - PLUGINS=0
    - SWARM=0
    - SYSTEM=0
    - LOG_LEVEL=info
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
  networks:
    - socket_proxy_network
```

### Homepage docker.yaml for Socket-Proxy
```yaml
# Source: https://gethomepage.dev/configs/docker/
my-docker:
  host: socket-proxy
  port: 2375
```

### Autokuma Container Configuration
```yaml
# Source: https://github.com/BigBoot/AutoKuma
autokuma:
  image: ghcr.io/bigboot/autokuma:master
  container_name: autokuma
  restart: unless-stopped
  depends_on:
    - uptime-kuma
  environment:
    # Uptime Kuma connection
    - AUTOKUMA__KUMA__URL=http://uptime-kuma:3001
    - AUTOKUMA__KUMA__USERNAME=${UPTIME_KUMA_USERNAME}
    - AUTOKUMA__KUMA__PASSWORD=${UPTIME_KUMA_PASSWORD}
    # Tag for tracking managed monitors
    - AUTOKUMA__TAG_NAME=autokuma
    - AUTOKUMA__TAG_COLOR=#4287f5
    # Docker socket for label discovery
    - AUTOKUMA__DOCKER__HOSTS=tcp://socket-proxy:2375
    # Delete monitors when labels removed (with 5min grace period)
    - AUTOKUMA__ON_DELETE=delete
    - AUTOKUMA__DELETE_GRACE_PERIOD=300
    # Default settings for all monitors
    - AUTOKUMA__DEFAULT_SETTINGS=*.interval: 60\n*.max_retries: 3
  volumes:
    - autokuma-data:/data
  networks:
    - socket_proxy_network
    - proxy
```

### Autokuma Labels for Service (HTTP + Container)
```yaml
# Source: https://github.com/BigBoot/AutoKuma
labels:
  # HTTP endpoint monitor
  - "kuma.sonarr.http.name=Sonarr"
  - "kuma.sonarr.http.url=https://sonarr.ragnalab.xyz"
  - "kuma.sonarr.http.parent_name=Media"
  # Docker container monitor
  - "kuma.sonarr-container.docker.name=Sonarr Container"
  - "kuma.sonarr-container.docker.docker_container=sonarr"
  - "kuma.sonarr-container.docker.docker_host=my-docker"
  - "kuma.sonarr-container.docker.parent_name=Containers"
```

### Docker Compose Include with Shared Networks
```yaml
# Root docker-compose.yml
# Source: https://docs.docker.com/compose/how-tos/multiple-compose-files/include/
include:
  - path: infra/docker-compose.yml
  - path: media/docker-compose.yml
  - path: apps/docker-compose.yml

# Networks defined at root level, available to all includes
networks:
  proxy:
    name: proxy
  socket_proxy_network:
    name: socket_proxy_network
  media:
    name: media
```

```yaml
# infra/docker-compose.yml
services:
  traefik:
    profiles: ["infra"]
    networks:
      - proxy
      - socket_proxy_network
    # ... rest of config

networks:
  proxy:
    external: true
  socket_proxy_network:
    external: true
```

## Backup Audit Results

### Current Backup Coverage

**Volumes in backup system:**
| Service | Volume | Backed Up | Stop During Backup |
|---------|--------|-----------|-------------------|
| Vaultwarden | vaultwarden-data | Yes | Yes |
| Prowlarr | prowlarr-config | Yes | Yes |
| Sonarr | sonarr-config | Yes | Yes |
| Radarr | radarr-config | Yes | Yes |
| Bazarr | bazarr-config | Yes | Yes |
| Jellyfin | jellyfin-config | Yes | Yes |
| Jellyseerr | jellyseerr-config | Yes | Yes |
| qBittorrent | qbittorrent-config | Yes | Yes |
| Gluetun | gluetun-data | Yes | No (stateless VPN) |
| Pi-hole | etc-pihole (bind mount) | Yes | No |

**Volumes NOT in backup (need adding):**
| Service | Volume Name | Critical | Notes |
|---------|-------------|----------|-------|
| Uptime Kuma | uptime-kuma_uptime-kuma-data | HIGH | Monitor history, settings, users |
| RustDesk | rustdesk_rustdesk-data | MEDIUM | Server keys, session data |
| Traefik | ./traefik/acme | HIGH | Let's Encrypt certificates |

**Services without persistent state (no backup needed):**
| Service | Reason |
|---------|--------|
| Glances | Real-time monitoring, no persistent data |
| ip-info | Stateless API service |
| Unpackerr | Stateless, config from environment |

### Backup Stop Strategy Recommendation

**Must stop during backup (SQLite/database integrity):**
- Vaultwarden, Prowlarr, Sonarr, Radarr, Bazarr, Jellyfin, Jellyseerr, qBittorrent, Uptime Kuma

**Safe for hot backup (no database, or stateless):**
- Gluetun (wireguard state), Pi-hole (dnsmasq config), RustDesk (keys only), Traefik (ACME JSON)

## Services Requiring Socket Migration

### Current Docker Socket Mounts (violations to fix)
| Service | Current Mount | Migration Plan |
|---------|---------------|----------------|
| Uptime Kuma | `/var/run/docker.sock:/var/run/docker.sock:ro` | Add to socket_proxy_network, configure via UI |
| Homepage | `/var/run/docker.sock:/var/run/docker.sock:ro` | Add to socket_proxy_network, update docker.yaml |
| Glances | `/var/run/docker.sock:/var/run/docker.sock:ro` | **Keep as-is**: Glances needs extensive API access for system monitoring |
| Backup | `/var/run/docker.sock:/var/run/docker.sock:ro` | **Keep as-is**: Needs to stop/start containers |

### Socket-Proxy Permission Summary
```
CONTAINERS=1  # Traefik (discovery), Homepage (status), Uptime Kuma (monitors)
NETWORKS=1    # Traefik (routing)
IMAGES=1      # Homepage (version info) - optional
INFO=1        # System info - optional
EVENTS=1      # Real-time updates (default on)
POST=0        # No write operations
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Multiple `-f` flags | `include` directive | Compose 2.20.0 (2023) | Cleaner path resolution, native support |
| Manual Uptime Kuma monitors | Autokuma labels | Autokuma 2023 | Version-controlled, auto-sync |
| Per-app .env files | Shared .env with profiles | N/A | Simpler secret management |

**Deprecated/outdated:**
- `extends` for compose files: Use `include` instead; extends requires same directory structure
- `--project-directory` flag: Include handles paths automatically

## Open Questions

Things that couldn't be fully resolved:

1. **Glances and socket-proxy compatibility**
   - What we know: Glances needs extensive Docker API access (container stats, processes)
   - What's unclear: Which specific endpoints; whether socket-proxy can satisfy them
   - Recommendation: Keep Glances with direct socket mount (it's a monitoring tool, security tradeoff acceptable)

2. **Autokuma first-run migration**
   - What we know: `AUTOKUMA__MIGRATE=true` adopts existing monitors
   - What's unclear: Exact behavior with existing manual monitors - will it tag them or recreate?
   - Recommendation: Delete all manual monitors before Autokuma deployment (clean slate per user decision)

3. **Backup container socket access**
   - What we know: Backup needs to stop/start containers (POST operations)
   - What's unclear: Whether socket-proxy with POST=1 is acceptable security tradeoff
   - Recommendation: Keep backup with direct socket mount (runs on schedule, not exposed to network)

## Sources

### Primary (HIGH confidence)
- [Tecnativa/docker-socket-proxy README](https://github.com/Tecnativa/docker-socket-proxy/blob/master/README.md) - Environment variables, permissions
- [Docker Compose Include Docs](https://docs.docker.com/compose/how-tos/multiple-compose-files/include/) - Syntax, conflict handling
- [Homepage Docker Configuration](https://gethomepage.dev/configs/docker/) - Socket-proxy setup
- [AutoKuma GitHub](https://github.com/BigBoot/AutoKuma) - Label format, environment variables
- [offen/docker-volume-backup Reference](https://offen.github.io/docker-volume-backup/reference/) - All configuration options

### Secondary (MEDIUM confidence)
- [GitHub Discussion: Homepage socket-proxy](https://github.com/gethomepage/homepage/discussions/2252) - Working configurations
- [GitHub Issue: Uptime Kuma socket security](https://github.com/louislam/uptime-kuma/issues/4783) - API endpoint analysis
- [Uptime Kuma Docker Container Wiki](https://github.com/louislam/uptime-kuma/wiki/How-to-Monitor-Docker-Containers) - Docker host configuration

### Tertiary (LOW confidence)
- WebSearch results for Docker Compose profiles best practices - Community patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools already deployed or documented in official sources
- Architecture: HIGH - Docker Compose include is stable, socket-proxy pattern proven
- Pitfalls: HIGH - Based on official docs and verified issue discussions
- Backup audit: HIGH - Direct inspection of existing compose files and volumes

**Research date:** 2026-01-18
**Valid until:** 2026-02-18 (30 days - stable tooling, no rapid changes expected)
