# Backup System Installation

Automated Docker volume backups with offsite sync.

---

## Prerequisites

- Traefik running (see [Traefik](traefik.md))
- Uptime Kuma with Push monitor created (see [Uptime Kuma](uptime-kuma.md))

---

## Installation

### 1. Configure Environment

```bash
cp apps/backup/.env.example apps/backup/.env
nano apps/backup/.env
```

Add the Push URL from Uptime Kuma:
```
BACKUP_NOTIFICATION_URL=https://status.ragnalab.xyz/api/push/YOUR_TOKEN?status=up&msg=OK&ping=
```

### 2. Deploy

```bash
docker compose -f apps/backup/docker-compose.yml up -d
```

### 3. Test Backup

```bash
# Trigger manual backup
docker exec backup backup

# Check backup files
ls -la backups/
```

---

## Manual Steps

**Configure Uptime Kuma Push Monitor:**

1. Create Push monitor in Uptime Kuma (see uptime-kuma INSTALL.md)
2. Copy the Push URL
3. Add to `apps/backup/.env`
4. Restart backup container

---

## Backup Schedule

Default: Daily at 2:00 AM (configured in docker-compose.yml)

Backups are retained for 7 days locally.

---

## What Gets Backed Up

All Docker volumes with `docker-volume-backup.archive-pre` label:

- uptime-kuma
- vaultwarden
- traefik (certificates)
- All media app configs (sonarr, radarr, etc.)

Services with `docker-volume-backup.stop-during-backup` label are stopped during backup for data consistency.

---

## Restore Procedure

### List Available Backups

```bash
ls -la backups/
```

### Restore a Service

```bash
make restore SERVICE=vaultwarden
```

Or manually:
```bash
# Stop service
docker compose -f apps/vaultwarden/docker-compose.yml down

# Find latest backup
BACKUP=$(ls -t backups/backup-*.tar.gz | head -1)

# Extract specific volume
docker run --rm -v vaultwarden:/data -v $(pwd)/backups:/backup alpine \
  tar xzf /backup/$(basename $BACKUP) --strip-components=1 -C /data backup/vaultwarden

# Start service
docker compose -f apps/vaultwarden/docker-compose.yml up -d
```

---

## Files

| File | Purpose |
|------|---------|
| `apps/backup/docker-compose.yml` | Backup container configuration |
| `apps/backup/.env` | Notification URL |
| `apps/backup/scripts/` | Custom backup scripts |
| `backups/` | Local backup archives |

---

## Offsite Sync (Optional)

To sync backups offsite, add rclone configuration:

```bash
# Configure rclone (one-time)
docker exec -it backup rclone config

# Add to docker-compose.yml environment
BACKUP_ARCHIVE_RCLONE_DESTINATION=remote:bucket/ragnalab-backups
```

---

## Troubleshooting

### Backup not running

Check container logs:
```bash
docker logs backup
```

### Push notification not working

1. Verify URL in .env is correct
2. Test manually: `curl -s "YOUR_PUSH_URL"`
3. Check Uptime Kuma shows the Push monitor

### Restore failed

Ensure target service is stopped before restoring.
