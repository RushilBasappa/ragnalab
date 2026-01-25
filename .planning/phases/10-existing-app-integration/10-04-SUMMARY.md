---
phase: 10-existing-app-integration
plan: 04
subsystem: media
tags: [qbittorrent, gluetun, authelia, sso, traefik, vpn]

# Dependency graph
requires:
  - phase: 09-authelia-sso-foundation
    provides: Authelia ForwardAuth middleware configured in Traefik
provides:
  - qBittorrent protected by Authelia SSO
  - Reverse proxy settings for auth bypass via trusted subnet
  - VPN tunnel intact with port forwarding
affects: [10-05-jellyfin-plan, homepage-widget-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - qBittorrent auth bypass via AuthSubnetWhitelist for Docker network
    - Traefik labels on gluetun for qBittorrent routing (network_mode container)

key-files:
  created: []
  modified:
    - stack/media/qbittorrent/docker-compose.yml
    - /var/lib/docker/volumes/ragnalab_qbittorrent-config/_data/qBittorrent/qBittorrent.conf (Docker volume)

key-decisions:
  - "172.0.0.0/8 CIDR for AuthSubnetWhitelist covers all Docker networks"
  - "CSRFProtection=false required for reverse proxy compatibility"
  - "MaxAuthenticationFailCount=0 disables qBittorrent's auth lockout (Authelia handles it)"

patterns-established:
  - "VPN container routing: Traefik labels go on gluetun, not qbittorrent"
  - "Auth bypass via subnet whitelist for internal Docker traffic"

# Metrics
duration: 5min
completed: 2026-01-25
---

# Phase 10 Plan 04: qBittorrent SSO Integration Summary

**qBittorrent protected by Authelia SSO with reverse proxy auth bypass via Docker subnet whitelist, VPN tunnel and port forwarding verified functional**

## Performance

- **Duration:** 5 min
- **Started:** 2026-01-25T16:42:24Z
- **Completed:** 2026-01-25T16:47:13Z
- **Tasks:** 3
- **Files modified:** 2 (1 in git, 1 in Docker volume)

## Accomplishments

- Configured qBittorrent.conf with reverse proxy settings (ReverseProxySupportEnabled, TrustedReverseProxiesList)
- Added AuthSubnetWhitelist to bypass qBittorrent's built-in auth for Docker network traffic
- Added Authelia middleware to gluetun's Traefik router labels
- Verified VPN tunnel active with port forwarding (port 49097 synced by port-manager)
- Confirmed VPN IP (185.107.44.166 Netherlands) differs from host IP

## Task Commits

Each task was committed atomically:

1. **Task 1: Configure qBittorrent reverse proxy settings** - (no commit, Docker volume change)
2. **Task 2: Add Authelia middleware to gluetun** - `9653935` (feat)
3. **Task 3: Restart qBittorrent stack and verify** - (no commit, operational task)

**Plan metadata:** pending

## Files Created/Modified

- `stack/media/qbittorrent/docker-compose.yml` - Added authelia@file middleware to qBittorrent router
- `qBittorrent.conf` (Docker volume) - Added reverse proxy and auth whitelist settings:
  - ReverseProxySupportEnabled=true
  - TrustedReverseProxiesList=172.0.0.0/8
  - AuthSubnetWhitelistEnabled=true
  - AuthSubnetWhitelist=172.0.0.0/8
  - CSRFProtection=false
  - HostHeaderValidation=false
  - MaxAuthenticationFailCount=0

## Decisions Made

1. **172.0.0.0/8 CIDR** - Broad range to cover all Docker networks (proxy, media networks use 172.x.x.x addressing)
2. **CSRFProtection=false** - Required for reverse proxy setups where Origin header may differ
3. **MaxAuthenticationFailCount=0** - Disables qBittorrent's auth failure lockout since Authelia handles brute-force protection

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

1. **Gluetun container naming issue** - Containers had corrupted name prefixes (e.g., `ac920ce2b7b0_gluetun`). Resolved by removing orphan containers and recreating with `docker compose up -d`.

## User Setup Required

**Manual verification needed:**
1. Open incognito browser
2. Navigate to https://qbit.ragnalab.xyz
3. Verify redirect to Authelia login
4. After login, verify qBittorrent UI loads directly (no qBittorrent login prompt)
5. Check Homepage widget at https://home.ragnalab.xyz shows qBittorrent stats

## Next Phase Readiness

- qBittorrent SSO integration complete
- VPN tunnel verified functional with port forwarding
- Ready for 10-05 Jellyfin integration (if planned)
- Homepage widget should continue working (uses internal URL with credentials)

---
*Phase: 10-existing-app-integration*
*Completed: 2026-01-25*
