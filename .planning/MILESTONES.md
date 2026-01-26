# Project Milestones: RagnaLab

## v3.0 SSO & Apps (Shipped: 2026-01-26)

**Delivered:** Unified single sign-on with passkey authentication, per-user access control, SSO protection for all services, and three new applications (Paperless-ngx, Dozzle, IT-Tools).

**Phases completed:** 9-11 (8 plans total)

**Key accomplishments:**

- Authelia SSO with WebAuthn passkey 2FA and password fallback
- Four access levels configured (Admin 2FA, Power Users 1FA, Family 1FA, Guests)
- 17 services protected with forwardAuth middleware
- *arr apps use External auth mode (no double login)
- Paperless-ngx document management with trusted header SSO
- Dozzle container log viewer with forward-proxy auth
- IT-Tools utility suite with forwardAuth middleware
- API bypass rules for mobile apps and widgets

**Stats:**

- 3 phases, 8 plans, 31 requirements
- 3 new services deployed (IT-Tools, Dozzle, Paperless-ngx)
- 17 services with SSO protection
- 36 files modified, +4,005 lines
- 2 days from milestone start to ship

**Git range:** `feat(09-01)` → `feat(11-02)`

**What's next:** v4.0 — Complex SSO integrations (Jellyfin plugin, Jellyseerr OIDC), app expansion (Immich, Tandoor, ntfy)

---

## v2.0 Network Services (Shipped: 2026-01-20)

**Delivered:** Extended homelab with network-wide ad blocking, complete media automation stack, operational hardening, and modern backup infrastructure.

**Phases completed:** 5-7.1 (19 plans total)

**Key accomplishments:**

- Pi-hole DNS-based ad blocking with macvlan networking (DNS-only mode)
- Complete media automation stack: Gluetun VPN, qBittorrent, Prowlarr, Sonarr, Radarr, Bazarr, Unpackerr, Jellyfin, Jellyseerr
- Reorganized to stack/ folder structure with nested Docker Compose includes
- Socket-proxy security hardening for Homepage and Uptime Kuma
- Autokuma automatic monitoring via Docker labels (33 monitors)
- Backrest web UI backup system replacing script-based backups
- Bonus deploys: Plex, Recyclarr, Flaresolverr, Maintainerr

**Stats:**

- 4 phases (5, 6, 7, 7.1), 19 plans, ~18 summaries
- 12+ new services deployed
- ~30 commits since v1.0
- 4 days from v1.0 to v2.0 ship

**Git range:** `feat(05-01)` → `feat(07-08)` + manual Phase 7.1

**What's next:** v3.0 SSO & Access Control — Authelia SSO first, then app expansion

---

## v1.0 Foundation (Shipped: 2026-01-17)

**Delivered:** Secure, private-only homelab infrastructure with Traefik reverse proxy, Tailscale VPN, automated backups, and core applications.

**Phases completed:** 1-4 (14 plans total)

**Key accomplishments:**

- Traefik v3.6 reverse proxy with Let's Encrypt DNS-01 certificates
- Tailscale VPN integration (host-level, dual LAN + VPN access)
- Docker socket-proxy security for Traefik
- Uptime Kuma monitoring with 7+ monitors
- Homepage dashboard with widgets
- Vaultwarden password manager
- Automated backup with 3-2-1 strategy
- App template for future deployments

**Stats:**

- 4 phases, 14 plans
- 6 services deployed (Traefik, Uptime Kuma, Homepage, Vaultwarden, Glances, RustDesk)
- 1 day from project start to v1.0 ship

**Git range:** Initial commit → `feat(04-03)`

**What's next:** v2.0 Network Services — Pi-hole, media stack, operational hardening

---

*For detailed phase information, see `.planning/milestones/v{X.Y}-ROADMAP.md`*
