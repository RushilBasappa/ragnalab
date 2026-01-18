# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** v2.0 Network Services — Media Automation Stack

## Current Position

Milestone: v2.0 Network Services
Phase: 5 of 6 (Pi-hole Network-Wide Ad Blocking) - COMPLETE
Plan: 3 of 3 complete in phase
Status: Phase complete, ready for Phase 6

Progress: [Phase 5] ██████ 3/3 plans | [v2.0] ███░░░░░░░░ 3/11 plans (27%)

## v2.0 Scope

**Phase 5: Pi-hole Network-Wide Ad Blocking** (COMPLETE)
- [x] Pi-hole Docker deployment with Traefik integration (05-01)
- [x] DHCP server configuration (05-02) - *DNS-only mode due to locked gateway*
- [x] Blocklist and monitoring setup (05-03)

**Phase 6: Media Automation Stack** (PENDING)
- Gluetun VPN + qBittorrent (torrent privacy)
- Prowlarr, Sonarr, Radarr (media automation)
- Bazarr, Unpackerr (subtitles, extraction)
- Jellyfin media server + Jellyseerr requests
- Grouped structure: `apps/media/*`
- Storage: `/media/` local, future external migration

**Plans:** 3 (Phase 5) + 8 (Phase 6) = 11 total

## Services Deployed

| Service | URL | Status |
|---------|-----|--------|
| Traefik | traefik.ragnalab.xyz | v1.0 |
| Uptime Kuma | status.ragnalab.xyz | v1.0 |
| Homepage | home.ragnalab.xyz | v1.0 |
| Vaultwarden | vault.ragnalab.xyz | v1.0 |
| **Pi-hole** | **pihole.ragnalab.xyz** | **v2.0 (NEW)** |

## Key Decisions (v2.0)

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| DNS-only mode for Pi-hole | Xfinity XB8 gateway DHCP settings locked and cannot be disabled | Implemented (05-02) |
| Manual device DNS config | Users set DNS to 10.0.0.200 on devices they want ad blocking for | Implemented (05-02) |
| DHCP config preserved | Commented config kept for future if gateway replaced or bridge mode enabled | Documented (05-02) |
| Macvlan networking for Pi-hole | Dedicated LAN IP (10.0.0.200) avoids port conflicts, enables DHCP | Implemented (05-01) |
| Macvlan-shim at 10.0.0.201 | Linux kernel limitation requires shim for host-to-container communication | Implemented (05-01) |

## Previous Milestone

**v1.0 (Complete 2026-01-17):**
- Traefik reverse proxy with production Let's Encrypt SSL
- Tailscale VPN integration (host-level, dual access)
- Uptime Kuma monitoring with 7+ monitors
- Automated backups with restore procedure
- Homepage dashboard with widgets
- Vaultwarden password manager
- App template for future deployments

## Roadmap Evolution

- Phase 6 added: Media Automation Stack (arr suite + Jellyfin)

## Session Continuity

Last session: 2026-01-18
Stopped at: Completed Phase 5 (Pi-hole Network-Wide Ad Blocking)
Resume file: .planning/phases/06-media-automation-stack/06-01-PLAN.md
Next action: Begin Phase 6 (Media Automation Stack) with 06-01 (Directory structure and Gluetun VPN)
