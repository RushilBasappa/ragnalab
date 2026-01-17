# Project State

## Project Reference

See: .planning/PROJECT.md

**Core value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.
**Current focus:** Phase 2 - VPN & Production Readiness

## Current Position

Phase: 2 of 4 (VPN & Production Readiness)
Plan: Not started
Status: Ready to plan
Last activity: 2026-01-17 - Completed Phase 1

Progress: ████████░░░░░░░░░░░░ 25% (1/4 phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 4
- Average duration: ~2 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1 - Foundation & Routing | 4/4 ✓ | ~8 min | ~2 min |

## Accumulated Context

### Decisions

| Phase-Plan | Decision | Rationale |
|------------|----------|-----------|
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

### Blockers/Concerns

(None)

## Session Continuity

Last session: 2026-01-17
Stopped at: Phase 1 complete, ready for Phase 2
Resume file: None
