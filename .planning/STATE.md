# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** v2.0 Network Services — Media Automation Stack

## Current Position

Milestone: v2.0 Network Services
Phase: 6 of 6 (Media Automation Stack) - IN PROGRESS
Plan: 4 of 8 complete in phase
Status: Plan 06-04 complete, ready for 06-05

Progress: [Phase 6] ████░░░░ 4/8 plans | [v2.0] ██████░░░░░ 7/11 plans (64%)

## v2.0 Scope

**Phase 5: Pi-hole Network-Wide Ad Blocking** (COMPLETE)
- [x] Pi-hole Docker deployment with Traefik integration (05-01)
- [x] DHCP server configuration (05-02) - *DNS-only mode due to locked gateway*
- [x] Blocklist and monitoring setup (05-03)

**Phase 6: Media Automation Stack** (IN PROGRESS)
- [x] Directory structure + Gluetun VPN (06-01)
- [x] qBittorrent torrent client (06-02)
- [x] Prowlarr indexer manager (06-03)
- [x] Sonarr + Radarr media automation (06-04)
- [ ] Bazarr subtitles + Unpackerr extraction (06-05)
- [ ] Jellyfin media server (06-06)
- [ ] Jellyseerr request management (06-07)
- [ ] Homepage integration (06-08)
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
| **Gluetun** | (VPN tunnel, no UI) | **v2.0 (NEW)** |
| **qBittorrent** | localhost:8080 (via VPN) | **v2.0 (NEW)** |
| **Prowlarr** | **prowlarr.ragnalab.xyz** | **v2.0 (NEW)** |
| **Sonarr** | **sonarr.ragnalab.xyz** | **v2.0 (NEW)** |
| **Radarr** | **radarr.ragnalab.xyz** | **v2.0 (NEW)** |

## Key Decisions (v2.0)

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| DNS-only mode for Pi-hole | Xfinity XB8 gateway DHCP settings locked and cannot be disabled | Implemented (05-02) |
| Manual device DNS config | Users set DNS to 10.0.0.200 on devices they want ad blocking for | Implemented (05-02) |
| DHCP config preserved | Commented config kept for future if gateway replaced or bridge mode enabled | Documented (05-02) |
| Macvlan networking for Pi-hole | Dedicated LAN IP (10.0.0.200) avoids port conflicts, enables DHCP | Implemented (05-01) |
| Macvlan-shim at 10.0.0.201 | Linux kernel limitation requires shim for host-to-container communication | Implemented (05-01) |
| ProtonVPN for torrent privacy | User-selected VPN provider with WireGuard support | Implemented (06-01) |
| WireGuard over OpenVPN | Better performance on Raspberry Pi, lower resource usage | Implemented (06-01) |
| Credentials in .env file | apps/media/.env excluded from git, .env.example provides template | Implemented (06-01) |
| network_mode over depends_on | Cross-compose depends_on doesn't work; network_mode: container:gluetun enforces dependency | Implemented (06-02) |
| Forms auth via API | Prowlarr auth configured programmatically during deployment | Implemented (06-03) |
| Media group in Homepage | Added layout group for arr services auto-discovery | Implemented (06-03) |
| Multi-network for arr apps | Sonarr/Radarr need proxy (Traefik) + media (qBittorrent) networks | Implemented (06-04) |
| API-based arr configuration | Auth, download clients, root folders configured via API during deployment | Implemented (06-04) |

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
Stopped at: Completed 06-04-PLAN.md (Sonarr + Radarr media automation)
Resume file: .planning/phases/06-media-automation-stack/06-05-PLAN.md
Next action: Execute 06-05 (Bazarr subtitles + Unpackerr extraction)
