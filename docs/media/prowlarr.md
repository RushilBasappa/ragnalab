# Prowlarr Installation

Indexer manager that syncs to Sonarr, Radarr, and other arr apps.

**URL:** https://prowlarr.ragnalab.xyz

---

## Prerequisites

- Traefik running

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/prowlarr/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://prowlarr.ragnalab.xyz
```

---

## Manual Steps Required

### Initial Login

1. Open https://prowlarr.ragnalab.xyz
2. Login with default credentials:
   - Username: `admin`
   - Password: `Ragnalab2026`

### Add Indexers

1. Go to **Indexers → Add Indexer**
2. Add public indexers (no account needed):

| Indexer | Type | Notes |
|---------|------|-------|
| YTS | Movies | Good for movies |
| EZTV | TV | Good for TV shows |
| TorrentGalaxy | General | Movies and TV |
| Nyaa | Anime | If you want anime |

3. For each indexer:
   - Click Add
   - Test connection
   - Save

**Note:** Some indexers (1337x) are blocked by Cloudflare. Skip those or add FlareSolverr later.

### Verify Sync to Arr Apps

1. Go to **Settings → Apps**
2. Sonarr and Radarr should show connected
3. Check **Settings → Indexers** in Sonarr/Radarr - indexers should appear

### Change Default Password

1. Go to **Settings → General → Security**
2. Change authentication credentials
3. Save

---

## How It Works

Prowlarr centralizes indexer management:
- Configure indexers once in Prowlarr
- Prowlarr automatically syncs to Sonarr, Radarr
- No need to add indexers individually to each app

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/prowlarr/docker-compose.yml` | Container configuration |
| Volume: `prowlarr-config` | Settings, indexer configs |
| `apps/media/.env` | API key for Homepage widget |

---

## Troubleshooting

### Indexers not syncing

1. Check Settings → Apps in Prowlarr
2. Verify API keys match in Sonarr/Radarr
3. Test connection from Prowlarr

### Cloudflare blocked indexers

Some indexers use Cloudflare protection. Options:
1. Skip those indexers (use alternatives)
2. Add FlareSolverr (separate container)

### Search returning no results

1. Verify indexers are healthy (green status)
2. Test search directly in Prowlarr
3. Check indexer-specific requirements (some need registration)
