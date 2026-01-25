# Phase 10: Existing App Integration - Research

**Researched:** 2026-01-25
**Domain:** Traefik ForwardAuth middleware, *arr apps External auth, qBittorrent reverse proxy, service-specific auth settings
**Confidence:** HIGH

## Summary

This phase integrates all existing applications with Authelia SSO by adding the ForwardAuth middleware to Traefik router labels. The implementation is straightforward for most services - adding a single middleware label. For *arr apps (Sonarr, Radarr, Prowlarr), the "External" authentication mode must be set in config.xml to avoid double login. qBittorrent requires IP whitelist configuration since it runs inside the gluetun container and sees the reverse proxy IP. Services without built-in auth (Homepage, Glances) work immediately with middleware. Services with built-in auth (Uptime Kuma, Backrest) should have their auth disabled to avoid double login.

The existing Authelia access control rules already define policies for each service. The ForwardAuth middleware `authelia@file` is already configured in Traefik's middlewares.yml. API bypass rules are in place for mobile apps and widgets. The main work is adding the middleware label to each service's docker-compose.yml.

**Primary recommendation:** Add `traefik.http.routers.{service}.middlewares=authelia@file` to each service, configure *arr apps with `<AuthenticationMethod>External</AuthenticationMethod>` in config.xml, and configure qBittorrent with reverse proxy IP whitelist.

## Standard Stack

No additional libraries needed. This phase uses existing infrastructure:

### Core (Already Deployed)
| Component | Version | Purpose | Status |
|-----------|---------|---------|--------|
| Authelia | 4.39.14 | SSO/2FA portal | Running at auth.ragnalab.xyz |
| Traefik | v3.6 | Reverse proxy with ForwardAuth | Running with middleware defined |
| ForwardAuth middleware | authelia@file | Middleware for protected services | Defined in middlewares.yml |

### Services to Protect
| Service | Auth Mode | Approach |
|---------|-----------|----------|
| Homepage | None | Add middleware only |
| Traefik dashboard | None | Add middleware only |
| Glances | None (no password set) | Add middleware only |
| Uptime Kuma | Built-in auth | Disable auth + add middleware |
| Backrest | Built-in auth | Disable auth + add middleware |
| Sonarr | Forms auth | External mode + add middleware |
| Radarr | Forms auth | External mode + add middleware |
| Prowlarr | Forms auth | External mode + add middleware |
| qBittorrent | Built-in auth | IP whitelist + add middleware to gluetun |

## Architecture Patterns

### Pattern 1: Simple Middleware Addition

**What:** Add ForwardAuth middleware to existing Traefik router labels
**When to use:** Services without built-in auth (Homepage, Glances) or where existing auth can remain (not conflicting)
**Example:**

```yaml
# Source: Existing docker-compose.yml pattern + Authelia middleware
labels:
  # Existing routing labels (keep as-is)
  - "traefik.enable=true"
  - "traefik.http.routers.homepage.rule=Host(`home.ragnalab.xyz`)"
  - "traefik.http.routers.homepage.entrypoints=websecure"
  - "traefik.http.routers.homepage.tls=true"
  - "traefik.http.routers.homepage.tls.certresolver=letsencrypt"
  - "traefik.http.services.homepage.loadbalancer.server.port=3000"
  # ADD THIS LINE - ForwardAuth middleware
  - "traefik.http.routers.homepage.middlewares=authelia@file"
  - "traefik.docker.network=proxy"
```

### Pattern 2: Disable Built-in Auth + Middleware

**What:** Disable the app's built-in authentication and rely on Authelia
**When to use:** Services with their own login page that would cause double login (Uptime Kuma, Backrest)
**Example:**

```yaml
# Uptime Kuma: Disable auth in Settings -> Advanced -> Disable Auth
# Then add middleware to docker-compose.yml:
labels:
  - "traefik.http.routers.uptime-kuma.middlewares=authelia@file"
```

### Pattern 3: *arr Apps External Auth Mode

**What:** Set AuthenticationMethod to External in config.xml, then add middleware
**When to use:** Sonarr, Radarr, Prowlarr (LinuxServer.io images)
**Steps:**
1. Stop the container
2. Edit config.xml: `<AuthenticationMethod>External</AuthenticationMethod>`
3. Add middleware label
4. Restart container

**Config.xml location:** `/config/config.xml` inside container (mapped to volume)

```xml
<!-- Source: https://wiki.servarr.com/sonarr/faq-v4 -->
<Config>
  <!-- Change from 'Forms' to 'External' -->
  <AuthenticationMethod>External</AuthenticationMethod>
  <!-- Keep other settings -->
</Config>
```

**Important:** Only the TOPMOST `<AuthenticationMethod>` is used if multiple exist. Remove any duplicates.

### Pattern 4: qBittorrent Reverse Proxy Whitelist

**What:** Configure qBittorrent to trust the reverse proxy IP and bypass auth for whitelisted IPs
**When to use:** qBittorrent (runs inside gluetun container with network isolation)
**Gotcha:** qBittorrent sees the gluetun/Traefik IP, not the real client IP

**qBittorrent.conf settings (inside config volume):**

```ini
# Source: https://github.com/qbittorrent/qBittorrent/wiki/NGINX-Reverse-Proxy-for-Web-UI
[Preferences]
# Enable reverse proxy support to trust X-Forwarded-For header
WebUI\ReverseProxySupportEnabled=true
# List of trusted reverse proxy IPs (gluetun's docker network)
WebUI\TrustedReverseProxiesList=172.0.0.0/8
# Whitelist the reverse proxy subnet to bypass qBittorrent's auth
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\AuthSubnetWhitelist=172.0.0.0/8
# Disable CSRF protection (reverse proxy handles security)
WebUI\CSRFProtection=false
# Disable host header validation (behind reverse proxy)
WebUI\HostHeaderValidation=false
# Disable IP banning (could ban the proxy IP)
WebUI\MaxAuthenticationFailCount=0
```

**Note:** The `172.0.0.0/8` range covers Docker bridge networks. Adjust to your actual Docker network CIDR if needed.

### Anti-Patterns to Avoid

- **Double authentication:** Adding middleware without disabling app's built-in auth causes users to authenticate twice
- **Forgetting API bypass:** Mobile apps and widgets need API paths bypassed (already configured in Authelia)
- **Editing running container configs:** Always stop container before editing config.xml or qBittorrent.conf
- **Multiple AuthenticationMethod entries:** In *arr config.xml, only the first entry is used

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Service authentication | Custom auth per service | Authelia ForwardAuth | SSO across all services |
| Middleware chaining | Multiple separate middlewares | authelia@file (already chains rate-limit) | Simpler config |
| API auth bypass | Per-service API key management | Authelia bypass rules | Centralized in Authelia config |
| User login pages | Per-app login forms | Authelia portal redirect | Consistent UX |

**Key insight:** ForwardAuth middleware handles everything - the protected app doesn't need to know about auth at all. It just receives authenticated requests with Remote-User headers.

## Common Pitfalls

### Pitfall 1: Autokuma HTTP Checks Fail After Middleware Added

**What goes wrong:** Autokuma makes HTTP requests to monitor services. After adding authelia@file middleware, these checks return 401/302 redirects instead of 200.
**Why it happens:** Autokuma's HTTP checks don't have Authelia session cookies.
**How to avoid:**
- Autokuma runs inside Docker network and can reach services directly via container name
- Use internal URLs in Autokuma labels: `kuma.service.http.url=http://container:port`
- OR add Autokuma's IP to Authelia bypass rules (less ideal)
**Warning signs:** Monitors show DOWN after adding middleware

**Verification:** Check existing Autokuma labels - they already use internal URLs like `http://sonarr:8989` so this should NOT be an issue.

### Pitfall 2: *arr Config.xml Has Multiple AuthenticationMethod Entries

**What goes wrong:** Setting External auth doesn't work; app still shows login page.
**Why it happens:** Config.xml can have duplicate keys; only the first is read.
**How to avoid:** Search for ALL `<AuthenticationMethod>` entries and remove duplicates.
**Warning signs:** App shows login page despite External setting

```bash
# Find all AuthenticationMethod entries
docker exec sonarr grep -n "AuthenticationMethod" /config/config.xml
```

### Pitfall 3: qBittorrent IP Banning Locks Out Reverse Proxy

**What goes wrong:** After failed auth attempts, qBittorrent bans the reverse proxy IP (172.x.x.x).
**Why it happens:** qBittorrent sees proxy IP, not real client IP, and bans it.
**How to avoid:** Set `WebUI\MaxAuthenticationFailCount=0` to disable banning.
**Warning signs:** "WebAPI login failure. Reason: IP has been banned, IP: 172.x.x.x"

### Pitfall 4: Homepage HOMEPAGE_ALLOWED_HOSTS Blocks Authelia Redirect

**What goes wrong:** Authelia redirects fail with CORS or host validation errors.
**Why it happens:** Homepage validates the Host header; Authelia uses different host during redirect.
**How to avoid:** Already handled - HOMEPAGE_ALLOWED_HOSTS=home.ragnalab.xyz is set. No change needed.
**Warning signs:** Error about invalid host header

### Pitfall 5: Uptime Kuma WebSocket Connection Fails

**What goes wrong:** Uptime Kuma dashboard loads but real-time updates don't work.
**Why it happens:** ForwardAuth can interfere with WebSocket upgrade if not configured properly.
**How to avoid:** Already handled - Authelia's ForwardAuth passes WebSocket upgrades correctly.
**Warning signs:** Dashboard shows but status doesn't update in real-time

### Pitfall 6: Forgetting to Restart After Config Changes

**What goes wrong:** Config changes don't take effect.
**Why it happens:** *arr apps, qBittorrent only read config on startup.
**How to avoid:** Always restart container after config.xml or qBittorrent.conf changes.
**Warning signs:** Old behavior persists despite config change

## Code Examples

### Adding Middleware to Simple Services (Homepage, Glances, Traefik Dashboard)

```yaml
# Homepage: Add single middleware label
labels:
  - "traefik.http.routers.homepage.middlewares=authelia@file"

# Glances: Add single middleware label
labels:
  - "traefik.http.routers.glances.middlewares=authelia@file"

# Traefik dashboard: Add single middleware label
labels:
  - "traefik.http.routers.dashboard.middlewares=authelia@file"
```

### Uptime Kuma: Disable Auth Then Add Middleware

1. Access Uptime Kuma UI at https://status.ragnalab.xyz
2. Go to Settings -> Advanced -> Disable Auth
3. Confirm by entering current password
4. Add middleware label to docker-compose.yml:

```yaml
labels:
  - "traefik.http.routers.uptime-kuma.middlewares=authelia@file"
```

### Backrest: Disable Auth Then Add Middleware

1. Access Backrest UI at https://backups.ragnalab.xyz
2. During initial setup or in settings, choose to disable authentication
3. Add middleware label to docker-compose.yml:

```yaml
labels:
  - "traefik.http.routers.backrest.middlewares=authelia@file"
```

### *arr Apps (Sonarr, Radarr, Prowlarr): External Auth Mode

```bash
# Stop the container
docker stop sonarr

# Edit config.xml (via docker volume or bind mount)
# For LinuxServer.io images, config is at /config/config.xml
# Find existing AuthenticationMethod and change to External:
# <AuthenticationMethod>External</AuthenticationMethod>

# Verify only ONE AuthenticationMethod entry exists
docker exec sonarr cat /config/config.xml | grep AuthenticationMethod

# Start container
docker start sonarr
```

**Sample config.xml change:**

```xml
<!-- Before -->
<AuthenticationMethod>Forms</AuthenticationMethod>

<!-- After -->
<AuthenticationMethod>External</AuthenticationMethod>
```

### qBittorrent: Reverse Proxy Configuration

Edit `qBittorrent.conf` at `/config/qBittorrent/qBittorrent.conf`:

```ini
[Preferences]
WebUI\ReverseProxySupportEnabled=true
WebUI\TrustedReverseProxiesList=172.0.0.0/8
WebUI\AuthSubnetWhitelistEnabled=true
WebUI\AuthSubnetWhitelist=172.0.0.0/8
WebUI\CSRFProtection=false
WebUI\HostHeaderValidation=false
WebUI\MaxAuthenticationFailCount=0
```

Then add middleware label to gluetun (which handles qBittorrent's routing):

```yaml
# On gluetun service (not qbittorrent - it uses gluetun's network)
labels:
  - "traefik.http.routers.qbittorrent.middlewares=authelia@file"
```

## Order of Operations

Recommended implementation order to minimize disruption:

### Phase 1: Simple Services (No Config Changes)
1. **Homepage** - Add middleware, test SSO redirect
2. **Glances** - Add middleware, verify system stats visible after auth
3. **Traefik dashboard** - Add middleware, verify dashboard access

### Phase 2: Services Requiring Auth Disable
4. **Uptime Kuma** - Disable built-in auth first, then add middleware
5. **Backrest** - Disable built-in auth first, then add middleware

### Phase 3: *arr Apps (Config.xml Changes)
6. **Prowlarr** - Stop, edit config.xml, add middleware, start
7. **Sonarr** - Stop, edit config.xml, add middleware, start
8. **Radarr** - Stop, edit config.xml, add middleware, start

### Phase 4: Complex Configuration
9. **qBittorrent** - Edit qBittorrent.conf, add middleware to gluetun, restart

**Rationale:** Start with services that require no config changes to validate the middleware approach. Then progress to services requiring manual auth disable (can be done in UI). Finally tackle *arr apps and qBittorrent which require container stops and config file edits.

## Testing Approach

### For Each Service After Adding Middleware:

1. **Clear browser session** - Logout from Authelia or use incognito
2. **Navigate to service URL** - Should redirect to auth.ragnalab.xyz
3. **Complete Authelia login** - Password + passkey 2FA
4. **Verify redirect back** - Should land on original service
5. **Check SSO persistence** - Navigate to another protected service, should NOT require re-login
6. **Test logout** - Logout from Authelia, verify service access blocked

### For *arr Apps Specifically:

1. **Verify no login page** - Should go directly to UI after Authelia auth
2. **Check API access** - Homepage widgets should still work (uses internal URL)
3. **Test mobile app** - LunaSea or similar should work via API bypass

### For qBittorrent Specifically:

1. **Check Traefik logs** - Verify requests forwarded correctly
2. **Test download** - Add a torrent, verify it starts
3. **Check port-manager** - Verify forwarded port still syncs

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Per-app authentication | ForwardAuth SSO | Standard practice | Single login for all services |
| *arr Basic auth | External auth mode | *arr v4+ | Clean SSO integration |
| qBittorrent plain auth | Reverse proxy whitelist | qBittorrent 4.1+ | Works with external auth |

**Current best practice:** All services behind ForwardAuth middleware, apps configured to trust external authentication headers. API paths bypassed for programmatic access.

## Open Questions

1. **Autokuma monitoring URLs**
   - What we know: Labels use internal URLs like `http://sonarr:8989`
   - What's unclear: Do any labels use external URLs that would fail with middleware?
   - Recommendation: Verify all kuma.*.http.url labels use internal container URLs before deployment

2. **Homepage widget API access**
   - What we know: Homepage uses internal URLs like `http://sonarr:8989` with API keys
   - What's unclear: Will Authelia's API bypass rules interfere?
   - Recommendation: Bypass rules match `/api/*` which should cover widget calls

3. **qBittorrent Docker network CIDR**
   - What we know: Docker uses 172.x.x.x range for bridge networks
   - What's unclear: Exact CIDR for the media network
   - Recommendation: Use broad 172.0.0.0/8 or check `docker network inspect media` for precise range

## Sources

### Primary (HIGH confidence)
- [Servarr Wiki - Sonarr v4 FAQ](https://wiki.servarr.com/sonarr/faq-v4) - External auth mode documentation
- [qBittorrent Wiki - NGINX Reverse Proxy](https://github.com/qbittorrent/qBittorrent/wiki/NGINX-Reverse-Proxy-for-Web-UI) - Reverse proxy settings
- [Authelia Traefik Integration](https://www.authelia.com/integration/proxies/traefik/) - ForwardAuth configuration
- [Uptime Kuma Wiki - Reverse Proxy](https://github.com/louislam/uptime-kuma/wiki/Reverse-Proxy) - Trust Proxy settings

### Secondary (MEDIUM confidence)
- [Authentik Sonarr Integration](https://integrations.goauthentik.io/services/sonarr/) - External auth pattern (applies to Authelia)
- [Authentik Uptime Kuma Integration](https://integrations.goauthentik.io/monitoring/uptime-kuma/) - Disable built-in auth pattern
- [Backrest Getting Started](https://garethgeorge.github.io/backrest/introduction/getting-started/) - Auth disable option
- [qBittorrent Issue #15582](https://github.com/qbittorrent/qBittorrent/issues/15582) - Whitelist behind reverse proxy

### Tertiary (LOW confidence)
- [Sonarr Forums - External Auth](https://forums.sonarr.tv/t/solved-external-auth-disable-authentication-for-all-addresses/33526) - Community discussion
- [Authelia Discussion #3497](https://github.com/authelia/authelia/discussions/3497) - Uptime Kuma monitoring protected services

## Metadata

**Confidence breakdown:**
- Adding middleware labels: HIGH - Standard Traefik pattern, documented
- *arr External auth: HIGH - Official wiki documentation
- qBittorrent config: MEDIUM - Multiple sources agree, some version-specific nuances
- Uptime Kuma disable auth: HIGH - Official wiki and Authentik integration docs
- Backrest disable auth: MEDIUM - Getting started docs mention it, no detailed guide
- Autokuma compatibility: MEDIUM - Should work with internal URLs, needs verification

**Research date:** 2026-01-25
**Valid until:** 30 days (stable patterns, no expected breaking changes)
