---
created: 2026-01-18T12:15
title: Create bootstrap scripts for arr stack initial configuration
area: automation
files:
  - stack/media/
---

## Problem

When arr stack containers are freshly deployed (volumes deleted/recreated), manual configuration is required:
- Sonarr, Radarr, Prowlarr, Bazarr need auth, API keys, download clients configured
- Jellyfin needs setup wizard completed, libraries created
- Jellyseerr needs Jellyfin integration configured
- Currently relying on Claude to run API-based setup commands each time

Claude already configured these services via API during initial deployment (06-01 through 06-08 plans), proving API-based automation is possible. The API keys end up in .env files for future use.

This creates friction when:
- Full stack redeploy needed
- New environment setup
- Disaster recovery from backup failure
- Adding new arr services

## Solution

Create persistent bootstrap scripts that run the same API-based configuration Claude used:

1. **Per-service bootstrap scripts** in each service folder:
   - `stack/media/sonarr/bootstrap.sh` - auth, download client, root folder
   - `stack/media/radarr/bootstrap.sh` - auth, download client, root folder
   - `stack/media/prowlarr/bootstrap.sh` - auth, app syncs
   - `stack/media/bazarr/bootstrap.sh` - auth, subtitle providers
   - `stack/media/jellyfin/bootstrap.sh` - setup wizard, libraries
   - `stack/media/jellyseerr/bootstrap.sh` - Jellyfin integration

2. **Master bootstrap script** `stack/media/bootstrap-all.sh`:
   - Waits for each service to be healthy
   - Runs individual bootstrap scripts in dependency order
   - Sources .env for API keys/credentials
   - Idempotent (safe to re-run)

3. **Makefile target** `make bootstrap-media`:
   - Convenience wrapper for full stack bootstrap

Reference: API calls used in 06-* plan executions.
