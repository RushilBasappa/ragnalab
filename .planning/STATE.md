# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-25)

**Core value:** Unified single sign-on with passkey support and per-user access control, plus lightweight app expansion.
**Current focus:** Phase 10 — Existing App Integration

## Current Position

Milestone: v3.0 SSO & Apps
Phase: 10 of 11 (Existing App Integration)
Plan: 04 of 04 complete
Status: Phase complete
Last activity: 2026-01-25 — Completed 10-02 Uptime Kuma & Backrest SSO

Progress: [v1.0] ████████ SHIPPED | [v2.0] ████████ SHIPPED | [v3.0] ███████░ 80%

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
| Authelia | auth.ragnalab.xyz | v3.0 |

**Total services:** 23

## v3.0 Scope

**SSO & Access Control:**
- [x] Authelia SSO with Traefik forward auth
- [x] Passkey/WebAuthn + password fallback
- [x] Four access levels: Admin, Power Users, Family, Guests
- [x] Authelia operations: backup, monitoring, documentation
- [x] Existing apps trust external auth (arr apps, Jellyfin, Uptime Kuma, Backrest) - Phase 10

**App Expansion (after SSO):**
- Paperless-ngx (docs.ragnalab.xyz)
- Dozzle (logs.ragnalab.xyz)
- IT-Tools (tools.ragnalab.xyz)

**Deferred to v4.0+:**
- Immich, Tandoor, ntfy, Stirling-PDF, Actual, Kavita, Linkding, Memos, Syncthing

## Key Decisions (Cumulative)

See PROJECT.md Key Decisions table for full history.

Recent v3.0 decisions:
- SQLite storage for Authelia (no Redis needed for 4 users)
- Argon2id m=256, t=1, p=2 for ARM64 performance
- Passkeys as 2FA (passwordless not in 4.39.14)
- Filesystem notifier (no email needed)
- WebAuthn rp_id=ragnalab.xyz (immutable)
- Session cookie domain=ragnalab.xyz (parent for SSO)

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
Stopped at: Completed 10-02-PLAN.md (Uptime Kuma & Backrest SSO)
Resume file: None
Next action: Phase 10 complete - ready for Phase 11 (New Apps)

## Pending Todos

Check `.planning/todos/pending/` for any pending items.

## Active Debug Sessions

Check `.planning/debug/` for any active debug sessions (exclude resolved/).
