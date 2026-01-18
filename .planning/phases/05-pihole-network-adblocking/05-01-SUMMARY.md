---
phase: 05-pihole-network-adblocking
plan: 01
subsystem: infra
tags: [pihole, dns, macvlan, docker, traefik, network]

# Dependency graph
requires:
  - phase: 04-vaultwarden-password-manager
    provides: Traefik reverse proxy patterns and proxy network
provides:
  - Pi-hole container with macvlan networking (10.0.0.200)
  - DNS-based ad blocking for network devices
  - Traefik-routed web UI at pihole.ragnalab.xyz
  - Homepage widget integration
  - Macvlan-shim systemd service for host communication
affects: [05-02, 05-03, homepage-widgets, uptime-kuma-monitors]

# Tech tracking
tech-stack:
  added: [pihole/pihole:latest]
  patterns: [macvlan-networking, dual-network-containers, systemd-network-shim]

key-files:
  created:
    - apps/pihole/docker-compose.yml
    - apps/pihole/.env.example
    - apps/pihole/.gitignore
    - apps/pihole/README.md
    - apps/pihole/etc-dnsmasq.d/.gitkeep
  modified: []

key-decisions:
  - "Macvlan network for Pi-hole to get dedicated LAN IP (10.0.0.200)"
  - "Dual network attachment: macvlan for DNS/DHCP, proxy for Traefik routing"
  - "Macvlan-shim systemd service for host-to-container communication"

patterns-established:
  - "Macvlan networking pattern for services needing dedicated LAN IP"
  - "System-level configuration documented in README.md"

# Metrics
duration: 8min
completed: 2026-01-18
---

# Phase 5 Plan 1: Pi-hole Docker Deployment Summary

**Pi-hole deployed with macvlan networking (10.0.0.200) and Traefik integration for HTTPS web UI at pihole.ragnalab.xyz**

## Performance

- **Duration:** 8 min
- **Started:** 2026-01-18T07:38:28Z
- **Completed:** 2026-01-18T07:46:24Z
- **Tasks:** 3
- **Files modified:** 5 created

## Accomplishments

- Deployed Pi-hole with macvlan network providing dedicated LAN IP (10.0.0.200)
- Configured macvlan-shim systemd service for Raspberry Pi host communication
- Integrated with Traefik for HTTPS access at pihole.ragnalab.xyz
- DNS ad blocking operational (doubleclick.net, ads.google.com blocked)
- Homepage widget labels configured for dashboard integration

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Pi-hole Docker configuration with macvlan network** - `ad515a0` (feat)
2. **Task 2: Create systemd service for macvlan host communication** - `a0a92d0` (feat)
3. **Task 3: Deploy Pi-hole and verify DNS + web UI** - (deployment verification, no tracked files)

## Files Created/Modified

- `apps/pihole/docker-compose.yml` - Pi-hole container with dual networks (macvlan + proxy)
- `apps/pihole/.env.example` - Template for PIHOLE_PASSWORD and PIHOLE_API_KEY
- `apps/pihole/.gitignore` - Exclude .env and etc-pihole data directory
- `apps/pihole/README.md` - Architecture documentation and system config reference
- `apps/pihole/etc-dnsmasq.d/.gitkeep` - Preserve dnsmasq configuration directory

**System files created (not in git):**
- `/usr/local/bin/pihole-macvlan.sh` - Script to create/destroy macvlan-shim interface
- `/etc/systemd/system/pihole-macvlan.service` - Systemd service for persistence

## Decisions Made

1. **Macvlan networking for DHCP capability** - Pi-hole needs its own LAN IP to serve as DHCP server later (plan 05-02). Macvlan gives 10.0.0.200 without port conflicts with Traefik.

2. **Dual network attachment** - Container attached to both macvlan (for DNS/DHCP) and proxy (for Traefik web UI routing). Pattern uses `traefik.docker.network=proxy` label.

3. **Macvlan-shim at 10.0.0.201** - Linux kernel limitation prevents macvlan containers from communicating with host. Shim interface provides routing path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Cleaned up stale Cloudflare ACME challenge record**
- **Found during:** Task 3 (HTTPS verification)
- **Issue:** Let's Encrypt certificate issuance failed with "An identical record already exists" for _acme-challenge.pihole.ragnalab.xyz
- **Fix:** Deleted stale TXT record via Cloudflare API, restarted Traefik to retry certificate issuance
- **Verification:** openssl s_client shows valid Let's Encrypt certificate (issuer CN = R13)
- **Committed in:** N/A (runtime fix, not code change)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Minor delay for certificate cleanup. No scope creep.

## Issues Encountered

- **Certificate issuance delay:** Initial Let's Encrypt challenge failed due to stale DNS record from previous attempt. Resolved by deleting orphaned TXT record via Cloudflare API and restarting Traefik.
- **NTP warning in logs:** Pi-hole logs show "Insufficient permissions to set system time (CAP_SYS_TIME required)". This is informational only - NTP client not needed since host manages time.

## User Setup Required

None - deployment is functional with initial password. User should:
1. Log into Pi-hole at https://pihole.ragnalab.xyz with password from .env
2. Optionally update PIHOLE_PASSWORD in .env to a stronger value
3. Get API key from Settings > API for Homepage widget (plan 05-04)

## Next Phase Readiness

**Ready for:**
- Plan 05-02: DHCP configuration (Pi-hole DNS working, ready for DHCP cutover)
- Plan 05-03: Blocklist configuration (baseline blocking operational)
- Plan 05-04: Homepage widget (labels in place, needs API key)
- Plan 05-05: Uptime Kuma monitoring (container accessible)

**Pre-requisites verified:**
- Pi-hole container healthy
- DNS resolution working from host
- Macvlan-shim persists across reboots
- Traefik routing operational with valid SSL

---
*Phase: 05-pihole-network-adblocking*
*Completed: 2026-01-18*
