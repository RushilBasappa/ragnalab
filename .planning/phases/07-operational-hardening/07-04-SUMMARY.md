---
phase: 07-operational-hardening
plan: 04
subsystem: infra
tags: [docker, socket-proxy, security, homepage, uptime-kuma]

# Dependency graph
requires:
  - phase: 07-01
    provides: socket-proxy deployed with extended permissions (IMAGES=1, INFO=1)
  - phase: 07-03
    provides: stack/ structure with services migrated
provides:
  - Socket-proxy as sole Docker API access point for Homepage and Uptime Kuma
  - Eliminated direct docker.sock exposure from monitoring services
  - Homepage docker.yaml configured for TCP socket-proxy access
affects: [07-05-backup, 07-07-autokuma]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Socket-proxy TCP access pattern for Docker API consumers
    - External volume declarations to avoid include conflicts

key-files:
  created: []
  modified:
    - stack/infra/uptime-kuma/docker-compose.yml
    - stack/infra/homepage/docker-compose.yml
    - stack/infra/homepage/config/docker.yaml
    - stack/infra/backup/docker-compose.yml

key-decisions:
  - "External volume naming for include compatibility - volumes declared in multiple compose files must use external: true with explicit name"
  - "UI configuration required for Uptime Kuma Docker host - no DOCKER_HOST env var support"

patterns-established:
  - "Socket-proxy access: services use socket_proxy_network and connect to socket-proxy:2375"
  - "Volume conflict resolution: use external volumes with explicit names when volume referenced in multiple compose files"

# Metrics
duration: 4min
completed: 2026-01-18
---

# Phase 07 Plan 04: Socket-Proxy Migration Summary

**Migrated Homepage and Uptime Kuma to socket-proxy for Docker API access, eliminating direct docker.sock exposure**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-18T16:06:15Z
- **Completed:** 2026-01-18T16:10:15Z
- **Tasks:** 3 (1 already complete, 2 executed)
- **Files modified:** 4

## Accomplishments

- Removed docker.sock mount from Uptime Kuma
- Removed docker.sock mount from Homepage
- Configured Homepage docker.yaml for socket-proxy:2375 TCP access
- Fixed volume naming conflict between uptime-kuma and backup composes
- Verified only 3 services mount docker.sock (socket-proxy, backup, glances)

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend socket-proxy permissions** - N/A (already complete from 07-01)
2. **Task 2: Migrate Uptime Kuma to socket-proxy** - `54a34a6` (feat)
3. **Task 3: Migrate Homepage to socket-proxy** - `ee60c23` (feat)

## Files Created/Modified

- `stack/infra/uptime-kuma/docker-compose.yml` - Removed docker.sock mount, added socket_proxy_network, made volume external
- `stack/infra/homepage/docker-compose.yml` - Removed docker.sock mount, removed PGID=123, added socket_proxy_network
- `stack/infra/homepage/config/docker.yaml` - Changed from socket path to socket-proxy:2375 TCP
- `stack/infra/backup/docker-compose.yml` - Fixed uptime-kuma-data volume name to ragnalab_uptime-kuma-data

## Decisions Made

- **External volume declarations:** When the same volume is referenced in multiple compose files within an include tree (uptime-kuma defines it, backup references it), both must use `external: true` with the same explicit name to avoid Docker Compose conflicts.
- **Uptime Kuma Docker host configuration:** Uptime Kuma stores Docker host settings in its SQLite database, not environment variables. UI configuration required at Settings > Docker Hosts to add socket-proxy:2375 connection.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Volume naming conflict between compose files**
- **Found during:** Task 3 (Homepage migration)
- **Issue:** Docker Compose errored with "volumes.uptime-kuma-data conflicts with imported resource" when trying to start homepage
- **Root cause:** backup/docker-compose.yml declared uptime-kuma-data as external with name `uptime-kuma_uptime-kuma-data`, while uptime-kuma/docker-compose.yml declared it as a local volume
- **Fix:** Made both declarations use `external: true` with the correct running volume name `ragnalab_uptime-kuma-data`
- **Files modified:** stack/infra/uptime-kuma/docker-compose.yml, stack/infra/backup/docker-compose.yml
- **Verification:** `docker compose --profile infra up -d homepage` succeeds
- **Committed in:** ee60c23 (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Fix was necessary to complete the migration. The volume naming issue was a pre-existing technical debt from the 07-01 migration that only manifested when both files were included in the same compose operation.

## Issues Encountered

None beyond the auto-fixed blocking issue.

## User Setup Required

**Uptime Kuma Docker host configuration required:**
1. Navigate to https://status.ragnalab.xyz
2. Go to Settings > Docker Hosts
3. Add new host:
   - Name: `my-docker`
   - Connection Type: `TCP / HTTP`
   - Docker Host: `socket-proxy`
   - Docker Port: `2375`
4. Click "Test" to verify connection
5. Save
6. Update any existing Docker container monitors to use the new host

## Next Phase Readiness

- Socket-proxy migration complete
- Homepage shows container status via socket-proxy
- Ready for backup audit (07-05) or Autokuma deployment (07-07)
- Only 3 services now mount docker.sock directly: socket-proxy (required), backup (required for stop/start), glances (extensive monitoring)

---
*Phase: 07-operational-hardening*
*Completed: 2026-01-18*
