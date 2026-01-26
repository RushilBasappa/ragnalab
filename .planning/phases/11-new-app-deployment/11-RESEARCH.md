# Phase 11: New App Deployment - Research

**Researched:** 2026-01-25
**Domain:** Paperless-ngx trusted header SSO, Dozzle forward-proxy auth, IT-Tools forwardAuth, Homepage widgets, Autokuma labels
**Confidence:** HIGH

## Summary

This phase deploys three new applications with SSO protection from day one using Authelia ForwardAuth middleware. Each app has a different authentication integration pattern:

1. **Paperless-ngx** uses trusted header authentication - it reads the `Remote-User` header passed by Authelia and creates/authenticates users automatically. This requires specific environment variables and an initial superuser for first-time setup.

2. **Dozzle** uses forward-proxy authentication - it expects `Remote-User`, `Remote-Email`, and `Remote-Name` headers from Authelia, enabled via `DOZZLE_AUTH_PROVIDER=forward-proxy`. Dozzle needs read access to Docker API for container logs.

3. **IT-Tools** is a static client-side application with no built-in authentication - simply adding the `authelia@file` middleware protects it completely.

All three Docker images support ARM64 architecture (verified via manifest inspection). The existing `authelia@file` middleware already passes the required headers. Homepage integration varies: Paperless-ngx has a dedicated widget, while Dozzle and IT-Tools use basic service links only (no widgets).

**Primary recommendation:** Deploy all three apps with `authelia@file` middleware, configure Paperless-ngx with HTTP remote user variables, configure Dozzle with forward-proxy auth provider, and use socket-proxy for Dozzle's Docker API access.

## Standard Stack

### Core Images (All ARM64 Compatible)

| Image | Version | Architecture | Purpose |
|-------|---------|--------------|---------|
| `ghcr.io/paperless-ngx/paperless-ngx` | latest | amd64, arm64 | Document management |
| `amir20/dozzle` | latest | amd64, arm64, armv7 | Docker log viewer |
| `corentinth/it-tools` | latest | amd64, arm64 | Developer utilities |
| `redis:7` | 7 | amd64, arm64 | Required by Paperless-ngx |

### Supporting Components

| Component | Purpose | Notes |
|-----------|---------|-------|
| Redis | Paperless-ngx task queue | Required - handles async tasks |
| Socket-proxy | Docker API for Dozzle | Already deployed, may need LOGS access |

### Existing Infrastructure Used

| Component | Already Configured |
|-----------|-------------------|
| Authelia middleware | `authelia@file` with Remote-User headers |
| Socket-proxy | CONTAINERS=1, EVENTS=1, INFO=1 |
| Traefik | ForwardAuth with header passthrough |
| Homepage | Docker label discovery enabled |
| Autokuma | Docker label discovery enabled |

## Architecture Patterns

### Pattern 1: Trusted Header SSO (Paperless-ngx)

**What:** App reads authenticated username from HTTP header set by Authelia
**When to use:** Apps that support `HTTP_REMOTE_USER` authentication
**Authelia Response Headers Required:** `Remote-User`

```yaml
# Paperless-ngx docker-compose.yml
services:
  paperless-webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    environment:
      # SSO via trusted header
      PAPERLESS_ENABLE_HTTP_REMOTE_USER: "true"
      PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME: "HTTP_REMOTE_USER"
      PAPERLESS_LOGOUT_REDIRECT_URL: "https://auth.ragnalab.xyz/logout"
      # Auto-create superuser on first start
      PAPERLESS_ADMIN_USER: ${PAPERLESS_ADMIN_USER}
      PAPERLESS_ADMIN_PASSWORD: ${PAPERLESS_ADMIN_PASSWORD}
      # URL configuration for reverse proxy
      PAPERLESS_URL: "https://docs.ragnalab.xyz"
      # Redis broker
      PAPERLESS_REDIS: "redis://paperless-redis:6379"
    labels:
      - "traefik.http.routers.paperless.middlewares=authelia@file"
```

**Key Points:**
- Header `Remote-User` becomes `HTTP_REMOTE_USER` in Django
- User accounts created automatically from SSO username
- Initial superuser needed for admin tasks before SSO users exist
- Logout redirects to Authelia for complete session termination

### Pattern 2: Forward Proxy Auth (Dozzle)

**What:** App reads multiple authentication headers for user identity and roles
**When to use:** Apps with built-in forward-proxy auth mode
**Authelia Response Headers Required:** `Remote-User`, `Remote-Email`, `Remote-Name`

```yaml
# Dozzle docker-compose.yml
services:
  dozzle:
    image: amir20/dozzle:latest
    environment:
      # Forward proxy authentication
      DOZZLE_AUTH_PROVIDER: "forward-proxy"
      DOZZLE_AUTH_LOGOUT_URL: "https://auth.ragnalab.xyz/logout"
      # Docker socket via proxy
      DOCKER_HOST: "tcp://socket-proxy:2375"
    labels:
      - "traefik.http.routers.dozzle.middlewares=authelia@file"
```

**Key Points:**
- Dozzle reads `Remote-User`, `Remote-Email`, `Remote-Name` headers automatically
- No user configuration file needed when using forward-proxy
- User preferences stored in `/data` volume
- Uses socket-proxy instead of raw Docker socket for security

### Pattern 3: Simple ForwardAuth (IT-Tools)

**What:** Static app protected purely by middleware, no app-level auth
**When to use:** Client-side apps with no authentication system
**Authelia Response Headers Required:** None (headers ignored)

```yaml
# IT-Tools docker-compose.yml
services:
  it-tools:
    image: corentinth/it-tools:latest
    labels:
      - "traefik.http.routers.it-tools.middlewares=authelia@file"
```

**Key Points:**
- Simplest pattern - just add middleware
- App has no concept of users
- All protection handled by Authelia
- User preferences stored in browser localStorage

### Recommended Project Structure

```
stack/apps/
├── docker-compose.yml          # Include pattern (add 3 new paths)
├── paperless/
│   └── docker-compose.yml      # Paperless + Redis
├── dozzle/
│   └── docker-compose.yml      # Dozzle with socket-proxy
└── it-tools/
    └── docker-compose.yml      # IT-Tools static app
```

### Anti-Patterns to Avoid

- **Mounting raw Docker socket to Dozzle:** Use socket-proxy for security
- **Skipping Redis for Paperless-ngx:** Required for task processing
- **Setting PAPERLESS_DISABLE_REGULAR_LOGIN too early:** Need local admin first
- **Using OIDC for Paperless-ngx:** Trusted headers are simpler for Authelia integration

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Paperless user sync | Custom user provisioning | Trusted header auto-create | Built-in feature |
| Docker log aggregation | Log shipping to external system | Dozzle direct access | Simpler, real-time |
| Developer tools | Individual tool containers | IT-Tools collection | 85+ tools in one container |
| Redis for Paperless | Use SQLite everywhere | Dedicated Redis container | Required for async tasks |

**Key insight:** All three apps have native support for the authentication pattern we're using. No custom code needed.

## Common Pitfalls

### Pitfall 1: Paperless-ngx First User Creation

**What goes wrong:** Can't access Paperless-ngx because no users exist and trusted header requires existing user
**Why it happens:** Trusted header auth maps to existing users, doesn't create them from headers
**How to avoid:**
1. Set `PAPERLESS_ADMIN_USER` and `PAPERLESS_ADMIN_PASSWORD` on first deployment
2. This creates initial superuser that matches Authelia username
3. Subsequent SSO logins will match or create users
**Warning signs:** HTTP 403 or redirect loop after Authelia auth

### Pitfall 2: Socket-Proxy Missing Access for Dozzle

**What goes wrong:** Dozzle can't fetch container logs
**Why it happens:** Socket-proxy restricts API access, logs accessed via CONTAINERS endpoint
**How to avoid:**
- Verify `CONTAINERS=1` is set (already configured)
- Verify `EVENTS=1` is set (already configured)
- Current socket-proxy config should work without changes
**Warning signs:** "Cannot connect to Docker daemon" or empty container list

### Pitfall 3: Paperless-ngx Redis Connection Failure

**What goes wrong:** Paperless-ngx starts but tasks don't process
**Why it happens:** Redis container not running or wrong connection string
**How to avoid:**
1. Deploy Redis in same Docker Compose as Paperless
2. Use Docker service name in connection string: `redis://paperless-redis:6379`
3. Both containers on same network
**Warning signs:** "Cannot connect to Redis" in logs, documents stuck in consume folder

### Pitfall 4: Dozzle AUTH_LOGOUT_URL Not Set

**What goes wrong:** User clicks logout in Dozzle but session remains active
**Why it happens:** Dozzle only clears its local state, Authelia session persists
**How to avoid:** Set `DOZZLE_AUTH_LOGOUT_URL=https://auth.ragnalab.xyz/logout`
**Warning signs:** Can immediately re-access Dozzle without Authelia login

### Pitfall 5: IT-Tools Blank Page Behind Reverse Proxy

**What goes wrong:** IT-Tools shows blank page or missing assets
**Why it happens:** Asset paths assume root deployment
**How to avoid:**
- Don't use `BASE_URL` unless deploying to subdirectory
- Ensure Traefik routes to port 80 (not 8080)
**Warning signs:** Console errors about missing JS/CSS files

### Pitfall 6: Autokuma HTTP Checks Return 401/302

**What goes wrong:** Autokuma marks new apps as DOWN after deployment
**Why it happens:** Autokuma HTTP checks hit external URL which requires Authelia auth
**How to avoid:**
- Use internal container URLs: `http://paperless:8000`, `http://dozzle:8080`
- Or use Docker container monitors instead of HTTP checks
**Warning signs:** Monitors flip to DOWN immediately after middleware added

## Code Examples

### Complete Paperless-ngx Docker Compose

```yaml
# stack/apps/paperless/docker-compose.yml
# Source: https://docs.paperless-ngx.com/setup/
# Source: https://www.authelia.com/integration/trusted-header-sso/paperless/

services:
  paperless-redis:
    image: redis:7
    container_name: paperless-redis
    restart: unless-stopped
    profiles: ["apps"]
    volumes:
      - paperless-redis-data:/data
    networks:
      - paperless-internal
    deploy:
      resources:
        limits:
          memory: 64M
          cpus: '0.1'

  paperless:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    container_name: paperless
    restart: unless-stopped
    profiles: ["apps"]
    depends_on:
      - paperless-redis
    environment:
      # User/permissions
      USERMAP_UID: 1000
      USERMAP_GID: 1000
      # Redis broker (required)
      PAPERLESS_REDIS: "redis://paperless-redis:6379"
      # URL configuration
      PAPERLESS_URL: "https://docs.ragnalab.xyz"
      # SSO via Authelia trusted header
      PAPERLESS_ENABLE_HTTP_REMOTE_USER: "true"
      PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME: "HTTP_REMOTE_USER"
      PAPERLESS_LOGOUT_REDIRECT_URL: "https://auth.ragnalab.xyz/logout"
      # Initial admin (matches Authelia username)
      PAPERLESS_ADMIN_USER: ${PAPERLESS_ADMIN_USER}
      PAPERLESS_ADMIN_PASSWORD: ${PAPERLESS_ADMIN_PASSWORD}
      # Performance tuning for Raspberry Pi
      PAPERLESS_WEBSERVER_WORKERS: 1
      PAPERLESS_OCR_MODE: "skip"
      PAPERLESS_OCR_SKIP_ARCHIVE_FILE: "with_text"
    volumes:
      - paperless-data:/usr/src/paperless/data
      - paperless-media:/usr/src/paperless/media
      - paperless-consume:/usr/src/paperless/consume
    networks:
      - proxy
      - paperless-internal
    labels:
      # Traefik routing
      - "traefik.enable=true"
      - "traefik.http.routers.paperless.rule=Host(`docs.ragnalab.xyz`)"
      - "traefik.http.routers.paperless.entrypoints=websecure"
      - "traefik.http.routers.paperless.tls=true"
      - "traefik.http.routers.paperless.tls.certresolver=letsencrypt"
      - "traefik.http.services.paperless.loadbalancer.server.port=8000"
      - "traefik.http.routers.paperless.middlewares=authelia@file"
      - "traefik.docker.network=proxy"
      # Homepage dashboard
      - "homepage.group=Applications"
      - "homepage.name=Paperless"
      - "homepage.icon=paperless-ngx.png"
      - "homepage.href=https://docs.ragnalab.xyz"
      - "homepage.description=Documents"
      - "homepage.widget.type=paperlessngx"
      - "homepage.widget.url=http://paperless:8000"
      - "homepage.widget.key=${PAPERLESS_API_KEY}"
      - "homepage.server=ragnalab-docker"
      # Autokuma monitoring
      - "kuma.paperless.http.name=Paperless"
      - "kuma.paperless.http.url=http://paperless:8000"
      - "kuma.paperless.http.parent_name=apps-group"
      # Backup
      - "docker-volume-backup.stop-during-backup=paperless"

volumes:
  paperless-redis-data:
    external: true
    name: ragnalab_paperless-redis-data
  paperless-data:
    external: true
    name: ragnalab_paperless-data
  paperless-media:
    external: true
    name: ragnalab_paperless-media
  paperless-consume:
    external: true
    name: ragnalab_paperless-consume

networks:
  proxy:
    external: true
  paperless-internal:
    # Internal network for Redis communication
```

### Complete Dozzle Docker Compose

```yaml
# stack/apps/dozzle/docker-compose.yml
# Source: https://dozzle.dev/guide/authentication

services:
  dozzle:
    image: amir20/dozzle:latest
    container_name: dozzle
    restart: unless-stopped
    profiles: ["apps"]
    environment:
      # Forward proxy authentication via Authelia
      DOZZLE_AUTH_PROVIDER: "forward-proxy"
      DOZZLE_AUTH_LOGOUT_URL: "https://auth.ragnalab.xyz/logout"
      # Docker API via socket-proxy
      DOCKER_HOST: "tcp://socket-proxy:2375"
      # UI settings
      DOZZLE_NO_ANALYTICS: "true"
    volumes:
      - dozzle-data:/data
    networks:
      - proxy
      - socket_proxy_network
    labels:
      # Traefik routing
      - "traefik.enable=true"
      - "traefik.http.routers.dozzle.rule=Host(`logs.ragnalab.xyz`)"
      - "traefik.http.routers.dozzle.entrypoints=websecure"
      - "traefik.http.routers.dozzle.tls=true"
      - "traefik.http.routers.dozzle.tls.certresolver=letsencrypt"
      - "traefik.http.services.dozzle.loadbalancer.server.port=8080"
      - "traefik.http.routers.dozzle.middlewares=authelia@file"
      - "traefik.docker.network=proxy"
      # Homepage dashboard
      - "homepage.group=Infrastructure"
      - "homepage.name=Dozzle"
      - "homepage.icon=dozzle.png"
      - "homepage.href=https://logs.ragnalab.xyz"
      - "homepage.description=Container Logs"
      - "homepage.server=ragnalab-docker"
      # Autokuma monitoring
      - "kuma.dozzle.http.name=Dozzle"
      - "kuma.dozzle.http.url=http://dozzle:8080"
      - "kuma.dozzle.http.parent_name=infra-group"

volumes:
  dozzle-data:
    external: true
    name: ragnalab_dozzle-data

networks:
  proxy:
    external: true
  socket_proxy_network:
    external: true
```

### Complete IT-Tools Docker Compose

```yaml
# stack/apps/it-tools/docker-compose.yml
# Source: https://github.com/CorentinTh/it-tools

services:
  it-tools:
    image: corentinth/it-tools:latest
    container_name: it-tools
    restart: unless-stopped
    profiles: ["apps"]
    networks:
      - proxy
    labels:
      # Traefik routing
      - "traefik.enable=true"
      - "traefik.http.routers.it-tools.rule=Host(`tools.ragnalab.xyz`)"
      - "traefik.http.routers.it-tools.entrypoints=websecure"
      - "traefik.http.routers.it-tools.tls=true"
      - "traefik.http.routers.it-tools.tls.certresolver=letsencrypt"
      - "traefik.http.services.it-tools.loadbalancer.server.port=80"
      - "traefik.http.routers.it-tools.middlewares=authelia@file"
      - "traefik.docker.network=proxy"
      # Homepage dashboard
      - "homepage.group=Applications"
      - "homepage.name=IT Tools"
      - "homepage.icon=it-tools.png"
      - "homepage.href=https://tools.ragnalab.xyz"
      - "homepage.description=Developer Utilities"
      - "homepage.server=ragnalab-docker"
      # Autokuma monitoring
      - "kuma.it-tools.http.name=IT Tools"
      - "kuma.it-tools.http.url=http://it-tools:80"
      - "kuma.it-tools.http.parent_name=apps-group"
    deploy:
      resources:
        limits:
          memory: 64M
          cpus: '0.1'

networks:
  proxy:
    external: true
```

### Authelia Access Control Update

```yaml
# Add to stack/infra/authelia/config/configuration.yml
# Under access_control.rules (before the catch-all rule)

    # New apps - admin only with two_factor
    - domain:
        - 'docs.ragnalab.xyz'
        - 'logs.ragnalab.xyz'
      subject: 'group:admin'
      policy: two_factor

    # IT-Tools - power users with one_factor
    - domain: 'tools.ragnalab.xyz'
      subject:
        - 'group:admin'
        - 'group:powerusers'
      policy: one_factor
```

## Homepage Integration

### Paperless-ngx Widget

Paperless-ngx has a dedicated Homepage widget showing document counts.

```yaml
# Via Docker labels (automatic discovery)
- "homepage.widget.type=paperlessngx"
- "homepage.widget.url=http://paperless:8000"
- "homepage.widget.key=${PAPERLESS_API_KEY}"

# Widget displays: total documents, inbox count
```

**Getting API Key:**
1. Deploy Paperless-ngx first
2. Login as admin
3. Settings -> API Token -> Copy token
4. Add to `.env` as `PAPERLESS_API_KEY`

### Dozzle - No Widget

Dozzle has no dedicated Homepage widget (feature was requested but declined as "dead simple app").

```yaml
# Use basic service link only
- "homepage.group=Infrastructure"
- "homepage.name=Dozzle"
- "homepage.icon=dozzle.png"
- "homepage.href=https://logs.ragnalab.xyz"
- "homepage.description=Container Logs"
```

### IT-Tools - No Widget

IT-Tools is a client-side app with no API, no widget possible.

```yaml
# Use basic service link only
- "homepage.group=Applications"
- "homepage.name=IT Tools"
- "homepage.icon=it-tools.png"
- "homepage.href=https://tools.ragnalab.xyz"
- "homepage.description=Developer Utilities"
```

## Autokuma Patterns

### HTTP Monitoring (Recommended)

Use internal URLs to bypass Authelia for health checks:

```yaml
# Paperless-ngx
- "kuma.paperless.http.name=Paperless"
- "kuma.paperless.http.url=http://paperless:8000"
- "kuma.paperless.http.parent_name=apps-group"

# Dozzle
- "kuma.dozzle.http.name=Dozzle"
- "kuma.dozzle.http.url=http://dozzle:8080"
- "kuma.dozzle.http.parent_name=infra-group"

# IT-Tools
- "kuma.it-tools.http.name=IT Tools"
- "kuma.it-tools.http.url=http://it-tools:80"
- "kuma.it-tools.http.parent_name=apps-group"
```

### Monitoring Groups

Need to create parent groups in Autokuma if they don't exist:
- `apps-group` - For application services
- `infra-group` - Already exists for infrastructure

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Per-app authentication | Trusted headers + ForwardAuth | Single SSO for all |
| Direct Docker socket mount | Socket-proxy | Better security |
| Manual monitor creation | Autokuma labels | Auto-discovery |
| Manual Homepage config | Docker labels | Auto-discovery |
| Complex Paperless OIDC | Trusted headers | Simpler config |

## Volume Creation Commands

```bash
# Paperless-ngx volumes
docker volume create ragnalab_paperless-redis-data
docker volume create ragnalab_paperless-data
docker volume create ragnalab_paperless-media
docker volume create ragnalab_paperless-consume

# Dozzle volume
docker volume create ragnalab_dozzle-data
```

## Environment Variables Summary

```bash
# Add to .env file
# Paperless-ngx
PAPERLESS_ADMIN_USER=rushil          # Must match Authelia username
PAPERLESS_ADMIN_PASSWORD=<secure>    # Initial password
PAPERLESS_API_KEY=<from-ui>          # Get after first login

# No additional env vars needed for Dozzle or IT-Tools
```

## Open Questions

1. **Paperless-ngx consume folder location**
   - What we know: Needs a volume for document ingestion
   - What's unclear: Should it be on shared storage or local?
   - Recommendation: Local volume initially, can add network mount later

2. **Autokuma apps-group**
   - What we know: Existing services use `infra-group` and `media-group`
   - What's unclear: Does `apps-group` exist?
   - Recommendation: Create `apps-group` in Uptime Kuma before deployment or use `infra-group`

3. **Paperless-ngx OCR for scanned documents**
   - What we know: OCR is resource-intensive on Raspberry Pi
   - What's unclear: User's scanning workflow
   - Recommendation: Disabled by default (`skip`), enable if needed

## Sources

### Primary (HIGH confidence)
- [Authelia Paperless Integration](https://www.authelia.com/integration/trusted-header-sso/paperless/) - Trusted header configuration
- [Paperless-ngx Configuration](https://docs.paperless-ngx.com/configuration/) - All environment variables
- [Dozzle Authentication](https://dozzle.dev/guide/authentication) - Forward-proxy auth setup
- [Dozzle Environment Variables](https://dozzle.dev/guide/supported-env-vars) - All configuration options
- [Homepage Paperless-ngx Widget](https://gethomepage.dev/widgets/services/paperlessngx/) - Widget configuration

### Secondary (MEDIUM confidence)
- [Paperless-ngx Setup](https://docs.paperless-ngx.com/setup/) - Docker deployment guide
- [IT-Tools GitHub](https://github.com/CorentinTh/it-tools) - Docker deployment
- [Tecnativa Docker Socket Proxy](https://github.com/Tecnativa/docker-socket-proxy) - API access control

### Tertiary (LOW confidence)
- [Homepage Dozzle Discussion](https://github.com/gethomepage/homepage/discussions/1250) - No widget planned

## Metadata

**Confidence breakdown:**
- ARM64 compatibility: HIGH - Verified via `docker manifest inspect`
- Paperless-ngx SSO: HIGH - Official Authelia integration docs
- Dozzle forward-proxy: HIGH - Official Dozzle documentation
- IT-Tools auth: HIGH - Simple middleware pattern
- Homepage widgets: HIGH - Official docs
- Autokuma labels: MEDIUM - Based on existing patterns in codebase
- Socket-proxy compatibility: MEDIUM - No LOGS variable, uses CONTAINERS

**Research date:** 2026-01-25
**Valid until:** 30 days (stable patterns, no breaking changes expected)
