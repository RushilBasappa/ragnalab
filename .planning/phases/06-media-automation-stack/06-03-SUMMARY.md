---
phase: 06-media-automation-stack
plan: 03
subsystem: media
tags: [prowlarr, indexer, traefik, homepage, docker]

# Dependency graph
requires:
  - phase: 06-01
    provides: Directory structure and Gluetun VPN container
provides:
  - Prowlarr indexer manager accessible at https://prowlarr.ragnalab.xyz
  - Media group in Homepage layout for arr services
  - Forms authentication enabled (username: admin)
  - API key for Homepage widget integration
affects: [06-04, 06-05, 06-07, 06-08]

# Tech tracking
tech-stack:
  added: [prowlarr]
  patterns: [linuxserver-image, arr-app-pattern, traefik-auto-discovery]

key-files:
  created:
    - apps/media/prowlarr/docker-compose.yml
  modified:
    - apps/homepage/config/settings.yaml
    - apps/media/.env

key-decisions:
  - "Forms authentication enabled via API during deployment"
  - "Media group added to Homepage layout for arr service discovery"
  - "Default credentials set (admin/Ragnalab2026) - user should change"

patterns-established:
  - "Arr apps use LinuxServer images with Traefik labels"
  - "API keys stored in apps/media/.env for Homepage widgets"
  - "Media group in Homepage for all arr services"

# Metrics
duration: 5min
completed: 2026-01-18
---

# Phase 6 Plan 3: Prowlarr Indexer Manager Summary

**Prowlarr indexer manager deployed with Traefik HTTPS, forms authentication, and Homepage integration under new Media group**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-18T09:49:35Z
- **Completed:** 2026-01-18T09:54:56Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- Prowlarr deployed and accessible at https://prowlarr.ragnalab.xyz
- Forms authentication configured via API (no open access)
- Homepage Media group created with Prowlarr as first service
- API key saved in .env for widget integration

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Prowlarr docker-compose.yml** - `811d995` (feat)
2. **Task 2: Deploy and configure authentication** - (no tracked files - container deployment + .env update)
3. **Task 3: Verify Homepage integration** - `576f866` (feat - included Media group layout)

## Files Created/Modified
- `apps/media/prowlarr/docker-compose.yml` - Prowlarr container with Traefik/Homepage labels
- `apps/homepage/config/settings.yaml` - Added Media group to layout
- `apps/media/.env` - Added PROWLARR_API_KEY (gitignored)

## Decisions Made
- **Forms authentication via API**: Configured authentication programmatically during deployment rather than requiring manual UI setup
- **Default credentials**: Set admin/Ragnalab2026 as initial credentials (user should change these)
- **Media layout group**: Added to Homepage settings.yaml to enable discovery of arr services

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added Media group to Homepage layout**
- **Found during:** Task 3 (Homepage integration verification)
- **Issue:** Homepage wouldn't show Prowlarr because no "Media" group was defined in layout
- **Fix:** Added Media group with filmstrip icon to settings.yaml
- **Files modified:** apps/homepage/config/settings.yaml
- **Verification:** Prowlarr now appears in Homepage under Media group
- **Committed in:** 576f866

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential for Homepage integration. Enables all future media services.

## Issues Encountered
None - deployment proceeded smoothly.

## User Setup Required

**Prowlarr credentials should be changed:**
1. Visit https://prowlarr.ragnalab.xyz
2. Login with admin / Ragnalab2026
3. Go to Settings -> General -> Security
4. Change password to something secure

**Indexers will be configured after Sonarr/Radarr deployment (Plan 06-04).**

## Next Phase Readiness
- Prowlarr ready for indexer configuration
- API key available for Sonarr/Radarr sync
- Homepage Media group ready for additional arr services
- No blockers for Plan 06-04 (Sonarr + Radarr)

---
*Phase: 06-media-automation-stack*
*Completed: 2026-01-18*
