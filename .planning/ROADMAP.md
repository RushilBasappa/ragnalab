# Roadmap

**Project:** RagnaLab
**Created:** 2026-01-16
**Current Milestone:** v2.0 Network Services
**Phases:** 8 (8 complete, Phase 8 moved to v3.0)

## Overview

This roadmap follows a strict dependency order. Phases 1-4 (v1.0) established infrastructure foundation with security-first networking, VPN access with production SSL, operational infrastructure for reliability, and applications with developer templates. Phase 5 (v2.0) extends the homelab to provide network-wide services for the entire home network, starting with DNS-based ad blocking via Pi-hole.

## Phases

### Phase 1: Foundation & Routing

**Goal:** Secure reverse proxy infrastructure with automatic SSL certificates is operational and verified
**Depends on:** Nothing (first phase)
**Requirements:** INFRA-01, INFRA-02, INFRA-03, INFRA-04, INFRA-06, DNS-01, DNS-02, ROUTE-01, ROUTE-03, ROUTE-04, SEC-01, SEC-02, SEC-03, SEC-04, SEC-05, SEC-06, STORAGE-02, STORAGE-03, STORAGE-04, OPS-02

**Success Criteria:**
1. User can access Traefik dashboard via HTTPS with valid Let's Encrypt staging certificate
2. Docker networks (proxy, socket_proxy_network) exist and Traefik discovers services via labels
3. Docker socket is protected by read-only proxy, never exposed directly to Traefik
4. Wildcard DNS `*.ragnalab.xyz` resolves to Tailscale IP address
5. Security headers middleware (HSTS, CSP, X-Frame-Options) applies to all routes

**Plans:** 4 plans

Plans:
- [x] 01-01-PLAN.md — Project structure, Docker networks, Cloudflare DNS setup
- [x] 01-02-PLAN.md — Traefik static config and security middleware
- [x] 01-03-PLAN.md — Docker Compose files (proxy infrastructure + whoami test service)
- [x] 01-04-PLAN.md — Deploy and verify all success criteria

---

### Phase 2: VPN & Production Readiness

**Goal:** Services accessible via both local network and Tailscale VPN with production-grade SSL certificates
**Depends on:** Phase 1
**Requirements:** VPN-01, VPN-02, ROUTE-02, ROUTE-05, STORAGE-01, OPS-03, OPS-04, MON-04, MON-05

**Success Criteria:**
1. User can access test service (whoami) with valid production Let's Encrypt certificate
2. Services accessible via both local network AND Tailscale VPN (dual access)
3. Tailscale persists across host reboots (systemd service enabled)
4. HTTP requests automatically redirect to HTTPS for all services
5. SSD storage architecture validated and Docker data on reliable storage

**Plans:** 4 plans

Plans:
- [x] 02-01-PLAN.md — Host system preparation (IP forwarding, cgroup memory, thermal check)
- [x] 02-02-PLAN.md — Tailscale host installation for remote VPN access
- [x] 02-03-PLAN.md — Production Let's Encrypt certificates and resource limits
- [x] 02-04-PLAN.md — End-to-end verification and storage validation

---

### Phase 3: Operational Infrastructure

**Goal:** Platform has automated backups, health monitoring, and operational observability before deploying critical services
**Depends on:** Phase 2
**Requirements:** BACKUP-01, BACKUP-02, BACKUP-03, BACKUP-04, BACKUP-05, MON-01, MON-02, MON-03, OPS-01, OPS-05

**Success Criteria:**
1. User can view health status of all services in Uptime Kuma dashboard
2. Automated backups run on schedule and upload to offsite storage (3-2-1 strategy verified)
3. User can restore service data from backup (tested and documented)
4. Traefik dashboard shows active routes, middleware, and service health
5. All infrastructure configs (Traefik, compose files) committed to git with version control

**Plans:** 3 plans

Plans:
- [x] 03-01-PLAN.md — Deploy Uptime Kuma monitoring dashboard
- [x] 03-02-PLAN.md — Configure monitors and deploy backup infrastructure
- [x] 03-03-PLAN.md — Create restore script, test procedure, verify phase complete

---

### Phase 4: Applications & Templates

**Goal:** Core applications deployed with modular structure and dead-simple process for adding new apps
**Depends on:** Phase 3
**Requirements:** APP-01, APP-02, APP-03, APP-04, APP-05, APP-06, DX-01, DX-02, DX-03, DX-04, DX-05, DX-06

**Success Criteria:**
1. User can access Homepage dashboard at home.ragnalab.xyz showing all deployed services with status
2. User can access Vaultwarden password manager at vault.ragnalab.xyz and store passwords
3. Vaultwarden data backs up automatically and is restorable from backup
4. User can deploy new application by copying template, editing compose file, and running `docker compose up`
5. New applications automatically appear in Traefik routing and Homepage dashboard

**Plans:** 3 plans

Plans:
- [x] 04-01-PLAN.md — Deploy Homepage dashboard with Docker label discovery
- [x] 04-02-PLAN.md — Deploy Vaultwarden password manager with backup integration
- [x] 04-03-PLAN.md — Create app template and add Homepage labels to infrastructure

---

### Phase 5: Pi-hole Network-Wide Ad Blocking

**Goal:** Network-wide DNS-based ad blocking with Pi-hole as DHCP server and automatic fallback for high availability
**Depends on:** Phase 4 (existing infrastructure)
**Milestone:** v2.0
**Requirements:** DNS-01, DNS-02, DNS-03, DNS-04, DHCP-01, DHCP-02, DHCP-03, DHCP-04, HA-01, HA-02, HA-03, OBS-01, OBS-02, OBS-03, OPS-01, OPS-02, OPS-03

**Success Criteria:**
1. User's devices automatically get ad blocking without any client-side configuration
2. Pi-hole admin UI accessible at pihole.ragnalab.xyz with valid SSL certificate
3. All network devices receive Pi-hole as DNS via DHCP (visible in Pi-hole query log)
4. Internet works for existing devices if Pi-hole/Pi is temporarily unavailable (fallback verified)
5. Pi-hole statistics visible in Homepage dashboard widget

**Plans:** 3 plans

Plans:
- [x] 05-01-PLAN.md — Pi-hole Docker deployment with macvlan network and Traefik integration
- [x] 05-02-PLAN.md — DHCP configuration and network cutover from Xfinity gateway (*DNS-only mode - gateway locked*)
- [x] 05-03-PLAN.md — Monitoring, Homepage widget, backup, and full verification

---

### Phase 6: Media Automation Stack

**Goal:** Complete media automation system with arr stack for TV/movies, VPN-protected downloads, and Jellyfin media server
**Depends on:** Phase 5
**Milestone:** v2.0
**Plans:** 8 plans

**Success Criteria:**
1. All media services accessible via HTTPS at ragnalab.xyz subdomains
2. VPN protection verified for torrent traffic (qBittorrent shows VPN IP)
3. End-to-end flow works: request in Jellyseerr -> download via qBittorrent -> organized by Sonarr/Radarr -> viewable in Jellyfin
4. All services appear in Homepage dashboard with working widgets
5. All service data included in automated backup system

Plans:
- [x] 06-01-PLAN.md — Media directory structure and Gluetun VPN setup
- [x] 06-02-PLAN.md — qBittorrent download client with VPN routing
- [x] 06-03-PLAN.md — Prowlarr indexer manager
- [x] 06-04-PLAN.md — Sonarr (TV) and Radarr (Movies) automation
- [x] 06-05-PLAN.md — Bazarr subtitles and Unpackerr extraction
- [x] 06-06-PLAN.md — Jellyfin media server (direct-play only)
- [x] 06-07-PLAN.md — Jellyseerr requests and backup integration
- [x] 06-08-PLAN.md — End-to-end verification and indexer configuration

**Services deployed:**
- gluetun.ragnalab.xyz (VPN status - internal only)
- prowlarr.ragnalab.xyz (Indexer manager)
- sonarr.ragnalab.xyz (TV automation)
- radarr.ragnalab.xyz (Movie automation)
- bazarr.ragnalab.xyz (Subtitle automation)
- jellyfin.ragnalab.xyz (Media server)
- requests.ragnalab.xyz (Jellyseerr request portal)

---

### Phase 7: Operational Hardening

**Goal:** Restructure compose files into stack/ folder with nested includes, complete backup coverage, eliminate direct Docker socket exposure, and automate monitoring with Autokuma
**Depends on:** Phase 6
**Milestone:** v2.0
**Plans:** 8 plans

**Success Criteria:**
1. All services organized under `stack/` with nested include pattern (stack/infra/traefik/, etc.)
2. All services with persistent data are included in automated backup system
3. No containers mount /var/run/docker.sock directly (except socket-proxy)
4. Uptime Kuma and Homepage use socket-proxy for Docker API access
5. Backup restore procedure verified for newly added volumes
6. Autokuma deployed and all services have monitoring labels
7. All existing services automatically monitored (HTTP + Docker container checks)

Plans:
- [x] 07-01-PLAN.md — Create stack/ structure and migrate infrastructure services
- [x] 07-02-PLAN.md — Migrate media services to stack/media/
- [x] 07-03-PLAN.md — Migrate apps to stack/apps/ and simplify Makefile
- [x] 07-04-PLAN.md — Socket-proxy migration for Uptime Kuma and Homepage
- [x] 07-05-PLAN.md — Expand backup coverage with missing volumes
- [x] 07-06-PLAN.md — Deploy Autokuma and add kuma labels to infrastructure
- [x] 07-07-PLAN.md — Add kuma labels to media and app services
- [x] 07-08-PLAN.md — Final verification checkpoint

**Scope:**
- Restructure into `stack/` folder with nested includes (root -> category -> service composes)
- Migrate existing services from proxy/, apps/*, media/ into stack/{category}/{service}/
- Audit all apps for backup requirements
- Add missing volumes to backup system
- Verify backup/restore works for all services
- Configure socket-proxy access for Uptime Kuma
- Configure socket-proxy access for Homepage
- Deploy Autokuma container alongside Uptime Kuma
- Delete existing manual monitors from Uptime Kuma (clean slate)
- Add kuma labels to all existing docker-compose files
- Monitors auto-created for: HTTP endpoints, Docker containers, TCP ports (RustDesk)

---

### Phase 7.1: Backrest Backup System (INSERTED)

**Goal:** Replace offen/docker-volume-backup with Backrest for UI-based backup management, better deduplication, and easier restore operations
**Depends on:** Phase 7
**Milestone:** v2.0
**Plans:** 0 plans

**Success Criteria:**
1. Backrest accessible at backups.ragnalab.xyz with valid SSL certificate
2. All 13 volumes + 2 bind mounts configured as backup sources
3. Pre/post hooks stop SQLite containers (9 services) during backup
4. Retention policy configured (7 daily, 4 weekly, 12 monthly)
5. Test restore completes successfully via Backrest UI
6. Old backup system removed after parallel verification period

Plans:
- [ ] TBD (run /gsd:plan-phase 7.1 to break down)

**Scope:**
- Deploy Backrest container with Traefik integration
- Mount all backup source volumes (read-only)
- Configure local repository at /backups
- Set up backup plans via Backrest UI
- Configure container stop/start hooks for SQLite databases
- Run parallel with old system during verification
- Remove old offen/docker-volume-backup after Backrest verified

**Migration notes:**
- Keep old system temporarily for safety
- Old system: offen/docker-volume-backup:v2 (no UI, script-based restore)
- New system: Backrest (Restic backend, web UI, better deduplication)

---

### Phase 8: Application Expansion (MOVED TO v3.0)

**Status:** Moved to v3.0 — apps will be deployed after Authelia SSO is in place

**Rationale:** Deploying Authelia first means all new apps get SSO protection from day one, avoiding retrofit.

**Apps moved to v3.0:**
- Immich, Paperless-ngx, Tandoor Recipes, ntfy, Dozzle, IT-Tools, Stirling-PDF, Actual Budget, Kavita, Linkding, Memos, Syncthing

**Already deployed (v2.0):**
- Plex, Recyclarr, Flaresolverr, Maintainerr (deployed outside GSD workflow)

---

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1 - Foundation & Routing | Complete | 2026-01-17 |
| 2 - VPN & Production Readiness | Complete | 2026-01-17 |
| 3 - Operational Infrastructure | Complete | 2026-01-17 |
| 4 - Applications & Templates | Complete | 2026-01-17 |
| 5 - Pi-hole Network-Wide Ad Blocking | Complete | 2026-01-18 |
| 6 - Media Automation Stack | Complete | 2026-01-18 |
| 7 - Operational Hardening | Complete | 2026-01-18 |
| 7.1 - Backrest Backup System | Complete | 2026-01-20 |
| 8 - Application Expansion | Moved to v3.0 | — |

---

*Roadmap for milestones: v1.0 (complete), v2.0 (in progress)*
