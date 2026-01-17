# Phase 1: Foundation & Routing - Research

**Researched:** 2026-01-16
**Domain:** Docker infrastructure, Traefik reverse proxy, Let's Encrypt SSL, security hardening
**Confidence:** HIGH

## Summary

Phase 1 establishes the secure foundation for the RagnaLab homelab: Traefik v3.6+ reverse proxy with automatic SSL certificates via Let's Encrypt DNS-01 challenge using Cloudflare. The infrastructure must be secure-by-default with Docker socket protection via Tecnativa socket proxy, network isolation, and security headers middleware.

The standard approach uses:
1. External Docker networks created before any compose files run
2. Docker socket proxy (tecnativa/docker-socket-proxy) to restrict Traefik's Docker API access to read-only container discovery
3. Traefik v3.6 with file provider for reusable middleware and Docker provider for automatic service discovery
4. Let's Encrypt staging certificates first (OPS-02), then migration to production
5. Security headers middleware defined in file provider and referenced via `@file` namespace

**Primary recommendation:** Use separate Docker Compose files for infrastructure (Traefik + socket proxy) and applications, with external networks created via `docker network create` before starting any services.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Traefik | v3.6.7 | Reverse proxy, HTTPS termination, service discovery | Native Docker integration via labels, automatic Let's Encrypt, no database required, CVE-2026-22045 patched |
| tecnativa/docker-socket-proxy | v0.4.2 | Docker API firewall | Restricts Traefik to read-only container/network queries, prevents privilege escalation |
| Let's Encrypt | via Traefik ACME | SSL certificates | Free, automated, 90-day certs with auto-renewal at 30 days before expiry |
| Docker Compose | v5.0.1+ | Container orchestration | Integrated plugin in Docker Engine v29+, compose v1 deprecated |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Cloudflare API | DNS-01 provider | Wildcard certificate challenges | Required for VPN-only setup (no public ports 80/443) |
| HAProxy (inside socket-proxy) | Alpine-based | Socket proxy backend | Automatically included in tecnativa image |
| whoami | traefik/whoami | Test service | Validate routing and certificates before adding real apps |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| tecnativa/docker-socket-proxy | linuxserver/socket-proxy | LinuxServer has similar API but different env var naming; tecnativa more established |
| File provider middleware | Docker labels only | Labels become verbose; file provider enables DRY middleware definitions |
| acme.json single file | Separate staging/production files | Single file simpler but requires delete/recreate when migrating to production |

**Installation:**
```bash
# Create external networks first
docker network create proxy
docker network create socket_proxy_network

# Pull images
docker pull traefik:v3.6
docker pull tecnativa/docker-socket-proxy:latest
docker pull traefik/whoami:latest
```

## Architecture Patterns

### Recommended Project Structure
```
ragnalab/
├── proxy/
│   ├── docker-compose.yml      # Traefik + socket proxy
│   ├── .env                    # CF_API_EMAIL, CF_DNS_API_TOKEN
│   ├── secrets/                # Optional Docker secrets
│   │   └── cf_api_token.txt
│   ├── traefik/
│   │   ├── traefik.yml         # Static configuration
│   │   ├── dynamic/            # File provider directory
│   │   │   ├── middlewares.yml # Security headers, rate limiting
│   │   │   └── tls.yml         # TLS options (optional)
│   │   ├── acme/
│   │   │   └── acme.json       # Let's Encrypt certificates (chmod 600)
│   │   └── logs/               # Access and error logs (optional)
├── apps/
│   ├── whoami/                 # Test service
│   │   └── docker-compose.yml
│   └── [future-apps]/
└── scripts/
    └── init-networks.sh        # Network creation script
```

### Pattern 1: External Shared Networks
**What:** Create Docker networks outside compose files, reference with `external: true`
**When to use:** Always - enables multi-compose communication
**Example:**
```yaml
# In any docker-compose.yml
networks:
  proxy:
    external: true
  socket_proxy_network:
    external: true
```

### Pattern 2: Socket Proxy Security Boundary
**What:** Traefik connects to socket proxy instead of raw Docker socket
**When to use:** Always - never expose Docker socket directly
**Example:**
```yaml
# Source: https://github.com/Tecnativa/docker-socket-proxy
services:
  socket-proxy:
    image: tecnativa/docker-socket-proxy:latest
    container_name: socket-proxy
    restart: unless-stopped
    privileged: true
    environment:
      - CONTAINERS=1    # Allow container listing
      - NETWORKS=1      # Allow network listing
      - SERVICES=0      # Deny service access
      - TASKS=0         # Deny task access
      - POST=0          # Deny ALL write operations
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - socket_proxy_network

  traefik:
    image: traefik:v3.6
    environment:
      - DOCKER_HOST=tcp://socket-proxy:2375
    networks:
      - socket_proxy_network
      - proxy
    # NO docker.sock volume mount!
```

### Pattern 3: File Provider for Shared Middleware
**What:** Define reusable middleware in YAML files, reference via `@file` namespace
**When to use:** For middleware shared across multiple services (security headers, rate limiting)
**Example:**
```yaml
# Source: https://doc.traefik.io/traefik/reference/install-configuration/providers/others/file/
# traefik/dynamic/middlewares.yml
http:
  middlewares:
    security-headers:
      headers:
        frameDeny: true
        contentTypeNosniff: true
        browserXssFilter: true
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
        forceSTSHeader: true
        contentSecurityPolicy: "default-src 'self'; script-src 'self'; object-src 'none';"
        referrerPolicy: "strict-origin-when-cross-origin"
        permissionsPolicy: "geolocation=(), microphone=(), camera=()"
        customResponseHeaders:
          server: ""
          x-powered-by: ""

    rate-limit:
      rateLimit:
        average: 100
        burst: 200
        period: 1s
```

### Pattern 4: Traefik Label-Based Routing
**What:** Configure routing via Docker container labels
**When to use:** All application services proxied by Traefik
**Example:**
```yaml
# Source: https://doc.traefik.io/traefik/providers/docker/
services:
  whoami:
    image: traefik/whoami:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(`whoami.ragnalab.xyz`)"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.tls.certresolver=letsencrypt"
      - "traefik.http.routers.whoami.middlewares=security-headers@file,rate-limit@file"
      - "traefik.http.services.whoami.loadbalancer.server.port=80"
      - "traefik.docker.network=proxy"
    networks:
      - proxy
```

### Anti-Patterns to Avoid
- **Direct Docker socket mount:** Never use `/var/run/docker.sock:/var/run/docker.sock` in Traefik container
- **exposedByDefault=true:** Always set to `false` and opt-in per service with `traefik.enable=true`
- **Secrets in compose files:** Never hardcode `CF_DNS_API_TOKEN=abc123` - use .env files or Docker secrets
- **Default bridge network:** Always define and use named networks with `external: true`
- **Single compose file:** Separate infrastructure (Traefik) from applications for independent lifecycle

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docker API filtering | Custom proxy or firewall rules | tecnativa/docker-socket-proxy | Battle-tested HAProxy config, maintained, multi-arch |
| SSL certificate management | Manual certbot, scripted renewal | Traefik ACME with DNS-01 | Automatic renewal, storage, domain detection |
| HTTP to HTTPS redirect | Nginx config, iptables | Traefik entrypoint redirections | Built-in, declarative, no extra containers |
| Security headers | Manual header injection | Traefik headers middleware | Consistent, reusable, validated defaults |
| Log rotation | External logrotate, cron | Traefik built-in + Docker log driver | maxSize, maxBackups options; json-file driver limits |
| Container discovery | Service registry, manual config | Traefik Docker provider | Automatic via labels, hot reload |

**Key insight:** Traefik is designed as a complete edge router - resist the urge to add external tools for SSL, routing, or security headers.

## Common Pitfalls

### Pitfall 1: Let's Encrypt Rate Limit Exhaustion
**What goes wrong:** Hitting 50 certificates/week limit during testing, locked out for 7 days
**Why it happens:** Using production ACME server during initial setup, acme.json loss, misconfiguration causing re-requests
**How to avoid:**
- ALWAYS use staging server first: `caServer: https://acme-staging-v02.api.letsencrypt.org/directory`
- Persist acme.json on named volume, not bind mount to SD card
- Test with `curl -k` to accept staging certs, then migrate to production
**Warning signs:** Traefik logs show repeated ACME failures, "too many certificates" errors

### Pitfall 2: Docker Socket Privilege Escalation
**What goes wrong:** Traefik compromise leads to host root access
**Why it happens:** Mounting Docker socket directly gives full Docker API access (even with `:ro`)
**How to avoid:**
- Use socket proxy with `POST=0` (read-only)
- Run Traefik with `security_opt: - no-new-privileges:true`
- Enable only `CONTAINERS=1` and `NETWORKS=1` in socket proxy
**Warning signs:** Socket mounted without proxy, no security_opt in compose

### Pitfall 3: DNS-01 Propagation Timeout
**What goes wrong:** Let's Encrypt DNS-01 challenges fail because TXT record not propagated
**Why it happens:** Default `delayBeforeCheck` too short for DNS propagation (20-180 seconds)
**How to avoid:**
- Set `delayBeforeCheck: 60` or higher in dnsChallenge config
- Use Cloudflare (fast propagation ~20s) not slow providers
- Add resolvers for verification: `resolvers: ["1.1.1.1:53", "8.8.8.8:53"]`
**Warning signs:** "no TXT record found" in logs, works on retry

### Pitfall 4: Wrong Docker Network Selection
**What goes wrong:** 502 Bad Gateway because Traefik routes to wrong network
**Why it happens:** Container on multiple networks, Traefik picks randomly
**How to avoid:**
- Always set `traefik.docker.network=proxy` label
- Verify network with `docker network inspect proxy`
- Use Docker service names, never localhost
**Warning signs:** Services work directly but fail through Traefik, random routing failures

### Pitfall 5: Staging to Production Migration Failure
**What goes wrong:** Changing caServer doesn't issue new production certificates
**Why it happens:** Traefik reuses cached staging certs from acme.json
**How to avoid:**
- Use separate files: `acme-staging.json` and `acme-prod.json`
- OR stop Traefik, delete acme.json, `touch acme.json && chmod 600 acme.json`, restart
- Test staging thoroughly before switching
**Warning signs:** Browser shows "Fake LE Intermediate X1" after switching to production

### Pitfall 6: File Provider Watch Failure in Docker
**What goes wrong:** Changes to dynamic config files not detected
**Why it happens:** Docker volume mounts break fsnotify file system notifications
**How to avoid:**
- Mount entire parent directory, not individual files
- Use `providers.file.directory` not `providers.file.filename`
- Set `watch: true` explicitly
**Warning signs:** Config changes require Traefik restart to apply

## Code Examples

Verified patterns from official sources:

### Traefik Static Configuration (traefik.yml)
```yaml
# Source: https://doc.traefik.io/traefik/v3.6/setup/docker/
api:
  dashboard: true
  insecure: false  # Never true in production

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"
    http:
      tls: true

providers:
  docker:
    endpoint: "tcp://socket-proxy:2375"
    exposedByDefault: false
    network: proxy
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /etc/traefik/acme/acme.json
      # STAGING - comment out for production
      caServer: https://acme-staging-v02.api.letsencrypt.org/directory
      dnsChallenge:
        provider: cloudflare
        delayBeforeCheck: 60
        resolvers:
          - "1.1.1.1:53"
          - "8.8.8.8:53"

log:
  level: INFO
  filePath: /var/log/traefik/traefik.log
  maxSize: 100
  maxBackups: 5

accessLog:
  filePath: /var/log/traefik/access.log
  format: json
  bufferingSize: 100
```

### Infrastructure Docker Compose (proxy/docker-compose.yml)
```yaml
# Source: https://doc.traefik.io/traefik/v3.6/setup/docker/
# Source: https://github.com/Tecnativa/docker-socket-proxy

services:
  socket-proxy:
    image: tecnativa/docker-socket-proxy:latest
    container_name: socket-proxy
    restart: unless-stopped
    privileged: true
    environment:
      - CONTAINERS=1
      - NETWORKS=1
      - SERVICES=0
      - TASKS=0
      - POST=0
      - BUILD=0
      - COMMIT=0
      - CONFIGS=0
      - SECRETS=0
      - IMAGES=0
      - VOLUMES=0
      - AUTH=0
      - EXEC=0
      - PLUGINS=0
      - SWARM=0
      - SYSTEM=0
      - LOG_LEVEL=info
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - socket_proxy_network
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  traefik:
    image: traefik:v3.6
    container_name: traefik
    restart: unless-stopped
    depends_on:
      - socket-proxy
    security_opt:
      - no-new-privileges:true
    environment:
      - CF_API_EMAIL=${CF_API_EMAIL}
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik/dynamic:/etc/traefik/dynamic:ro
      - ./traefik/acme:/etc/traefik/acme
      - traefik_logs:/var/log/traefik
    networks:
      - socket_proxy_network
      - proxy
    labels:
      - "traefik.enable=true"
      # Dashboard routing
      - "traefik.http.routers.dashboard.rule=Host(`traefik.ragnalab.xyz`)"
      - "traefik.http.routers.dashboard.entrypoints=websecure"
      - "traefik.http.routers.dashboard.service=api@internal"
      - "traefik.http.routers.dashboard.tls=true"
      - "traefik.http.routers.dashboard.tls.certresolver=letsencrypt"
      - "traefik.http.routers.dashboard.middlewares=security-headers@file"
      # Optional: Add basicauth for dashboard
      # - "traefik.http.middlewares.dashboard-auth.basicauth.users=${DASHBOARD_AUTH}"
      # - "traefik.http.routers.dashboard.middlewares=security-headers@file,dashboard-auth@docker"
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

networks:
  proxy:
    external: true
  socket_proxy_network:
    external: true

volumes:
  traefik_logs:
    name: traefik_logs
```

### Security Headers Middleware (traefik/dynamic/middlewares.yml)
```yaml
# Source: https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/headers/
http:
  middlewares:
    security-headers:
      headers:
        # HSTS - force HTTPS
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
        forceSTSHeader: true

        # Prevent clickjacking
        frameDeny: true

        # Prevent MIME type sniffing
        contentTypeNosniff: true

        # XSS protection (legacy but still useful)
        browserXssFilter: true

        # Content Security Policy
        contentSecurityPolicy: >-
          default-src 'self';
          script-src 'self';
          style-src 'self' 'unsafe-inline';
          img-src 'self' data:;
          font-src 'self';
          object-src 'none';
          base-uri 'self';
          form-action 'self';
          frame-ancestors 'none';

        # Referrer Policy
        referrerPolicy: "strict-origin-when-cross-origin"

        # Permissions Policy
        permissionsPolicy: "geolocation=(), microphone=(), camera=()"

        # Hide server info
        customResponseHeaders:
          server: ""
          x-powered-by: ""

    rate-limit:
      rateLimit:
        average: 100
        burst: 200
        period: 1s

    # Optional: More restrictive rate limit for APIs
    rate-limit-api:
      rateLimit:
        average: 20
        burst: 50
        period: 1s
```

### Test Service (apps/whoami/docker-compose.yml)
```yaml
services:
  whoami:
    image: traefik/whoami:latest
    container_name: whoami
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(`whoami.ragnalab.xyz`)"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.tls.certresolver=letsencrypt"
      - "traefik.http.routers.whoami.middlewares=security-headers@file,rate-limit@file"
      - "traefik.http.services.whoami.loadbalancer.server.port=80"
      - "traefik.docker.network=proxy"
    networks:
      - proxy
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

networks:
  proxy:
    external: true
```

### Environment File Template (.env.example)
```bash
# Cloudflare API credentials for DNS-01 challenge
CF_API_EMAIL=your-email@example.com
CF_DNS_API_TOKEN=your-cloudflare-api-token

# Optional: Dashboard basic auth (generate with: htpasswd -nb admin password | sed -e 's/\$/\$\$/g')
# DASHBOARD_AUTH=admin:$$apr1$$...
```

### Network Initialization Script (scripts/init-networks.sh)
```bash
#!/bin/bash
# Create external networks before starting any compose files

echo "Creating Docker networks..."

docker network create proxy 2>/dev/null || echo "Network 'proxy' already exists"
docker network create socket_proxy_network 2>/dev/null || echo "Network 'socket_proxy_network' already exists"

echo "Networks ready:"
docker network ls | grep -E 'proxy|socket_proxy'
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Traefik v2.x | Traefik v3.6+ | v3.0 GA April 2024 | New router syntax, breaking changes in labels |
| docker-compose (hyphenated) | docker compose (space) | Compose v2, July 2023 | CLI change, v1 deprecated |
| HTTP-01 challenge | DNS-01 challenge | Standard for VPN-only | Enables wildcard certs without public ports |
| Single compose file | Modular compose files | Best practice | Independent service lifecycles |
| Direct socket mount | Socket proxy | Security best practice | Prevents privilege escalation |

**Deprecated/outdated:**
- Traefik v2.11.x: Security updates only, no new features
- `traefik.frontend.*` labels: v1 syntax, use `traefik.http.routers.*`
- `docker-compose` CLI: Replaced by `docker compose` plugin
- HTTP-01 with VPN: Incompatible with Tailscale-only access

## Open Questions

Things that couldn't be fully resolved:

1. **ARM64 compatibility verification for socket-proxy**
   - What we know: tecnativa/docker-socket-proxy uses Alpine HAProxy, should work on ARM64
   - What's unclear: Official multi-arch manifest not documented
   - Recommendation: Test on Pi 5 before committing; fallback to linuxserver/socket-proxy if needed

2. **Optimal delayBeforeCheck for Cloudflare**
   - What we know: Cloudflare propagates ~20 seconds, docs recommend 60-120s
   - What's unclear: Exact optimal value for ragnalab.xyz zone
   - Recommendation: Start with 60s, increase if seeing propagation failures

3. **CSP policy for future apps**
   - What we know: Restrictive default CSP defined
   - What's unclear: Which apps will need CSP relaxation
   - Recommendation: Define base CSP, allow per-app overrides via separate middleware

## Sources

### Primary (HIGH confidence)
- [Traefik v3.6 Docker Setup](https://doc.traefik.io/traefik/v3.6/setup/docker/) - Static configuration, Docker provider, entry points
- [Traefik ACME Certificate Resolvers](https://doc.traefik.io/traefik/reference/install-configuration/tls/certificate-resolvers/acme/) - DNS-01 challenge, Cloudflare, wildcard certs
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/) - Label-based routing, exposedByDefault
- [Traefik File Provider](https://doc.traefik.io/traefik/reference/install-configuration/providers/others/file/) - Directory watch, middleware files
- [Traefik Headers Middleware](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/headers/) - Security headers, HSTS, CSP
- [Traefik RateLimit Middleware](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/ratelimit/) - Token bucket, average/burst
- [tecnativa/docker-socket-proxy GitHub](https://github.com/Tecnativa/docker-socket-proxy) - Environment variables, security warnings
- [Docker Storage - tmpfs](https://docs.docker.com/engine/storage/tmpfs) - Ephemeral mounts
- [Docker Storage - Volumes](https://docs.docker.com/engine/storage/volumes) - Named volumes best practices

### Secondary (MEDIUM confidence)
- [SimpleHomelab Traefik Docker Compose Guide 2025](https://www.simplehomelab.com/udms-18-traefik-docker-compose-guide/) - Socket proxy network separation
- [SimpleHomelab Docker Security Best Practices](https://www.simplehomelab.com/traefik-docker-security-best-practices/) - Security hardening patterns
- [Wildcard LetsEncrypt certificates with Traefik and Cloudflare](https://major.io/p/wildcard-letsencrypt-certificates-traefik-cloudflare/) - DNS-01 configuration
- [Hardening Traefik with Security Headers](https://xfuture-blog.com/posts/hardening-your-traefik-with-security-headers/) - Complete middleware examples
- [Let's Encrypt Community: Staging to Production](https://community.letsencrypt.org/t/switching-from-lets-encrypt-staging-to-production/69587) - Migration process

### Tertiary (LOW confidence - needs validation)
- ARM64 compatibility for tecnativa/docker-socket-proxy: Not officially documented, inferred from Alpine base

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official documentation, verified versions
- Architecture: HIGH - Multiple authoritative guides agree
- Security patterns: HIGH - Official Traefik docs + security best practice sources
- Pitfalls: HIGH - Documented in project research + community forums
- ARM64 socket-proxy: MEDIUM - Inferred, needs testing

**Research date:** 2026-01-16
**Valid until:** ~30 days (Traefik stable, slow-moving infrastructure)

---
*Phase 1 research for: RagnaLab Homelab Infrastructure*
