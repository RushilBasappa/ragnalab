# Roadmap

**Project:** RagnaLab
**Created:** 2026-01-16
**Phases:** 4

## Overview

This roadmap follows a strict dependency order derived from the 47 v1 requirements: infrastructure foundation with security-first networking, VPN access with production SSL, operational infrastructure for reliability, and finally applications with developer templates. Each phase delivers a complete, verifiable capability that unblocks the next. The structure prevents the top homelab pitfalls: accidental public exposure, Let's Encrypt rate limits, SD card corruption, and missing backups.

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
- [ ] 03-01-PLAN.md — Deploy Uptime Kuma monitoring dashboard
- [ ] 03-02-PLAN.md — Configure monitors and deploy backup infrastructure
- [ ] 03-03-PLAN.md — Create restore script, test procedure, verify phase complete

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

**Plans:** (created by /gsd:plan-phase)

---

## Progress

| Phase | Status | Completed |
|-------|--------|-----------|
| 1 - Foundation & Routing | ✓ Complete | 2026-01-17 |
| 2 - VPN & Production Readiness | ✓ Complete | 2026-01-17 |
| 3 - Operational Infrastructure | Not started | — |
| 4 - Applications & Templates | Not started | — |

---

*Roadmap for milestone: v1.0*
