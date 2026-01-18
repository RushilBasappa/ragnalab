# Jellyfin Installation

Media server for streaming your TV shows and movies.

**URL:** https://jellyfin.ragnalab.xyz

---

## Prerequisites

- Media library directories exist (`/media/library/tv`, `/media/library/movies`)

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/jellyfin/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://jellyfin.ragnalab.xyz
```

---

## Manual Steps Required

### Complete Setup Wizard

1. Open https://jellyfin.ragnalab.xyz
2. Select language
3. Create admin account:
   - Username: (your choice)
   - Password: (your choice)
   - **Save these credentials!**

### Configure Libraries (Pre-configured)

Libraries should be auto-configured:
- Movies: `/data/media/movies`
- TV Shows: `/data/media/tv`

If missing:
1. Go to **Dashboard → Libraries**
2. Add Library:
   - Content type: Movies
   - Folder: `/data/media/movies`
3. Repeat for TV Shows with `/data/media/tv`

### Verify Transcoding is Disabled

**Important for Pi 5:** Hardware transcoding is not available.

1. Go to **Dashboard → Playback**
2. Ensure hardware acceleration is set to **None**
3. Direct play should be enabled

### Get API Key for Homepage

1. Go to **Dashboard → API Keys**
2. Click **Add** (or + button)
3. Name: `Homepage`
4. Copy the API key
5. Add to `apps/media/.env`:
   ```
   JELLYFIN_API_KEY=your-api-key
   ```

---

## How It Works

Jellyfin reads from `/data/media` which maps to `/media/library`:
- `/data/media/tv` → `/media/library/tv` (managed by Sonarr)
- `/data/media/movies` → `/media/library/movies` (managed by Radarr)

Mount is **read-only** - Jellyfin cannot modify media files.

### Playback

Pi 5 cannot hardware transcode. Clients must support **direct play**:
- ✅ Modern browsers, smart TVs, Roku, Apple TV, Android
- ⚠️ Some older devices may not play all formats

If playback fails, check if the client supports the video codec (usually H.264/H.265).

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/jellyfin/docker-compose.yml` | Container configuration |
| Volume: `jellyfin-config` | Settings, database, metadata |
| `apps/media/.env` | API key for Homepage |

---

## Client Apps

| Platform | App |
|----------|-----|
| iOS/iPadOS | Jellyfin (App Store) |
| Android | Jellyfin (Play Store) |
| Apple TV | Jellyfin |
| Roku | Jellyfin |
| Web | https://jellyfin.ragnalab.xyz |

---

## Troubleshooting

### Video won't play

1. Check if transcoding is being attempted (Dashboard → Activity)
2. Try a different client/browser
3. Verify video codec is supported for direct play

### Libraries empty

1. Check mount paths in Dashboard → Libraries
2. Verify media files exist: `ls /media/library/movies`
3. Trigger library scan: Dashboard → Libraries → Scan

### Buffering issues

1. Pi 5 is direct-play only - ensure client isn't requesting transcode
2. Check network speed between client and Pi
3. Large 4K files may buffer on slow networks
