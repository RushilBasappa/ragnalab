---
phase: 11-new-app-deployment
plan: 01
subsystem: infra
tags: [authelia, it-tools, traefik, sso, docker]

# Dependency graph
requires:
  - phase: 09-authelia-sso
    provides: Authelia SSO with forwardAuth middleware pattern
  - phase: 10-existing-app-integration
    provides: Established SSO integration patterns for apps
provides:
  - Authelia ACL rules for docs, logs, tools subdomains
  - IT-Tools deployment with SSO protection
  - Pattern for deploying new apps with Authelia forwardAuth
affects: [11-02, 11-03]

# Tech tracking
tech-stack:
  added: [it-tools]
  patterns: [authelia-forwardAuth-new-app, acl-expansion]

key-files:
  created:
    - stack/apps/it-tools/docker-compose.yml
  modified:
    - stack/infra/authelia/config/configuration.yml
    - stack/apps/docker-compose.yml

key-decisions:
  - "IT-Tools accessible to admin and powerusers groups with one_factor"
  - "Paperless-ngx and Dozzle reserved for admin-only with two_factor"
  - "ACL rules added before catch-all rule for proper precedence"

patterns-established:
  - "New app deployment pattern: ACL first, then docker-compose with authelia@file middleware"
  - "Internal Autokuma monitoring URL bypasses auth (http://container:port)"

# Metrics
duration: 4min
completed: 2026-01-26
---

# Phase 11 Plan 01: IT-Tools & ACL Rules Summary

**IT-Tools deployed at tools.ragnalab.xyz with Authelia SSO protection; ACL rules prepared for Paperless-ngx and Dozzle**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-26T02:55:40Z
- **Completed:** 2026-01-26T02:59:30Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added Authelia ACL rules for three new subdomains (docs, logs, tools)
- Deployed IT-Tools as first SSO-protected new app
- Established pattern for new app deployment with forwardAuth

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Authelia access control rules for new apps** - `5f21059` (feat)
2. **Task 2: Create IT-Tools Docker Compose** - `885eb12` (feat)
3. **Task 3: Update apps include and deploy** - `9860ac3` (feat)

## Files Created/Modified

- `stack/infra/authelia/config/configuration.yml` - Added ACL rules #7 (docs/logs - admin/two_factor) and #8 (tools - admin+powerusers/one_factor)
- `stack/apps/it-tools/docker-compose.yml` - IT-Tools container with Traefik, Authelia, Homepage, Autokuma labels
- `stack/apps/docker-compose.yml` - Added it-tools include

## Decisions Made

- IT-Tools uses `one_factor` policy (developer utilities, lower sensitivity than logs/docs)
- Paperless-ngx (docs) and Dozzle (logs) use `two_factor` policy (sensitive data, admin-only)
- ACL rules inserted before catch-all rule #9 for proper precedence
- Internal Autokuma monitoring URL (http://it-tools:80) bypasses Authelia

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Let's Encrypt certificate for tools.ragnalab.xyz took ~60 seconds to issue (normal for new subdomain with DNS-01 challenge)
- Initial curl verification showed self-signed cert, resolved automatically by Traefik ACME

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- ACL rules already in place for docs.ragnalab.xyz and logs.ragnalab.xyz
- Pattern established: create docker-compose with authelia@file middleware
- Ready for 11-02-PLAN.md (Dozzle) and 11-03-PLAN.md (Paperless-ngx)

---
*Phase: 11-new-app-deployment*
*Completed: 2026-01-26*
