---
phase: 06-media-automation-stack
plan: 07
subsystem: media
tags: [jellyseerr, request-management, jellyfin, sonarr, radarr, backup]

# Dependency graph
requires:
  - phase: 06-04
    provides: Sonarr/Radarr for processing media requests
  - phase: 06-06
    provides: Jellyfin for user authentication
provides:
  - Jellyseerr request portal at https://requests.ragnalab.xyz
  - User-friendly media request interface
  - Integration with Jellyfin authentication
  - Request routing to Sonarr (TV) and Radarr (Movies)
  - All media stack volumes in backup rotation
affects: [06-08]

# Tech tracking
tech-stack:
  added: [fallenbagel/jellyseerr]
  patterns: [jellyfin-auth-integration, backup-volume-aggregation]

key-files:
  created:
    - apps/media/jellyseerr/docker-compose.yml
  modified:
    - apps/backup/docker-compose.yml (added 8 media volumes)
    - apps/media/.env (JELLYSEERR_API_KEY)

key-decisions:
  - "Jellyfin authentication - users log in with existing Jellyfin accounts"
  - "Backup aggregation - all 8 media volumes now included in nightly backup"
  - "Stop-during-backup - media containers paused during backup for consistency"

patterns-established:
  - "Jellyfin SSO for media request management"
  - "Centralized backup configuration for all media stack volumes"

# Metrics
duration: 15min
completed: 2026-01-18
---

# Phase 6 Plan 7: Jellyseerr Request Management Summary

**Jellyseerr request portal at requests.ragnalab.xyz with Jellyfin SSO, Sonarr/Radarr integration, and all media volumes added to backup system**

## Performance

- **Duration:** 15 min (including user setup wizard)
- **Started:** 2026-01-18T10:25:00Z
- **Completed:** 2026-01-18T10:40:00Z
- **Tasks:** 3
- **Files created:** 1 (docker-compose.yml)
- **Files modified:** 2 (backup compose, .env)

## Accomplishments
- Deployed Jellyseerr at https://requests.ragnalab.xyz with valid SSL
- Configured Jellyfin authentication (users sign in with Jellyfin credentials)
- Connected Radarr for movie requests
- Connected Sonarr for TV show requests
- Added all 8 media stack volumes to backup system (prowlarr, sonarr, radarr, bazarr, jellyfin, jellyseerr, qbittorrent, gluetun)
- Updated backup container stop list for data consistency

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Jellyseerr docker-compose.yml** - `0e16545` (feat)
2. **Task 2: Deploy Jellyseerr and configure integrations** - No commit (user completed setup wizard via browser)
3. **Task 3: Update backup system with all media volumes** - `8ebaee3` (feat)

## Files Created/Modified
- `apps/media/jellyseerr/docker-compose.yml` - Jellyseerr container with Traefik/Homepage labels
- `apps/backup/docker-compose.yml` - Added 8 external volume mounts for media stack
- `apps/media/.env` - Added JELLYSEERR_API_KEY for Homepage widget

## Decisions Made
- **Jellyfin authentication:** Users authenticate via Jellyfin accounts - no separate Jellyseerr credentials
- **Backup aggregation:** All media stack volumes consolidated in single backup job (previously only vaultwarden)
- **Stop-during-backup:** Added prowlarr, sonarr, radarr, bazarr, jellyfin, jellyseerr, qbittorrent to stop list for consistent backups

## Deviations from Plan

None - plan executed exactly as written.

## Authentication Gates

During execution, user authentication was required:

1. **Task 2:** Jellyseerr setup wizard required browser interaction
   - User signed in with Jellyfin credentials
   - User added Radarr and Sonarr services via UI
   - Resumed after confirmation of initialization

## Issues Encountered

None - deployment proceeded smoothly.

## User Setup Required

**Making requests:**
1. Access Jellyseerr at https://requests.ragnalab.xyz
2. Sign in with Jellyfin credentials
3. Search for movies or TV shows
4. Click "Request" to send to Radarr/Sonarr

**Admin configuration (optional):**
- Settings -> General -> API Key (for Homepage widget)
- Settings -> Notifications (Discord, email, etc.)
- Settings -> Users (permission management)

## Next Phase Readiness
- Jellyseerr ready to accept media requests from users
- Full media stack operational: Prowlarr -> Sonarr/Radarr -> qBittorrent -> Jellyfin
- All services backed up nightly
- Ready for Plan 06-08 (Homepage integration finalization)
- No blockers for remaining plan

---
*Phase: 06-media-automation-stack*
*Plan: 07*
*Completed: 2026-01-18*
