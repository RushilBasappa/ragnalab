---
phase: 04-applications-templates
plan: 03
subsystem: infra
tags: [homepage, docker, template, traefik, widgets]

# Dependency graph
requires:
  - phase: 04-01
    provides: Homepage dashboard with Docker label discovery
  - phase: 04-02
    provides: Vaultwarden deployment pattern
provides:
  - App template for new deployments at apps/_template/
  - Homepage labels on all infrastructure services
  - Widget integration for Traefik and Uptime Kuma
  - Complete INSTALL.md documentation for Phase 4
affects: [future app deployments, new developer onboarding]

# Tech tracking
tech-stack:
  added: []
  patterns: [homepage.server label for discovery, widget configuration via Docker labels]

key-files:
  created:
    - apps/_template/docker-compose.yml
    - apps/_template/README.md
  modified:
    - proxy/docker-compose.yml
    - apps/uptime-kuma/docker-compose.yml
    - apps/homepage/config/settings.yaml
    - apps/homepage/config/widgets.yaml
    - INSTALL.md

key-decisions:
  - "homepage.server=my-docker label required for Homepage Docker discovery"
  - "Modern glass design theme with widgets for status visibility"
  - "Slate color scheme for dark theme consistency"

patterns-established:
  - "App template workflow: cp -r apps/_template apps/newapp, edit TODOs, deploy"
  - "Homepage widget labels: homepage.widget.type, homepage.widget.url"

# Metrics
duration: ~45min
completed: 2026-01-17
---

# Phase 4 Plan 3: App Template & Finalization Summary

**App deployment template with Homepage widget integration, infrastructure service labels, and Phase 4 documentation in INSTALL.md**

## Performance

- **Duration:** ~45 min (including user verification and design iterations)
- **Started:** 2026-01-17
- **Completed:** 2026-01-17
- **Tasks:** 4
- **Files modified:** 12

## Accomplishments

- Created apps/_template/ with docker-compose.yml and README.md for new app deployments
- Added Homepage labels with widgets to Traefik and Uptime Kuma services
- Fixed Homepage Docker label discovery (homepage.server label required)
- Iterated Homepage design through user verification to final modern glass theme
- Updated INSTALL.md with Phase 4 setup steps (Homepage, Vaultwarden, app template)

## Task Commits

Each task was committed atomically:

1. **Task 1: Create app template** - `daa4545` (feat)
2. **Task 2: Add Homepage labels to infrastructure services** - `f77994e` (feat)
3. **Task 3: Update INSTALL.md with Phase 4 setup steps** - `1f244f4` (docs)
4. **Task 4: Human verification** - Multiple commits during design iteration:
   - `6c0ea3a` - Fix Homepage Docker label discovery
   - `647f6b4` - Homepage slate theme with search bar
   - `d8d5ed9` - Homepage modern glass design
   - `681a2a3` - Homepage final design with widgets

## Files Created/Modified

- `apps/_template/docker-compose.yml` - Boilerplate with Traefik and Homepage labels, TODO markers
- `apps/_template/README.md` - Usage instructions and deployment checklist
- `proxy/docker-compose.yml` - Added Homepage labels with Traefik widget
- `apps/uptime-kuma/docker-compose.yml` - Added Homepage labels with Uptime Kuma widget
- `apps/homepage/config/settings.yaml` - Modern glass design with slate theme
- `apps/homepage/config/widgets.yaml` - DateTime, search, and resources widgets
- `apps/homepage/config/bookmarks.yaml` - Refined bookmark organization
- `INSTALL.md` - Added sections 12-14 for Phase 4 setup

## Decisions Made

- **homepage.server=my-docker label required:** Homepage Docker discovery requires this label to match the socket name in docker.yaml. Without it, services with homepage.* labels are not discovered.
- **Modern glass design with slate theme:** User preferred clean, modern aesthetic over default dark theme. Settled on glass card backgrounds with slate color scheme.
- **Widget layout:** DateTime on left, search centered, resources (CPU/memory/disk) on right for quick system status visibility.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added homepage.server label for Docker discovery**
- **Found during:** Task 4 (Human verification)
- **Issue:** Services with homepage.* labels not appearing in Homepage dashboard
- **Fix:** Added `homepage.server=my-docker` label to all services, matching docker.yaml socket configuration
- **Files modified:** apps/_template/docker-compose.yml, proxy/docker-compose.yml, apps/uptime-kuma/docker-compose.yml, apps/vaultwarden/docker-compose.yml
- **Verification:** All services now appear in Homepage with correct widgets
- **Committed in:** 6c0ea3a

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Discovery fix required for core Homepage functionality. Design iterations were part of human-verify checkpoint.

## Issues Encountered

- **Homepage not discovering Docker services:** Initial deployment showed empty service groups. Investigation revealed homepage.server label must match docker.yaml socket name. Added to all existing services and documented in template.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 4 complete. All objectives achieved:

- Homepage dashboard operational at home.ragnalab.xyz with modern theme
- Vaultwarden password manager at vault.ragnalab.xyz with backup integration
- App template ready for future deployments
- INSTALL.md complete with all setup instructions

**Project status:** All 4 phases complete. RagnaLab homelab is fully operational with:
- Traefik reverse proxy with automatic HTTPS
- Tailscale VPN for remote access
- Uptime Kuma monitoring
- Automated volume backups
- Homepage dashboard
- Vaultwarden password manager
- Template for adding new applications

---
*Phase: 04-applications-templates*
*Completed: 2026-01-17*
