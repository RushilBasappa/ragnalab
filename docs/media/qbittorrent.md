# qBittorrent Installation

Torrent download client with VPN protection.

**Access:** http://localhost:8080 (through VPN tunnel)

---

## Prerequisites

- Gluetun running and healthy (see [Gluetun](gluetun.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/qbittorrent/docker-compose.yml up -d
```

### 2. Verify VPN Protection

```bash
# Check IP (MUST be VPN IP, not your home IP)
docker exec qbittorrent curl -s ifconfig.me

# Compare with home IP
curl -s ifconfig.me

# These MUST be different!
```

### 3. Access WebUI

Open http://localhost:8080 or http://<pi-ip>:8080

Default credentials:
- Username: `admin`
- Password: Check logs for temporary password:
  ```bash
  docker logs qbittorrent 2>&1 | grep "temporary password"
  ```

---

## Manual Steps

### Change Default Password

1. Open qBittorrent WebUI
2. Go to Settings (gear icon)
3. Web UI → Authentication
4. Set new password
5. Save

### Configure Categories (Pre-configured)

Categories are set up automatically:
- `tv` → `/media/downloads/tv`
- `movies` → `/media/downloads/movies`

Sonarr/Radarr use these categories when sending downloads.

---

## How It Works

qBittorrent uses `network_mode: container:gluetun`, meaning:
- All network traffic goes through Gluetun's VPN tunnel
- Your real IP is never exposed to torrent peers
- If VPN disconnects, qBittorrent loses internet (kill switch)

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/qbittorrent/docker-compose.yml` | Container configuration |
| Volume: `qbittorrent-config` | Settings, categories |

---

## Troubleshooting

### Can't access WebUI

1. Check Gluetun is healthy: `docker inspect gluetun --format='{{.State.Health.Status}}'`
2. Check qBittorrent is running: `docker ps | grep qbittorrent`
3. Port 8080 is exposed through Gluetun, not qBittorrent directly

### Downloads not starting

1. Verify VPN is connected: `docker exec qbittorrent curl -s ifconfig.me`
2. Check qBittorrent logs: `docker logs qbittorrent`

### Slow speeds

1. Check VPN server location (closer = faster)
2. Verify port forwarding if your VPN supports it
3. Check qBittorrent connection limits in settings
