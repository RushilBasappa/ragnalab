# Sonarr Installation

TV show automation - monitors, downloads, and organizes TV series.

**URL:** https://sonarr.ragnalab.xyz

---

## Prerequisites

- qBittorrent running (see [qbittorrent/INSTALL.md](../qbittorrent/INSTALL.md))
- Prowlarr running (see [prowlarr/INSTALL.md](../prowlarr/INSTALL.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/sonarr/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://sonarr.ragnalab.xyz
```

---

## Manual Steps Required

### Initial Login

1. Open https://sonarr.ragnalab.xyz
2. Login with default credentials:
   - Username: `admin`
   - Password: `Ragnalab2026`

### Verify Download Client

1. Go to **Settings → Download Clients**
2. qBittorrent should be pre-configured
3. Click Test to verify connection

### Verify Indexers

1. Go to **Settings → Indexers**
2. Indexers from Prowlarr should appear automatically
3. If empty, check Prowlarr sync in Settings → Apps

### Add Root Folder (Pre-configured)

Root folder is set to `/media/library/tv`

If missing:
1. Go to **Settings → Media Management**
2. Add Root Folder: `/media/library/tv`

### Add a TV Show

1. Click **Add New** (or Series → Add New)
2. Search for a show
3. Select quality profile
4. Click Add

### Change Default Password

1. Go to **Settings → General → Security**
2. Change authentication credentials
3. Save

---

## How It Works

1. You add a TV show to monitor
2. Sonarr searches Prowlarr indexers for episodes
3. Sonarr sends downloads to qBittorrent (category: `tv`)
4. When complete, Sonarr moves/hardlinks to `/media/library/tv`
5. Jellyfin detects and adds to library

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/sonarr/docker-compose.yml` | Container configuration |
| Volume: `sonarr-config` | Settings, database |
| `apps/media/.env` | API key for integrations |

---

## Troubleshooting

### Can't connect to qBittorrent

1. Verify qBittorrent is on `media` network
2. Check host is `qbittorrent` and port is `8080`
3. Test: `docker exec sonarr curl -s http://qbittorrent:8080`

### Downloads stuck / not importing

1. Check qBittorrent categories are correct (`tv`)
2. Verify `/media` mount is consistent across containers
3. Check Sonarr logs: Activity → Queue

### Indexers empty

1. Check Prowlarr Settings → Apps
2. Verify Sonarr API key matches
3. Trigger sync in Prowlarr
