---
status: resolved
trigger: "VPN_PORT_FORWARDING_UP_COMMAND fails to reach qBittorrent at localhost:8080 from gluetun container"
created: 2026-01-19T12:00:00Z
updated: 2026-01-19T12:00:00Z
---

## Current Focus

hypothesis: CONFIRMED - qBittorrent references OLD gluetun container ID in network_mode, so they have separate network namespaces
test: Compare container IDs - qBittorrent's network_mode vs current gluetun ID
expecting: IDs should match for shared network; if different, confirms root cause
next_action: Restart qBittorrent to pick up new gluetun container reference

## Symptoms

expected: When gluetun gets a forwarded port, it should auto-update qBittorrent's listening port via the API command: `wget -qO- "http://localhost:8080/api/v2/app/setPreferences?json={\"listen_port\":{{FORWARDED_PORT}}}"`
actual: Connection refused when gluetun tries to reach localhost:8080. Error in logs: `ERROR [port forwarding] running up command: exit status 4`
errors:
- `wget: Connecting to localhost (localhost)|127.0.0.1|:8080... failed: Connection refused`
- qBittorrent uses `network_mode: container:gluetun` but after gluetun recreate, the old container ID no longer exists
reproduction:
1. Run `docker compose --profile media up -d gluetun --force-recreate`
2. Port forwarding succeeds (port 58235 assigned)
3. UP_COMMAND fails with connection refused
started: Just configured - first time setting up port forwarding automation

## Eliminated

## Evidence

- timestamp: 2026-01-19T12:00:00Z
  checked: docker-compose configurations
  found: |
    - gluetun has VPN_PORT_FORWARDING_UP_COMMAND using localhost:8080
    - qbittorrent has `network_mode: "container:gluetun"` - shares gluetun's network namespace
    - qbittorrent has `depends_on: gluetun: condition: service_healthy`
  implication: Network namespace sharing is configured correctly - they should share localhost

- timestamp: 2026-01-19T12:01:00Z
  checked: Container IDs and network namespace
  found: |
    - Current gluetun container ID: e558868de093cbd3d52a7a3bcea999c2352d5dd8d92bce588caff70f6374b17a
    - qBittorrent network_mode references: f56e696fed113134db3741ca1e638231a17ae600ce2cd98d8ef9fc86b09fabdc (OLD ID)
    - From gluetun netstat: Only ports 9999 (healthcheck), 53 (DNS), 8000 visible - NO 8080
    - From qbittorrent netstat: Port 8080 IS listening (in its own namespace)
    - gluetun logs show port forwarding worked but UP_COMMAND failed with exit status 4 (wget connection refused)
  implication: qBittorrent kept reference to old gluetun container after force-recreate, causing network isolation

- timestamp: 2026-01-19T15:04:00Z
  checked: Gluetun template variable syntax
  found: |
    - Gluetun uses `{{PORTS}}` or `{{PORT}}` as template variables
    - `{{FORWARDED_PORT}}` is NOT a valid gluetun template variable
    - The original command's variable was never substituted
    - qBittorrent API requires POST method for setPreferences endpoint
  implication: Wrong template variable was the primary cause of UP_COMMAND failure

- timestamp: 2026-01-19T15:05:00Z
  checked: Final verification after fix
  found: |
    - Gluetun port forwarded: 44547
    - qBittorrent listen_port: 44547 (matches!)
    - No errors in gluetun logs
    - UP_COMMAND with {{PORTS}} template works correctly
  implication: Fix verified working

## Resolution

root_cause: |
  THREE issues found:

  1. NETWORK NAMESPACE ISSUE: When gluetun is force-recreated, qBittorrent keeps referencing
     the OLD container ID in its network_mode setting. Docker allows qBittorrent to continue
     running in an orphaned network namespace. As a result:
     - gluetun's localhost:8080 has nothing listening (qBittorrent not in this namespace)
     - qBittorrent's localhost:8080 IS listening but in a separate, orphaned namespace
     - The UP_COMMAND runs inside gluetun and cannot reach qBittorrent

  2. HTTP METHOD ISSUE: The UP_COMMAND used wget GET request but qBittorrent's setPreferences
     API requires POST. The original command returned 405 Method Not Allowed.

  3. TEMPLATE VARIABLE ISSUE (primary cause): The UP_COMMAND used `{{FORWARDED_PORT}}` but
     gluetun's template syntax uses `{{PORTS}}` (or `{{PORT}}`). The variable was never
     substituted, causing the command to fail silently or with invalid JSON.

fix: |
  1. Changed template variable from `{{FORWARDED_PORT}}` to `{{PORTS}}` (gluetun syntax)
  2. Changed wget from GET to POST using `--post-data` flag
  3. Added retry loop (10 attempts, 5s apart) to handle startup race condition
  4. Recreated qBittorrent container to attach to current gluetun network namespace

verification: |
  - Recreated both containers fresh
  - Gluetun obtained forwarded port 44547
  - Verified qBittorrent listen_port is 44547 (matches!)
  - No errors in gluetun logs
  - UP_COMMAND succeeded on startup

files_changed:
  - stack/media/gluetun/docker-compose.yml
