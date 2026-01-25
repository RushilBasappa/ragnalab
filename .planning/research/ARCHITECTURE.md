# Architecture Research: Authelia + Traefik Integration

**Domain:** SSO/Authentication Layer for Homelab
**Researched:** 2026-01-24
**Overall Confidence:** HIGH

## Summary

Authelia integrates with Traefik v3 using the ForwardAuth middleware pattern. Traefik intercepts requests to protected services and delegates authentication decisions to Authelia via HTTP subrequests. When authenticated, Authelia returns user identity headers that Traefik forwards to backend services. Session state is maintained via cookies scoped to the parent domain (`ragnalab.xyz`), enabling SSO across all subdomains.

The integration requires: (1) Authelia container on the `proxy` network, (2) ForwardAuth middleware definition, (3) middleware applied to protected service routers, and (4) session cookies configured for the parent domain.

## Request Flow

### Unauthenticated Request (First Visit)

```
┌──────────┐    ┌─────────┐    ┌──────────┐    ┌─────────┐
│  Client  │───▶│ Traefik │───▶│ Authelia │    │ Service │
│ Browser  │    │  :443   │    │  :9091   │    │ Backend │
└──────────┘    └─────────┘    └──────────┘    └─────────┘
     │               │               │
     │  1. GET sonarr.ragnalab.xyz   │
     │──────────────▶│               │
     │               │               │
     │               │ 2. ForwardAuth subrequest
     │               │   GET /api/authz/forward-auth
     │               │   Headers: X-Forwarded-*
     │               │──────────────▶│
     │               │               │
     │               │ 3. No session cookie found
     │               │   Return 401 + redirect URL
     │               │◀──────────────│
     │               │               │
     │ 4. 302 Redirect to auth.ragnalab.xyz
     │   ?rd=https://sonarr.ragnalab.xyz
     │◀──────────────│               │
     │               │               │
     │ 5. User lands on Authelia portal
     │   (login form / passkey prompt)
     │
```

### Authentication Flow (Login Portal)

```
┌──────────┐    ┌─────────┐    ┌──────────┐    ┌─────────┐
│  Client  │───▶│ Traefik │───▶│ Authelia │───▶│ Storage │
│ Browser  │    │  :443   │    │  :9091   │    │ (Redis) │
└──────────┘    └─────────┘    └──────────┘    └─────────┘
     │               │               │               │
     │ 1. POST credentials/passkey   │               │
     │──────────────▶│──────────────▶│               │
     │               │               │               │
     │               │ 2. Validate credentials       │
     │               │   (check users_database.yml)  │
     │               │               │               │
     │               │ 3. Create session             │
     │               │   Store in Redis ────────────▶│
     │               │               │               │
     │ 4. Set-Cookie: authelia_session=...           │
     │   Domain: ragnalab.xyz (parent domain)        │
     │   Secure: true, HttpOnly: true, SameSite: Lax │
     │◀──────────────│◀──────────────│               │
     │               │               │               │
     │ 5. Redirect back to original URL              │
     │   (sonarr.ragnalab.xyz)       │               │
     │               │               │               │
```

### Authenticated Request (Subsequent Visits)

```
┌──────────┐    ┌─────────┐    ┌──────────┐    ┌─────────┐
│  Client  │───▶│ Traefik │───▶│ Authelia │───▶│ Service │
│ Browser  │    │  :443   │    │  :9091   │    │ Backend │
└──────────┘    └─────────┘    └──────────┘    └─────────┘
     │               │               │               │
     │ 1. GET sonarr.ragnalab.xyz    │               │
     │   Cookie: authelia_session=...│               │
     │──────────────▶│               │               │
     │               │               │               │
     │               │ 2. ForwardAuth subrequest     │
     │               │   Cookie forwarded            │
     │               │──────────────▶│               │
     │               │               │               │
     │               │ 3. Session valid              │
     │               │   Return 200 + identity headers
     │               │   Remote-User: admin          │
     │               │   Remote-Groups: admins       │
     │               │   Remote-Email: admin@...     │
     │               │◀──────────────│               │
     │               │               │               │
     │               │ 4. Forward to backend         │
     │               │   + identity headers          │
     │               │──────────────────────────────▶│
     │               │               │               │
     │ 5. Response from service      │               │
     │◀──────────────│◀──────────────────────────────│
     │               │               │               │
```

### Access Denied Flow (Insufficient Permissions)

```
┌──────────┐    ┌─────────┐    ┌──────────┐
│  Client  │───▶│ Traefik │───▶│ Authelia │
│ Browser  │    │  :443   │    │  :9091   │
└──────────┘    └─────────┘    └──────────┘
     │               │               │
     │ 1. GET prowlarr.ragnalab.xyz  │
     │   Cookie: authelia_session=...│
     │   (user is in "family" group) │
     │──────────────▶│               │
     │               │               │
     │               │ 2. ForwardAuth check          │
     │               │──────────────▶│               │
     │               │               │               │
     │               │ 3. User authenticated but     │
     │               │   ACL denies access           │
     │               │   (family not in rule)        │
     │               │   Return 403 Forbidden        │
     │               │◀──────────────│               │
     │               │               │               │
     │ 4. 403 Forbidden page         │               │
     │◀──────────────│               │               │
     │               │               │               │
```

## Component Boundaries

### Components and Responsibilities

| Component | Responsibility | Talks To | Protocol |
|-----------|---------------|----------|----------|
| **Traefik** | TLS termination, routing, middleware orchestration | Authelia, all services | HTTPS (external), HTTP (internal) |
| **Authelia** | Authentication, authorization, session management | Traefik, Redis, user database | HTTP (forwardAuth), Redis protocol |
| **Redis** | Session storage (stateless Authelia) | Authelia only | Redis protocol (6379) |
| **Protected Services** | Application logic | Traefik only (via proxy network) | HTTP |
| **Unprotected Services** | Public/bypass endpoints | Traefik only | HTTP |

### Data Flow Boundaries

```
┌─────────────────────────────────────────────────────────────────────┐
│                          EXTERNAL                                    │
│                    (Tailscale Network)                               │
│                                                                      │
│    ┌──────────────────────────────────────────────────────────┐     │
│    │                    Traefik :443                          │     │
│    │              (TLS Termination Point)                     │     │
│    │         ┌─────────────────────────────────┐              │     │
│    │         │ ForwardAuth Middleware          │              │     │
│    │         │ (intercepts protected routes)   │              │     │
│    │         └─────────────────────────────────┘              │     │
│    └────────────────────────┬─────────────────────────────────┘     │
│                             │                                        │
└─────────────────────────────│────────────────────────────────────────┘
                              │
┌─────────────────────────────│────────────────────────────────────────┐
│                    INTERNAL │(proxy network)                         │
│                             ▼                                        │
│    ┌────────────────────────────────────────────────────────┐       │
│    │                   Authelia :9091                        │       │
│    │            (Decision Engine - No Data)                  │       │
│    │  ┌──────────────────────────────────────────────────┐  │       │
│    │  │ /api/authz/forward-auth                          │  │       │
│    │  │ Evaluates: session + ACL rules → 200/401/403     │  │       │
│    │  └──────────────────────────────────────────────────┘  │       │
│    └────────────────────────┬───────────────────────────────┘       │
│                             │                                        │
│                             ▼                                        │
│    ┌────────────────────────────────────────────────────────┐       │
│    │                     Redis :6379                         │       │
│    │                  (Session Storage)                      │       │
│    │         Sessions persist across container restarts      │       │
│    └────────────────────────────────────────────────────────┘       │
│                                                                      │
│    ┌────────────────────────────────────────────────────────┐       │
│    │              Protected Services                         │       │
│    │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐    │       │
│    │  │ Sonarr  │  │ Radarr  │  │Jellyfin │  │Homepage │    │       │
│    │  │  :8989  │  │  :7878  │  │  :8096  │  │  :3000  │    │       │
│    │  └─────────┘  └─────────┘  └─────────┘  └─────────┘    │       │
│    │  (Receive Remote-User/Remote-Groups headers)           │       │
│    └────────────────────────────────────────────────────────┘       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### API Boundaries

**Authelia exposes two key endpoints:**

| Endpoint | Purpose | When Used |
|----------|---------|-----------|
| `/api/authz/forward-auth` | ForwardAuth verification | Every protected request |
| `/` (portal UI) | Login form, passkey registration | Unauthenticated users |

**Authelia returns these headers on successful auth:**

| Header | Content | Backend Usage |
|--------|---------|---------------|
| `Remote-User` | Username (e.g., `admin`) | Logging, user-specific features |
| `Remote-Groups` | Comma-separated groups (e.g., `admins,users`) | Authorization decisions |
| `Remote-Email` | User email | Notifications, display |
| `Remote-Name` | Display name | UI personalization |

## Session Architecture

### Cookie Configuration

```yaml
# Authelia session configuration
session:
  cookies:
    - name: 'authelia_session'
      domain: 'ragnalab.xyz'          # Parent domain - covers all subdomains
      authelia_url: 'https://auth.ragnalab.xyz'
      expiration: '1h'                 # Session expires after 1 hour
      inactivity: '5m'                 # Destroyed after 5 min idle
      remember_me: '1M'                # "Remember me" extends to 1 month
      same_site: 'lax'                 # Lax allows redirect-based flows
```

### Cookie Properties

| Property | Value | Rationale |
|----------|-------|-----------|
| **Domain** | `ragnalab.xyz` | Parent domain enables SSO across all `*.ragnalab.xyz` |
| **Secure** | `true` | Mandatory - Authelia refuses HTTP |
| **HttpOnly** | `true` | Prevents JavaScript access |
| **SameSite** | `Lax` | Allows redirects from external links while blocking CSRF |
| **Path** | `/` | Cookie sent for all paths |

### Session Storage: Redis

**Why Redis (not in-memory):**
- Sessions persist across Authelia container restarts
- Users do not need to re-login after updates
- "Remember Me" actually works
- Required for future high-availability (if ever needed)

```yaml
# Authelia session storage
session:
  redis:
    host: 'authelia-redis'
    port: 6379
```

**Redis container requirements:**
- Named volume for persistence
- Same network as Authelia
- No external exposure needed

### SSO Flow Across Subdomains

```
1. User logs into auth.ragnalab.xyz
   ↓
2. Cookie set: authelia_session
   Domain: ragnalab.xyz (NOT auth.ragnalab.xyz)
   ↓
3. User visits sonarr.ragnalab.xyz
   ↓
4. Browser sends cookie (domain matches)
   ↓
5. Authelia validates session → 200 OK
   ↓
6. User is already logged in (no redirect)
```

**Critical:** Cookie domain MUST be the parent (`ragnalab.xyz`), not the Authelia subdomain (`auth.ragnalab.xyz`). Otherwise cookies are not sent to other subdomains.

## Docker Network Topology

### Current Network Layout

```
┌─────────────────────────────────────────────────────────────────────┐
│                        socket_proxy_network                          │
│  ┌──────────────────┐     ┌───────────────────────────────────────┐ │
│  │   socket-proxy   │◀────│              Traefik                   │ │
│  │  (docker.sock)   │     │  (reads container labels via proxy)   │ │
│  └──────────────────┘     └───────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                            proxy network                             │
│                                                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ Traefik │  │ Sonarr  │  │ Radarr  │  │Jellyfin │  │Homepage │   │
│  │  :443   │  │  :8989  │  │  :7878  │  │  :8096  │  │  :3000  │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
│       ▲                                                              │
│       │ (traefik.docker.network=proxy)                               │
└───────│─────────────────────────────────────────────────────────────┘
        │
┌───────│─────────────────────────────────────────────────────────────┐
│       │                      media network                           │
│       │                                                              │
│  ┌────┴────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐                 │
│  │ Sonarr  │  │ Radarr  │  │Prowlarr │  │qBittor. │                 │
│  │         │──│         │──│         │──│         │                 │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘                 │
│                   (inter-arr communication)                          │
└─────────────────────────────────────────────────────────────────────┘
```

### With Authelia Added

```
┌─────────────────────────────────────────────────────────────────────┐
│                            proxy network                             │
│                                                                      │
│  ┌─────────┐      ┌──────────┐      ┌─────────┐                     │
│  │ Traefik │◀────▶│ Authelia │◀────▶│  Redis  │                     │
│  │  :443   │      │   :9091  │      │  :6379  │                     │
│  └────┬────┘      └──────────┘      └─────────┘                     │
│       │                                                              │
│       │  ForwardAuth subrequest:                                    │
│       │  http://authelia:9091/api/authz/forward-auth                │
│       │                                                              │
│       ▼                                                              │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │ Sonarr  │  │ Radarr  │  │Jellyfin │  │Homepage │  │ ...etc  │   │
│  │  :8989  │  │  :7878  │  │  :8096  │  │  :3000  │  │         │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Key points:**
- Authelia joins the existing `proxy` network
- Redis can be on `proxy` or a dedicated `authelia` network
- No new networks required (simplicity)
- Traefik reaches Authelia via container name (`http://authelia:9091`)

### Container Placement

| Container | Networks | Rationale |
|-----------|----------|-----------|
| `traefik` | `proxy`, `socket_proxy_network` | Routes to all services, reads Docker labels |
| `authelia` | `proxy` | Needs Traefik access, needs Redis access |
| `authelia-redis` | `proxy` | Only Authelia needs access (could isolate further) |
| Protected services | `proxy` (+ others) | Traefik routing |

## Traefik Middleware Chain

### Middleware Definition (Dynamic Config)

**Option 1: File-based (recommended for RagnaLab)**

Add to `/home/rushil/workspace/ragnalab/stack/infra/traefik/config/dynamic/middlewares.yml`:

```yaml
http:
  middlewares:
    # ... existing middlewares ...

    # Authelia ForwardAuth middleware
    authelia:
      forwardAuth:
        address: 'http://authelia:9091/api/authz/forward-auth'
        trustForwardHeader: true
        authResponseHeaders:
          - 'Remote-User'
          - 'Remote-Groups'
          - 'Remote-Email'
          - 'Remote-Name'

    # Authelia with basic auth fallback (for API access)
    authelia-basic:
      forwardAuth:
        address: 'http://authelia:9091/api/verify?auth=basic'
        trustForwardHeader: true
        authResponseHeaders:
          - 'Remote-User'
          - 'Remote-Groups'
```

**Option 2: Docker labels on Authelia container**

```yaml
labels:
  - "traefik.http.middlewares.authelia.forwardAuth.address=http://authelia:9091/api/authz/forward-auth"
  - "traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader=true"
  - "traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders=Remote-User,Remote-Groups,Remote-Email,Remote-Name"
```

**Recommendation:** Use file-based. Keeps middleware definition separate from Authelia container. If Authelia container is down/recreating, middleware definition persists.

### Applying Middleware to Services

**Current service labels (Sonarr example):**

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.sonarr.rule=Host(`sonarr.ragnalab.xyz`)"
  - "traefik.http.routers.sonarr.entrypoints=websecure"
  - "traefik.http.routers.sonarr.tls=true"
  - "traefik.http.routers.sonarr.tls.certresolver=letsencrypt"
  - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
```

**With Authelia protection added:**

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.sonarr.rule=Host(`sonarr.ragnalab.xyz`)"
  - "traefik.http.routers.sonarr.entrypoints=websecure"
  - "traefik.http.routers.sonarr.tls=true"
  - "traefik.http.routers.sonarr.tls.certresolver=letsencrypt"
  - "traefik.http.routers.sonarr.middlewares=authelia@file"  # <-- ADD THIS
  - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
```

**Middleware reference format:**
- `authelia@file` - middleware defined in file config
- `authelia@docker` - middleware defined via Docker labels

### Middleware Chains (Optional)

For services needing multiple middlewares:

```yaml
# In middlewares.yml
http:
  middlewares:
    chain-authelia:
      chain:
        middlewares:
          - security-headers
          - rate-limit
          - authelia
```

Then reference as `chain-authelia@file`.

### Authelia Service Labels (Self-routing)

Authelia needs its own router (NOT protected by itself):

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.authelia.rule=Host(`auth.ragnalab.xyz`)"
  - "traefik.http.routers.authelia.entrypoints=websecure"
  - "traefik.http.routers.authelia.tls=true"
  - "traefik.http.routers.authelia.tls.certresolver=letsencrypt"
  - "traefik.http.services.authelia.loadbalancer.server.port=9091"
  - "traefik.docker.network=proxy"
  # NOTE: No middlewares - Authelia portal must be accessible to unauthenticated users
```

## Build Order

The integration has clear dependencies that dictate build order:

### Phase 1: Infrastructure Prerequisites

```
1. Redis container
   └── No dependencies
   └── Must be running before Authelia starts
   └── Verify: docker exec authelia-redis redis-cli ping → PONG

2. Authelia middleware definition
   └── Add to middlewares.yml
   └── Traefik hot-reloads (no restart needed)
   └── Verify: Traefik dashboard shows middleware
```

### Phase 2: Authelia Core

```
3. Authelia configuration files
   └── Depends on: Redis container name decided
   └── Create: configuration.yml, users_database.yml
   └── Generate: JWT secret, session secret, storage encryption key

4. Authelia container
   └── Depends on: Redis running, config files ready
   └── Joins: proxy network
   └── Verify: https://auth.ragnalab.xyz shows login portal
```

### Phase 3: Service Integration

```
5. Test service protection
   └── Add middleware to ONE service (e.g., Traefik dashboard)
   └── Verify: Redirects to auth portal, login works
   └── Verify: Remote-User header reaches service

6. Access control rules
   └── Configure ACL in Authelia config
   └── Add user groups to users_database.yml
   └── Test: Different users get appropriate access

7. Roll out to remaining services
   └── Add middlewares to each service
   └── Service by service, verify access control
```

### Phase 4: Backend Trust Configuration

```
8. Configure apps to trust external auth
   └── Sonarr/Radarr: Authentication = "External"
   └── Jellyfin: Configure remote header auth (if desired)
   └── Some apps may not support this - SSO is gateway-only
```

### Dependency Graph

```
                    ┌──────────────┐
                    │    Redis     │
                    └──────┬───────┘
                           │
           ┌───────────────┴───────────────┐
           │                               │
           ▼                               ▼
    ┌─────────────┐               ┌────────────────┐
    │  Authelia   │               │  Middleware    │
    │  Container  │               │  Definition    │
    └──────┬──────┘               └────────┬───────┘
           │                               │
           └───────────────┬───────────────┘
                           │
                           ▼
                  ┌────────────────┐
                  │  Test Service  │
                  │  (one service) │
                  └────────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │   ACL Rules    │
                  │   User Groups  │
                  └────────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │   Full Rollout │
                  │  (all services)│
                  └────────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │  Backend Trust │
                  │  Configuration │
                  └────────────────┘
```

## Key Architectural Decisions

### Decision: File-based Middleware Definition

**Rationale:**
- Middleware persists if Authelia container is down
- Cleaner separation of concerns
- Consistent with existing `middlewares.yml` pattern
- Easier to audit security configuration

### Decision: Redis for Session Storage

**Rationale:**
- Sessions survive container restarts
- "Remember Me" actually persists
- Single Pi deployment, but future-proofs for HA
- Minimal resource overhead (~10MB)

### Decision: Parent Domain Cookie

**Rationale:**
- SSO requires cookie visible to all subdomains
- `ragnalab.xyz` not on Public Suffix List (user owns it)
- Single login covers entire homelab

### Decision: Authelia on proxy Network (No Isolation)

**Rationale:**
- Simpler configuration
- Traefik already on proxy network
- No security benefit from isolation (Authelia needs Traefik access anyway)
- Redis can be on same network

## Anti-Patterns to Avoid

### Anti-Pattern: Protecting Authelia with Itself

**Wrong:**
```yaml
# Authelia service labels
- "traefik.http.routers.authelia.middlewares=authelia@file"
```

**Why:** Creates infinite redirect loop. Users cannot reach login page.

**Correct:** Authelia router has NO middleware.

### Anti-Pattern: Subdomain Cookie Domain

**Wrong:**
```yaml
session:
  cookies:
    - domain: 'auth.ragnalab.xyz'  # WRONG
```

**Why:** Cookie only sent to `auth.ragnalab.xyz`, not to `sonarr.ragnalab.xyz`.

**Correct:** Use parent domain `ragnalab.xyz`.

### Anti-Pattern: In-Memory Sessions in Production

**Wrong:**
```yaml
session:
  # No Redis configuration - uses in-memory
```

**Why:** All sessions lost on Authelia restart. Users must re-login.

**Correct:** Configure Redis session storage.

### Anti-Pattern: Middleware on Wrong Network Reference

**Wrong:**
```yaml
# Service label
- "traefik.http.routers.sonarr.middlewares=authelia@docker"
# When middleware is defined in file config
```

**Why:** Traefik cannot find middleware, request fails.

**Correct:** Match reference (`@file` vs `@docker`) to definition location.

## Sources

- [Authelia Traefik Integration](https://www.authelia.com/integration/proxies/traefik/) - HIGH confidence
- [Authelia Architecture Overview](https://www.authelia.com/overview/prologue/architecture/) - HIGH confidence
- [Authelia Session Configuration](https://www.authelia.com/configuration/session/introduction/) - HIGH confidence
- [Authelia Access Control](https://www.authelia.com/configuration/security/access-control/) - HIGH confidence
- [Authelia + Traefik Setup Guide](https://www.authelia.com/blog/authelia--traefik-setup-guide/) - HIGH confidence
- [Authelia Redis Configuration](https://www.authelia.com/configuration/session/redis/) - HIGH confidence

---
*Last updated: 2026-01-24*
