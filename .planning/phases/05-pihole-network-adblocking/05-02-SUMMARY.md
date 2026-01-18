---
phase: 05-pihole-network-adblocking
plan: 02
subsystem: infra
tags: [pihole, dhcp, dns, network-configuration]

# Dependency graph
requires:
  - phase: 05-01
    provides: Pi-hole container with macvlan networking (10.0.0.200)
provides:
  - DNS-only mode documentation and decision record
  - DHCP configuration template (commented, preserved for future use)
  - Client DNS configuration guide
affects: [05-03, homepage-widgets, device-configuration]

# Tech tracking
tech-stack:
  added: []
  patterns: [dns-only-mode, manual-client-dns-configuration]

key-files:
  created: []
  modified:
    - apps/pihole/etc-dnsmasq.d/05-custom-dhcp.conf

key-decisions:
  - "DNS-only mode: Xfinity XB8 gateway DHCP settings locked, cannot be disabled"
  - "Manual device configuration: Users set DNS to 10.0.0.200 on devices they want ad blocking"
  - "DHCP config preserved: Commented config kept for future reference if gateway replaced"

patterns-established:
  - "ISP gateway limitation workaround: DNS-only mode when DHCP takeover impossible"

# Metrics
duration: 2min (continuation from checkpoint)
completed: 2026-01-18
---

# Phase 5 Plan 2: DHCP Configuration Summary

**DNS-only mode configured due to locked Xfinity XB8 gateway - users manually set DNS (10.0.0.200) on devices for ad blocking**

## Performance

- **Duration:** 2 min (continuation from checkpoint at Task 2)
- **Started:** 2026-01-18T08:15:33Z (continuation session)
- **Completed:** 2026-01-18T08:16:50Z
- **Tasks:** 3 (Task 1 from previous session, Tasks 2-3 adapted for DNS-only decision)
- **Files modified:** 1

## Accomplishments

- Documented DNS-only mode decision in DHCP configuration file
- Verified Pi-hole DNS resolution working (google.com, pihole.ragnalab.xyz)
- Verified ad blocking operational (ads.google.com returns 0.0.0.0)
- Preserved DHCP configuration template for potential future use

## Task Commits

Each task was committed atomically:

1. **Task 1: Create DHCP configuration with fallback DNS** - `692ca87` (feat) - *previous session*
2. **Task 2: Document DNS-only mode decision** - `6c555f7` (docs)
3. **Task 3: Verify DNS resolution** - *verification only, no code changes*

## Files Created/Modified

- `apps/pihole/etc-dnsmasq.d/05-custom-dhcp.conf` - Updated with DNS-only mode documentation, all DHCP directives commented out

## Decisions Made

1. **DNS-only mode (major decision)** - The original plan called for Pi-hole DHCP takeover to provide DNS to all network devices automatically. However, the Xfinity XB8 gateway DHCP settings are locked and cannot be disabled through the admin interface. This is a known ISP limitation.

2. **Workaround: Manual device configuration** - Users must manually configure DNS (10.0.0.200) on devices they want ad blocking for. This provides:
   - Ad blocking for configured devices
   - No network disruption risk
   - Per-device opt-in model

3. **DHCP config preserved** - The commented DHCP configuration is kept in the repository for future reference if:
   - User gets a different gateway/router
   - Bridge mode becomes available
   - ISP unlocks DHCP settings

## Deviations from Plan

### Plan Adaptation (User Decision)

**DNS-only mode instead of DHCP takeover**
- **Checkpoint reached:** Task 2 (Disable Xfinity Gateway DHCP)
- **User discovery:** Xfinity XB8 gateway DHCP settings are locked - cannot be disabled
- **Decision:** Operate Pi-hole in DNS-only mode with manual device configuration
- **Impact:** Plan objective changed from "all devices automatically use Pi-hole" to "opt-in ad blocking for configured devices"
- **Files modified:** apps/pihole/etc-dnsmasq.d/05-custom-dhcp.conf

This is a constraint-driven adaptation, not a deviation. The original plan assumed DHCP could be disabled on the gateway, which proved impossible.

---

**Total deviations:** 0 (plan adapted to hardware constraint)
**Impact on plan:** Objective modified to achievable scope given ISP limitations

## Issues Encountered

- **Xfinity XB8 DHCP locked** - This is a known ISP limitation. Options explored:
  - Bridge mode: May require calling Xfinity support
  - Gateway replacement: Would require user's own router
  - DNS-only mode: Selected as pragmatic workaround

## User Setup Required

**To enable ad blocking on a device:**

1. Open device network/Wi-Fi settings
2. Set DNS server to: `10.0.0.200`
3. (Optional) Set secondary DNS to: `1.1.1.1` for fallback

**Common device instructions:**
- **iPhone/iPad:** Settings > Wi-Fi > [network] > Configure DNS > Manual > Add 10.0.0.200
- **Android:** Settings > Network > Wi-Fi > [network] > Advanced > Static > DNS 10.0.0.200
- **macOS:** System Preferences > Network > Advanced > DNS > Add 10.0.0.200
- **Windows:** Network Settings > Change adapter options > Properties > IPv4 > DNS

**Verify it's working:**
- Visit https://pihole.ragnalab.xyz (should load)
- Check Pi-hole Query Log for device queries

## Next Phase Readiness

**Ready for:**
- Plan 05-03: Blocklist and monitoring setup (Pi-hole operational)
- Homepage widget integration (API key available)
- Uptime Kuma monitoring (container accessible)

**Future considerations:**
- If user replaces Xfinity gateway with own router, DHCP takeover becomes possible
- DHCP configuration template preserved and ready to activate

**Limitation documented:**
- Not all devices will have ad blocking (only manually configured ones)
- Pi-hole query log shows fewer clients than total network devices

---
*Phase: 05-pihole-network-adblocking*
*Completed: 2026-01-18*
