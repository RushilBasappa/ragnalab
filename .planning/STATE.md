# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** Phase 7.1 - Backrest Backup System

## Current Position

Milestone: v2.0 Network Services - IN PROGRESS
Phase: 7.1 (Backrest Backup System) - IN PROGRESS
Plan: Backrest deployed and configured, verification pending
Status: Backrest running with 4 backup plans scheduled daily at 3 AM
Last activity: 2026-01-19 - Configured backup plans, hooks, and retention

Progress: [Phase 7] ████████ 8/8 plans (COMPLETE) | [Phase 7.1] ██████░░ 3/5 tasks | [v2.0] 14+ plans

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
- Grouped structure: `stack/media/*`
- Storage: `/media/` local, future external migration

**Phase 7: Operational Hardening** (COMPLETE)
- [x] Restructure to stack/ folder with nested includes (07-01)
- [x] Migrate media stack to stack/media/ (07-02)
- [x] Migrate apps to stack/apps/ + simplify Makefile (07-03)
- [x] Socket-proxy migration for Uptime Kuma/Homepage (07-04)
- [x] Backup audit and volume coverage (07-05)
- [x] Autokuma deployment and configuration (07-06)
- [x] Kuma labels for media and app services (07-07)
- [x] Final verification and phase summary (07-08)

**Phase 7.1: Backrest Backup System** (IN PROGRESS) - INSERTED
- [x] Deploy Backrest with Traefik integration
- [x] Configure backup plans (4 plans via config.json)
- [x] Set up pre/post hooks for SQLite containers
- [ ] Verify backups and test restore (run manual backup from UI)
- [ ] Remove old backup system after verification

**Phase 8: Application Expansion** (NOT PLANNED)
- [ ] Immich (photos)
- [ ] Paperless-ngx (documents)
- [ ] Tandoor Recipes (recipes)
- [ ] ntfy (notifications)
- [ ] Dozzle (logs)
- [ ] IT-Tools (dev utilities)
- [ ] Stirling-PDF (PDF tools)
- [ ] Actual Budget (budgeting)
- [ ] Recyclarr (arr sync)
- [ ] Kavita (manga/comics)
- [ ] Plex (media server)
- [ ] Linkding (bookmarks)
- [ ] Memos (quick notes)
- [ ] Syncthing (file sync)

**Plans:** 3 (Phase 5) + 8 (Phase 6) + TBD (Phase 7) + TBD (Phase 8) = 11+ total

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
| RustDesk | 100.75.173.7:21115-21119 | v1.0 |
| Glances | glances.ragnalab.xyz | v1.0 |
| Autokuma | (headless, no UI) | v2.0 |
| Backrest | backups.ragnalab.xyz | v2.0 |

**Total services:** 18 (6 from v1.0 + 12 from v2.0)

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
| Nested includes pattern | stack/ -> category -> service composes for modular management | Implemented (07-01) |
| Networks as external | Pre-existing networks (proxy, socket_proxy_network, media) marked external | Implemented (07-01) |
| Extended socket-proxy permissions | IMAGES=1, INFO=1, EVENTS=1 for Homepage/Uptime Kuma | Implemented (07-01) |
| External volume naming | Use project_volumename format to match existing Docker volumes | Implemented (07-02) |
| Gluetun include order | Must be first in media includes (qbittorrent uses network_mode: container:gluetun) | Implemented (07-02) |
| Makefile simplification | Only backup, restore, status targets - services via docker compose --profile | Implemented (07-03) |
| Old directories archived | apps/ and proxy/ moved to archive/pre-stack-migration/ for reference | Implemented (07-03) |
| Socket-proxy for Docker API | Homepage and Uptime Kuma use socket-proxy:2375 instead of direct docker.sock | Implemented (07-04) |
| External volume declarations | Volumes referenced in multiple compose files use external: true with explicit name | Implemented (07-04) |
| Uptime Kuma volume sharing | Volumes in same include tree share without external redeclaration | Implemented (07-05) |
| Traefik ACME bind mount backup | Certificates backed up via bind mount (config dir, not Docker volume) | Implemented (07-05) |
| RustDesk hot backup | Keys only, no database - safe for backup without stopping | Implemented (07-05) |
| Uptime Kuma stop during backup | SQLite database requires consistent state via stop label | Implemented (07-05) |
| HTTP monitors under service category | Easier to find service status by category (Media, Apps) | Implemented (07-07) |
| Container monitors under Containers | Single location for container health across all services | Implemented (07-07) |
| TCP port monitors for RustDesk | RustDesk uses custom protocol, not HTTP - TCP port check appropriate | Implemented (07-07) |
| Container-only for headless services | Gluetun, qBittorrent, Unpackerr have no web UI to monitor | Implemented (07-07) |
| Parent groups in traefik compose | Traefik always-running ensures groups created before services reference them | Implemented (07-06) |
| Docker host via socket-proxy | socket-proxy already provides filtered Docker API access | Implemented (07-06) |
| autokuma tag for tracking | Easy identification of Autokuma-managed vs manual monitors | Implemented (07-06) |

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
- Phase 7 added: Operational Hardening (backup coverage + socket-proxy migration)
- Phase 7.1 inserted after Phase 7: Backrest Backup System (URGENT) - replace script-based backup with UI tool
- Phase 8 added: Application Expansion (14 new apps)

## Session Continuity

Last session: 2026-01-18
Stopped at: Completed 07-06-PLAN.md and 07-07-PLAN.md
Resume file: None
Next action: 07-08-PLAN.md (final verification and phase summary)

**Architecture completed (2026-01-18):**
- `stack/` parent folder for all services
- Nested includes: root -> category -> service composes
- Each service has own folder with own docker-compose.yml
- Infrastructure services operational from stack/infra/
- Media services operational from stack/media/
- App services operational from stack/apps/
- Old apps/ and proxy/ directories archived
- Makefile simplified to operational targets only

**Socket-proxy hardening (2026-01-18):**
- Homepage and Uptime Kuma migrated to socket-proxy
- Only socket-proxy, backup, and glances mount docker.sock directly
- Uptime Kuma Docker host requires UI configuration (socket-proxy:2375)

**Backup coverage expanded (2026-01-18):**
- 13 data sources in nightly backup (was 10)
- Added: Uptime Kuma (SQLite), RustDesk (keys), Traefik ACME (certificates)
- Restore script rewritten for stack/ directory structure
- Bind mount restore support for pihole and traefik-acme

**Autokuma deployment (2026-01-18):**
- Autokuma service deployed in stack/infra/autokuma/
- Connected to Uptime Kuma via API for monitor management
- Connected to socket-proxy for Docker label discovery
- Parent groups created: Infrastructure (HTTP), Containers (Docker)
- Docker host created: my-docker via socket-proxy:2375
- Infrastructure monitors: 3 HTTP + 5 container = 8 total

**Autokuma monitoring labels (2026-01-18):**
- All 9 media services have kuma labels for automatic monitoring
- All 5 app containers have kuma labels (4 services, RustDesk has 2 containers)
- HTTP monitors grouped under Media and Apps parent groups
- Container monitors all under Containers parent group
- TCP port monitors for RustDesk non-HTTP services
- Total: 33 monitors across all services (infrastructure + media + apps)

## Accumulated Context

### Pending Todos

1 pending todo(s) in `.planning/todos/pending/`:
- **Configure Pi-hole DNS for ragnalab.xyz subdomains** (networking)
