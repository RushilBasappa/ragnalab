# Phase 7: Operational Hardening - Context

**Gathered:** 2026-01-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete backup coverage, eliminate direct Docker socket exposure, automate monitoring with Autokuma, and restructure Docker Compose for cleaner operations. This includes:
- Audit and extend backup coverage
- Socket-proxy migration for Uptime Kuma and Homepage
- Deploy Autokuma for automated monitoring
- Restructure to root-level `docker compose` with includes
- Simplify Makefile to operational essentials (backup, restore, status)

</domain>

<decisions>
## Implementation Decisions

### Compose Restructuring
- Group services by category: `infra/`, `media/`, `apps/` — each has its own compose that includes its services
- Use Docker Compose profiles: `infra`, `media`, `apps` — matches directory categories
- Profiles required to bring up services: `docker compose --profile media up`
- Shared resources (networks, common volumes) defined in `infra/docker-compose.yml`, referenced by other composes
- Root-level `docker-compose.yml` uses `include` directive to pull in category composes

### Makefile Targets
- Keep it minimal: only `backup`, `restore`, `status` targets
- `make backup`: Full workflow — stop services if needed, backup, verify, upload to offsite, report status
- `make restore`: Interactive selection — list available backups, prompt user to select which to restore
- `make status`: Summary overview with drill-down — quick view by default, `make status SERVICE=media` for detailed view
- No `up`/`down` targets — that's now `docker compose` responsibility

### Socket-proxy Migration
- Migrate Uptime Kuma and Homepage simultaneously (all at once) — brief downtime acceptable
- Claude to verify if socket-proxy already exists (Traefik may already use it)
- All services needing Docker API access must use socket-proxy, never direct docker.sock mount

### Claude's Discretion
- Docker API permission levels for Homepage and Uptime Kuma (minimum required per service)
- Socket-proxy verification approach (script vs manual review)
- Autokuma monitor strategy (HTTP, container health, TCP ports, label conventions)
- How to handle services during backup (which need stopping vs hot backup)

</decisions>

<specifics>
## Specific Ideas

- User wants to move away from `make up`/`make down` pattern to standard `docker compose` commands
- Profiles should match directory structure for easy mental model
- Makefile becomes purely operational — "things that matter: backup, restore, status"

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 07-operational-hardening*
*Context gathered: 2026-01-18*
