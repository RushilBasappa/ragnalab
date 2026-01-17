# Phase 3: Operational Infrastructure - Context

**Gathered:** 2026-01-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Platform has automated backups, health monitoring, and operational observability before deploying critical services. Includes Uptime Kuma dashboard, automated backup with 3-2-1 strategy, tested restore capability, and infrastructure configs in git.

</domain>

<decisions>
## Implementation Decisions

### Backup Strategy
- Docker volumes only (not compose files or .planning/)
- Weekly backup schedule
- Per-service backups (each app's volumes backed up separately for granular restore)
- Local storage in a `backups/` folder (no offsite upload)
- Alert via Uptime Kuma on backup failure, plus logging

### Monitoring Scope
- Full stack monitoring: web services (HTTPS), Docker containers, and host metrics (CPU/memory/disk)
- Check interval: every 5 minutes
- Status page private (VPN only, like other services)

### Dashboard Layout
- Services organized by category (not flat list)

### Restore Workflow
- Both granular (individual service) and full platform restore options
- Restore must be tested and verified as part of this phase
- Documented restore procedure

### Claude's Discretion
- Backup retention policy (reasonable default)
- Backup tooling approach (container-based vs host scripts)
- Encryption decision for backups (based on what's being backed up)
- Notification method for alerts (push vs email vs dashboard)
- Dashboard categories (logical groupings based on deployed services)
- Uptime history display settings
- Whether to add external meta-monitoring for Uptime Kuma
- Restore trigger mechanism (script vs documented procedure)
- Documentation depth for restore procedures

</decisions>

<specifics>
## Specific Ideas

- Backup alerts should go through Uptime Kuma (user specifically mentioned this for failure notifications)
- Per-service backup granularity was important — enables restoring just one app without touching others

</specifics>

<deferred>
## Deferred Ideas

- **Postgres backup strategy** — When adding Postgres databases, use pg_dump-based logical backups (e.g., prodrigestivill/postgres-backup-local) instead of volume snapshots. Logical backups allow no-downtime backups and portable restores. Current volume backup approach works for file-based services but isn't ideal for databases.

</deferred>

---

*Phase: 03-operational-infrastructure*
*Context gathered: 2026-01-17*
