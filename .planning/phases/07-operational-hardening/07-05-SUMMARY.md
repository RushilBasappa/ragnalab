---
phase: 07-operational-hardening
plan: 05
subsystem: infra
tags: [backup, docker-volume-backup, restore, disaster-recovery]

# Dependency graph
requires:
  - phase: 07-03
    provides: stack/ directory structure with nested includes
provides:
  - Backup coverage for Uptime Kuma, RustDesk, Traefik ACME
  - Updated restore script for stack/ paths
  - 13 total data sources in nightly backup
affects: [07-07-autokuma, disaster-recovery, future-services]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Bind mount backup for ACME certificates"
    - "Stop-during-backup label for SQLite services"

key-files:
  created: []
  modified:
    - stack/infra/backup/docker-compose.yml
    - stack/infra/backup/scripts/restore.sh
    - stack/infra/uptime-kuma/docker-compose.yml

key-decisions:
  - "Uptime Kuma volume referenced without external (same compose tree)"
  - "Traefik ACME as bind mount (certificates in config dir, not Docker volume)"
  - "RustDesk safe for hot backup (keys only, no database)"

patterns-established:
  - "Volume sharing: volumes in same include tree share without external declarations"
  - "Bind mount backup: config directories can be backed up via bind mount"

# Metrics
duration: 5min
completed: 2026-01-18
---

# Phase 7 Plan 5: Backup Audit and Volume Coverage Summary

**Expanded backup to 13 data sources: added Uptime Kuma (SQLite), RustDesk (keys), and Traefik ACME (certificates); updated restore script for stack/ directory structure**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-18T16:06:07Z
- **Completed:** 2026-01-18T16:10:48Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Added 3 missing data sources to nightly backup (12 total sources)
- Updated Pi-hole bind mount path from apps/ to stack/apps/
- Rewrote restore script with service-to-compose mapping for stack/ structure
- Added bind mount restore support for pihole and traefik-acme
- Added docker-volume-backup.stop-during-backup label to uptime-kuma
- Verified backup archive contains all new directories

## Task Commits

Each task was committed atomically:

1. **Task 1: Add missing volumes to backup configuration** - `de4bb87` (feat)
2. **Task 2: Update restore script for new structure** - `eb12448` (feat)
3. **Task 3: Test backup and verify new volumes included** - `8287ea6` (fix)

## Files Created/Modified

- `stack/infra/backup/docker-compose.yml` - Added uptime-kuma-data, rustdesk-data, traefik-acme volumes; updated pihole path
- `stack/infra/backup/scripts/restore.sh` - Complete rewrite with service mapping, bind mount support, stack/ paths
- `stack/infra/uptime-kuma/docker-compose.yml` - Added docker-volume-backup.stop-during-backup label

## Decisions Made

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Remove duplicate uptime-kuma-data from backup | Volume already declared in uptime-kuma compose; same include tree shares volumes | Resolved compose conflict |
| Traefik ACME as bind mount | Certificates stored in config directory, not Docker volume | Backup path: /stack/infra/traefik/config/acme |
| RustDesk safe for hot backup | Only contains server keys, no database to corrupt | No stop-during-backup label needed |
| Uptime Kuma stop during backup | SQLite database requires consistent state | Added stop-during-backup label |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Volume naming conflict**
- **Found during:** Task 3 (backup container start)
- **Issue:** Backup compose declared uptime-kuma-data as external pointing to `uptime-kuma_uptime-kuma-data`, but actual volume is `ragnalab_uptime-kuma-data` and already declared in uptime-kuma compose
- **Fix:** Removed duplicate declaration from backup compose; volumes in same include tree share without redeclaration
- **Files modified:** stack/infra/backup/docker-compose.yml
- **Verification:** `docker compose --profile infra up -d backup` succeeds
- **Committed in:** 8287ea6

**2. [Rule 2 - Missing Critical] Missing backup stop label**
- **Found during:** Task 3 (backup verification)
- **Issue:** Uptime Kuma container lacked docker-volume-backup.stop-during-backup label; SQLite database could be corrupted during backup
- **Fix:** Added label to uptime-kuma compose
- **Files modified:** stack/infra/uptime-kuma/docker-compose.yml
- **Verification:** `docker inspect uptime-kuma | grep backup` shows label
- **Committed in:** 8287ea6

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical)
**Impact on plan:** Both fixes necessary for correct operation. Volume conflict blocked startup; missing label risked data corruption.

## Issues Encountered

- Pi-hole bind mount path needed updating from `apps/pihole/etc-pihole` to `stack/apps/pihole/etc-pihole` (discovered during Task 1, fixed inline)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Backup system now covers all 13 critical data sources
- Ready for 07-07-autokuma (automated monitoring configuration)
- Restore script tested and functional with new structure

### Backup Coverage Summary

| Category | Service | Backup Method | Stop During Backup |
|----------|---------|---------------|-------------------|
| Infrastructure | Uptime Kuma | Docker volume | Yes (SQLite) |
| Infrastructure | Traefik ACME | Bind mount | No (JSON file) |
| Apps | Vaultwarden | Docker volume | Yes (SQLite) |
| Apps | Pi-hole | Bind mount | No |
| Apps | RustDesk | Docker volume | No (keys only) |
| Media | Prowlarr | Docker volume | Yes (SQLite) |
| Media | Sonarr | Docker volume | Yes (SQLite) |
| Media | Radarr | Docker volume | Yes (SQLite) |
| Media | Bazarr | Docker volume | Yes (SQLite) |
| Media | Jellyfin | Docker volume | Yes (SQLite) |
| Media | Jellyseerr | Docker volume | Yes (SQLite) |
| Media | qBittorrent | Docker volume | Yes |
| Media | Gluetun | Docker volume | No (config) |

---
*Phase: 07-operational-hardening*
*Completed: 2026-01-18*
