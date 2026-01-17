# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** Phase 3 Complete - Ready for Phase 4

## Current Position

Phase: 3 of 4 (Operational Infrastructure) - COMPLETE
Plan: 3 of 3 complete
Status: Phase complete
Last activity: 2026-01-17 - Completed 03-03-PLAN.md (Restore Procedure & Phase Verification)

Progress: ████████████████████░ 69% (11/16 plans across phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 11
- Average duration: ~2.5 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 - Foundation & Routing | 4/4 | ~8 min | ~2 min |
| 2 - VPN & Production Readiness | 4/4 | ~10 min | ~2.5 min |
| 3 - Operational Infrastructure | 3/3 | ~11 min | ~3.7 min |

## Accumulated Context

### Decisions

| Phase-Plan | Decision | Rationale |
|------------|----------|-----------|
| 03-03 | Volume naming convention search pattern | Handles both <stack>_<service>-data and <service>-data patterns |
| 03-03 | Interactive confirmation prompt | Destructive restore operation requires explicit user consent |
| 03-02 | Weekly backup Sunday 3 AM, 28-day retention | Low-activity time, 4 weeks recovery window |
| 03-02 | Push monitor for backup verification | 7-day heartbeat detects missed backups |
| 03-02 | Stop uptime-kuma during backup | Consistent SQLite volume state |
| 03-01 | Direct Docker socket mount for Uptime Kuma | Socket proxy lacks required endpoints for container monitoring |
| 03-01 | Backup stop label on containers | Enables safe volume backups by stopping container before backup |
| 02-01 | Host-level Tailscale (not containerized) | Simpler, more robust; Tailscale is infrastructure like OS |
| 02-01 | Dual access (local + VPN) instead of VPN-only | User prefers local network access; VPN for remote only |
| 01-01 | External Docker networks via Makefile | Cross-stack communication requires networks created outside compose files |
| 01-01 | DNS-only mode for Cloudflare | Traefik handles SSL termination directly; proxy would interfere |
| 01-01 | Wildcard DNS *.ragnalab.xyz | Single A record covers all future subdomains |
| 01-02 | Socket proxy endpoint (tcp://socket-proxy:2375) | Security best practice - never mount Docker socket directly |
| 01-02 | Let's Encrypt staging server first | Avoid rate limits during testing |
| 01-02 | Restrictive CSP default | Apps needing relaxed CSP define their own middleware |
| 01-02 | Two rate limit tiers (100/s, 10/s) | Standard for most endpoints, strict for sensitive ones |
| 01-03 | Socket proxy with POST=0 | Read-only Docker API access - Traefik can discover but not modify |
| 01-03 | Traefik no-new-privileges | Prevents privilege escalation attacks in container |
| 01-03 | traefik.docker.network=proxy label required | Critical for routing - tells Traefik which network to use |
| 01-04 | No CSP on Traefik dashboard | CSP blocks dashboard's inline scripts; internal admin tool, VPN-protected |
| 01-04 | Makefile for service management | Auto-discovers apps in apps/*/, better for 40+ services than compose includes |

### Pending Todos

(None)

### Deferred Improvements

| Item | Priority | Notes |
|------|----------|-------|
| Notification channel for Uptime Kuma | Medium | Add Ntfy/Telegram/email alerts when services go down |
| Backup encryption | Medium | docker-volume-backup supports encryption; protects against disk theft |
| Template for new apps | Phase 4 | `apps/_template/` with starter docker-compose.yml |
| Offsite backup | Low | 3-2-1 not complete; single disk failure = data loss |
| Log viewer (Dozzle) | v2 | Web UI for viewing all container logs |
| Postgres backup strategy | Future | Use pg_dump for databases, not volume snapshots |

### Blockers/Concerns

(None)

### Documentation Rules

| File | Purpose |
|------|---------|
| README.md | Project overview, structure, daily commands, quick reference |
| INSTALL.md | Complete fresh-install walkthrough, all manual/UI setup steps |

**Rule:** Any new feature or manual setup must update INSTALL.md. README.md only needs updates for new daily commands or structure changes.

## Session Continuity

Last session: 2026-01-17
Stopped at: Completed 03-03-PLAN.md (Restore Procedure & Phase Verification) - Phase 3 COMPLETE
Resume file: None
