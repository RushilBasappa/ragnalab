# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** v2.0 Network Services COMPLETE

## Current Position

Milestone: v2.0 Network Services - COMPLETE
Phase: 6 of 6 (Media Automation Stack) - COMPLETE
Plan: 8 of 8 complete in phase
Status: v2.0 milestone complete

Progress: [Phase 6] ████████ 8/8 plans | [v2.0] ███████████ 11/11 plans (100%)

## v2.0 Scope

**Phase 5: Pi-hole Network-Wide Ad Blocking** (COMPLETE)
- [x] Pi-hole Docker deployment with Traefik integration (05-01)
- [x] DHCP server configuration (05-02) - *DNS-only mode due to locked gateway*
- [x] Blocklist and monitoring setup (05-03)

**Phase 6: Media Automation Stack** (COMPLETE)
- [x] Directory structure + Gluetun VPN (06-01)
- [x] qBittorrent torrent client (06-02)
- [x] Prowlarr indexer manager (06-03)
- [x] Sonarr + Radarr media automation (06-04)
- [x] Bazarr subtitles + Unpackerr extraction (06-05)
- [x] Jellyfin media server (06-06)
- [x] Jellyseerr request management (06-07)
- [x] Stack verification & Homepage integration (06-08)
- Grouped structure: `apps/media/*`
- Storage: `/media/` local, future external migration

**Plans:** 3 (Phase 5) + 8 (Phase 6) = 11 total - ALL COMPLETE

## Services Deployed

| Service | URL | Status |
|---------|-----|--------|
| Traefik | traefik.ragnalab.xyz | v1.0 |
| Uptime Kuma | status.ragnalab.xyz | v1.0 |
| Homepage | home.ragnalab.xyz | v1.0 |
| Vaultwarden | vault.ragnalab.xyz | v1.0 |
| Pi-hole | pihole.ragnalab.xyz | v2.0 |
| Gluetun | (VPN tunnel, no UI) | v2.0 |
| qBittorrent | localhost:8080 (via VPN) | v2.0 |
| Prowlarr | prowlarr.ragnalab.xyz | v2.0 |
| Sonarr | sonarr.ragnalab.xyz | v2.0 |
| Radarr | radarr.ragnalab.xyz | v2.0 |
| Bazarr | bazarr.ragnalab.xyz | v2.0 |
| Unpackerr | (headless, no UI) | v2.0 |
| Jellyfin | jellyfin.ragnalab.xyz | v2.0 |
| Jellyseerr | requests.ragnalab.xyz | v2.0 |

**Total services:** 14 (4 from v1.0 + 10 from v2.0)

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
| Read-only media mount for Jellyfin | Jellyfin reads from library but cannot modify - Sonarr/Radarr own the files | Implemented (06-06) |
| Direct-play only (no transcoding) | Pi 5 lacks hardware encoding; clients must support direct-play | Implemented (06-06) |
| API-based Jellyfin setup | Setup wizard, libraries, and transcoding config completed via API | Implemented (06-06) |
| golift/unpackerr image | hotio/unpackerr doesn't exist; golift is the original maintainer | Implemented (06-05) |
| Config file modification for Bazarr | API settings weren't persisting; direct config.yaml modification required | Implemented (06-05) |
| OpenSubtitles.com as default | Works without account for limited use; most popular subtitle source | Implemented (06-05) |
| Jellyfin auth for Jellyseerr | Users authenticate with existing Jellyfin accounts, no separate credentials | Implemented (06-07) |
| Backup volume aggregation | All 8 media volumes added to nightly backup for disaster recovery | Implemented (06-07) |
| User-configured indexers | Prowlarr indexers require manual setup due to personal tracker preferences | Implemented (06-08) |

## Completed Milestones

**v2.0 (Complete 2026-01-18):**
- Pi-hole network-wide ad blocking with DNS-only mode
- Complete media automation stack (9 services)
- VPN-protected torrent downloads via Gluetun/ProtonVPN
- Prowlarr indexer management synced to arr apps
- Sonarr/Radarr automated TV/movie acquisition
- Bazarr automatic subtitle downloads
- Unpackerr automated archive extraction
- Jellyfin media server (direct-play only)
- Jellyseerr request management with Jellyfin auth
- Full Homepage dashboard integration with widgets
- Uptime Kuma monitoring for all public services
- Backup coverage for all media service volumes

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
- v2.0 complete: Ready for future milestones

## Session Continuity

Last session: 2026-01-18
Stopped at: Completed v2.0 milestone (all 11 plans)
Resume file: None
Next action: Plan v2.1 or v3.0 when ready
