# Features Research: Authelia SSO & App Integration

**Domain:** Homelab SSO/Authentication
**Researched:** 2026-01-24
**Confidence:** HIGH (official documentation verified)

## Summary

Authelia provides comprehensive access control via rules-based policies supporting one-factor, two-factor, bypass, and deny policies. Apps fall into four integration categories: (1) apps supporting header-based SSO (Paperless-ngx, Dozzle), (2) apps supporting OIDC (Jellyseerr, Vaultwarden), (3) apps supporting "External" auth mode (*arr family), and (4) apps requiring bypass or special handling (Plex, Jellyfin mobile, qBittorrent). The critical path is Traefik forwardAuth middleware setup, followed by per-app configuration based on integration method.

## Authelia Access Control Features

### Policy Levels

| Policy | Effect | Use Case |
|--------|--------|----------|
| `deny` | Blocks access completely | Default policy (recommended) |
| `bypass` | Skips authentication | Public resources, health checks, API endpoints for mobile apps |
| `one_factor` | Username/password only | Internal services, low-sensitivity apps |
| `two_factor` | Requires MFA (WebAuthn/TOTP) | Admin dashboards, sensitive services |

### Rule Matching Criteria

Rules are evaluated sequentially - first match wins. Available criteria:

| Criteria | Example | Notes |
|----------|---------|-------|
| `domain` | `*.ragnalab.xyz`, `sonarr.ragnalab.xyz` | Supports wildcards |
| `domain_regex` | `^(?P<user>[a-z]+)\.ragnalab\.xyz$` | Extract user/group from subdomain |
| `resources` | `^/api/.*` | Regex matching path and query |
| `subject` | `user:rushil`, `group:admin` | Requires prior authentication |
| `networks` | `10.0.0.0/8`, `internal` | Named network definitions supported |
| `methods` | `GET`, `OPTIONS` | Useful for CORS preflight bypass |

**Critical constraint:** Subject-based rules cannot use `bypass` policy (authentication must happen first to identify subject).

### Second Factor Options

| Method | Support | Notes |
|--------|---------|-------|
| WebAuthn/Passkeys | Full | Passwordless login supported (v4.39+) |
| TOTP | Full | Standard authenticator apps |
| Duo Push | Full | Mobile push notifications |
| Multiple credentials | Full | Multiple WebAuthn devices per user (v4.38+) |

### User/Group Management

- File-based user database (YAML) - perfect for homelab scale
- Groups defined per user
- Password hashing via `authelia hash-password` command
- No LDAP required for simple deployments

## App Integration Matrix

| App | External Auth Support | Integration Method | Complexity | Native Auth Disable | Notes |
|-----|----------------------|-------------------|------------|---------------------|-------|
| **Sonarr** | Yes | External auth mode | Low | Yes (`AuthenticationMethod: External`) | Edit config.xml |
| **Radarr** | Yes | External auth mode | Low | Yes (`AuthenticationMethod: External`) | Same as Sonarr |
| **Prowlarr** | Yes | External auth mode | Low | Yes (`AuthenticationMethod: External`) | Same as Sonarr |
| **Bazarr** | Partial | Forms/Basic only | Medium | No direct option | May need auth enabled |
| **Jellyfin** | Plugin required | SSO plugin (OIDC) | High | No | Requires plugin installation, manual account linking |
| **Jellyseerr** | Yes (preview) | OIDC | Medium | Optional | Use `preview-OIDC` Docker tag |
| **Plex** | No | Bypass required | N/A | N/A | Interferes with client apps - use bypass |
| **qBittorrent** | Partial | IP whitelist | Medium | Yes (whitelist 0.0.0.0/0) | Must configure reverse proxy IP for X-Forwarded-For |
| **Homepage** | N/A | ForwardAuth only | Low | N/A | No built-in auth to disable |
| **Uptime Kuma** | Yes | Disable auth setting | Low | Yes (Settings > Advanced) | Must create account first, then disable |
| **Traefik Dashboard** | N/A | ForwardAuth only | Low | N/A | Protected via middleware |
| **Backrest** | Yes | Disable auth | Low | Yes (first login option) | Works on subpaths only |
| **Vaultwarden** | Yes | OIDC (SSO) | Medium | Optional (`SSO_ONLY=true`) | Mobile app issues with 2FA reported |
| **Pi-hole** | Problematic | Issues in v6 | High | Password removal only | v6 has reverse proxy auth issues |
| **Paperless-ngx** | Yes | Trusted headers | Low | Yes (`PAPERLESS_ENABLE_HTTP_REMOTE_USER`) | Excellent SSO support |
| **Dozzle** | Yes | Forward proxy | Low | N/A | `DOZZLE_AUTH_PROVIDER=forward-proxy` |
| **IT-Tools** | N/A | ForwardAuth only | Low | N/A | Static app, no built-in auth |
| **Glances** | Partial | No password flag | Low | Yes (omit `--password`) | Run without password, rely on proxy |

### Integration Method Details

**1. Traefik ForwardAuth (all apps)**
```yaml
# Authelia middleware definition (on Authelia container)
traefik.http.middlewares.authelia.forwardAuth.address: 'http://authelia:9091/api/authz/forward-auth'
traefik.http.middlewares.authelia.forwardAuth.trustForwardHeader: 'true'
traefik.http.middlewares.authelia.forwardAuth.authResponseHeaders: 'Remote-User,Remote-Groups,Remote-Email,Remote-Name'

# Apply to any service
traefik.http.routers.myapp.middlewares: 'authelia@docker'
```

**2. External Auth Mode (*arr apps)**
Edit `config.xml` before starting container:
```xml
<AuthenticationMethod>External</AuthenticationMethod>
<AuthenticationType>DisabledForLocalAddresses</AuthenticationType>
```

**3. Trusted Header SSO (Paperless-ngx)**
```yaml
environment:
  PAPERLESS_ENABLE_HTTP_REMOTE_USER: "true"
  PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME: "HTTP_REMOTE_USER"
  PAPERLESS_LOGOUT_REDIRECT_URL: "https://auth.ragnalab.xyz/logout"
```

**4. Forward Proxy Auth (Dozzle)**
```yaml
environment:
  DOZZLE_AUTH_PROVIDER: forward-proxy
  DOZZLE_AUTH_HEADER_USER: Remote-User
  DOZZLE_AUTH_HEADER_EMAIL: Remote-Email
```

**5. OIDC Integration (Jellyseerr, Vaultwarden)**
Requires Authelia OIDC client configuration + app-side OIDC setup.

## Table Stakes Features

Must have for v3.0 SSO to be useful:

| Feature | Why Required | Complexity |
|---------|--------------|------------|
| Traefik forwardAuth middleware | Foundation for all SSO | Medium |
| User/group file configuration | Define admin, powerusers, family, guests | Low |
| Access control rules per group | Different access levels per user type | Low |
| WebAuthn/Passkey support | Primary auth method per requirements | Low |
| Password fallback | Compatibility for devices without passkey | Low |
| Session management | Remember logged-in users | Built-in |
| *Arr apps External auth | Core media management tools | Low |
| Uptime Kuma auth disable | Monitoring must work | Low |
| Homepage protection | Dashboard access control | Low |

## Nice to Have

Can defer if complex or blocked:

| Feature | Value | Complexity | Deferral Reason |
|---------|-------|------------|-----------------|
| Jellyfin SSO plugin | Single login for media | High | Requires plugin install, account linking, mobile app testing |
| Jellyseerr OIDC | Single login for requests | Medium | Preview branch only |
| Vaultwarden OIDC | SSO for password vault | Medium | Mobile app 2FA issues reported |
| Pi-hole auth integration | Admin protection | High | v6 has known reverse proxy issues |
| Per-service 2FA policies | Granular security | Low | Can start with global policy |
| TOTP as backup MFA | Alternative to passkeys | Low | Passkeys sufficient initially |

## Anti-Features

Things to deliberately NOT configure:

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Plex behind forwardAuth | Breaks client apps (Roku, phones, etc.) | Use Authelia bypass policy for Plex |
| Double authentication | Annoying UX (Authelia + app login) | Disable app auth when using External mode |
| LDAP backend | Overkill for 4 users, adds complexity | Use file-based user database |
| OAuth providers (Google/GitHub) | Users are known family, not public | Local user accounts only |
| API endpoints behind 2FA | Breaks automation (Homepage widgets, Autokuma) | Bypass policy for `/api/*` paths |
| Basic auth middleware for everything | Poor UX vs forms | Use basic auth only for specific services (monitoring exporters) |
| Jellyfin native auth + SSO | Creates duplicate accounts | Pick one method |
| qBittorrent without reverse proxy IP config | Auth bypass won't work | Configure WebUI > Reverse Proxy IP setting |

## Integration Dependencies

```
Phase 1: Foundation (must be first)
    Authelia deployment
         |
         v
    Traefik forwardAuth middleware
         |
         v
    User/group configuration
         |
         v
    Access control rules
         |
    +----+----+----+----+
    |    |    |    |    |
    v    v    v    v    v

Phase 2: Simple integrations (parallel)
    - Homepage (just add middleware)
    - Traefik dashboard (just add middleware)
    - IT-Tools (just add middleware)
    - Dozzle (forward-proxy mode)
    - Glances (no password + middleware)
    - Uptime Kuma (disable auth + middleware)
    - Backrest (disable auth + middleware)

Phase 3: Config file apps (parallel)
    - Sonarr (config.xml edit)
    - Radarr (config.xml edit)
    - Prowlarr (config.xml edit)
    - Bazarr (may keep native auth)

Phase 4: Special handling (sequential, careful testing)
    - qBittorrent (whitelist + reverse proxy IP)
    - Plex (bypass policy - DO NOT protect)
    - Paperless-ngx (trusted headers + new deploy)

Phase 5: Complex integrations (optional, defer if problematic)
    - Jellyfin (SSO plugin)
    - Jellyseerr (OIDC preview branch)
    - Vaultwarden (OIDC)
    - Pi-hole (evaluate v6 issues)
```

## Access Control Rules Structure

Recommended rule ordering for RagnaLab:

```yaml
access_control:
  default_policy: deny

  rules:
    # 1. Bypass rules (no auth required)
    - domain: plex.ragnalab.xyz
      policy: bypass

    - domain: "*.ragnalab.xyz"
      resources: "^/api/.*"
      policy: bypass  # For mobile apps, widgets

    # 2. Admin-only services (two_factor)
    - domain:
        - traefik.ragnalab.xyz
        - backups.ragnalab.xyz
        - pihole.ragnalab.xyz
        - logs.ragnalab.xyz
      subject: "group:admin"
      policy: two_factor

    # 3. Power users (media management)
    - domain:
        - sonarr.ragnalab.xyz
        - radarr.ragnalab.xyz
        - prowlarr.ragnalab.xyz
        - torrents.ragnalab.xyz
      subject:
        - "group:admin"
        - "group:powerusers"
      policy: one_factor

    # 4. Family (media consumption + requests)
    - domain:
        - jellyfin.ragnalab.xyz
        - requests.ragnalab.xyz
      subject:
        - "group:admin"
        - "group:powerusers"
        - "group:family"
      policy: one_factor

    # 5. Guest access (view only)
    - domain: jellyfin.ragnalab.xyz
      subject: "group:guests"
      policy: one_factor

    # 6. General authenticated access
    - domain: "*.ragnalab.xyz"
      subject:
        - "group:admin"
      policy: one_factor
```

## Sources

### HIGH Confidence (Official Documentation)
- [Authelia Access Control Configuration](https://www.authelia.com/configuration/security/access-control/)
- [Authelia Traefik Integration](https://www.authelia.com/integration/proxies/traefik/)
- [Authelia WebAuthn Configuration](https://www.authelia.com/configuration/second-factor/webauthn/)
- [Authelia Paperless Integration](https://www.authelia.com/integration/trusted-header-sso/paperless/)
- [Dozzle Authentication](https://dozzle.dev/guide/authentication)
- [Paperless-ngx Configuration](https://docs.paperless-ngx.com/configuration/)
- [Servarr Wiki - Prowlarr Settings](https://wiki.servarr.com/prowlarr/settings)
- [Sonarr v4 FAQ](https://wiki.servarr.com/sonarr/faq-v4)

### MEDIUM Confidence (Verified Community Sources)
- [Authelia + Traefik Setup Guide](https://www.authelia.com/blog/authelia--traefik-setup-guide/)
- [Jellyfin SSO Plugin](https://github.com/9p4/jellyfin-plugin-sso)
- [Jellyseerr OIDC PR](https://github.com/Fallenbagel/jellyseerr/pull/184)
- [qBittorrent Reverse Proxy Whitelist Fix](https://github.com/qbittorrent/qBittorrent/pull/9176)
- [Uptime Kuma Authentik Integration](https://integrations.goauthentik.io/monitoring/uptime-kuma/)
- [Vaultwarden Authelia OIDC](https://www.authelia.com/integration/openid-connect/clients/vaultwarden/)

### LOW Confidence (Community Reports - Verify Before Use)
- Pi-hole v6 reverse proxy issues (multiple GitHub issues)
- Vaultwarden mobile app 2FA loops (GitHub discussions)
- Radarr config.xml duplication bug (GitHub issue #9353)
