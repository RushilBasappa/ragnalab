---
phase: 11-new-app-deployment
plan: 02
subsystem: infra
tags: [dozzle, paperless-ngx, authelia, sso, docker, forward-proxy, trusted-header]

# Dependency graph
requires:
  - phase: 11-01
    provides: Authelia ACL rules for docs and logs subdomains
  - phase: 09-authelia-sso
    provides: Authelia forwardAuth middleware pattern
provides:
  - Dozzle container log viewer with forward-proxy SSO at logs.ragnalab.xyz
  - Paperless-ngx document management with trusted header SSO at docs.ragnalab.xyz
  - Pattern for forward-proxy auth (Dozzle)
  - Pattern for trusted header auto-login (Paperless-ngx)
affects: [11-03, future-app-deployments]

# Tech tracking
tech-stack:
  added: [dozzle, paperless-ngx, redis]
  patterns: [forward-proxy-auth, trusted-header-sso, redis-sidecar]

key-files:
  created:
    - stack/apps/dozzle/docker-compose.yml
    - stack/apps/paperless/docker-compose.yml
  modified:
    - stack/apps/docker-compose.yml
    - .env (gitignored)

key-decisions:
  - "Dozzle uses forward-proxy auth (reads Remote-User header directly)"
  - "Paperless-ngx uses trusted header SSO (HTTP_REMOTE_USER for Django)"
  - "Paperless admin username must match Authelia username for SSO auto-login"
  - "OCR disabled by default for Raspberry Pi performance"
  - "Redis sidecar for Paperless async task queue"
  - "Dozzle connects to socket-proxy not raw Docker socket"

patterns-established:
  - "Forward-proxy auth pattern: DOZZLE_AUTH_PROVIDER=forward-proxy + logout URL"
  - "Trusted header SSO pattern: PAPERLESS_ENABLE_HTTP_REMOTE_USER + matching username"
  - "Internal Redis sidecar for stateful apps needing task queue"

# Metrics
duration: 8min
completed: 2026-01-26
---

# Phase 11 Plan 02: Dozzle & Paperless-ngx Summary

**Dozzle at logs.ragnalab.xyz with forward-proxy auth and Paperless-ngx at docs.ragnalab.xyz with trusted header SSO, both protected by Authelia 2FA**

## Performance

- **Duration:** 8 min
- **Started:** 2026-01-26T03:05:00Z
- **Completed:** 2026-01-26T03:13:00Z
- **Tasks:** 4 (3 auto + 1 human-verify)
- **Files modified:** 4

## Accomplishments

- Deployed Dozzle with forward-proxy authentication pattern
- Deployed Paperless-ngx with trusted header SSO for auto-login
- Both apps protected by Authelia two-factor authentication
- Both apps integrated with Homepage dashboard and Autokuma monitoring
- Dozzle securely connected to Docker API via socket-proxy

## Task Commits

Each task was committed atomically:

1. **Task 1: Deploy Dozzle with forward-proxy authentication** - `5a42468` (feat)
2. **Task 2: Deploy Paperless-ngx with trusted header SSO** - `99ff5a3` (feat)
3. **Task 3: Deploy both apps and verify** - `2ddd77f` (feat)
4. **Task 4: Human verification checkpoint** - (no commit, user approved)

## Files Created/Modified

- `stack/apps/dozzle/docker-compose.yml` - Dozzle container with forward-proxy auth, socket-proxy connection, Homepage/Autokuma labels
- `stack/apps/paperless/docker-compose.yml` - Paperless-ngx with Redis sidecar, trusted header SSO, Pi-optimized settings
- `stack/apps/docker-compose.yml` - Added dozzle and paperless includes
- `.env` - Added PAPERLESS_ADMIN_USER and PAPERLESS_ADMIN_PASSWORD (gitignored)

## Decisions Made

- **Forward-proxy vs trusted header:** Dozzle natively supports forward-proxy auth (reads headers directly), while Paperless-ngx uses Django's HTTP_REMOTE_USER pattern
- **Dozzle via socket-proxy:** Uses TCP connection to socket-proxy:2375 instead of raw Docker socket for security
- **Paperless username matching:** Admin username set to match Authelia username (rushil) for seamless SSO auto-login
- **OCR disabled:** Set PAPERLESS_OCR_MODE=skip for Raspberry Pi performance; can enable later if needed
- **Redis sidecar:** Paperless requires Redis for async task processing; deployed as dedicated container
- **Backup label:** Paperless marked for container stop during backup for SQLite consistency

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - both applications deployed successfully and passed verification.

## User Setup Required

**Paperless-ngx initial configuration:**
- PAPERLESS_ADMIN_USER and PAPERLESS_ADMIN_PASSWORD set in .env
- Admin username matches Authelia username for SSO auto-login
- Optional: Retrieve API key from Paperless Settings > API Token for Homepage widget

## Next Phase Readiness

- Both Dozzle and Paperless-ngx operational with SSO protection
- Phase 11 (New App Deployment) complete - IT-Tools, Dozzle, and Paperless-ngx all deployed
- v3.0 milestone complete: SSO foundation + app expansion delivered
- Ready to mark v3.0 as shipped

---
*Phase: 11-new-app-deployment*
*Completed: 2026-01-26*
