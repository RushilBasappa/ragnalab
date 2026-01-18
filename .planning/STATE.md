# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** v2.0 Network Services — Pi-hole with network-wide ad blocking

## Current Position

Milestone: v2.0 Network Services
Phase: 5 of 6 (Pi-hole Network-Wide Ad Blocking)
Plan: 1 of 3 complete in phase
Status: In progress

Progress: [Phase 5] ██░░░░ 1/3 plans | [v2.0] █░░░░░░░░░░ 1/11 plans (9%)

## v2.0 Scope

**Phase 5: Pi-hole Network-Wide Ad Blocking** (IN PROGRESS)
- [x] Pi-hole Docker deployment with Traefik integration (05-01)
- [ ] DHCP server configuration (05-02)
- [ ] Blocklist and monitoring setup (05-03)

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
| Pi-hole as DHCP server | Xfinity gateway DNS settings locked; only way to provide DNS to all devices | Pending (05-02) |
| Fallback DNS strategy | Network must work if Pi goes down; automatic failover required | Pending (05-02) |
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
Stopped at: Completed 05-01-PLAN.md (Pi-hole Docker deployment)
Resume file: .planning/phases/05-pihole-network-adblocking/05-02-PLAN.md
Next action: Execute plan 05-02 (DHCP configuration)
