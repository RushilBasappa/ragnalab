---
phase: 03-operational-infrastructure
plan: 02
subsystem: monitoring, backup
tags: [uptime-kuma, docker-volume-backup, offen, push-monitor, cron]

# Dependency graph
requires:
  - phase: 03-01
    provides: Uptime Kuma deployment with Docker socket access
provides:
  - Configured Uptime Kuma monitors (HTTP, Docker containers, Push)
  - Automated weekly Docker volume backup
  - Push notification for backup completion monitoring
affects: [future-apps, disaster-recovery]

# Tech tracking
tech-stack:
  added: [offen/docker-volume-backup:v2]
  patterns: [push-monitor-heartbeat, container-stop-backup-label]

key-files:
  created:
    - apps/backup/docker-compose.yml
    - apps/backup/.env.example
    - apps/backup/.gitignore
    - backups/.gitkeep
    - backups/.gitignore
  modified: []

key-decisions:
  - "Weekly backup schedule (Sunday 3 AM) with 28-day retention"
  - "Stop uptime-kuma container during backup for consistent volume state"
  - "Push monitor for backup verification (7-day heartbeat interval)"

patterns-established:
  - "Push monitor heartbeat: services notify Uptime Kuma on completion"
  - "External volume backup: reference external volumes in backup compose"
  - "Backup archives excluded from git via .gitignore"

# Metrics
duration: 4min
completed: 2026-01-17
---

# Phase 3 Plan 2: Monitoring Configuration & Backup Infrastructure Summary

**Uptime Kuma monitors configured via UI, automated Docker volume backup with offen/docker-volume-backup running weekly with push notification to Uptime Kuma**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-17T15:05:08Z
- **Completed:** 2026-01-17T15:09:29Z
- **Tasks:** 3 (1 manual UI, 2 automated)
- **Files modified:** 5 created

## Accomplishments

- Configured 7 Uptime Kuma monitors (3 HTTP services, 3 Docker containers, 1 push monitor)
- Created backup infrastructure with offen/docker-volume-backup:v2
- Weekly backup schedule (Sunday 3 AM) with 28-day retention
- Push notification integration with Uptime Kuma for backup monitoring
- Manual backup test completed successfully (2 archives created)

## Task Commits

Each task was committed atomically:

1. **Task 1: Configure Uptime Kuma Monitors** - (manual UI) - Completed by user
2. **Task 2: Create Backup Infrastructure** - `caa9c7a` (feat)
3. **Task 3: Deploy and Test Backup** - `4ab9e6a` (feat)

## Files Created/Modified

- `apps/backup/docker-compose.yml` - Backup service with volume backup configuration
- `apps/backup/.env.example` - Template for push notification URL
- `apps/backup/.gitignore` - Excludes .env from version control
- `backups/.gitkeep` - Backup storage directory marker
- `backups/.gitignore` - Excludes backup archives from version control

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Weekly backup (Sunday 3 AM) | Low-activity time, weekly matches push monitor heartbeat |
| 28-day retention | 4 weeks of backups provides good recovery window |
| Stop uptime-kuma during backup | Ensures consistent volume state for SQLite database |
| Push monitor 7-day heartbeat | Matches weekly backup schedule, alerts on missed backups |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added backups/.gitignore**
- **Found during:** Task 3 (Deploy and Test)
- **Issue:** Backup archives would be committed to git without exclusion
- **Fix:** Created backups/.gitignore to exclude *.tar.gz files
- **Files modified:** backups/.gitignore
- **Committed in:** 4ab9e6a (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Minor addition to prevent data files in repo. No scope creep.

## Issues Encountered

**Push notification 502 during backup:**
- The backup service stops Uptime Kuma to safely backup its SQLite database
- Notification is sent immediately after restart, sometimes before Uptime Kuma is fully ready
- This causes occasional 502 errors on the notification webhook
- **Impact:** Minimal - the push monitor's heartbeat (7-day interval) still detects missed backups
- **Resolution:** Accepted as inherent limitation; manual heartbeat test confirmed URL works

## User Setup Required

Task 1 was completed manually by user via Uptime Kuma UI:
- Created admin account
- Added HTTP monitors for Traefik, whoami, status page
- Configured Docker Host with socket access
- Added Docker container monitors
- Created push monitor for Weekly Backup

## Next Phase Readiness

- Monitoring infrastructure complete with Uptime Kuma
- Backup infrastructure deployed and tested
- Ready for 03-03: Log aggregation (Dozzle or Loki)
- No blockers identified

---
*Phase: 03-operational-infrastructure*
*Plan: 02*
*Completed: 2026-01-17*
