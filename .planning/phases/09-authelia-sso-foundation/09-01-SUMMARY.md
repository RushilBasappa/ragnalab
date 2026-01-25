---
phase: 09-authelia-sso-foundation
plan: 01
subsystem: auth
tags: [authelia, sso, webauthn, passkey, traefik, forwardauth, argon2id]

# Dependency graph
requires:
  - phase: 01-04 (traefik)
    provides: reverse proxy with dynamic config and labels
provides:
  - Authelia SSO portal at auth.ragnalab.xyz
  - WebAuthn/passkey 2FA authentication
  - Password fallback authentication
  - User groups (admin, powerusers, family, guests)
  - Access control rules (bypass, one_factor, two_factor)
  - ForwardAuth middleware ready for Traefik
  - Session cookie for cross-subdomain SSO
affects: [09-02 service integration, 10-paperless, 10-dozzle, 10-it-tools, all future protected services]

# Tech tracking
tech-stack:
  added: [authelia 4.39.14, argon2id, webauthn, sqlite3]
  patterns: [forwardAuth middleware, file-based user database, filesystem notifier]

key-files:
  created:
    - stack/infra/authelia/docker-compose.yml
    - stack/infra/authelia/config/configuration.yml
    - stack/infra/authelia/config/users_database.yml
    - stack/infra/authelia/.env
  modified:
    - stack/infra/docker-compose.yml
    - stack/infra/traefik/config/dynamic/middlewares.yml
    - .gitignore

key-decisions:
  - "SQLite storage (no Redis) - sufficient for 4 users"
  - "Argon2id m=256, t=1, p=2 - ARM64 tuned to avoid slow logins"
  - "Passkeys work as 2FA (passwordless not available in 4.39.14)"
  - "Filesystem notifier - no email service needed"

patterns-established:
  - "ForwardAuth middleware: authelia@file for web UI, authelia-basic@file for API"
  - "Session cookie domain: ragnalab.xyz (parent domain for SSO)"
  - "WebAuthn rp_id: ragnalab.xyz (immutable after passkey registration)"
  - "Access control: bypass first, then specific rules, deny default"

# Metrics
duration: 45min
completed: 2026-01-25
---

# Phase 9 Plan 01: Authelia SSO Foundation Summary

**Authelia SSO with WebAuthn passkey 2FA at auth.ragnalab.xyz, forwardAuth middleware ready for service protection**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-01-25T07:30:00Z
- **Completed:** 2026-01-25T08:15:00Z
- **Tasks:** 5 (4 auto + 1 checkpoint)
- **Files modified:** 6

## Accomplishments

- Authelia running at auth.ragnalab.xyz with login portal
- WebAuthn passkey registration and 2FA login working
- Password fallback authentication working
- Session cookie domain set to .ragnalab.xyz for cross-subdomain SSO
- ForwardAuth middleware defined and ready in Traefik
- Access control rules configured (bypass Plex/API, two_factor admin, one_factor others)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Authelia service stack** - `96b3420` (feat)
2. **Task 2: Generate secrets and create admin user** - `4f53500` (feat)
3. **Task 3: Add forwardAuth middleware to Traefik** - `6c2aa1f` (feat)
4. **Task 4: Deploy and verify Authelia** - `8d31a30` (feat)
5. **Task 5: Checkpoint - Human Verification** - APPROVED

## Files Created/Modified

- `stack/infra/authelia/docker-compose.yml` - Authelia container with Traefik labels, Autokuma, Homepage
- `stack/infra/authelia/config/configuration.yml` - Full Authelia config (WebAuthn, session, ACL, storage)
- `stack/infra/authelia/config/users_database.yml` - Admin user with argon2id password hash
- `stack/infra/authelia/.env` - JWT, session, and storage encryption secrets
- `stack/infra/docker-compose.yml` - Added authelia include
- `stack/infra/traefik/config/dynamic/middlewares.yml` - ForwardAuth middleware definitions
- `.gitignore` - Added authelia secrets patterns

## Decisions Made

1. **SQLite over Redis** - Only 4 users, no need for Redis complexity
2. **Argon2id tuning for ARM64** - m=256, t=1, p=2 prevents slow logins on Pi 5
3. **Passkey as 2FA only** - Authelia 4.39.14 doesn't support passwordless WebAuthn
4. **Filesystem notifier** - No email service needed for family homelab

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed WebAuthn config for Authelia 4.39.14**
- **Found during:** Task 4 (Deploy and verify)
- **Issue:** Authelia failed to start with deprecated `rp_id` setting in webauthn config
- **Fix:** Removed deprecated `rp_id` setting, using only supported 4.39.14 options
- **Files modified:** stack/infra/authelia/config/configuration.yml
- **Verification:** Container started successfully, WebAuthn registration works
- **Committed in:** 8d31a30

**2. [Rule 1 - Bug] Regenerated password hash with ARM64-tuned parameters**
- **Found during:** Task 2 (Generate secrets)
- **Issue:** Default argon2id parameters caused slow logins on ARM64
- **Fix:** Used m=256, t=1, p=2 parameters for faster hash verification
- **Files modified:** stack/infra/authelia/config/users_database.yml
- **Verification:** Login completes in <1 second
- **Committed in:** 4f53500

**3. [Expected Behavior] Passwordless WebAuthn not available**
- **Found during:** Task 5 (Human verification)
- **Issue:** Plan expected passwordless passkey login, but 4.39.14 only supports passkeys as 2FA
- **Resolution:** Documented as limitation - passkeys work as second factor after password
- **Impact:** Users enter password + passkey (acceptable security model)

---

**Total deviations:** 2 auto-fixed bugs, 1 expected behavior clarification
**Impact on plan:** All fixes necessary for functionality. Core SSO working as intended.

## Issues Encountered

None - deployment proceeded smoothly after config fixes.

## User Setup Required

**Initial admin setup completed during execution:**
- Admin user (rushil) created with temporary password
- Passkey registered via browser
- Session verified across subdomains

**For additional users:**
1. Edit `stack/infra/authelia/config/users_database.yml`
2. Generate password hash: `docker exec authelia authelia crypto hash generate argon2 --password 'PASSWORD'`
3. Restart Authelia: `docker restart authelia`
4. User logs in and registers passkey at auth.ragnalab.xyz

## Next Phase Readiness

**Ready for Plan 09-02 (Service Integration):**
- ForwardAuth middleware `authelia@file` available in Traefik
- Can add `traefik.http.routers.X.middlewares=authelia@file` to any service
- Access control rules will enforce appropriate policy per group

**Services to protect (per ROADMAP.md):**
- Admin services: traefik, backups, pihole (two_factor)
- Power user services: sonarr, radarr, prowlarr, bazarr, qbit, maintainerr (one_factor)
- Family services: jellyfin, requests (one_factor)
- Bypass: plex, API endpoints

---
*Phase: 09-authelia-sso-foundation*
*Completed: 2026-01-25*
