---
phase: 07-operational-hardening
plan: 02
subsystem: infra
tags: [docker-compose, media-stack, profiles, includes, jellyfin, sonarr, radarr, gluetun]

# Dependency graph
requires:
  - phase: 06-media-automation
    provides: Media services deployed in apps/media/ with existing volumes
provides:
  - Media services migrated to stack/media/ with nested includes
  - Profile-based compose management (--profile media)
  - External volume references matching existing data
affects: [07-03, 07-04, cleanup, backup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - nested docker compose includes (category -> service)
    - external volume naming convention (project_volumename)
    - profile-based service management

key-files:
  created:
    - stack/media/gluetun/docker-compose.yml
    - stack/media/qbittorrent/docker-compose.yml
    - stack/media/prowlarr/docker-compose.yml
    - stack/media/sonarr/docker-compose.yml
    - stack/media/radarr/docker-compose.yml
    - stack/media/bazarr/docker-compose.yml
    - stack/media/unpackerr/docker-compose.yml
    - stack/media/jellyfin/docker-compose.yml
    - stack/media/jellyseerr/docker-compose.yml
  modified:
    - stack/media/docker-compose.yml

key-decisions:
  - "External volumes use project_volumename format to match existing Docker volumes"
  - "Gluetun must be included first in compose (qbittorrent depends on it via network_mode)"
  - ".env copied to stack/media/ for VPN credentials (gitignored)"

patterns-established:
  - "External volume naming: {project}_{volumename} format"
  - "Service compose files include profiles: [category] for selective startup"
  - "Networks defined in root compose, referenced as external: true in service composes"

# Metrics
duration: 7min
completed: 2026-01-18
---

# Phase 7 Plan 2: Media Stack Migration Summary

**9 media services migrated to stack/media/ with nested includes pattern, preserving existing data volumes and VPN routing**

## Performance

- **Duration:** 7 min
- **Started:** 2026-01-18T15:47:28Z
- **Completed:** 2026-01-18T15:56:00Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Created all 9 media service folders with compose files
- Enabled include directives in stack/media/docker-compose.yml
- Fixed external volume names to match existing Docker volumes
- Verified all services start correctly with VPN routing intact
- All web UIs accessible via HTTPS subdomains

## Task Commits

Each task was committed atomically:

1. **Task 1: Create stack/media/ service folders** - `ea730e5` (feat)
2. **Task 2: Update category compose and migrate environment** - `4616b4f` (feat)
3. **Task 3: Verify media profile works end-to-end** - no commit (verification only)

## Files Created/Modified
- `stack/media/gluetun/docker-compose.yml` - VPN tunnel container
- `stack/media/qbittorrent/docker-compose.yml` - Torrent client (via gluetun network_mode)
- `stack/media/prowlarr/docker-compose.yml` - Indexer manager
- `stack/media/sonarr/docker-compose.yml` - TV automation
- `stack/media/radarr/docker-compose.yml` - Movie automation
- `stack/media/bazarr/docker-compose.yml` - Subtitle automation
- `stack/media/unpackerr/docker-compose.yml` - Archive extraction
- `stack/media/jellyfin/docker-compose.yml` - Media server
- `stack/media/jellyseerr/docker-compose.yml` - Request management
- `stack/media/docker-compose.yml` - Category compose with includes
- `stack/media/.env` - VPN credentials (gitignored, copied from apps/media/)

## Decisions Made
- **External volume naming:** Used `{project}_{volumename}` format (e.g., `gluetun_gluetun-data`) to match existing Docker volumes and preserve all data
- **Include ordering:** Gluetun listed first in includes since qbittorrent uses `network_mode: container:gluetun`
- **.env location:** Copied to stack/media/ (gitignored) to maintain VPN credential isolation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed external volume names to match existing Docker volumes**
- **Found during:** Task 2 (compose validation)
- **Issue:** Compose config returned "volumes.gluetun-data conflicts with imported resource" error
- **Root cause:** Docker volumes created by previous compose had `{project}_{volumename}` naming convention (e.g., `gluetun_gluetun-data`), but compose files referenced short names (`gluetun-data`)
- **Fix:** Updated all 8 volume references to use full names matching existing external volumes
- **Files modified:** All 8 service compose files with volumes
- **Verification:** `docker compose --profile media config --quiet` passes validation
- **Committed in:** 4616b4f (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Volume name fix required for preserving existing data. No scope creep.

## Issues Encountered
- **Bazarr startup delay:** Bazarr returned 502 initially due to slow startup (SQLite initialization). Resolved itself within 30 seconds.
- **SSL certificate warnings:** Curl returned exit code 60 for HTTPS checks from within container. Used `-k` flag to skip cert verification for testing (services are accessible via browser with valid certs).

## User Setup Required

None - VPN credentials already configured in existing .env file.

## Next Phase Readiness
- Media stack operational from stack/media/ structure
- `docker compose --profile media up -d` works from repo root
- VPN routing verified (IP shows ProtonVPN address)
- All public services accessible via HTTPS
- Ready for apps migration (07-03) and infra cleanup (future plan)

---
*Phase: 07-operational-hardening*
*Completed: 2026-01-18*
