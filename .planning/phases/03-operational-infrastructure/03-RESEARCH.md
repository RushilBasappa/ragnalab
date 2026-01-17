# Phase 3: Operational Infrastructure - Research

**Researched:** 2026-01-17
**Domain:** Docker volume backups, uptime monitoring, host metrics, operational observability
**Confidence:** HIGH

## Summary

This phase implements operational infrastructure for the RagnaLab homelab: automated Docker volume backups, health monitoring via Uptime Kuma, host resource monitoring, and disaster recovery documentation.

The standard approach uses **offen/docker-volume-backup** (v2.47.0) for automated, per-service volume backups with weekly scheduling. For monitoring, **Uptime Kuma v2** handles web service uptime and container health checks. Uptime Kuma does NOT provide host metrics (CPU/memory/disk) - this requires a separate lightweight tool. **Beszel** (v0.18.2) is recommended as a minimal-overhead solution for host resource monitoring (under 500MB RAM combined with Uptime Kuma).

Backup failure alerts integrate with Uptime Kuma via **push monitors** - a curl request at backup completion signals success; missed heartbeats trigger alerts. The Traefik dashboard is already configured and accessible at `traefik.ragnalab.xyz`.

**Primary recommendation:** Deploy offen/docker-volume-backup with per-service configurations, Uptime Kuma for uptime/container monitoring, and optionally Beszel for host metrics. Use Uptime Kuma push monitors for backup failure alerting.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| offen/docker-volume-backup | v2.47.0 | Automated Docker volume backups | Lightweight (<25MB), per-service backup labels, local storage support, ARM64 compatible |
| louislam/uptime-kuma | v2 (2.x) | Uptime monitoring, container health, status page | Self-hosted, 90+ notification services, Docker container monitoring, ARM64 native |
| henrygd/beszel | v0.18.2 | Host resource monitoring (CPU/memory/disk) | Lightweight hub+agent model, Docker stats, configurable alerts, ARM64 compatible |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| shoutrrr | (bundled) | Notification routing | Used internally by docker-volume-backup for failure alerts |
| Traefik dashboard | v3.6 | Routing inspection | Already deployed - MON-03 satisfied |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Beszel | Netdata | More features but heavier resource usage (~300MB+ RAM) |
| Beszel | Prometheus+Grafana | Enterprise-grade but massive overkill for single Pi |
| docker-volume-backup | Duplicati | GUI-based but breaks GitOps, heavier |

**Installation (ARM64 Raspberry Pi 5):**
```bash
# All images support ARM64/aarch64 natively
docker pull offen/docker-volume-backup:v2
docker pull louislam/uptime-kuma:2
docker pull henrygd/beszel:latest
docker pull henrygd/beszel-agent:latest
```

## Architecture Patterns

### Recommended Directory Structure
```
apps/
├── uptime-kuma/
│   └── docker-compose.yml       # Monitoring + status page
├── beszel/
│   └── docker-compose.yml       # Hub + agent for host metrics
├── backup/
│   └── docker-compose.yml       # Backup service(s)
│   └── scripts/
│       └── restore.sh           # Documented restore procedure
backups/                          # Local backup storage (outside apps/)
├── whoami/
├── uptime-kuma/
└── [service-name]/
```

### Pattern 1: Per-Service Backup Configuration

**What:** Each service's volumes backed up independently with its own schedule and labels
**When to use:** When granular restore capability is required (user decision)
**Example:**
```yaml
# Source: https://offen.github.io/docker-volume-backup/recipes/
# apps/backup/docker-compose.yml
services:
  backup:
    image: offen/docker-volume-backup:v2
    environment:
      BACKUP_CRON_EXPRESSION: "0 3 * * 0"  # Weekly, Sunday 3 AM
      BACKUP_FILENAME: "backup-%Y-%m-%dT%H-%M-%S.tar.gz"
      BACKUP_RETENTION_DAYS: "28"  # Keep 4 weeks
      BACKUP_STOP_DURING_BACKUP_LABEL: "backup"
      # Backup completion notification via push monitor
      NOTIFICATION_URLS: "generic+https://status.ragnalab.xyz/api/push/BACKUP_TOKEN?status=up&msg=OK"
      NOTIFICATION_LEVEL: "info"  # Notify on success AND failure
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # Mount each service's volumes for backup
      - uptime-kuma-data:/backup/uptime-kuma:ro
      - vaultwarden-data:/backup/vaultwarden:ro
      # Local backup destination
      - /home/rushil/workspace/ragnalab/backups:/archive
```

### Pattern 2: Uptime Kuma with Container Monitoring via Socket Proxy

**What:** Monitor Docker containers without exposing raw socket
**When to use:** When container health monitoring is needed with socket proxy security model
**Example:**
```yaml
# apps/uptime-kuma/docker-compose.yml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    container_name: uptime-kuma
    restart: unless-stopped
    volumes:
      - uptime-kuma-data:/app/data
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.uptime-kuma.rule=Host(`status.ragnalab.xyz`)"
      - "traefik.http.routers.uptime-kuma.entrypoints=websecure"
      - "traefik.http.routers.uptime-kuma.tls=true"
      - "traefik.http.routers.uptime-kuma.tls.certresolver=letsencrypt"
      - "traefik.http.services.uptime-kuma.loadbalancer.server.port=3001"
      - "traefik.docker.network=proxy"

volumes:
  uptime-kuma-data:

networks:
  proxy:
    external: true
```

**Note:** Container monitoring requires either:
1. Direct socket mount: `-v /var/run/docker.sock:/var/run/docker.sock` (simple but less secure)
2. TCP connection to existing socket proxy (requires socket proxy reconfiguration for Uptime Kuma access)

### Pattern 3: Push Monitor for Backup Alerting

**What:** Use Uptime Kuma push monitors to detect backup failures
**When to use:** When backup success/failure needs monitoring without complex integrations
**Example:**
```bash
# Curl command for backup success notification
# Source: https://blog.programster.org/uptime-kuma-configure-push-monitor
curl -s "https://status.ragnalab.xyz/api/push/BACKUP_TOKEN?status=up&msg=OK&ping=0"

# Configure push monitor in Uptime Kuma:
# - Monitor Type: Push
# - Heartbeat Interval: 604800 seconds (1 week + buffer)
# - Retries: 0 (immediate alert on missed heartbeat)
```

### Pattern 4: Beszel Hub+Agent for Host Metrics

**What:** Lightweight host monitoring with centralized dashboard
**When to use:** When CPU/memory/disk/temperature monitoring is needed
**Example:**
```yaml
# apps/beszel/docker-compose.yml
services:
  beszel-hub:
    image: henrygd/beszel:latest
    container_name: beszel-hub
    restart: unless-stopped
    volumes:
      - beszel-data:/beszel_data
      - beszel-socket:/beszel_socket
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.beszel.rule=Host(`metrics.ragnalab.xyz`)"
      # ... standard Traefik labels

  beszel-agent:
    image: henrygd/beszel-agent:latest
    container_name: beszel-agent
    restart: unless-stopped
    network_mode: host
    volumes:
      - beszel-socket:/beszel_socket
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - LISTEN=/beszel_socket/beszel.sock
      - HUB_URL=wss://metrics.ragnalab.xyz
      - TOKEN=${BESZEL_TOKEN}
      - KEY=${BESZEL_KEY}
```

### Anti-Patterns to Avoid
- **Mounting Docker socket to every container:** Use socket proxy or limit to monitoring tools only
- **Single monolithic backup:** Prevents granular restore, creates huge archives
- **Backup without stop-during-backup:** Leads to corrupt database backups
- **NFS-mounted Uptime Kuma data:** Causes SQLite corruption due to file locking issues
- **Relying only on uptime checks:** Service can respond 200 but be broken internally

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docker volume backups | Shell scripts with tar/cron | offen/docker-volume-backup | Handles container lifecycle, compression, retention, notifications |
| Uptime monitoring | Custom ping scripts | Uptime Kuma | 90+ notification services, push monitors, status pages |
| Host metrics | Custom scripts with top/free | Beszel | Historical data, alerts, dashboard, container stats |
| Notification routing | Custom webhook implementations | shoutrrr (built into backup tool) | Supports 50+ services with single URL format |
| Backup scheduling | Cron on host | BACKUP_CRON_EXPRESSION in container | Contained, portable, logs visible in Docker |

**Key insight:** The operational tooling space is mature. These tools handle edge cases (container stop/start ordering, notification retries, timezone handling) that custom scripts inevitably miss.

## Common Pitfalls

### Pitfall 1: Backup Without Stopping Containers
**What goes wrong:** Database corruption, inconsistent application state
**Why it happens:** Assuming tar on mounted volume is sufficient
**How to avoid:** Use `docker-volume-backup.stop-during-backup=true` label on stateful containers
**Warning signs:** Backup restores that fail or produce corrupt data

### Pitfall 2: NFS Storage for Uptime Kuma
**What goes wrong:** SQLite database corruption
**Why it happens:** NFS doesn't support POSIX file locks required by SQLite
**How to avoid:** Always use local storage or Docker named volumes on local disk
**Warning signs:** Random database errors, lost monitoring history

### Pitfall 3: Forgetting BACKUP_STOP_DURING_BACKUP_LABEL
**What goes wrong:** ALL containers with stop-during-backup label get stopped, not just target
**Why it happens:** Missing label scoping configuration
**How to avoid:** Set `BACKUP_STOP_DURING_BACKUP_LABEL` to unique value per backup instance
**Warning signs:** Unrelated services restarting during backups

### Pitfall 4: Push Monitor Heartbeat Too Short
**What goes wrong:** False positives during long backup runs
**Why it happens:** Heartbeat interval shorter than backup duration
**How to avoid:** Set heartbeat interval to expected backup time + generous buffer (e.g., 1 week + 1 day)
**Warning signs:** Alerts during normal backup operations

### Pitfall 5: Uptime Kuma Container Monitoring Without Socket Access
**What goes wrong:** Container monitoring feature doesn't work
**Why it happens:** Docker socket not mounted or TCP endpoint not configured
**How to avoid:** Either mount socket directly or configure TCP Docker host
**Warning signs:** "Docker Host" option in Uptime Kuma shows connection errors

### Pitfall 6: Beszel Agent Memory Stats Missing on ARM
**What goes wrong:** Container memory shows 0 despite CPU working
**Why it happens:** Known issue with cgroups v2 on some ARM configurations
**How to avoid:** Ensure cgroups v2 is properly configured; check Beszel GitHub issues
**Warning signs:** CPU stats visible but memory stats all zero

## Code Examples

Verified patterns from official sources:

### Weekly Backup with Local Storage and Retention
```yaml
# Source: https://offen.github.io/docker-volume-backup/reference/
services:
  backup:
    image: offen/docker-volume-backup:v2
    restart: unless-stopped
    environment:
      # Weekly backup on Sunday at 3 AM
      BACKUP_CRON_EXPRESSION: "0 3 * * 0"
      # Filename with timestamp
      BACKUP_FILENAME: "backup-%Y-%m-%dT%H-%M-%S.tar.gz"
      # Keep 4 weeks of backups
      BACKUP_RETENTION_DAYS: "28"
      # Only stop containers with matching label
      BACKUP_STOP_DURING_BACKUP_LABEL: "backup-weekly"
      # Symlink to latest backup for easy restore reference
      BACKUP_LATEST_SYMLINK: "backup-latest.tar.gz"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - app-data:/backup/app-data:ro
      - /path/to/backups:/archive
```

### Uptime Kuma Docker Compose with Traefik
```yaml
# Source: https://github.com/louislam/uptime-kuma/wiki
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2
    container_name: uptime-kuma
    restart: unless-stopped
    volumes:
      - uptime-kuma-data:/app/data
      # Optional: for container monitoring
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.uptime-kuma.rule=Host(`status.ragnalab.xyz`)"
      - "traefik.http.routers.uptime-kuma.entrypoints=websecure"
      - "traefik.http.routers.uptime-kuma.tls=true"
      - "traefik.http.routers.uptime-kuma.tls.certresolver=letsencrypt"
      - "traefik.http.services.uptime-kuma.loadbalancer.server.port=3001"
      - "traefik.docker.network=proxy"
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  uptime-kuma-data:

networks:
  proxy:
    external: true
```

### Restore Script Template
```bash
#!/bin/bash
# Source: https://offen.github.io/docker-volume-backup/how-tos/restore-volumes-from-backup.html
# restore.sh - Restore a specific service's volumes from backup

set -euo pipefail

SERVICE_NAME="${1:-}"
BACKUP_FILE="${2:-}"
BACKUP_DIR="/home/rushil/workspace/ragnalab/backups"

if [[ -z "$SERVICE_NAME" ]] || [[ -z "$BACKUP_FILE" ]]; then
    echo "Usage: $0 <service-name> <backup-filename>"
    echo "Example: $0 uptime-kuma backup-2026-01-17T03-00-00.tar.gz"
    exit 1
fi

BACKUP_PATH="${BACKUP_DIR}/${BACKUP_FILE}"
if [[ ! -f "$BACKUP_PATH" ]]; then
    echo "Error: Backup file not found: $BACKUP_PATH"
    exit 1
fi

echo "=== Restoring ${SERVICE_NAME} from ${BACKUP_FILE} ==="

# Step 1: Stop the service
echo "Stopping ${SERVICE_NAME}..."
docker compose -f "/home/rushil/workspace/ragnalab/apps/${SERVICE_NAME}/docker-compose.yml" down

# Step 2: Extract backup to temp location
TEMP_DIR=$(mktemp -d)
echo "Extracting backup to ${TEMP_DIR}..."
tar -xzf "$BACKUP_PATH" -C "$TEMP_DIR"

# Step 3: Identify the volume name and restore
VOLUME_NAME="${SERVICE_NAME}-data"
echo "Restoring to volume ${VOLUME_NAME}..."

# Remove existing volume data and restore
docker run --rm \
    -v "${VOLUME_NAME}:/restore" \
    -v "${TEMP_DIR}:/backup:ro" \
    alpine sh -c "rm -rf /restore/* && cp -a /backup/${SERVICE_NAME}/. /restore/"

# Step 4: Cleanup and restart
rm -rf "$TEMP_DIR"
echo "Restarting ${SERVICE_NAME}..."
docker compose -f "/home/rushil/workspace/ragnalab/apps/${SERVICE_NAME}/docker-compose.yml" up -d

echo "=== Restore complete ==="
```

### Push Monitor Curl for Backup Success
```bash
# Source: https://blog.programster.org/uptime-kuma-configure-push-monitor
# Add to backup container's NOTIFICATION_URLS or exec-post hook

# Using shoutrrr generic webhook format
NOTIFICATION_URLS="generic+https://status.ragnalab.xyz/api/push/YOUR_TOKEN?status=up&msg=Backup%20completed"

# Or direct curl in post-backup script
curl -s "https://status.ragnalab.xyz/api/push/YOUR_TOKEN?status=up&msg=OK&ping=0"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Uptime Kuma v1.x | Uptime Kuma v2.x | Late 2025 | New UI, improved performance, `:2` tag now recommended |
| Custom backup scripts | Container-based backup tools | 2023+ | Better lifecycle management, portable configs |
| Prometheus+Grafana | Beszel for homelabs | 2024+ | 90%+ less resource usage for simple monitoring |
| BACKUP_FROM_SNAPSHOT | exec-pre/exec-post labels | 2024 | Deprecated, use labels for pre/post commands |

**Deprecated/outdated:**
- `louislam/uptime-kuma:1` - Use `:2` tag for new installations
- `BACKUP_FROM_SNAPSHOT` in docker-volume-backup - Use exec-pre/exec-post labels instead
- Email notification env vars in docker-volume-backup - Use NOTIFICATION_URLS with shoutrrr instead

## Open Questions

Things that couldn't be fully resolved:

1. **Socket proxy access for Uptime Kuma container monitoring**
   - What we know: Current socket proxy (tecnativa/docker-socket-proxy) is configured with read-only access for Traefik
   - What's unclear: Whether Uptime Kuma can use the same socket proxy endpoint or needs direct socket mount
   - Recommendation: Test with existing socket proxy first; if container monitoring fails, mount socket directly to Uptime Kuma only

2. **Beszel vs simpler alternative for host metrics**
   - What we know: Beszel provides CPU/memory/disk/temperature monitoring with hub+agent model
   - What's unclear: Whether the hub+agent complexity is justified for single-node monitoring
   - Recommendation: User can decide during planning if host metrics are essential (MON-01 only requires service health, not host metrics)

3. **Backup encryption necessity**
   - What we know: docker-volume-backup supports GPG and age encryption
   - What's unclear: Whether encryption is needed for local-only backups on encrypted disk
   - Recommendation: Skip encryption for simplicity if disk is already encrypted; add if security audit requires it

## Sources

### Primary (HIGH confidence)
- [offen/docker-volume-backup GitHub](https://github.com/offen/docker-volume-backup) - v2.47.0, ARM64 support confirmed
- [offen/docker-volume-backup Reference](https://offen.github.io/docker-volume-backup/reference/) - All configuration options
- [offen/docker-volume-backup Restore Guide](https://offen.github.io/docker-volume-backup/how-tos/restore-volumes-from-backup.html) - Restore procedure
- [Uptime Kuma GitHub Wiki](https://github.com/louislam/uptime-kuma/wiki) - Installation, Docker container monitoring
- [Uptime Kuma Docker Hub](https://hub.docker.com/r/louislam/uptime-kuma) - ARM64 multi-arch images
- [Beszel Getting Started](https://beszel.dev/guide/getting-started) - Hub+agent setup

### Secondary (MEDIUM confidence)
- [Better Stack Uptime Kuma Guide](https://betterstack.com/community/guides/monitoring/uptime-kuma-guide/) - Push monitor configuration
- [Programster Uptime Kuma Push Monitor](https://blog.programster.org/uptime-kuma-configure-push-monitor) - Curl examples
- [Shoutrrr Generic Webhook](https://containrrr.dev/shoutrrr/v0.8/examples/generic/) - Notification URL format

### Tertiary (LOW confidence - verify before use)
- Beszel ARM64 container memory issue - Reported on GitHub, may be configuration-specific
- Uptime Kuma + socket proxy compatibility - Not explicitly documented, needs testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools verified on official docs, ARM64 confirmed
- Architecture: HIGH - Patterns from official documentation and recipes
- Pitfalls: HIGH - Well-documented in GitHub issues and official docs
- Host metrics (Beszel): MEDIUM - Newer tool, less community validation

**Research date:** 2026-01-17
**Valid until:** 2026-02-17 (30 days - stable tools, infrequent major changes)
