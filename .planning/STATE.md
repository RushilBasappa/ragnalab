# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-25)

**Core value:** Unified single sign-on with passkey support and per-user access control, plus lightweight app expansion.
**Current focus:** Phase 9 — Authelia SSO Foundation

## Current Position

Milestone: v3.0 SSO & Apps
Phase: 9 of 11 (Authelia SSO Foundation)
Plan: Not started
Status: Ready to plan
Last activity: 2026-01-25 — Roadmap created (3 phases, 31 requirements)

Progress: [v1.0] ████████ SHIPPED | [v2.0] ████████ SHIPPED | [v3.0] ░░░░░░░░ 0%

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

## v3.0 Scope

**SSO & Access Control:**
- Authelia SSO with Traefik forward auth
- Passkey/WebAuthn + password fallback
- Four access levels: Admin, Power Users, Family, Guests
- Existing apps trust external auth (arr apps, Jellyfin)

**App Expansion (after SSO):**
- Paperless-ngx (docs.ragnalab.xyz)
- Dozzle (logs.ragnalab.xyz)
- IT-Tools (tools.ragnalab.xyz)

**Deferred to v4.0+:**
- Immich, Tandoor, ntfy, Stirling-PDF, Actual, Kavita, Linkding, Memos, Syncthing

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

Last session: 2026-01-25
Stopped at: Roadmap created, ready to plan Phase 9
Resume file: None
Next action: /gsd:plan-phase 9

## Pending Todos

Check `.planning/todos/pending/` for any pending items.

## Active Debug Sessions

Check `.planning/debug/` for any active debug sessions (exclude resolved/).
