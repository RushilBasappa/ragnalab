---
phase: 07-operational-hardening
plan: 01
subsystem: infra
tags: [docker-compose, include, profiles, traefik, socket-proxy, uptime-kuma, homepage, backup]

# Dependency graph
requires:
  - phase: v1.0
    provides: Traefik reverse proxy, socket-proxy, Uptime Kuma, Homepage, backup service
provides:
  - Root docker-compose.yml with include directives for modular service management
  - stack/ folder structure with nested includes pattern
  - Infrastructure services (traefik, socket-proxy, uptime-kuma, homepage, backup) in stack/infra/
  - Profile-based deployment with `docker compose --profile infra up -d`
affects: [07-02, media-migration, apps-migration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Root compose includes category composes which include service composes"
    - "Networks defined as external in root, referenced by service composes"
    - "Each service has own folder with own docker-compose.yml"
    - "All services in a category share same profile"

key-files:
  created:
    - docker-compose.yml
    - stack/infra/docker-compose.yml
    - stack/infra/traefik/docker-compose.yml
    - stack/infra/socket-proxy/docker-compose.yml
    - stack/infra/uptime-kuma/docker-compose.yml
    - stack/infra/homepage/docker-compose.yml
    - stack/infra/backup/docker-compose.yml
    - stack/media/docker-compose.yml
    - stack/apps/docker-compose.yml
  modified: []

key-decisions:
  - "Networks marked as external (pre-existing from v1.0 setup)"
  - "Socket-proxy permissions extended with IMAGES=1, INFO=1, EVENTS=1 for Homepage/Uptime Kuma"
  - "Docker socket mount kept on Uptime Kuma and Homepage (socket-proxy migration in 07-02)"

patterns-established:
  - "Nested includes: root -> category -> service composes"
  - "Each service has own folder with own docker-compose.yml"
  - "Config files in service folder: ./config/ pattern"
  - "Profile naming matches directory structure (infra, media, apps)"

# Metrics
duration: 6min
completed: 2026-01-18
---

# Phase 07 Plan 01: Stack Directory Structure Summary

**Restructured Docker Compose into stack/ folder with nested includes pattern for modular service management**

## Performance

- **Duration:** 6 min
- **Started:** 2026-01-18T15:46:34Z
- **Completed:** 2026-01-18T15:52:40Z
- **Tasks:** 3
- **Files modified:** 22

## Accomplishments
- Created stack/ folder structure with infra/, media/, apps/ categories
- Migrated all infrastructure services (traefik, socket-proxy, uptime-kuma, homepage, backup) to stack/infra/
- Established nested includes pattern: root -> category -> service composes
- Verified `docker compose --profile infra up -d` brings up all 5 infrastructure services
- All web UIs accessible via HTTPS (Traefik, Uptime Kuma, Homepage)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create stack/ directory structure and root compose** - `da4076b` (feat)
2. **Task 2: Migrate infrastructure services to stack/infra/** - `8827f93` (feat)
3. **Task 3: Verify infra profile works end-to-end** - `8611016` (fix - network external marking)

## Files Created/Modified
- `docker-compose.yml` - Root compose with include directives for all categories
- `stack/infra/docker-compose.yml` - Infrastructure category with nested service includes
- `stack/infra/traefik/docker-compose.yml` - Traefik reverse proxy with profile: ["infra"]
- `stack/infra/traefik/config/` - Static and dynamic traefik configuration
- `stack/infra/socket-proxy/docker-compose.yml` - Docker socket security proxy
- `stack/infra/uptime-kuma/docker-compose.yml` - Service health monitoring
- `stack/infra/homepage/docker-compose.yml` - Application dashboard
- `stack/infra/homepage/config/` - Homepage YAML configuration files
- `stack/infra/backup/docker-compose.yml` - Automated volume backup service
- `stack/infra/backup/scripts/restore.sh` - Backup restore script
- `stack/media/docker-compose.yml` - Placeholder for media services
- `stack/apps/docker-compose.yml` - Placeholder for app services

## Decisions Made
- **Networks as external:** Networks (proxy, socket_proxy_network, media) pre-exist from v1.0 setup. Marked as `external: true` in root compose rather than creating new ones.
- **Extended socket-proxy permissions:** Added IMAGES=1, INFO=1, EVENTS=1 to support Homepage showing image versions and Uptime Kuma system stats. POST=0 maintained for security.
- **Direct socket mount retained:** Uptime Kuma and Homepage still have direct docker.sock mount. Socket-proxy migration planned for 07-02.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Network conflict with pre-existing networks**
- **Found during:** Task 3 (Verify infra profile works end-to-end)
- **Issue:** Root compose tried to create networks (proxy, socket_proxy_network, media) but they already existed from v1.0 setup. Docker Compose reported "network proxy was found but has incorrect label"
- **Fix:** Changed network definitions in root compose from `name: proxy` to `external: true`
- **Files modified:** docker-compose.yml
- **Verification:** `docker compose --profile infra up -d` succeeds, all 5 containers running
- **Committed in:** 8611016 (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Network definition change was necessary for the compose structure to work with pre-existing infrastructure. No scope creep.

## Issues Encountered
- Service compose files initially had network definitions with `external: true` which conflicted with root compose definitions. Resolved by removing network definitions from service composes and keeping them only at root level.

## User Setup Required
None - infrastructure services start automatically with existing configuration.

## Next Phase Readiness
- Infrastructure services operational from new stack/infra/ structure
- Ready for 07-02: Socket-proxy migration for Uptime Kuma and Homepage
- Media and apps services still in old locations (apps/media/, apps/) - future migration planned
- Old proxy/ and apps/{uptime-kuma,homepage,backup}/ directories can be archived after full verification

---
*Phase: 07-operational-hardening*
*Completed: 2026-01-18*
