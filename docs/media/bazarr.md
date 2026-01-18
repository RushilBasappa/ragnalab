# Bazarr Installation

Automatic subtitle downloading for TV shows and movies.

**URL:** https://bazarr.ragnalab.xyz

---

## Prerequisites

- Sonarr running (see [Sonarr](sonarr.md))
- Radarr running (see [Radarr](radarr.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/bazarr/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://bazarr.ragnalab.xyz
```

---

## Manual Steps Required

### Initial Access

1. Open https://bazarr.ragnalab.xyz
2. No authentication by default (add if desired in Settings)

### Verify Sonarr/Radarr Connections

1. Go to **Settings → Sonarr**
   - Should be pre-configured
   - Click Test to verify

2. Go to **Settings → Radarr**
   - Should be pre-configured
   - Click Test to verify

### Configure Subtitle Providers

1. Go to **Settings → Providers**
2. Add providers (OpenSubtitles.com is pre-configured):

| Provider | Account Needed | Notes |
|----------|----------------|-------|
| OpenSubtitles.com | No (limited) | Works for basic use |
| Subscene | No | Good alternative |
| Addic7ed | Yes (free) | Good for TV |

### Configure Languages

1. Go to **Settings → Languages**
2. Add your preferred languages (English is default)
3. Set subtitle mode (e.g., "Also download if existing")

### Add Authentication (Recommended)

1. Go to **Settings → General**
2. Enable Forms authentication
3. Set username and password
4. Save

---

## How It Works

1. Bazarr monitors Sonarr and Radarr libraries
2. For each media file, it searches subtitle providers
3. Downloads matching subtitles automatically
4. Places `.srt` files next to media files
5. Jellyfin detects and offers subtitles during playback

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/bazarr/docker-compose.yml` | Container configuration |
| Volume: `bazarr-config` | Settings, cache |

---

## Troubleshooting

### Can't connect to Sonarr/Radarr

1. Verify services are on `media` network
2. Check API keys match
3. Test: `docker exec bazarr curl -s http://sonarr:8989`

### No subtitles found

1. Check provider status in Settings → Providers
2. Try adding more providers
3. Verify language settings match your content

### Subtitles out of sync

1. Check sync offset in Bazarr
2. Try different subtitle release
3. Some releases have timing issues - not fixable automatically
