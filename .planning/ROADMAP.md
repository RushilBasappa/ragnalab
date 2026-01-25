# Roadmap: RagnaLab v3.0 SSO & Apps

## Overview

Deploy Authelia SSO with passkey authentication and per-user access control, integrate all existing apps with SSO protection, then deploy new apps (Paperless-ngx, Dozzle, IT-Tools) with SSO from day one.

## Phases

**Phase Numbering:**
- v1.0 Foundation: Phases 1-4 (shipped)
- v2.0 Network Services: Phases 5-7.1 (shipped)
- v3.0 SSO & Apps: Phases 9-11 (this milestone)

- [x] **Phase 9: Authelia SSO Foundation** — Deploy Authelia, configure users/groups, enable passkey auth
- [ ] **Phase 10: Existing App Integration** — Protect existing apps with SSO, configure External auth mode
- [ ] **Phase 11: New App Deployment** — Deploy Paperless-ngx, Dozzle, IT-Tools with SSO

## Phase Details

### Phase 9: Authelia SSO Foundation
**Goal**: Deploy Authelia with Traefik integration, passkey authentication, and access control rules
**Depends on**: v2.0 complete
**Requirements**: SSO-01, SSO-02, SSO-03, SSO-04, SSO-05, SSO-06, SSO-07, SSO-08, ACL-01, ACL-02, ACL-03, ACL-04, ACL-05, ACL-06, OPS-01, OPS-02, OPS-03
**Success Criteria** (what must be TRUE):
  1. User can authenticate via passkey/fingerprint (WebAuthn)
  2. User can authenticate via username/password as fallback
  3. Four user groups configured (admin, powerusers, family, guests)
  4. Session persists across all ragnalab.xyz subdomains
  5. Access rules enforce correct policies per group (admin=2FA, others=1FA)
  6. API endpoints and Plex bypass auth for mobile app compatibility
  7. Authelia included in backup and has monitoring
**Plans**: 2 plans

Plans:
- [x] 09-01-PLAN.md — Deploy Authelia with Traefik forwardAuth, users/groups, WebAuthn passkeys, access control rules
- [x] 09-02-PLAN.md — Operations: Backrest backup, Autokuma monitoring, user management documentation

### Phase 10: Existing App Integration
**Goal**: Protect all existing apps with SSO, configure External auth mode for *arr apps
**Depends on**: Phase 9
**Requirements**: APP-01, APP-02, APP-03, APP-04, APP-05, APP-06, APP-07, APP-08, APP-09
**Success Criteria** (what must be TRUE):
  1. Simple apps protected via middleware (Homepage, Traefik dashboard, Glances, Uptime Kuma, Backrest)
  2. *Arr apps (Sonarr, Radarr, Prowlarr) use External auth mode (no double login)
  3. qBittorrent configured with IP whitelist and reverse proxy setting
  4. Mobile apps and widgets still work via API bypass
**Plans**: 4 plans

Plans:
- [ ] 10-01-PLAN.md — Simple services: Homepage, Glances, Traefik dashboard with authelia middleware
- [ ] 10-02-PLAN.md — Auth-disable services: Uptime Kuma, Backrest (disable built-in auth + middleware)
- [ ] 10-03-PLAN.md — *arr apps: Sonarr, Radarr, Prowlarr with External auth mode + middleware
- [ ] 10-04-PLAN.md — qBittorrent: reverse proxy config, IP whitelist + middleware

### Phase 11: New App Deployment
**Goal**: Deploy Paperless-ngx, Dozzle, IT-Tools with SSO protection from day one
**Depends on**: Phase 10
**Requirements**: NEW-01, NEW-02, NEW-03, NEW-04, NEW-05
**Success Criteria** (what must be TRUE):
  1. Paperless-ngx deployed at docs.ragnalab.xyz with trusted header SSO
  2. Dozzle deployed at logs.ragnalab.xyz with forward-proxy auth
  3. IT-Tools deployed at tools.ragnalab.xyz with forwardAuth middleware
  4. All new apps visible on Homepage dashboard
  5. All new apps have Autokuma monitoring
**Plans**: TBD

Plans:
- [ ] 11-01: TBD
- [ ] 11-02: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 9 → 10 → 11

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 9. Authelia SSO Foundation | 2/2 | Complete | 2026-01-25 |
| 10. Existing App Integration | 0/4 | Planned | — |
| 11. New App Deployment | 0/? | Not started | — |
