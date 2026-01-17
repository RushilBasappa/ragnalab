---
phase: 04-applications-templates
plan: 02
subsystem: infra
tags: [vaultwarden, bitwarden, password-manager, docker, traefik]

# Dependency graph
requires:
  - phase: 01-foundation-routing
    provides: Traefik reverse proxy with HTTPS and automatic service discovery
  - phase: 03-operational-infrastructure
    provides: Automated backup service with docker-volume-backup
provides:
  - Self-hosted Bitwarden-compatible password manager at vault.ragnalab.xyz
  - Automated backup of Vaultwarden data volume
  - Invite-only registration with hashed admin token
affects: [future app deployments, backup verification]

# Tech tracking
tech-stack:
  added: [vaultwarden/server]
  patterns: [same Traefik labels, backup integration, homepage widget]

key-files:
  created:
    - apps/vaultwarden/docker-compose.yml
    - apps/vaultwarden/.env.example
    - apps/vaultwarden/.gitignore
  modified:
    - apps/backup/docker-compose.yml

key-decisions:
  - "SMTP vars omitted from compose - Vaultwarden validates strictly, empty vars cause startup failure"
  - "Socket proxy restart required for new container discovery"

patterns-established:
  - "Password manager with invite-only registration for security"
  - "Restart socket-proxy + traefik when adding new containers"

# Metrics
duration: 4min
completed: 2026-01-17
---

# Phase 4 Plan 2: Vaultwarden Password Manager Summary

**Self-hosted Bitwarden-compatible password manager at vault.ragnalab.xyz with invite-only registration, hashed admin token, and automated backup integration**

## Performance

- **Duration:** 4 min
- **Started:** 2026-01-17T16:19:29Z
- **Completed:** 2026-01-17T16:23:01Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Vaultwarden accessible at https://vault.ragnalab.xyz with valid TLS certificate
- Admin panel at /admin protected by argon2id-hashed token
- Signups disabled, invitation-only registration enforced
- Vaultwarden data volume included in automated backup service

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Vaultwarden docker-compose.yml and env files** - `0401aea` (feat)
2. **Task 2: Add Vaultwarden volume to backup service** - `36a00c8` (feat)
3. **Task 3: Deploy Vaultwarden and verify** - `af087ba` (fix - SMTP config issue)

**Plan metadata:** [pending]

## Files Created/Modified

- `apps/vaultwarden/docker-compose.yml` - Vaultwarden container config with Traefik labels
- `apps/vaultwarden/.env.example` - Template for admin token generation
- `apps/vaultwarden/.gitignore` - Excludes .env from version control
- `apps/backup/docker-compose.yml` - Updated with vaultwarden-data volume mount

## Decisions Made

- **SMTP vars omitted from docker-compose.yml:** Vaultwarden validates SMTP_HOST and SMTP_FROM strictly - empty strings cause startup failure. SMTP configuration documented in .env.example comments for when user wants to enable email.
- **Socket proxy restart required:** New containers aren't immediately discovered by Traefik via socket proxy. Restarting socket-proxy and traefik ensures route registration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed SMTP environment variables causing startup failure**
- **Found during:** Task 3 (Deploy Vaultwarden)
- **Issue:** Vaultwarden container restarting with error "Both SMTP_HOST and SMTP_FROM need to be set for email support"
- **Fix:** Removed SMTP_* environment variables from docker-compose.yml since they were optional and empty values trigger validation
- **Files modified:** apps/vaultwarden/docker-compose.yml, apps/vaultwarden/.env.example
- **Verification:** Container starts successfully, logs show "Rocket has launched"
- **Committed in:** af087ba

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Bug fix required for service to start. No scope creep.

## Issues Encountered

- **Traefik not discovering vaultwarden route:** After container start, vault.ragnalab.xyz returned 404. Resolved by restarting socket-proxy and traefik to refresh container discovery.

## User Setup Required

User created apps/vaultwarden/.env with admin token hash generated via:
```bash
docker run --rm -it vaultwarden/server /vaultwarden hash
```

## Next Phase Readiness

- Vaultwarden fully operational with backup integration
- Ready for 04-03 App Template plan
- Homepage dashboard already showing Vaultwarden widget

---
*Phase: 04-applications-templates*
*Completed: 2026-01-17*
