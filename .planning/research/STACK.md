# Stack Research: Authelia SSO

**Researched:** 2026-01-24
**Overall Confidence:** HIGH

## Summary

Authelia v4.39.x is the correct choice for this setup. It gained passkey/WebAuthn passwordless support in v4.39.0 (May 2025), has native ARM64 Docker images, and integrates cleanly with Traefik v3.x via forwardAuth middleware. For a Pi 5 homelab with 4 users and no HA requirements, use in-memory session storage (no Redis needed) with SQLite for persistent data. The existing Traefik v3.6 configuration already has the dynamic middleware structure needed - Authelia middleware adds as another entry in `middlewares.yml`.

## Recommended Stack

| Component | Choice | Version | Rationale | Confidence |
|-----------|--------|---------|-----------|------------|
| **Auth Server** | Authelia | 4.39.14 | Passkey support (4.39.0+), lightweight (~30MB RAM), single container. Pin to .14 not .15 due to [reported LDAP regression](https://github.com/authelia/authelia/issues/10840) in latest. | HIGH |
| **Session Storage** | In-memory (default) | N/A | 4 users, single instance, no HA needed. Sessions lost on restart but users just re-auth. Avoids Redis dependency on Pi 5. | HIGH |
| **User Storage** | File-based YAML | N/A | Small user count (4), no external LDAP/AD. Passwords hashed with argon2id. Editable by hand. | HIGH |
| **Persistent Storage** | SQLite3 | Built-in | Stores 2FA credentials, WebAuthn keys, password reset tokens. Single-file database, no external DB needed. | HIGH |
| **Traefik Middleware** | forwardAuth | v3.6 compatible | Native Traefik v3 support via `/api/authz/forward-auth` endpoint. Already have dynamic middleware pattern in place. | HIGH |

## Configuration Approach

### How Components Wire Together

```
[User] --> [Traefik :443] --> [forwardAuth middleware] --> [Authelia :9091]
                                     |                           |
                                     | (if authenticated)        | (redirect to login)
                                     v                           v
                              [Protected Service]          [Authelia Portal]
```

**Integration points:**

1. **Authelia container** joins `proxy` network (same as Traefik)
2. **Traefik dynamic middleware** (`middlewares.yml`) adds `authelia` forwardAuth block
3. **Protected services** add label: `traefik.http.routers.<name>.middlewares=authelia@file`
4. **Authelia config** (`configuration.yml`) defines access rules per subdomain

### Middleware Configuration (add to existing `middlewares.yml`)

```yaml
# Authelia ForwardAuth Middleware
authelia:
  forwardAuth:
    address: 'http://authelia:9091/api/authz/forward-auth'
    trustForwardHeader: true
    authResponseHeaders:
      - 'Remote-User'
      - 'Remote-Groups'
      - 'Remote-Email'
      - 'Remote-Name'
```

### Access Control Model

Authelia uses policy-based rules in `configuration.yml`:

```yaml
access_control:
  default_policy: deny
  rules:
    # Admin-only services
    - domain: 'traefik.ragnalab.xyz'
      policy: two_factor
      subject: 'group:admins'

    # Media services - any authenticated user
    - domain: '*.ragnalab.xyz'
      resources: ['^/api/.*$']
      policy: bypass  # API endpoints for mobile apps

    - domain: ['jellyfin.ragnalab.xyz', 'plex.ragnalab.xyz']
      policy: one_factor
      subject: 'group:users'
```

### Passkey Configuration

```yaml
webauthn:
  disable: false
  display_name: 'RagnaLab'
  attestation_conveyance_preference: 'indirect'
  timeout: '60s'
  enable_passkey_login: true  # Passwordless via passkey

  # Optional: require passkey user verification as 2FA
  # experimental_enable_passkey_uv_two_factors: true
```

### User Database Structure (`users_database.yml`)

```yaml
users:
  rushil:
    displayname: "Rushil"
    password: "$argon2id$..."  # Generated with authelia hash-password
    email: rushil@example.com
    groups:
      - admins
      - users
  guest:
    displayname: "Guest"
    password: "$argon2id$..."
    email: guest@example.com
    groups:
      - users
```

## ARM64 Compatibility

| Component | ARM64 Image | Verified |
|-----------|-------------|----------|
| Authelia | `authelia/authelia:4.39.14` | YES - Multi-arch manifest includes linux/arm64 |
| Redis (if needed later) | `redis:alpine` | YES - Official image supports arm64v8 |

**Source:** [Authelia Docker Hub](https://hub.docker.com/r/authelia/authelia) confirms multi-architecture support.

**Known Issue:** v4.39.11 had a [broken ARM image](https://github.com/authelia/authelia/issues/10430) that crashed on start. Fixed in subsequent releases. Avoid that specific version.

## What NOT to Use

| Alternative | Why Not |
|-------------|---------|
| **Authentik** | Overkill for 4 users. Requires PostgreSQL + Redis (until 2025.10). Multiple containers. Enterprise-focused. Great product but wrong fit for lightweight Pi homelab. |
| **Keycloak** | Java-based, heavy resource usage (~500MB+ RAM). Enterprise-grade, excessive for homelab. |
| **LLDAP + Authelia** | LLDAP adds complexity for no benefit when you have <10 users. File-based user storage is simpler. |
| **Redis for sessions** | Unnecessary for single-instance, 4-user deployment. Adds container, memory overhead. In-memory sessions are fine when losing sessions on restart is acceptable. |
| **PostgreSQL/MySQL** | Overkill for storage. SQLite handles WebAuthn credentials fine for low-volume homelab. |
| **`authelia:latest` tag** | Breaking changes possible. Always pin version. Current stable: 4.39.14. |
| **Authelia v4.38.x** | Missing passkey/passwordless support. Passkeys require 4.39.0+. |

## Minimal Docker Compose

```yaml
services:
  authelia:
    image: authelia/authelia:4.39.14
    container_name: authelia
    restart: unless-stopped
    volumes:
      - ./config:/config:ro
      - ./data:/data  # SQLite DB + secrets
    environment:
      TZ: America/Los_Angeles
      AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE: /data/secrets/jwt
      AUTHELIA_SESSION_SECRET_FILE: /data/secrets/session
      AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE: /data/secrets/storage
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.authelia.rule=Host(`auth.ragnalab.xyz`)"
      - "traefik.http.routers.authelia.entrypoints=websecure"
      - "traefik.http.routers.authelia.tls.certresolver=letsencrypt"
      - "traefik.http.services.authelia.loadbalancer.server.port=9091"

networks:
  proxy:
    external: true
```

## Open Questions

| Question | When to Resolve | Notes |
|----------|-----------------|-------|
| **SMTP provider for password resets** | Phase implementation | Authelia needs SMTP for password reset emails. Options: existing mail server, Gmail SMTP, or disable password reset and use passkeys-only. |
| **Which services to bypass auth** | Phase implementation | Some services (Jellyfin, Plex) have their own auth. May want to bypass Authelia or use it as additional layer. Mobile app API endpoints often need bypass. |
| **Session timeout values** | Phase implementation | Default is reasonable. May want longer "remember me" for trusted devices on VPN. |
| **Apple passkey compatibility** | Validate during testing | Apple devices may not properly report passkey capability to Authelia. May need `experimental_enable_passkey_upgrade: true` setting. |

## Sources

- [Authelia v4.39 Release Notes](https://www.authelia.com/blog/4.39-release-notes/) - Passkey features (HIGH confidence)
- [Authelia WebAuthn Configuration](https://www.authelia.com/configuration/second-factor/webauthn/) - Config options (HIGH confidence)
- [Authelia Traefik Integration](https://www.authelia.com/integration/proxies/traefik/) - ForwardAuth setup (HIGH confidence)
- [Authelia Session Configuration](https://www.authelia.com/configuration/session/introduction/) - Storage options (HIGH confidence)
- [Authelia GitHub Releases](https://github.com/authelia/authelia/releases) - Version info (HIGH confidence)
- [Authelia Docker Hub](https://hub.docker.com/r/authelia/authelia) - ARM64 availability (HIGH confidence)
- [Authelia vs Authentik Comparison](https://www.houseoffoss.com/post/authelia-vs-authentik-which-self-hosted-identity-provider-is-better-in-2025) - Alternative analysis (MEDIUM confidence)
