---
phase: 06-media-automation-stack
plan: 05
subsystem: media
tags: [bazarr, unpackerr, subtitles, extraction, traefik, homepage]

# Dependency graph
requires:
  - phase: 06-04
    provides: Sonarr and Radarr media automation services
provides:
  - Bazarr subtitle automation at https://bazarr.ragnalab.xyz
  - Unpackerr archive extraction for RAR/ZIP downloads
  - OpenSubtitles.com provider for automatic subtitle downloads
affects: [06-06, 06-07, 06-08]

# Tech tracking
tech-stack:
  added: [linuxserver/bazarr, golift/unpackerr]
  patterns: [api-based-configuration, headless-service]

key-files:
  created:
    - apps/media/bazarr/docker-compose.yml
    - apps/media/unpackerr/docker-compose.yml
  modified:
    - apps/media/.env

key-decisions:
  - "Used golift/unpackerr instead of hotio/unpackerr (hotio image doesn't exist)"
  - "Forms authentication enabled for Bazarr via config file modification"
  - "OpenSubtitles.com enabled as default subtitle provider (no account required for limited use)"

patterns-established:
  - "Headless services (no web UI) only need media network, not proxy"
  - "Config file modification for complex service configuration when API is limited"

# Metrics
duration: 12min
completed: 2026-01-18
---

# Phase 6 Plan 5: Bazarr + Unpackerr Support Services Summary

**Bazarr subtitle automation deployed with Sonarr/Radarr integration and OpenSubtitles.com provider, plus Unpackerr for automatic RAR/ZIP extraction**

## Performance

- **Duration:** 12 min
- **Started:** 2026-01-18T10:12:12Z
- **Completed:** 2026-01-18T10:24:04Z
- **Tasks:** 4
- **Files modified:** 3 (2 docker-compose, 1 .env)

## Accomplishments
- Deployed Bazarr at https://bazarr.ragnalab.xyz with valid SSL
- Connected Bazarr to both Sonarr and Radarr for library sync
- Enabled OpenSubtitles.com as default subtitle provider
- Deployed Unpackerr for automatic archive extraction
- Unpackerr successfully connected to Sonarr and Radarr queues
- Both services integrated with Homepage dashboard

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Bazarr docker-compose.yml** - `e8c8d2e` (feat)
2. **Task 2: Create Unpackerr docker-compose.yml** - `051445c` (feat)
3. **Task 3: Deploy and configure Bazarr** - No commit (config in docker volume, .env gitignored)
4. **Task 4: Deploy Unpackerr** - `2651797` (fix: image correction)

## Files Created/Modified
- `apps/media/bazarr/docker-compose.yml` - Bazarr container with Traefik/Homepage labels
- `apps/media/unpackerr/docker-compose.yml` - Unpackerr container with arr connections
- `apps/media/.env` - Added BAZARR_API_KEY (gitignored)

## Decisions Made
- **golift/unpackerr over hotio/unpackerr:** The hotio image doesn't exist; golift is the original maintainer
- **Config file modification for Bazarr:** API settings changes weren't persisting, so modified config.yaml directly
- **OpenSubtitles.com as default provider:** Works without account for limited use, most popular source
- **Forms authentication for Bazarr:** Consistent with other arr services (admin/Ragnalab2026)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Changed Unpackerr image from hotio to golift**
- **Found during:** Task 4 (Deploy Unpackerr)
- **Issue:** hotio/unpackerr image does not exist on Docker Hub
- **Fix:** Changed to golift/unpackerr:latest (official maintainer)
- **Files modified:** apps/media/unpackerr/docker-compose.yml
- **Verification:** Container started, logs show successful connections
- **Committed in:** 2651797 (Task 4 commit)

**2. [Rule 3 - Blocking] Config file modification for Bazarr**
- **Found during:** Task 3 (Deploy Bazarr)
- **Issue:** Bazarr API POST to /api/system/settings wasn't persisting changes
- **Fix:** Modified config.yaml directly in docker volume while container stopped
- **Files modified:** Docker volume config (not in git)
- **Verification:** Settings persisted after restart, Sonarr/Radarr connected

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes essential for service functionality. Image issue was plan error; config modification was necessary workaround for API limitation.

## Issues Encountered
- Bazarr API settings were not persisting - resolved by direct config file modification
- Local DNS resolution returning different IP than Tailscale - used --resolve flag for curl verification

## User Setup Required

**Credentials should be changed:**
1. Bazarr: https://bazarr.ragnalab.xyz - Login with admin / Ragnalab2026, change password in Settings -> General -> Security

**Subtitle providers (optional):**
OpenSubtitles.com is enabled but has usage limits without an account. For unlimited use:
1. Create free account at opensubtitles.com
2. In Bazarr Settings -> Providers, add credentials

## Next Phase Readiness
- Bazarr ready for automatic subtitle downloads
- Unpackerr monitoring download folders for archives
- Media stack support services complete
- Ready for Plan 06-06 (Jellyfin media server)
- No blockers for remaining plans

---
*Phase: 06-media-automation-stack*
*Plan: 05*
*Completed: 2026-01-18*
