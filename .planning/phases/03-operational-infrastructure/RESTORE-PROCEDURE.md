# Restore Procedure - RagnaLab

**Last tested:** 2026-01-17
**Tested with:** Uptime Kuma

## Quick Reference

### Restore Single Service
```bash
cd /home/rushil/workspace/ragnalab
./apps/backup/scripts/restore.sh <service-name>
```

### Restore From Specific Backup
```bash
./apps/backup/scripts/restore.sh <service-name> backup-2026-01-17T03-00-00.tar.gz
```

### List Available Backups
```bash
ls -la /home/rushil/workspace/ragnalab/backups/
```

## Full Platform Recovery

In case of complete system failure, follow this order:

### 1. Restore Infrastructure (First)

```bash
# Start core infrastructure
cd /home/rushil/workspace/ragnalab
make networks  # Create Docker networks
docker compose -f proxy/docker-compose.yml up -d
```

Wait for Traefik to be healthy before proceeding.

### 2. Restore Monitoring

```bash
docker compose -f apps/uptime-kuma/docker-compose.yml up -d
./apps/backup/scripts/restore.sh uptime-kuma
```

### 3. Restore Other Services

For each service in `apps/`:
```bash
docker compose -f apps/<service>/docker-compose.yml up -d
./apps/backup/scripts/restore.sh <service>
```

### 4. Start Backup Service (Last)

```bash
docker compose -f apps/backup/docker-compose.yml up -d
```

## What Gets Backed Up

| Service | Volume | Contents |
|---------|--------|----------|
| uptime-kuma | uptime-kuma-data | Monitors, settings, history |

*Add rows as services are deployed*

## What Does NOT Get Backed Up

- Docker compose files (in git)
- Traefik configuration (in git)
- Environment files with secrets (.env files)
- Docker images (pulled from registries)

## Backup Schedule

- **Frequency:** Daily (3 AM)
- **Retention:** 7 days
- **Location:** `/home/rushil/workspace/ragnalab/backups/`
- **Monitoring:** Uptime Kuma push monitor alerts on missed backup

## Testing Backups

Backups should be tested periodically (monthly recommended):

1. Trigger manual backup: `docker kill --signal=SIGUSR1 backup`
2. Verify archive created: `ls -la backups/`
3. Test restore on non-critical service
4. Verify data integrity after restore

## Troubleshooting

### "Volume not found" error
The script looks for volumes named `<service>_<service>-data` or `<service>-data`.
Check actual volume name: `docker volume ls | grep <service>`

### Service won't start after restore
Check logs: `docker logs <service-name>`
Common issues:
- Permission problems: data owned by wrong user
- Corrupt data: try older backup

### Backup missing service data
Ensure service has the backup label:
```yaml
labels:
  - "docker-volume-backup.stop-during-backup=<label-value>"
```
And volume is mounted in backup service's docker-compose.yml.
