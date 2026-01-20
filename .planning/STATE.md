# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-20)

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** v3.0 SSO & Access Control — planning next milestone

## Current Position

Milestone: v3.0 SSO & Access Control - NOT STARTED
Phase: None (milestone not yet planned)
Plan: None
Status: Ready to plan v3.0 roadmap
Last activity: 2026-01-20 - v2.0 milestone completed and archived

Progress: [v1.0] ████████ SHIPPED | [v2.0] ████████ SHIPPED | [v3.0] ░░░░░░░░ NOT STARTED

## Completed Milestones

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

**Total services:** 22

## v3.0 Scope (Planned)

**SSO & Access Control:**
- Authelia SSO with Traefik forward auth
- Passkey/WebAuthn + password fallback
- Four access levels: Admin, Power Users, Family, Guests
- Apps trust external auth

**App Expansion (after SSO):**
- Immich, Paperless-ngx, Tandoor Recipes, ntfy, Dozzle, IT-Tools, Stirling-PDF, Actual Budget, Kavita, Linkding, Memos, Syncthing

## Key Decisions (Cumulative)

See PROJECT.md Key Decisions table for full history.

Recent v2.0 decisions:
- DNS-only mode for Pi-hole (gateway locked)
- ProtonVPN WireGuard for torrents
- Direct-play only for Jellyfin
- stack/ nested includes pattern
- Socket-proxy for Docker API
- Autokuma for automatic monitoring
- Backrest over script-based backup
- SSO-first app deployment approach

## Session Continuity

Last session: 2026-01-20
Stopped at: v2.0 milestone completion
Resume file: None
Next action: /gsd:discuss-milestone or /gsd:create-roadmap for v3.0

## Pending Todos

Check `.planning/todos/pending/` for any pending items.

## Active Debug Sessions

Check `.planning/debug/` for any active debug sessions (exclude resolved/).
