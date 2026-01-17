# Phase 4: Applications & Templates - Research

**Researched:** 2026-01-17
**Domain:** Homepage dashboard, Vaultwarden password manager, modular app templates, Docker label discovery
**Confidence:** HIGH

## Summary

This phase deploys core applications (Homepage dashboard, Vaultwarden password manager) and establishes the template system for adding future apps. The standard approach uses Docker labels for automatic service discovery by both Traefik (already working) and Homepage.

**Homepage** (gethomepage.dev) is a highly customizable dashboard that supports both YAML configuration files and Docker label-based automatic service discovery. It provides widgets for service status, including dedicated Traefik and Uptime Kuma integrations. Homepage requires `HOMEPAGE_ALLOWED_HOSTS` environment variable and Docker socket access for service discovery.

**Vaultwarden** is a lightweight, ARM64-compatible Bitwarden server. Key configuration includes ADMIN_TOKEN (argon2id hashed), SIGNUPS_ALLOWED=false for invite-only, and DOMAIN for correct invitation links. SMTP configuration is required for sending invitations; without SMTP, invitations cannot be sent but manual user creation via admin panel works.

**App template** pattern: each app lives in `apps/<name>/docker-compose.yml` with standard Traefik labels, Homepage labels for dashboard discovery, and backup.stop label for safe backups. A `apps/_template/` directory provides scaffolding for new apps.

**Primary recommendation:** Use Homepage Docker labels for automatic dashboard discovery (less config sprawl), Vaultwarden with argon2id hashed admin token and invite-only signups, and template in `apps/_template/` with all standard labels pre-configured.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ghcr.io/gethomepage/homepage | latest | Dashboard with service widgets | ARM64, Docker label discovery, 150+ service widgets, active development |
| vaultwarden/server | latest | Bitwarden-compatible password manager | ARM64, lightweight, full Bitwarden API compatibility, active development |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Traefik | v3.6 (deployed) | Reverse proxy with automatic HTTPS | Already deployed, auto-discovers via Docker labels |
| offen/docker-volume-backup | v2 (deployed) | Automated backups | Already deployed, needs volume mount additions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Homepage labels | Homepage services.yaml | Centralized config but requires editing Homepage config for each new app |
| Vaultwarden | Bitwarden official | Official requires more resources, not ARM64 native |

**Installation (ARM64 Raspberry Pi 5):**
```bash
# All images support ARM64/aarch64 natively via multi-arch
docker pull ghcr.io/gethomepage/homepage:latest
docker pull vaultwarden/server:latest
```

## Architecture Patterns

### Recommended Project Structure
```
apps/
├── _template/               # Template for new apps
│   ├── docker-compose.yml   # Placeholder compose with all labels
│   └── README.md            # How to customize, checklist
├── homepage/
│   ├── docker-compose.yml
│   └── config/              # Config volume mount
│       ├── settings.yaml    # Theme, layout settings
│       ├── services.yaml    # Empty or minimal (labels handle discovery)
│       ├── bookmarks.yaml   # External links
│       ├── widgets.yaml     # Top-of-page widgets
│       └── docker.yaml      # Docker provider config
├── vaultwarden/
│   ├── docker-compose.yml
│   └── .env                 # Secrets (gitignored)
├── uptime-kuma/             # (existing)
├── backup/                  # (existing, needs volume additions)
└── whoami/                  # (existing test service)
```

### Pattern 1: Homepage Docker Label Discovery
**What:** Services self-register with Homepage via Docker labels
**When to use:** All apps that should appear on dashboard
**Example:**
```yaml
# Source: https://gethomepage.dev/configs/docker/
labels:
  # Traefik labels (existing pattern)
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.ragnalab.xyz`)"
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls=true"
  - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"
  - "traefik.docker.network=proxy"
  # Homepage labels (new)
  - "homepage.group=Apps"
  - "homepage.name=My App"
  - "homepage.icon=myapp.png"
  - "homepage.href=https://myapp.ragnalab.xyz"
  - "homepage.description=What this app does"
  - "homepage.weight=100"
  # Backup label (existing pattern)
  - "docker-volume-backup.stop-during-backup=myapp"
```

### Pattern 2: Homepage Widget Integration
**What:** Display live stats from services in Homepage
**When to use:** Services with Homepage widget support (Traefik, Uptime Kuma, etc.)
**Example:**
```yaml
# Source: https://gethomepage.dev/widgets/services/traefik/
# In docker-compose.yml labels:
labels:
  - "homepage.group=Infrastructure"
  - "homepage.name=Traefik"
  - "homepage.icon=traefik.png"
  - "homepage.href=https://traefik.ragnalab.xyz"
  - "homepage.description=Reverse Proxy"
  - "homepage.widget.type=traefik"
  - "homepage.widget.url=http://traefik:8080"
```

### Pattern 3: Homepage Configuration Files
**What:** YAML files for settings, bookmarks, and non-Docker services
**When to use:** Theme settings, external bookmarks, services without Docker labels
**Example:**
```yaml
# Source: https://gethomepage.dev/configs/settings/
# config/settings.yaml
title: RagnaLab
theme: dark
color: blue
headerStyle: boxed
layout:
  Infrastructure:
    style: row
    columns: 3
  Apps:
    style: row
    columns: 3
  Bookmarks:
    style: row
    columns: 4
```

```yaml
# config/bookmarks.yaml
- Developer:
    - GitHub:
        - abbr: GH
          href: https://github.com/
          description: Code repositories
    - Cloudflare:
        - icon: cloudflare.png
          href: https://dash.cloudflare.com
          description: DNS management
```

### Pattern 4: Vaultwarden Secure Configuration
**What:** Password manager with invite-only signups and hashed admin token
**When to use:** Vaultwarden deployment
**Example:**
```yaml
# Source: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      # CRITICAL: Hash admin token with argon2id
      # Generate: docker run --rm -it vaultwarden/server /vaultwarden hash
      # In docker-compose.yml, double $$ for each $
      ADMIN_TOKEN: ${VAULTWARDEN_ADMIN_TOKEN}
      # Invite-only signups
      SIGNUPS_ALLOWED: "false"
      INVITATIONS_ALLOWED: "true"
      # Required for invitation links
      DOMAIN: "https://vault.ragnalab.xyz"
      # 2FA settings (Claude's discretion: recommend TOTP, disable email 2FA)
      AUTHENTICATOR_ALLOWED: "true"
      EMAIL_2FA_ALLOWED: "false"
      # Optional: SMTP for invitations
      SMTP_HOST: ${SMTP_HOST:-}
      SMTP_FROM: ${SMTP_FROM:-}
      SMTP_PORT: ${SMTP_PORT:-587}
      SMTP_SECURITY: ${SMTP_SECURITY:-starttls}
      SMTP_USERNAME: ${SMTP_USERNAME:-}
      SMTP_PASSWORD: ${SMTP_PASSWORD:-}
    volumes:
      - vaultwarden-data:/data
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.vaultwarden.rule=Host(`vault.ragnalab.xyz`)"
      # ... standard Traefik labels
      - "homepage.group=Apps"
      - "homepage.name=Vaultwarden"
      - "homepage.icon=bitwarden.png"
      - "homepage.href=https://vault.ragnalab.xyz"
      - "homepage.description=Password Manager"
      - "docker-volume-backup.stop-during-backup=vaultwarden"
```

### Pattern 5: App Template Structure
**What:** Boilerplate for new applications
**When to use:** When adding any new app to RagnaLab
**Example:**
```yaml
# apps/_template/docker-compose.yml
# Template for new RagnaLab applications
# Copy this folder, rename, and customize

services:
  # TODO: Rename 'myapp' to your service name
  myapp:
    image: # TODO: image:tag
    container_name: myapp
    restart: unless-stopped
    # TODO: Uncomment if service needs environment variables
    # environment:
    #   - VAR_NAME=value
    # TODO: Uncomment if service needs persistent data
    # volumes:
    #   - myapp-data:/data
    networks:
      - proxy
    labels:
      # === TRAEFIK (Required) ===
      - "traefik.enable=true"
      # TODO: Change 'myapp' to your subdomain
      - "traefik.http.routers.myapp.rule=Host(`myapp.ragnalab.xyz`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      # TODO: Change port to your service's port
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
      - "traefik.docker.network=proxy"
      # === HOMEPAGE (Required) ===
      # TODO: Choose group: Infrastructure, Apps, or create new
      - "homepage.group=Apps"
      - "homepage.name=My App"
      # TODO: Find icon at https://github.com/walkxcode/dashboard-icons
      - "homepage.icon=myapp.png"
      - "homepage.href=https://myapp.ragnalab.xyz"
      - "homepage.description=Brief description"
      # === BACKUP (If using volumes) ===
      # TODO: Uncomment if service has persistent data
      # - "docker-volume-backup.stop-during-backup=myapp"
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 128M
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

# TODO: Uncomment if service needs persistent data
# volumes:
#   myapp-data:

networks:
  proxy:
    external: true
```

### Anti-Patterns to Avoid
- **Homepage direct socket mount without considering security:** Use socket proxy or understand security implications
- **Plain text ADMIN_TOKEN in Vaultwarden:** Always hash with argon2id
- **Forgetting DOMAIN variable in Vaultwarden:** Invitation links will be broken
- **Mixing services.yaml and labels for same services:** Pick one approach, labels recommended
- **Hardcoding secrets in docker-compose.yml:** Use .env files and gitignore them

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Dashboard | Custom HTML/CSS status page | Homepage | 150+ widgets, auto-discovery, actively maintained |
| Password manager | Self-built auth system | Vaultwarden | Full Bitwarden API, browser extensions, mobile apps |
| Service discovery | Manual config editing | Docker labels | Zero-touch for new apps, consistent pattern |
| Admin token hashing | SHA256 or plain text | argon2id via /vaultwarden hash | Industry-standard password hashing |
| Icon library | Download individual icons | Dashboard Icons repo | 4000+ icons, consistent naming |

**Key insight:** Both Homepage and Vaultwarden are mature, well-maintained projects with ARM64 support. The Docker label approach for Homepage discovery aligns with existing Traefik patterns, minimizing cognitive overhead when adding new apps.

## Common Pitfalls

### Pitfall 1: Missing HOMEPAGE_ALLOWED_HOSTS
**What goes wrong:** Homepage returns 403 Forbidden or blank page
**Why it happens:** Security feature requiring explicit host allowlist
**How to avoid:** Set `HOMEPAGE_ALLOWED_HOSTS=home.ragnalab.xyz` (or `*` for development)
**Warning signs:** 403 errors, blank page, "not allowed" in logs

### Pitfall 2: Wrong Docker Network for Homepage Widget URLs
**What goes wrong:** Widget shows "API Error" or connection refused
**Why it happens:** Widget URL uses external hostname but Homepage can't resolve it
**How to avoid:** Use container name or internal port for widget URLs (e.g., `http://traefik:8080` not `https://traefik.ragnalab.xyz`)
**Warning signs:** Widgets show "API Error", logs show connection refused

### Pitfall 3: Vaultwarden ADMIN_TOKEN Dollar Sign Escaping
**What goes wrong:** Admin page returns invalid token error
**Why it happens:** Docker Compose interprets `$` as variable, argon2 hash contains many `$`
**How to avoid:** In docker-compose.yml, escape each `$` as `$$`. In .env file, use single quotes
**Warning signs:** "Invalid admin token" even with correct password

### Pitfall 4: Vaultwarden Without DOMAIN Variable
**What goes wrong:** Invitation emails contain wrong URLs, browser extension can't connect
**Why it happens:** Vaultwarden doesn't know its public URL
**How to avoid:** Always set `DOMAIN=https://vault.ragnalab.xyz`
**Warning signs:** Invitation links point to wrong host, WebSocket errors

### Pitfall 5: Homepage Docker Socket Access Misconfiguration
**What goes wrong:** No containers discovered, empty dashboard
**Why it happens:** docker.yaml misconfigured or socket not accessible
**How to avoid:** Verify docker.yaml points to correct socket or proxy, check socket permissions
**Warning signs:** Empty dashboard despite running containers, logs show Docker connection errors

### Pitfall 6: Forgetting to Add Uptime Kuma Monitor for New Apps
**What goes wrong:** App goes down without alerting
**Why it happens:** Template reminds but user forgets to create monitor
**How to avoid:** Template README includes checklist with explicit Uptime Kuma step
**Warning signs:** Service outage discovered manually instead of via alert

## Code Examples

Verified patterns from official sources:

### Homepage Docker Compose
```yaml
# Source: https://gethomepage.dev/installation/docker/
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest
    container_name: homepage
    restart: unless-stopped
    environment:
      HOMEPAGE_ALLOWED_HOSTS: "home.ragnalab.xyz"
      PUID: 1000
      PGID: 1000
    volumes:
      - ./config:/app/config
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.homepage.rule=Host(`home.ragnalab.xyz`)"
      - "traefik.http.routers.homepage.entrypoints=websecure"
      - "traefik.http.routers.homepage.tls=true"
      - "traefik.http.routers.homepage.tls.certresolver=letsencrypt"
      - "traefik.http.services.homepage.loadbalancer.server.port=3000"
      - "traefik.docker.network=proxy"
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 128M
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

networks:
  proxy:
    external: true
```

### Homepage docker.yaml for Socket Access
```yaml
# Source: https://gethomepage.dev/configs/docker/
# config/docker.yaml
my-docker:
  socket: /var/run/docker.sock
```

### Homepage settings.yaml
```yaml
# Source: https://gethomepage.dev/configs/settings/
# config/settings.yaml
title: RagnaLab
theme: dark
color: blue
headerStyle: boxed
statusStyle: dot
showStats: false  # Container stats, can be heavy
layout:
  Infrastructure:
    style: row
    columns: 3
    icon: mdi-server
  Apps:
    style: row
    columns: 3
    icon: mdi-apps
  Bookmarks:
    style: row
    columns: 4
    icon: mdi-bookmark
```

### Homepage services.yaml (Minimal with Labels)
```yaml
# Source: https://gethomepage.dev/configs/services/
# config/services.yaml
# Most services auto-discovered via Docker labels
# Only add services here that can't use labels (external, non-Docker)
---
```

### Homepage bookmarks.yaml
```yaml
# Source: https://gethomepage.dev/configs/bookmarks/
# config/bookmarks.yaml
- Developer:
    - GitHub:
        - abbr: GH
          href: https://github.com/
    - Cloudflare:
        - icon: cloudflare.png
          href: https://dash.cloudflare.com
          description: DNS & Domain

- Resources:
    - Tailscale Admin:
        - icon: tailscale.png
          href: https://login.tailscale.com/admin
          description: VPN Management
```

### Vaultwarden Docker Compose
```yaml
# Source: https://github.com/dani-garcia/vaultwarden/wiki/Configuration-overview
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      # Admin panel with argon2id hashed token
      # Generate: docker run --rm -it vaultwarden/server /vaultwarden hash
      ADMIN_TOKEN: ${VAULTWARDEN_ADMIN_TOKEN}
      # Security settings
      SIGNUPS_ALLOWED: "false"
      INVITATIONS_ALLOWED: "true"
      DOMAIN: "https://vault.ragnalab.xyz"
      # 2FA policy: TOTP only, no email 2FA
      AUTHENTICATOR_ALLOWED: "true"
      EMAIL_2FA_ALLOWED: "false"
      # SMTP (optional, for invitations)
      SMTP_HOST: ${SMTP_HOST:-}
      SMTP_FROM: ${SMTP_FROM:-}
      SMTP_PORT: ${SMTP_PORT:-587}
      SMTP_SECURITY: ${SMTP_SECURITY:-starttls}
      SMTP_USERNAME: ${SMTP_USERNAME:-}
      SMTP_PASSWORD: ${SMTP_PASSWORD:-}
    volumes:
      - vaultwarden-data:/data
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.vaultwarden.rule=Host(`vault.ragnalab.xyz`)"
      - "traefik.http.routers.vaultwarden.entrypoints=websecure"
      - "traefik.http.routers.vaultwarden.tls=true"
      - "traefik.http.routers.vaultwarden.tls.certresolver=letsencrypt"
      - "traefik.http.services.vaultwarden.loadbalancer.server.port=80"
      - "traefik.docker.network=proxy"
      # Homepage labels
      - "homepage.group=Apps"
      - "homepage.name=Vaultwarden"
      - "homepage.icon=bitwarden.png"
      - "homepage.href=https://vault.ragnalab.xyz"
      - "homepage.description=Password Manager"
      # Backup label
      - "docker-volume-backup.stop-during-backup=vaultwarden"
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 128M
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  vaultwarden-data:

networks:
  proxy:
    external: true
```

### Generate Vaultwarden Admin Token
```bash
# Source: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page
# Interactive prompt for password
docker run --rm -it vaultwarden/server /vaultwarden hash

# Output example:
# ADMIN_TOKEN='$argon2id$v=19$m=65540,t=3,p=4$...$...'

# For .env file: use single quotes, single $
# For docker-compose.yml environment: escape $ as $$
```

### Uptime Kuma Widget Configuration (via labels)
```yaml
# Source: https://gethomepage.dev/widgets/services/uptime-kuma/
# Add to uptime-kuma docker-compose.yml labels
labels:
  # Existing Traefik labels...
  # Homepage labels
  - "homepage.group=Infrastructure"
  - "homepage.name=Uptime Kuma"
  - "homepage.icon=uptime-kuma.png"
  - "homepage.href=https://status.ragnalab.xyz"
  - "homepage.description=Service Monitoring"
  - "homepage.widget.type=uptimekuma"
  - "homepage.widget.url=http://uptime-kuma:3001"
  - "homepage.widget.slug=status"  # Status page slug
```

### Traefik Widget Configuration (via labels)
```yaml
# Source: https://gethomepage.dev/widgets/services/traefik/
# Add to proxy/docker-compose.yml traefik labels
labels:
  # Existing labels...
  # Homepage labels
  - "homepage.group=Infrastructure"
  - "homepage.name=Traefik"
  - "homepage.icon=traefik.png"
  - "homepage.href=https://traefik.ragnalab.xyz"
  - "homepage.description=Reverse Proxy"
  - "homepage.widget.type=traefik"
  - "homepage.widget.url=http://traefik:8080"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Homepage services.yaml only | Docker labels for discovery | 2024+ | Zero-touch service registration |
| Plain text ADMIN_TOKEN | argon2id hashed token | v1.29.0+ | Industry-standard security |
| Bitwarden official | Vaultwarden for ARM/homelab | 2021+ | ARM64 native, lower resources |
| Manual dashboard icons | Dashboard Icons repository | 2023+ | 4000+ consistent icons |

**Deprecated/outdated:**
- `SMTP_SSL` in Vaultwarden - Use `SMTP_SECURITY` instead (starttls/force_tls/off)
- `SMTP_EXPLICIT_TLS` - Deprecated, use `SMTP_SECURITY`
- Plain text ADMIN_TOKEN - Always use argon2id hash

## Open Questions

Things that couldn't be fully resolved:

1. **Homepage Docker socket vs socket proxy**
   - What we know: Homepage needs Docker socket access for auto-discovery
   - What's unclear: Whether existing socket proxy (CONTAINERS=1) provides enough access for Homepage
   - Recommendation: Start with direct socket mount to Homepage (read-only), same pattern as Uptime Kuma

2. **SMTP provider for Vaultwarden invitations**
   - What we know: SMTP required to send invitation emails
   - What's unclear: Which SMTP provider user has (Gmail requires app password, Microsoft requires OAuth)
   - Recommendation: Make SMTP optional; document manual user creation via admin panel as fallback

3. **Homepage widget for Vaultwarden**
   - What we know: Homepage has 150+ service widgets
   - What's unclear: Whether Vaultwarden widget exists (not found in docs)
   - Recommendation: Use basic service card without widget; Vaultwarden doesn't expose useful stats anyway

## Sources

### Primary (HIGH confidence)
- [Homepage Docker Configuration](https://gethomepage.dev/configs/docker/) - Label discovery, docker.yaml setup
- [Homepage Settings](https://gethomepage.dev/configs/settings/) - Layout, theme, display options
- [Homepage Services](https://gethomepage.dev/configs/services/) - Widget configuration
- [Homepage Traefik Widget](https://gethomepage.dev/widgets/services/traefik/) - Traefik stats integration
- [Homepage Uptime Kuma Widget](https://gethomepage.dev/widgets/services/uptime-kuma/) - Status page integration
- [Vaultwarden Configuration Overview](https://github.com/dani-garcia/vaultwarden/wiki/Configuration-overview) - Environment variables
- [Vaultwarden Enabling Admin Page](https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page) - argon2id token generation
- [Vaultwarden SMTP Configuration](https://github.com/dani-garcia/vaultwarden/wiki/SMTP-Configuration) - Email setup for invitations

### Secondary (MEDIUM confidence)
- [GitHub gethomepage/homepage](https://github.com/gethomepage/homepage) - ARM64 multi-arch confirmation
- [Docker Hub vaultwarden/server](https://hub.docker.com/r/vaultwarden/server) - ARM64 support, version info
- [SimpleHomelab Vaultwarden Guide](https://www.simplehomelab.com/vaultwarden-docker-compose-guide/) - Docker Compose examples

### Tertiary (LOW confidence - verify before use)
- GitHub discussions on 2FA enforcement - Features may vary by version
- Socket proxy compatibility with Homepage - Needs testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official docs verified, ARM64 confirmed on both
- Architecture: HIGH - Patterns from official documentation
- Homepage labels: HIGH - Well-documented, matches existing Traefik label pattern
- Vaultwarden security: HIGH - Wiki documentation comprehensive
- Template pattern: MEDIUM - Derived from existing project patterns, not external standard

**Research date:** 2026-01-17
**Valid until:** 2026-02-17 (30 days - stable applications, mature projects)
