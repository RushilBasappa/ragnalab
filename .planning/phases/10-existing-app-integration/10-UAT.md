---
status: complete
phase: 10-existing-app-integration
source: [10-01-SUMMARY.md, 10-02-SUMMARY.md, 10-03-SUMMARY.md, 10-04-SUMMARY.md]
started: 2026-01-25T17:00:00Z
updated: 2026-01-25T17:05:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Homepage SSO Protection
expected: Opening https://home.ragnalab.xyz in incognito redirects to auth.ragnalab.xyz login page. After logging in, you see the Homepage dashboard.
result: pass

### 2. Glances SSO Protection
expected: Opening https://glances.ragnalab.xyz in incognito redirects to Authelia. After login, Glances system monitor loads directly.
result: pass

### 3. Traefik Dashboard SSO Protection
expected: Opening https://traefik.ragnalab.xyz in incognito redirects to Authelia. After login, Traefik dashboard loads directly.
result: pass

### 4. Uptime Kuma SSO Protection
expected: Opening https://status.ragnalab.xyz in incognito redirects to Authelia. After login, Uptime Kuma loads directly (no Uptime Kuma login form).
result: pass

### 5. Backrest SSO Protection
expected: Opening https://backups.ragnalab.xyz in incognito redirects to Authelia. After login, Backrest loads directly (no Backrest login form).
result: pass

### 6. Prowlarr SSO Protection (External Auth)
expected: Opening https://prowlarr.ragnalab.xyz in incognito redirects to Authelia. After login, Prowlarr UI appears (no Forms login page, External auth mode).
result: pass

### 7. Sonarr SSO Protection (External Auth)
expected: Opening https://sonarr.ragnalab.xyz in incognito redirects to Authelia. After login, Sonarr UI appears directly (no second login).
result: pass

### 8. Radarr SSO Protection (External Auth)
expected: Opening https://radarr.ragnalab.xyz in incognito redirects to Authelia. After login, Radarr UI appears directly (no second login).
result: pass

### 9. qBittorrent SSO Protection
expected: Opening https://qbit.ragnalab.xyz in incognito redirects to Authelia. After login, qBittorrent WebUI appears directly (no qBittorrent login prompt).
result: pass

### 10. SSO Session Persistence
expected: After logging into any protected service, other protected services (home, status, sonarr, etc.) load without requiring another login.
result: pass

### 11. Homepage Widget Functionality
expected: Homepage dashboard shows working widgets for Sonarr, Radarr, Prowlarr, qBittorrent (stats display, not broken/empty).
result: pass

## Summary

total: 11
passed: 11
issues: 0
pending: 0
skipped: 0

## Gaps

[none yet]
