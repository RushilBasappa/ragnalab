# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-26)

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** Planning next milestone (v4.0)

## Current Position

Milestone: v3.0 SSO & Apps — SHIPPED
Phase: Complete
Plan: Complete
Status: Ready to plan next milestone
Last activity: 2026-01-26 — v3.0 milestone shipped

Progress: [v1.0] SHIPPED | [v2.0] SHIPPED | [v3.0] SHIPPED

## Completed Milestones

**v3.0 SSO & Apps (Shipped 2026-01-26):**
- Authelia SSO with WebAuthn passkey 2FA
- Four access levels (Admin 2FA, Power Users 1FA, Family 1FA, Guests)
- 17 services protected with SSO middleware
- *arr apps use External auth mode (no double login)
- New apps: Paperless-ngx, Dozzle, IT-Tools

**v2.0 Network Services (Shipped 2026-01-20):**
- Pi-hole DNS-based ad blocking (DNS-only mode)
- Complete media automation stack (13 services)
- stack/ folder reorganization with nested includes
- Socket-proxy security hardening
- Autokuma automatic monitoring (33 monitors)
- Backrest web UI backup system
- Bonus: Plex, Recyclarr, Flaresolverr, Maintainerr

**v1.0 Foundation (Shipped 2026-01-17):**
- Traefik reverse proxy with Let's Encrypt DNS-01
- Tailscale VPN integration (host-level, dual access)
- Uptime Kuma monitoring
- Homepage dashboard with widgets
- Vaultwarden password manager
- Automated backups with 3-2-1 strategy

## Services Deployed

| Service | URL | Version |
|---------|-----|---------|
| Traefik | traefik.ragnalab.xyz | v1.0 |
| Uptime Kuma | status.ragnalab.xyz | v1.0 |
| Homepage | home.ragnalab.xyz | v1.0 |
| Vaultwarden | vault.ragnalab.xyz | v1.0 |
| RustDesk | 100.75.173.7:21115-21119 | v1.0 |
| Glances | glances.ragnalab.xyz | v1.0 |
| Pi-hole | pihole.ragnalab.xyz | v2.0 |
| Gluetun | (VPN tunnel, no UI) | v2.0 |
| qBittorrent | qbit.ragnalab.xyz | v2.0 |
| Prowlarr | prowlarr.ragnalab.xyz | v2.0 |
| Sonarr | sonarr.ragnalab.xyz | v2.0 |
| Radarr | radarr.ragnalab.xyz | v2.0 |
| Bazarr | bazarr.ragnalab.xyz | v2.0 |
| Unpackerr | (headless, no UI) | v2.0 |
| Jellyfin | jellyfin.ragnalab.xyz | v2.0 |
| Jellyseerr | requests.ragnalab.xyz | v2.0 |
| Plex | plex.ragnalab.xyz | v2.0 |
| Recyclarr | (scheduled job, no UI) | v2.0 |
| Flaresolverr | (internal, no UI) | v2.0 |
| Maintainerr | maintainerr.ragnalab.xyz | v2.0 |
| Autokuma | (headless, no UI) | v2.0 |
| Backrest | backups.ragnalab.xyz | v2.0 |
| Authelia | auth.ragnalab.xyz | v3.0 |
| IT-Tools | tools.ragnalab.xyz | v3.0 |
| Dozzle | logs.ragnalab.xyz | v3.0 |
| Paperless-ngx | docs.ragnalab.xyz | v3.0 |

**Total services:** 26

## v4.0 Ideas (Not Yet Scoped)

**Complex SSO Integrations:**
- Jellyfin SSO plugin (requires plugin install + account linking)
- Jellyseerr OIDC (preview branch stability unknown)
- Vaultwarden OIDC (mobile app 2FA issues)

**App Expansion:**
- Immich photo backup
- Tandoor recipes
- ntfy notifications
- Stirling-PDF tools

## Key Decisions (Cumulative)

See PROJECT.md Key Decisions table for full history.

## Session Continuity

Last session: 2026-01-26
Stopped at: v3.0 milestone completed
Resume file: None
Next action: `/gsd:discuss-milestone` to plan v4.0

## Pending Todos

Check `.planning/todos/pending/` for any pending items.

## Active Debug Sessions

Check `.planning/debug/` for any active debug sessions (exclude resolved/).
