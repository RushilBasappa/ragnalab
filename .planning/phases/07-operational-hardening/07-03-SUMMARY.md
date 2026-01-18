---
phase: 07-operational-hardening
plan: 03
subsystem: infra
tags: [docker-compose, apps, profiles, vaultwarden, pihole, rustdesk, glances, makefile]

# Dependency graph
requires:
  - phase: 07-02
    provides: Media stack migrated to stack/media/, profile-based compose pattern established
provides:
  - Apps (vaultwarden, pihole, rustdesk, glances) migrated to stack/apps/
  - Profile-based compose management (--profile apps)
  - Simplified Makefile with only operational targets (backup, restore, status)
  - Old directory structure archived
affects: [07-04, 07-05, cleanup, backup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - nested docker compose includes (category -> service)
    - external volume naming convention
    - profile-based service management
    - simplified Makefile for operations only

key-files:
  created:
    - stack/apps/vaultwarden/docker-compose.yml
    - stack/apps/pihole/docker-compose.yml
    - stack/apps/rustdesk/docker-compose.yml
    - stack/apps/glances/docker-compose.yml
  modified:
    - stack/apps/docker-compose.yml
    - Makefile
    - .gitignore

key-decisions:
  - "External volumes use project_volumename format (vaultwarden_vaultwarden-data, rustdesk_rustdesk-data)"
  - "Makefile reduced to backup, restore, status targets only - services managed via docker compose --profile"
  - "Old apps/ and proxy/ directories archived to archive/pre-stack-migration/"

patterns-established:
  - "Profile-based service management across all categories (infra, media, apps)"
  - "Service compose files include profiles: [category] for selective startup"
  - "Operational Makefile targets for backup/restore/status only"

# Metrics
duration: 5min
completed: 2026-01-18
---

# Phase 7 Plan 3: Apps Migration and Makefile Simplification Summary

**4 apps (vaultwarden, pihole, rustdesk, glances) migrated to stack/apps/ with profile-based management and Makefile simplified to operational essentials**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-18T15:59:27Z
- **Completed:** 2026-01-18T16:04:26Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Created all 4 app service folders with compose files in stack/apps/
- Added profiles: ["apps"] to all services for selective deployment
- Simplified Makefile to only backup, restore, status targets
- Archived old apps/ and proxy/ directories to archive/pre-stack-migration/
- Verified all apps accessible via HTTPS (vaultwarden, pihole, glances)
- Full stack operational with 19 profile-managed containers

## Task Commits

Each task was committed atomically:

1. **Task 1: Migrate remaining apps to stack/apps/** - `e8cde7d` (feat)
2. **Task 2: Simplify Makefile to operational essentials** - `1787968` (chore)
3. **Task 3: Verify apps profile and archive old directories** - `83abed4` (chore)

## Files Created/Modified
- `stack/apps/vaultwarden/docker-compose.yml` - Password manager with external volume
- `stack/apps/pihole/docker-compose.yml` - DNS ad blocking with macvlan network
- `stack/apps/rustdesk/docker-compose.yml` - Remote desktop with host networking
- `stack/apps/glances/docker-compose.yml` - System monitoring dashboard
- `stack/apps/docker-compose.yml` - Category compose with includes
- `Makefile` - Simplified to backup, restore, status targets
- `.gitignore` - Updated paths for stack/ structure, added archive/ exclusion

## Decisions Made
- **External volume naming:** Used `{project}_{volumename}` format (e.g., `vaultwarden_vaultwarden-data`) to match existing Docker volumes and preserve all data
- **Makefile simplification:** Removed up, down, restart, ps, logs, networks targets - services now managed via `docker compose --profile {infra|media|apps} up -d`
- **Pi-hole config bind mounts:** Copied etc-pihole/ and etc-dnsmasq.d/ to stack/apps/pihole/ for compose-relative paths
- **Archive strategy:** Old directories moved to archive/pre-stack-migration/ rather than deleted, preserving history

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- **Initial 404 from Traefik:** Immediately after starting apps profile, vaultwarden and pihole returned 404. Traefik needed a few seconds to pick up new container labels. Resolved by waiting briefly - services then returned 200.
- **SSL certificate errors on curl:** Local curl to HTTPS domains returned exit code 60 (cert verification). Used `-k` flag as workaround for testing - services accessible via browser with valid certs.

## User Setup Required

None - all services use existing configuration and data volumes.

## Next Phase Readiness
- Complete compose restructuring finished with all services in stack/ directory
- All 3 profiles operational: infra (5 services), media (9 services), apps (4+1 services)
- Makefile simplified to operational targets
- Ready for 07-04 (if exists) or subsequent operational hardening plans
- Socket-proxy migration for Uptime Kuma/Homepage still pending (planned for 07-05)

---
*Phase: 07-operational-hardening*
*Completed: 2026-01-18*
