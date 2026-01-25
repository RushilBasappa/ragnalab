---
phase: 10-existing-app-integration
plan: 03
subsystem: auth
tags: [authelia, sonarr, radarr, prowlarr, sso, external-auth, traefik-middleware]

# Dependency graph
requires:
  - phase: 09-authelia-sso-foundation
    provides: Authelia SSO with forwardAuth middleware
  - phase: 10-01
    provides: Infrastructure services with Authelia middleware pattern
provides:
  - Sonarr, Radarr, Prowlarr protected by Authelia SSO
  - *arr apps configured for External authentication mode
  - Single sign-on across media automation apps
affects: [10-04, future-media-apps]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "*arr External AuthenticationMethod for SSO trust"
    - "config.xml modification for auth mode change"

key-files:
  created: []
  modified:
    - stack/media/prowlarr/docker-compose.yml
    - stack/media/sonarr/docker-compose.yml
    - stack/media/radarr/docker-compose.yml

key-decisions:
  - "External auth mode requires container stop for config.xml edit"
  - "sed in-place edit for atomic auth method change"

patterns-established:
  - "*arr External auth: stop container, sed config.xml, add middleware, start container"

# Metrics
duration: 4min
completed: 2026-01-25
---

# Phase 10 Plan 03: *arr Apps SSO Integration Summary

**Sonarr, Radarr, and Prowlarr configured for Authelia SSO with External authentication mode**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-25T16:42:25Z
- **Completed:** 2026-01-25T16:46:01Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Prowlarr, Sonarr, and Radarr now require Authelia login
- External auth mode eliminates double login (no Forms page after SSO)
- API access preserved for Homepage widgets via API key bypass
- All three apps share SSO session (login once, access all)

## Task Commits

Each task was committed atomically:

1. **Task 1: Configure Prowlarr External auth and add middleware** - `8dfd052` (feat)
2. **Task 2: Configure Sonarr External auth and add middleware** - `e81a693` (feat)
3. **Task 3: Configure Radarr External auth and add middleware** - `f9429c1` (feat)

## Files Created/Modified

- `stack/media/prowlarr/docker-compose.yml` - Added authelia@file middleware label
- `stack/media/sonarr/docker-compose.yml` - Added authelia@file middleware label
- `stack/media/radarr/docker-compose.yml` - Added authelia@file middleware label

**Config files modified (Docker volumes, not in git):**
- `/var/lib/docker/volumes/ragnalab_prowlarr-config/_data/config.xml` - AuthenticationMethod=External
- `/var/lib/docker/volumes/ragnalab_sonarr-config/_data/config.xml` - AuthenticationMethod=External
- `/var/lib/docker/volumes/ragnalab_radarr-config/_data/config.xml` - AuthenticationMethod=External

## Decisions Made

None - followed plan as specified.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Gluetun container issue during stack recomposition:** Pre-existing issue unrelated to this plan. The *arr containers were recreated successfully despite gluetun container reference error. qBittorrent depends on gluetun and may need separate attention.
- **Prowlarr container name anomaly:** Container was named `42e6d991463d_prowlarr` instead of `prowlarr` due to previous state, but was recreated correctly during force-recreate.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Prowlarr, Sonarr, Radarr now protected by Authelia SSO
- Users will be redirected to auth.ragnalab.xyz when accessing *arr apps
- After Authelia login, users see app UI directly (no Forms login)
- Homepage widgets continue to work via API key authentication
- Ready for 10-04 (Bazarr SSO integration)

---
*Phase: 10-existing-app-integration*
*Completed: 2026-01-25*
