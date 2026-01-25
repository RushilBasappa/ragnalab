---
phase: 10-existing-app-integration
plan: 02
subsystem: auth
tags: [authelia, sso, uptime-kuma, backrest, traefik, forward-auth]

# Dependency graph
requires:
  - phase: 10-existing-app-integration
    plan: 01
    provides: Authelia middleware configured in Traefik
provides:
  - Uptime Kuma protected by Authelia SSO
  - Backrest protected by Authelia SSO
  - Both services with built-in auth disabled (no double login)
affects: [monitoring, backups, homepage]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Disable app built-in auth when using Authelia forward-auth"

key-files:
  created: []
  modified:
    - stack/infra/uptime-kuma/docker-compose.yml
    - stack/infra/backrest/docker-compose.yml

key-decisions:
  - "Disable built-in auth before adding middleware to prevent double login"
  - "User performs auth disable via UI (no automation available)"

patterns-established:
  - "Infrastructure services pattern: disable built-in auth, add authelia@file middleware"

# Metrics
duration: 2min
completed: 2026-01-25
---

# Phase 10 Plan 02: Uptime Kuma & Backrest SSO Summary

**Uptime Kuma and Backrest protected with Authelia forward-auth, built-in authentication disabled to provide single sign-on**

## Performance

- **Duration:** 2 min (continuation session)
- **Started:** 2026-01-25T16:53:32Z
- **Completed:** 2026-01-25T16:54:55Z
- **Tasks:** 4 (2 human-action checkpoints, 2 auto)
- **Files modified:** 2

## Accomplishments

- Uptime Kuma (status.ragnalab.xyz) redirects to Authelia for authentication
- Backrest (backups.ragnalab.xyz) redirects to Authelia for authentication
- Both services accessible without second login after Authelia authentication
- Infrastructure monitoring and backups now protected by SSO

## Task Commits

Each task was committed atomically:

1. **Task 1: Disable Uptime Kuma built-in auth** - (checkpoint, user action)
2. **Task 2: Add Authelia middleware to Uptime Kuma** - `a7e2cf8` (feat)
3. **Task 3: Disable Backrest built-in auth** - (checkpoint, user action)
4. **Task 4: Add Authelia middleware to Backrest** - `be6d678` (feat)

## Files Created/Modified

- `stack/infra/uptime-kuma/docker-compose.yml` - Added authelia@file middleware label
- `stack/infra/backrest/docker-compose.yml` - Added authelia@file middleware label

## Decisions Made

- User performs authentication disabling via web UI (no CLI/API available for these services)
- Middleware added after the loadbalancer.server.port label, before traefik.docker.network label (consistent pattern)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- After recreating uptime-kuma container, needed brief wait for startup before Authelia redirect worked (normal startup timing)

## User Setup Required

None - no external service configuration required beyond the checkpoint actions already completed.

## Next Phase Readiness

- Uptime Kuma and Backrest now join the SSO-protected services
- All infrastructure services (Traefik, Glances, Pi-hole, Uptime Kuma, Backrest) now behind Authelia
- Phase 10 now complete - ready for Phase 11 (New Apps)

---
*Phase: 10-existing-app-integration*
*Completed: 2026-01-25*
