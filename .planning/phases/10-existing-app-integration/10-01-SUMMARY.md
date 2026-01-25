---
phase: 10-existing-app-integration
plan: 01
subsystem: infra
tags: [authelia, sso, traefik, forwardauth, middleware]

# Dependency graph
requires:
  - phase: 09-authelia-sso-foundation
    provides: authelia@file middleware and Authelia authentication service
provides:
  - SSO-protected Homepage dashboard
  - SSO-protected Glances system monitor
  - SSO-protected Traefik dashboard
  - Pattern for adding SSO to simple services (label-only)
affects: [10-existing-app-integration, 11-apps-expansion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ForwardAuth middleware via Docker label: traefik.http.routers.X.middlewares=authelia@file"

key-files:
  created: []
  modified:
    - stack/infra/homepage/docker-compose.yml
    - stack/infra/glances/docker-compose.yml
    - stack/infra/traefik/docker-compose.yml

key-decisions:
  - "Single middleware label per router - no chaining with security-headers for these services"

patterns-established:
  - "SSO for simple services: Add single middleware label, no service changes needed"
  - "Test SSO with curl -sI to verify 302 redirect to auth.ragnalab.xyz"

# Metrics
duration: 2min 29s
completed: 2026-01-25
---

# Phase 10 Plan 01: Infrastructure SSO Summary

**Homepage, Glances, and Traefik dashboard protected with Authelia ForwardAuth middleware - single label addition per service**

## Performance

- **Duration:** 2 min 29 sec
- **Started:** 2026-01-25T16:42:30Z
- **Completed:** 2026-01-25T16:44:59Z
- **Tasks:** 3/3
- **Files modified:** 3

## Accomplishments

- Homepage dashboard (home.ragnalab.xyz) now requires Authelia authentication
- Glances system monitor (glances.ragnalab.xyz) now requires Authelia authentication
- Traefik dashboard (traefik.ragnalab.xyz) now requires Authelia authentication
- SSO session persists across all three services (single login for all)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Authelia middleware to Homepage** - `33dc56b` (feat)
2. **Task 2: Add Authelia middleware to Glances** - `cc8b39c` (feat)
3. **Task 3: Add Authelia middleware to Traefik dashboard** - `99b1075` (feat)

## Files Created/Modified

- `stack/infra/homepage/docker-compose.yml` - Added `traefik.http.routers.homepage.middlewares=authelia@file`
- `stack/infra/glances/docker-compose.yml` - Added `traefik.http.routers.glances.middlewares=authelia@file`
- `stack/infra/traefik/docker-compose.yml` - Added `traefik.http.routers.dashboard.middlewares=authelia@file`

## Decisions Made

None - followed plan as specified. The pattern of adding a single middleware label is straightforward for services without built-in authentication.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Recyclarr container conflict:** During stack redeployment, a stale recyclarr container caused a conflict. Resolved by removing the old container with `docker rm -f recyclarr` before redeploying.
- **Gluetun unhealthy:** Unrelated to SSO changes - the VPN tunnel had an issue during redeployment. This is a pre-existing condition and does not affect the SSO integration.

## User Setup Required

None - no external service configuration required. Changes are purely Docker label additions.

## Next Phase Readiness

- Ready for 10-02: Media stack SSO (arr apps, Jellyfin, etc.)
- Pattern established: Simple services need only the middleware label
- More complex services (arr apps) will need additional configuration for API key bypass and external auth trust

---
*Phase: 10-existing-app-integration*
*Completed: 2026-01-25*
