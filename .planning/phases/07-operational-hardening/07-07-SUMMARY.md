---
phase: 07-operational-hardening
plan: 07
subsystem: monitoring
tags: [autokuma, uptime-kuma, docker-labels, monitoring]

# Dependency graph
requires:
  - phase: 07-06
    provides: Autokuma deployment and configuration
provides:
  - Kuma labels on all media services (9 services)
  - Kuma labels on all app services (4 services, 5 containers)
  - Complete automatic monitoring coverage for entire stack
affects: [08-application-expansion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Autokuma label convention (kuma.{name}.{type}.{property})
    - HTTP monitors for web services under category parent groups
    - Container monitors under "Containers" parent group
    - TCP port monitors for non-HTTP services

key-files:
  created: []
  modified:
    - stack/media/gluetun/docker-compose.yml
    - stack/media/qbittorrent/docker-compose.yml
    - stack/media/prowlarr/docker-compose.yml
    - stack/media/sonarr/docker-compose.yml
    - stack/media/radarr/docker-compose.yml
    - stack/media/bazarr/docker-compose.yml
    - stack/media/unpackerr/docker-compose.yml
    - stack/media/jellyfin/docker-compose.yml
    - stack/media/jellyseerr/docker-compose.yml
    - stack/apps/vaultwarden/docker-compose.yml
    - stack/apps/pihole/docker-compose.yml
    - stack/apps/rustdesk/docker-compose.yml
    - stack/apps/glances/docker-compose.yml

key-decisions:
  - "HTTP monitors grouped by service category (Media, Apps)"
  - "Container monitors all grouped under Containers parent"
  - "TCP port monitors for RustDesk non-HTTP services"
  - "Headless services (gluetun, qbittorrent, unpackerr) get container monitors only"

patterns-established:
  - "kuma label pattern: kuma.{service}.http.{property} for HTTP monitors"
  - "kuma label pattern: kuma.{service}-container.docker.{property} for container monitors"
  - "kuma label pattern: kuma.{service}.port.{property} for TCP port monitors"

# Metrics
duration: 8min
completed: 2026-01-18
---

# Phase 7 Plan 7: Kuma Labels for Media and App Services Summary

**Kuma labels added to 13 service compose files enabling automatic Uptime Kuma monitoring via Autokuma for all media and app services**

## Performance

- **Duration:** 8 min
- **Started:** 2026-01-18T16:12:48Z
- **Completed:** 2026-01-18T16:21:00Z
- **Tasks:** 3
- **Files modified:** 13

## Accomplishments

- Added kuma labels to all 9 media services (gluetun, qbittorrent, prowlarr, sonarr, radarr, bazarr, unpackerr, jellyfin, jellyseerr)
- Added kuma labels to all 4 app services (vaultwarden, pihole, rustdesk, glances)
- Established monitoring groups: Media (HTTP), Apps (HTTP/TCP), Containers (all)
- RustDesk gets TCP port monitors since it doesn't use HTTP

## Task Commits

Each task was committed atomically:

1. **Task 1: Add kuma labels to media services** - `f4466be` (feat)
2. **Task 2: Add kuma labels to app services** - `11bf99b` (feat)
3. **Task 3: Verify complete monitoring coverage** - (verification only, no commit)

## Files Created/Modified

### Media Services
- `stack/media/gluetun/docker-compose.yml` - Container monitor labels for VPN tunnel
- `stack/media/qbittorrent/docker-compose.yml` - Container monitor labels for torrent client
- `stack/media/prowlarr/docker-compose.yml` - HTTP + container monitor labels
- `stack/media/sonarr/docker-compose.yml` - HTTP + container monitor labels
- `stack/media/radarr/docker-compose.yml` - HTTP + container monitor labels
- `stack/media/bazarr/docker-compose.yml` - HTTP + container monitor labels
- `stack/media/unpackerr/docker-compose.yml` - Container monitor labels for headless service
- `stack/media/jellyfin/docker-compose.yml` - HTTP + container monitor labels
- `stack/media/jellyseerr/docker-compose.yml` - HTTP + container monitor labels

### App Services
- `stack/apps/vaultwarden/docker-compose.yml` - HTTP + container monitor labels
- `stack/apps/pihole/docker-compose.yml` - HTTP + container monitor labels
- `stack/apps/rustdesk/docker-compose.yml` - TCP port + container monitor labels for hbbs and hbbr
- `stack/apps/glances/docker-compose.yml` - HTTP + container monitor labels (also added missing Homepage labels)

## Expected Monitor Coverage

When Autokuma syncs, the following monitors will be created:

### Media Group (HTTP)
- Prowlarr (https://prowlarr.ragnalab.xyz)
- Sonarr (https://sonarr.ragnalab.xyz)
- Radarr (https://radarr.ragnalab.xyz)
- Bazarr (https://bazarr.ragnalab.xyz)
- Jellyfin (https://jellyfin.ragnalab.xyz)
- Jellyseerr (https://requests.ragnalab.xyz)

### Apps Group (HTTP/TCP)
- Vaultwarden (https://vault.ragnalab.xyz)
- Pi-hole (https://pihole.ragnalab.xyz)
- Glances (https://glances.ragnalab.xyz)
- RustDesk ID Server (TCP 100.75.173.7:21116)
- RustDesk Relay Server (TCP 100.75.173.7:21117)

### Containers Group
- Gluetun VPN Container
- qBittorrent Container
- Prowlarr Container
- Sonarr Container
- Radarr Container
- Bazarr Container
- Unpackerr Container
- Jellyfin Container
- Jellyseerr Container
- Vaultwarden Container
- Pi-hole Container
- RustDesk HBBS Container
- RustDesk HBBR Container
- Glances Container

**Total monitors from this plan:** 25 (11 HTTP/TCP + 14 Container)

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| HTTP monitors under service category groups | Easier to find service status by category (Media, Apps) |
| All container monitors under "Containers" | Single location for container health across all services |
| TCP port monitors for RustDesk | RustDesk uses custom protocol, not HTTP - TCP port check appropriate |
| Container-only for headless services | Gluetun, qBittorrent, Unpackerr have no web UI to monitor |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added Homepage labels to Glances**
- **Found during:** Task 2 (Add kuma labels to app services)
- **Issue:** Glances was missing Homepage dashboard labels unlike other apps
- **Fix:** Added homepage.group, homepage.name, homepage.icon, homepage.href, homepage.description labels
- **Files modified:** stack/apps/glances/docker-compose.yml
- **Verification:** Labels present in file
- **Committed in:** 11bf99b (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Minor addition for consistency. No scope creep.

## Issues Encountered

- Plan 07-06 (Autokuma deployment) executing in parallel - Autokuma not yet running to verify monitor creation
- Verification limited to confirming labels in place; actual monitor creation will happen when containers restart with Autokuma running

## User Setup Required

None - labels are configuration only. Monitors created automatically by Autokuma when services restart.

## Next Phase Readiness

- All media and app services have kuma labels for automatic monitoring
- Once Autokuma is deployed (07-06) and services restart, monitors will be created automatically
- No manual monitor configuration needed going forward
- New services added in Phase 8 should follow same label pattern

---
*Phase: 07-operational-hardening*
*Completed: 2026-01-18*
