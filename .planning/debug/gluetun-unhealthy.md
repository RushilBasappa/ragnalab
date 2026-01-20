---
status: verifying
trigger: "gluetun-unhealthy - Gluetun VPN container keeps failing healthchecks and restarting despite VPN tunnel working"
created: 2026-01-19T00:00:00Z
updated: 2026-01-19T00:06:00Z
---

## Current Focus

hypothesis: CONFIRMED - Timing race between Docker healthcheck and gluetun's internal health server
test: Fix applied - user needs to verify by restarting gluetun container
expecting: Container should stay healthy after restart, no more "healthcheck did not run yet" errors
next_action: User verification - restart gluetun and confirm it becomes healthy without repeated restarts

## Symptoms

expected: Gluetun stays healthy, VPN connected, port forwarding active
actual: Container shows unhealthy status, restarts repeatedly (restart count ~3), healthcheck fails with "healthcheck did not run yet" initially then sometimes passes
errors: "HTTP response status is not OK: 500 500 Internal Server Error: healthcheck did not run yet"
reproduction: Start gluetun container, wait for healthcheck
started: After compose file reorganization, VPN credentials also updated

## Eliminated

## Evidence

- timestamp: 2026-01-19T00:01:00Z
  checked: Current docker-compose.yml configuration
  found: |
    - Uses HEALTH_VPN_DURATION_INITIAL=120s (OBSOLETE variable - no longer does anything)
    - Overrides Docker healthcheck with start_period: 120s, retries: 3
    - qbittorrent depends_on gluetun with condition: service_healthy
  implication: The obsolete env var isn't helping; Docker healthcheck override may not be sufficient

- timestamp: 2026-01-19T00:02:00Z
  checked: GitHub issues and gluetun wiki research
  found: |
    - HEALTH_VPN_DURATION_INITIAL is OBSOLETE in newer gluetun versions
    - Gluetun has TWO healthcheck systems:
      1. INTERNAL: runs from program start, hits cloudflare.com:443 and github.com:443
      2. DOCKER: the /gluetun-entrypoint healthcheck command that hits the internal HTTP server at 127.0.0.1:9999
    - The internal health server returns HTTP 500 with "healthcheck did not run yet" until first successful check
    - GitHub Issue #1190: healthcheck returns exit code 0 even when gluetun shows error
    - The Docker healthcheck runs a SECOND ephemeral gluetun instance as client to hit the health server
  implication: The error message is from gluetun's internal health server, not Docker's healthcheck mechanism

- timestamp: 2026-01-19T00:03:00Z
  checked: Archived pre-migration compose file
  found: |
    - Old config had NO Docker healthcheck override (used built-in defaults)
    - No HEALTH_ env variables at all
    - Note mentioned "Gluetun has built-in healthcheck at http://127.0.0.1:9999/"
  implication: Old config worked because it relied on defaults; new config adds conflicting/obsolete settings

- timestamp: 2026-01-19T00:04:00Z
  checked: Gluetun internal healthcheck mechanism (DeepWiki, GitHub source)
  found: |
    - Health server in internal/healthcheck/handler.go initially returns "healthcheck did not run yet"
    - Gluetun's Docker healthcheck: HEALTHCHECK --interval=5s --timeout=5s --start-period=10s --retries=1
    - The user's override specifies start_period: 120s, retries: 3 which SHOULD work
    - BUT: The internal health server returns 500 until first INTERNAL healthcheck passes
    - The Docker healthcheck command (/gluetun-entrypoint healthcheck) queries the internal server
    - If internal check hasn't run yet, Docker healthcheck fails regardless of start_period
  implication: Docker healthcheck override doesn't help if internal health server hasn't completed first check

- timestamp: 2026-01-19T00:05:00Z
  checked: VPN status confirmation from user
  found: |
    - VPN IS working: ping 1.1.1.1 succeeds from inside container
    - Public IP confirmed: 46.29.25.140 (Netherlands ProtonVPN)
    - Container restarts ~3 times but eventually stabilizes
  implication: VPN itself is fine; issue is purely healthcheck timing/reporting

- timestamp: 2026-01-19T00:06:00Z
  checked: Gluetun health check timing and configuration options
  found: |
    - Startup check: TCP+TLS dial to cloudflare.com:443 within 6s
    - Periodic small check: every minute with 3 tries (10s, 20s, 30s timeouts)
    - Periodic full check: every 5 minutes with 2 retries (20s, 30s timeouts)
    - User can configure HEALTH_TARGET_ADDRESS to change what's checked
    - WireGuard is "silent" - connection may not work without error messages
  implication: Default 6s startup timeout may be too aggressive for WireGuard + port forwarding setup

## Resolution

root_cause: |
  The healthcheck failure is a TIMING RACE between:
  1. Docker's healthcheck running (even with start_period, it still queries the health server)
  2. Gluetun's internal health server which returns HTTP 500 "healthcheck did not run yet" until its first internal check completes

  The problem is NOT the VPN (it works fine) but that:
  - HEALTH_VPN_DURATION_INITIAL=120s is OBSOLETE and does nothing in newer gluetun
  - The internal healthcheck still runs on its own schedule (first check at ~6s)
  - Docker's start_period only delays REPORTING unhealthy, not the check itself
  - With retries=1 (built-in default) or even retries=3, if internal server returns 500, Docker marks unhealthy
  - Container marked unhealthy -> dependent containers (qbittorrent) fail to start -> cascade restart

  The race condition happens because WireGuard + ProtonVPN port forwarding can take 10-30s to fully establish,
  but gluetun's internal health check starts at ~6s and queries cloudflare.com:443 via TCP+TLS.
  If DNS or TCP doesn't work yet, internal check fails -> health server returns 500 -> Docker healthcheck fails.

fix: |
  Two-part fix:
  1. REMOVE the obsolete HEALTH_VPN_DURATION_INITIAL environment variable
  2. INCREASE Docker healthcheck retries and adjust timing to be more forgiving:
     - interval: 30s (less aggressive than 10s)
     - timeout: 15s (more time for checks)
     - start_period: 120s (keep this - gives time for VPN + port forwarding)
     - retries: 5 (tolerate more transient failures during startup)

  This ensures Docker waits longer before declaring unhealthy, giving gluetun's internal
  healthcheck time to pass its first check and return 200 instead of 500.

verification: |
  Pending user verification. To verify the fix:
  1. cd /home/rushil/workspace/ragnalab/stack/media/qbittorrent
  2. docker compose --profile media down
  3. docker compose --profile media up -d
  4. Watch container status: docker compose --profile media ps --watch
  5. Check logs: docker compose logs gluetun --follow

  Expected outcome:
  - Container should NOT restart repeatedly
  - Should reach "healthy" status within 2-3 minutes
  - No more "healthcheck did not run yet" errors
  - qbittorrent and port-manager should start after gluetun is healthy

files_changed:
  - /home/rushil/workspace/ragnalab/stack/media/qbittorrent/docker-compose.yml
