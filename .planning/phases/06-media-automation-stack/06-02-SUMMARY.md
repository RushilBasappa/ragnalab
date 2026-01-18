---
phase: 06-media-automation-stack
plan: 02
subsystem: infra
tags: [qbittorrent, torrent, vpn, gluetun, docker, media]

# Dependency graph
requires:
  - phase: 06-01
    provides: Gluetun VPN tunnel and media directory structure
provides:
  - qBittorrent download client routing all traffic through VPN
  - Categories 'tv' and 'movies' configured for Sonarr/Radarr integration
  - Download paths pointing to /media/downloads and /media/incomplete
affects: [06-03, 06-04, 06-05]

# Tech tracking
tech-stack:
  added: [linuxserver/qbittorrent]
  patterns: [network_mode container for VPN routing, API-based configuration]

key-files:
  created:
    - apps/media/qbittorrent/docker-compose.yml
  modified: []

key-decisions:
  - "Removed depends_on - cross-compose service references don't work, rely on network_mode for implicit dependency"
  - "Categories configured via API for automation (tv, movies with correct save paths)"
  - "Temp downloads enabled with /media/incomplete path"

patterns-established:
  - "VPN-routed containers: Use network_mode: container:gluetun for traffic through VPN"
  - "qBittorrent API: Authenticate via /api/v2/auth/login, use cookie for subsequent calls"

# Metrics
duration: 3min
completed: 2026-01-18
---

# Phase 6 Plan 2: qBittorrent Download Client Summary

**qBittorrent deployed with verified VPN routing through Gluetun, categories configured for Sonarr/Radarr integration**

## Performance

- **Duration:** 3 min
- **Started:** 2026-01-18T09:49:22Z
- **Completed:** 2026-01-18T09:52:18Z
- **Tasks:** 3
- **Files modified:** 1

## Accomplishments
- Deployed qBittorrent container with network_mode: container:gluetun for VPN routing
- Verified VPN routing (IP: 95.173.221.45 matches Gluetun VPN exit)
- Configured download categories 'tv' and 'movies' for arr app integration
- Set download paths to /media/downloads with incomplete at /media/incomplete

## Task Commits

Each task was committed atomically:

1. **Task 1: Create qBittorrent docker-compose.yml** - `20ac110` (feat)
2. **Task 2: Deploy and configure qBittorrent** - `3e82a54` (feat)
3. **Task 3: Create qBittorrent categories for arr apps** - No commit (WebUI/API configuration only)

## Files Created/Modified
- `apps/media/qbittorrent/docker-compose.yml` - qBittorrent container configuration with VPN routing

## Decisions Made
- **Removed depends_on section:** Cross-compose service references don't work; the network_mode: container:gluetun implicitly requires gluetun to be running
- **Categories via API:** Created tv and movies categories using qBittorrent API for automation compatibility
- **Enabled temp path:** Downloads use /media/incomplete while in progress, then move to /media/downloads

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed depends_on section for cross-compose compatibility**
- **Found during:** Task 2 (Deploy and configure qBittorrent)
- **Issue:** depends_on: gluetun: condition: service_healthy fails because gluetun is in a different compose file
- **Fix:** Removed depends_on section; network_mode: container:gluetun implicitly enforces dependency (container won't start if gluetun doesn't exist)
- **Files modified:** apps/media/qbittorrent/docker-compose.yml
- **Verification:** docker compose up -d succeeded after removal
- **Committed in:** 3e82a54 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential fix for cross-compose deployment. The network_mode already enforces the gluetun dependency at runtime.

## Issues Encountered
None - deployment proceeded smoothly after fixing the depends_on issue.

## User Setup Required

**Change default password:** The temporary admin password (`uQXVznqzM`) should be changed:
1. Access http://localhost:8080
2. Login with admin / uQXVznqzM
3. Go to Options -> Web UI -> Change password

## Next Phase Readiness
- qBittorrent ready for Prowlarr indexer integration (06-03)
- Categories 'tv' and 'movies' ready for Sonarr and Radarr (06-04)
- Download client accessible at localhost:8080 via VPN tunnel
- No blockers for 06-03 (Prowlarr indexer manager)

---
*Phase: 06-media-automation-stack*
*Plan: 02*
*Completed: 2026-01-18*
