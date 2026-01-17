# Backlog

**Project:** RagnaLab
**Created:** 2026-01-17 (from v1.0 milestone deferred items)

## Priority: Medium

### Notification Channel for Uptime Kuma
**Source:** v1.0 deferred
**Description:** Add Ntfy/Telegram/email alerts when services go down
**Why deferred:** Core monitoring works; notifications are enhancement
**Effort:** Small (1 plan)

### Backup Encryption
**Source:** v1.0 deferred
**Description:** docker-volume-backup supports encryption; protects against disk theft
**Why deferred:** Backups working; encryption adds complexity
**Effort:** Small (1 plan)

## Priority: Low

### Offsite Backup
**Source:** v1.0 deferred
**Description:** 3-2-1 strategy not complete; single disk failure = data loss. Add cloud upload (S3, Backblaze, etc.)
**Why deferred:** Local backups sufficient for initial deployment
**Effort:** Medium (1-2 plans)

## Priority: v2

### Log Viewer (Dozzle)
**Source:** v1.0 deferred
**Description:** Web UI for viewing all container logs in one place
**Why deferred:** CLI logs work; Dozzle is nice-to-have
**Effort:** Small (1 plan)

### Postgres Backup Strategy
**Source:** v1.0 deferred
**Description:** Use pg_dump for databases, not volume snapshots. Volume snapshots can corrupt running databases.
**Why deferred:** No Postgres services in v1.0
**Effort:** Medium (research + implementation)

## Tech Debt

### Phase 2 Verification
**Source:** v1.0 audit
**Description:** Phase 02-vpn-production-readiness executed but no VERIFICATION.md created
**Impact:** Low — functionality verified by integration checker
**Resolution:** Create retroactive verification or accept as documented

---

## Completed

(Items moved here when done)

---

*Created from v1.0 milestone completion*
