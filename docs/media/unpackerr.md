# Unpackerr Installation

Automatic archive extraction for downloaded media.

**No Web UI** - runs headless, monitors download folders.

---

## Prerequisites

- Sonarr running (see [Sonarr](sonarr.md))
- Radarr running (see [Radarr](radarr.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/unpackerr/docker-compose.yml up -d
```

### 2. Verify

```bash
# Check container is running
docker ps | grep unpackerr

# Check logs for connection status
docker logs unpackerr
```

You should see:
```
Sonarr: 1 server: http://sonarr:8989
Radarr: 1 server: http://radarr:7878
```

---

## Manual Steps

**None** - Unpackerr is fully automated via environment variables in docker-compose.yml.

---

## How It Works

Some torrent releases come as RAR archives. Unpackerr:

1. Monitors Sonarr/Radarr activity queues
2. Detects when a download completes with archives
3. Extracts RAR/ZIP files automatically
4. Sonarr/Radarr then imports the extracted files

Without Unpackerr, archived downloads would be stuck in queue.

---

## Configuration

All configuration is in docker-compose.yml environment variables:

```yaml
environment:
  UN_SONARR_0_URL: http://sonarr:8989
  UN_SONARR_0_API_KEY: ${SONARR_API_KEY}
  UN_RADARR_0_URL: http://radarr:7878
  UN_RADARR_0_API_KEY: ${RADARR_API_KEY}
```

API keys are loaded from `apps/media/.env`.

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/unpackerr/docker-compose.yml` | Container configuration |
| `apps/media/.env` | API keys |

---

## Troubleshooting

### Not extracting archives

1. Check logs: `docker logs unpackerr`
2. Verify API keys are correct
3. Ensure Sonarr/Radarr are reachable: `docker exec unpackerr wget -qO- http://sonarr:8989`

### Connection refused errors

1. Check Sonarr/Radarr are on `media` network
2. Verify container names match URL hostnames

### Archives extracted but not imported

This is a Sonarr/Radarr issue, not Unpackerr:
1. Check Sonarr/Radarr Activity queue
2. Look for import errors
