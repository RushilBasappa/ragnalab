# Radarr Installation

Movie automation - monitors, downloads, and organizes movies.

**URL:** https://radarr.ragnalab.xyz

---

## Prerequisites

- qBittorrent running (see [qBittorrent](qbittorrent.md))
- Prowlarr running (see [Prowlarr](prowlarr.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/radarr/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://radarr.ragnalab.xyz
```

---

## Manual Steps Required

### Initial Login

1. Open https://radarr.ragnalab.xyz
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

Root folder is set to `/media/library/movies`

If missing:
1. Go to **Settings → Media Management**
2. Add Root Folder: `/media/library/movies`

### Add a Movie

1. Click **Add New** (or Movies → Add New)
2. Search for a movie
3. Select quality profile
4. Click Add

### Change Default Password

1. Go to **Settings → General → Security**
2. Change authentication credentials
3. Save

---

## How It Works

1. You add a movie to monitor
2. Radarr searches Prowlarr indexers for releases
3. Radarr sends downloads to qBittorrent (category: `movies`)
4. When complete, Radarr moves/hardlinks to `/media/library/movies`
5. Jellyfin detects and adds to library

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/radarr/docker-compose.yml` | Container configuration |
| Volume: `radarr-config` | Settings, database |
| `apps/media/.env` | API key for integrations |

---

## Troubleshooting

### Can't connect to qBittorrent

1. Verify qBittorrent is on `media` network
2. Check host is `qbittorrent` and port is `8080`
3. Test: `docker exec radarr curl -s http://qbittorrent:8080`

### Downloads stuck / not importing

1. Check qBittorrent categories are correct (`movies`)
2. Verify `/media` mount is consistent across containers
3. Check Radarr logs: Activity → Queue

### Indexers empty

1. Check Prowlarr Settings → Apps
2. Verify Radarr API key matches
3. Trigger sync in Prowlarr
