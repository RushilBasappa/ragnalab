# Jellyseerr Installation

Media request management - users request shows/movies, automatically sent to Sonarr/Radarr.

**URL:** https://requests.ragnalab.xyz

---

## Prerequisites

- Jellyfin running (see [jellyfin/INSTALL.md](../jellyfin/INSTALL.md))
- Sonarr running (see [sonarr/INSTALL.md](../sonarr/INSTALL.md))
- Radarr running (see [radarr/INSTALL.md](../radarr/INSTALL.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/media/jellyseerr/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://requests.ragnalab.xyz
```

---

## Manual Steps Required

### Complete Setup Wizard

1. Open https://requests.ragnalab.xyz
2. Click **Sign in with Jellyfin**
3. Enter Jellyfin URL: `http://jellyfin:8096`
4. Login with your Jellyfin admin credentials
5. Complete the setup wizard

### Add Radarr (Movies)

1. Go to **Settings → Services**
2. Click **Add Radarr Server**
3. Configure:
   - Server Name: `Radarr`
   - Hostname: `radarr`
   - Port: `7878`
   - API Key: (from `apps/media/.env` or Radarr Settings → General)
4. Click **Test** then **Save**

### Add Sonarr (TV)

1. Go to **Settings → Services**
2. Click **Add Sonarr Server**
3. Configure:
   - Server Name: `Sonarr`
   - Hostname: `sonarr`
   - Port: `8989`
   - API Key: (from `apps/media/.env` or Sonarr Settings → General)
4. Click **Test** then **Save**

### Get API Key for Homepage (Optional)

1. Go to **Settings → General**
2. Copy the API Key
3. Add to `apps/media/.env`:
   ```
   JELLYSEERR_API_KEY=your-api-key
   ```

---

## How It Works

1. **User browses** Jellyseerr for movies/TV shows
2. **User clicks Request**
3. **Jellyseerr** sends request to Sonarr (TV) or Radarr (movies)
4. **Sonarr/Radarr** searches and downloads automatically
5. **User gets notified** when available in Jellyfin

### User Management

Users authenticate with their Jellyfin accounts:
- No separate account needed
- Permissions can be set per user
- Admin can auto-approve or require manual approval

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/jellyseerr/docker-compose.yml` | Container configuration |
| Volume: `jellyseerr-config` | Settings, request database |
| `apps/media/.env` | API key for Homepage |

---

## Troubleshooting

### Can't connect to Jellyfin

1. Use internal hostname: `http://jellyfin:8096` (not the public URL)
2. Verify Jellyfin is on `media` network
3. Test: `docker exec jellyseerr wget -qO- http://jellyfin:8096`

### Requests not being sent

1. Check Sonarr/Radarr connections in Settings → Services
2. Verify API keys are correct
3. Check request status in Jellyseerr

### Users can't log in

1. Ensure Jellyfin authentication is working
2. Check Jellyseerr logs: `docker logs jellyseerr`
3. Verify user exists in Jellyfin
