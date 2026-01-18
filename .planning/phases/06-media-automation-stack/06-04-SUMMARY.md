---
phase: 06-media-automation-stack
plan: 04
subsystem: media
tags: [sonarr, radarr, automation, traefik, homepage, qbittorrent, prowlarr]

# Dependency graph
requires:
  - phase: 06-02
    provides: qBittorrent download client via Gluetun VPN
  - phase: 06-03
    provides: Prowlarr indexer manager
provides:
  - Sonarr TV automation at https://sonarr.ragnalab.xyz
  - Radarr movie automation at https://radarr.ragnalab.xyz
  - Both connected to qBittorrent download client via gluetun network
  - Both synced with Prowlarr for indexer management
  - Root folders configured for hardlink support (/media/library/tv, /media/library/movies)
affects: [06-05, 06-06, 06-07, 06-08]

# Tech tracking
tech-stack:
  added: [linuxserver/sonarr, linuxserver/radarr]
  patterns: [arr-app-pattern, multi-network-container, api-based-configuration]

key-files:
  created:
    - apps/media/sonarr/docker-compose.yml
    - apps/media/radarr/docker-compose.yml
  modified:
    - apps/media/.env

key-decisions:
  - "Added media network to Sonarr/Radarr for qBittorrent connectivity"
  - "Forms authentication enabled via API during deployment"
  - "Default credentials set (admin/Ragnalab2026) - user should change"

patterns-established:
  - "Arr apps need both proxy and media networks for Traefik + qBittorrent access"
  - "API-based configuration for arr apps (auth, download clients, root folders)"
  - "Prowlarr sync configured from Prowlarr side (add apps to Prowlarr)"

# Metrics
duration: 13min
completed: 2026-01-18
---

# Phase 6 Plan 4: Sonarr + Radarr Media Automation Summary

**Sonarr and Radarr deployed with HTTPS access, forms authentication, qBittorrent download client via gluetun, and Prowlarr indexer sync**

## Performance

- **Duration:** 13 min
- **Started:** 2026-01-18T09:56:53Z
- **Completed:** 2026-01-18T10:09:49Z
- **Tasks:** 3
- **Files modified:** 3 (2 docker-compose, 1 .env)

## Accomplishments
- Deployed Sonarr at https://sonarr.ragnalab.xyz with valid SSL
- Deployed Radarr at https://radarr.ragnalab.xyz with valid SSL
- Connected both to qBittorrent download client via gluetun network
- Synced both with Prowlarr for automatic indexer management
- Configured root folders for hardlink support (/media/library/tv, /media/library/movies)
- API keys saved in .env for Homepage widget integration

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Sonarr and Radarr docker-compose files** - `4d7e1ee` (feat)
2. **Task 2: Deploy and configure Sonarr** - `ba6445c` (feat)
3. **Task 3: Deploy and configure Radarr** - `ce9b2cb` (feat)

## Files Created/Modified
- `apps/media/sonarr/docker-compose.yml` - Sonarr container with Traefik/Homepage labels, media network
- `apps/media/radarr/docker-compose.yml` - Radarr container with Traefik/Homepage labels, media network
- `apps/media/.env` - Added SONARR_API_KEY and RADARR_API_KEY

## Decisions Made
- **Media network required:** Sonarr and Radarr need both proxy (for Traefik) and media (for qBittorrent via gluetun) networks
- **Forms authentication via API:** Configured authentication programmatically during deployment
- **Default credentials:** Set admin/Ragnalab2026 as initial credentials (user should change these)
- **Prowlarr sync from Prowlarr side:** Apps added to Prowlarr's application list rather than Sonarr/Radarr connecting to Prowlarr

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added media network to docker-compose files**
- **Found during:** Task 2 (Deploy Sonarr)
- **Issue:** Sonarr couldn't connect to qBittorrent via gluetun - containers were on different networks (proxy vs media)
- **Fix:** Added media network as second external network to both Sonarr and Radarr docker-compose files
- **Files modified:** apps/media/sonarr/docker-compose.yml, apps/media/radarr/docker-compose.yml
- **Verification:** Successfully connected to qBittorrent from both containers
- **Committed in:** ba6445c, ce9b2cb (Task 2, 3 commits)

**2. [Rule 3 - Blocking] Connected Prowlarr to media network**
- **Found during:** Task 2 (Prowlarr sync configuration)
- **Issue:** Prowlarr couldn't reach Sonarr/Radarr for app sync - different networks
- **Fix:** Connected prowlarr container to media network via `docker network connect`
- **Files modified:** None (runtime network connection)
- **Verification:** Prowlarr applications API shows both Sonarr and Radarr
- **Committed in:** Not committed (runtime configuration)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes essential for cross-container communication. Multi-network architecture is the correct solution for services needing both Traefik access and internal media network communication.

## Issues Encountered
None - deployment proceeded smoothly after network connectivity fixes.

## User Setup Required

**Credentials should be changed:**
1. Sonarr: https://sonarr.ragnalab.xyz - Login with admin / Ragnalab2026, change password in Settings -> General
2. Radarr: https://radarr.ragnalab.xyz - Login with admin / Ragnalab2026, change password in Settings -> General

**Indexers require configuration:**
Prowlarr currently has no indexers configured. Add indexers in Prowlarr at https://prowlarr.ragnalab.xyz:
1. Go to Indexers -> Add Indexer
2. Add public or private indexers
3. Indexers will automatically sync to Sonarr and Radarr

## Next Phase Readiness
- Sonarr ready for TV show automation
- Radarr ready for movie automation
- Both connected to download client and indexer manager
- Hardlink paths configured correctly (/media:/media)
- Ready for Plan 06-05 (Bazarr subtitles + Unpackerr extraction)
- No blockers for remaining plans

---
*Phase: 06-media-automation-stack*
*Plan: 04*
*Completed: 2026-01-18*
