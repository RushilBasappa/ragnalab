# Architecture Research: Docker-Based Homelab with Traefik and Tailscale

**Domain:** Homelab Infrastructure (Raspberry Pi 5)
**Researched:** 2026-01-16
**Confidence:** HIGH

## System Overview

Modern Docker-based homelabs with reverse proxy and VPN follow a layered architecture with clear separation between networking, routing, security, and application layers.

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLIENT ACCESS LAYER                         │
│  ┌──────────────┐                        ┌──────────────┐        │
│  │   Internet   │                        │  Tailscale   │        │
│  │  (ports 80/  │                        │     VPN      │        │
│  │     443)     │                        │   Network    │        │
│  └──────┬───────┘                        └──────┬───────┘        │
├─────────┼──────────────────────────────────────┼─────────────────┤
│         │              ROUTING LAYER            │                 │
│         └──────────────────┬───────────────────┘                 │
│                    ┌───────▼────────┐                            │
│                    │     Traefik    │                            │
│                    │ Reverse Proxy  │                            │
│                    │ (HTTPS Term.,  │                            │
│                    │  DNS Routing,  │                            │
│                    │  Let's Encrypt)│                            │
│                    └───────┬────────┘                            │
│                            │                                     │
├────────────────────────────┼─────────────────────────────────────┤
│              SECURITY & DISCOVERY LAYER                          │
│  ┌─────────────────┐       │       ┌──────────────────┐         │
│  │ Docker Socket   │◄──────┘       │   File Provider  │         │
│  │     Proxy       │               │   (Middleware,   │         │
│  │  (API Firewall) │               │   Certificates)  │         │
│  └─────────────────┘               └──────────────────┘         │
├──────────────────────────────────────────────────────────────────┤
│                   DOCKER NETWORK LAYER                           │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐    │
│  │  proxy_network   │  │  socket_network  │  │  internal  │    │
│  │  (Traefik ↔ Apps)│  │  (Traefik ↔ API) │  │  (App ↔DB) │    │
│  └────────┬─────────┘  └──────────────────┘  └─────┬──────┘    │
├───────────┼─────────────────────────────────────────┼───────────┤
│                    APPLICATION LAYER                 │           │
│  ┌────────┴─────────┬──────────────┬────────────────┴──────┐   │
│  │ App Service 1    │ App Service 2│  App Service N         │   │
│  │ (Docker labels)  │ (Docker      │  (Docker labels)       │   │
│  │                  │  labels)     │                        │   │
│  │  ┌───────────┐   │  ┌────────┐  │   ┌────────────┐      │   │
│  │  │ Container │   │  │Container│  │   │  Container │      │   │
│  │  └───────────┘   │  └────────┘  │   └────────────┘      │   │
│  └──────────────────┴──────────────┴────────────────────────┘   │
├──────────────────────────────────────────────────────────────────┤
│                      PERSISTENCE LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐         │
│  │ Volume Mounts│  │ Config Files │  │  Certificates │         │
│  │ (app data)   │  │ (.env, .yml) │  │  (acme.json)  │         │
│  └──────────────┘  └──────────────┘  └───────────────┘         │
└──────────────────────────────────────────────────────────────────┘
```

## Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **Traefik** | Reverse proxy, HTTPS termination, automatic service discovery, certificate management | Docker container with static config (traefik.yml) and dynamic config (file provider + Docker labels) |
| **Tailscale** | VPN overlay network, secure remote access, MagicDNS | Sidecar container pattern or subnet router mode |
| **Docker Socket Proxy** | API security firewall, restricts Traefik's Docker access | Tecnativa or FluenceLab socket proxy container with read-only socket mount |
| **Docker Networks** | Network isolation, service segmentation | User-defined bridge networks: `proxy`, `socket`, `internal` |
| **Let's Encrypt** | SSL/TLS certificate provisioning | DNS-01 challenge via Traefik for wildcard certs |
| **Application Services** | Core homelab functionality | Individual Docker Compose files per service with Traefik labels |
| **File Provider** | Static middleware, custom routes, shared config | YAML files in `config/` directory watched by Traefik |

## Recommended Project Structure

```
homelab/
├── docker-compose.yml              # Infrastructure baseline (Traefik, socket proxy)
├── .env                            # Global environment variables (DNS API tokens)
├── traefik/
│   ├── traefik.yml                 # Static configuration
│   ├── config/                     # Dynamic file provider configs
│   │   ├── middlewares.yml         # Reusable middleware (security headers, auth)
│   │   ├── tls.yml                 # TLS options, certificate resolvers
│   │   └── routes.yml              # Static routes (optional)
│   ├── acme.json                   # Let's Encrypt certificates (chmod 600)
│   └── logs/                       # Access and error logs
├── tailscale/
│   ├── docker-compose.yml          # Tailscale service
│   └── state/                      # Persistent tailscale state
├── apps/
│   ├── whoami/                     # Example app - each in own folder
│   │   ├── docker-compose.yml      # Service definition with labels
│   │   ├── .env                    # App-specific environment variables
│   │   └── data/                   # App data volumes
│   ├── homepage/
│   │   ├── docker-compose.yml
│   │   └── config/
│   └── [service-n]/
│       └── docker-compose.yml
└── scripts/
    ├── add-service.sh              # Template for adding new services
    └── backup.sh                   # Backup automation
```

### Structure Rationale

- **Modular service isolation:** Each app in `apps/` has its own compose file, making it easy to start/stop/update independently
- **Centralized routing config:** Traefik configuration in dedicated directory with file provider for shared middleware
- **Security-first defaults:** Socket proxy prevents Docker API exposure, networks isolate traffic
- **Version control friendly:** `.env` files for secrets (gitignored), YAML for configuration (committed)
- **Pi 5 optimized:** SSD-mounted volumes for `/var/lib/docker` and persistent data to avoid SD card wear

## Architectural Patterns

### Pattern 1: External Shared Networks

**What:** Create Docker networks outside of any compose file, then reference them as `external: true` in multiple compose files.

**When to use:** When running multiple compose projects that need to communicate (e.g., all apps need to reach Traefik).

**Trade-offs:**
- **Pro:** Services in different compose files can communicate seamlessly
- **Pro:** Networks persist across `docker-compose down`
- **Con:** Must be created manually before first `docker-compose up`
- **Con:** Not obvious from compose file alone that network is shared

**Example:**
```bash
# Create networks once
docker network create proxy
docker network create socket_proxy_network

# Reference in docker-compose.yml
networks:
  proxy:
    external: true
  socket_proxy_network:
    external: true
```

### Pattern 2: Traefik Docker Label-Based Routing

**What:** Use Docker labels on service containers to automatically configure Traefik routes, middleware, and TLS settings.

**When to use:** For all application services that should be proxied by Traefik. This is the primary service discovery mechanism.

**Trade-offs:**
- **Pro:** Automatic service discovery - no manual route configuration
- **Pro:** Configuration lives with the service it configures
- **Pro:** Hot reload when containers start/stop
- **Con:** Labels can become verbose for complex routing
- **Con:** Harder to share middleware across services without file provider

**Example:**
```yaml
services:
  whoami:
    image: traefik/whoami
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(`whoami.yourdomain.com`)"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.tls=true"
      - "traefik.http.routers.whoami.tls.certresolver=letsencrypt"
      - "traefik.http.routers.whoami.middlewares=security-headers@file"
      - "traefik.http.services.whoami.loadbalancer.server.port=80"
    networks:
      - proxy
```

### Pattern 3: Tailscale Sidecar Container

**What:** Deploy Tailscale as a sidecar container using `network_mode: service:<name>` to share network namespace with application.

**When to use:** When you want individual services accessible via Tailscale with their own tailnet hostnames, without exposing via Traefik.

**Trade-offs:**
- **Pro:** Each service gets its own Tailscale node and hostname
- **Pro:** Fine-grained access control per service
- **Pro:** No reverse proxy needed for Tailscale access
- **Con:** More Tailscale nodes (consumes tailnet node quota)
- **Con:** Requires `depends_on` and careful container startup ordering
- **Con:** More resource usage (one Tailscale container per service)

**Example:**
```yaml
services:
  tailscale-whoami:
    image: tailscale/tailscale:latest
    hostname: whoami-homelab
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=true
    volumes:
      - ./tailscale/whoami:/var/lib/tailscale

  whoami:
    image: traefik/whoami
    network_mode: service:tailscale-whoami
    depends_on:
      - tailscale-whoami
```

### Pattern 4: File Provider for Shared Middleware

**What:** Define reusable Traefik middleware in YAML files that are referenced from Docker labels using `@file` namespace syntax.

**When to use:** For security headers, rate limiting, authentication middleware used by multiple services.

**Trade-offs:**
- **Pro:** DRY - define once, use everywhere via labels
- **Pro:** Easier to audit and update security policies centrally
- **Pro:** Hot reload with `file.watch=true`
- **Con:** Middleware definition separated from service definition
- **Con:** Requires understanding of Traefik provider namespaces

**Example:**
```yaml
# traefik/config/middlewares.yml
http:
  middlewares:
    security-headers:
      headers:
        frameDeny: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000

    rate-limit:
      rateLimit:
        average: 100
        burst: 50

# Reference from Docker label
labels:
  - "traefik.http.routers.myapp.middlewares=security-headers@file,rate-limit@file"
```

### Pattern 5: Docker Socket Proxy Security

**What:** Place a security proxy (Tecnativa or FluenceLab socket-proxy) between Traefik and the Docker socket, restricting API access to read-only container/network queries.

**When to use:** Always in production or internet-exposed homelabs. Essential security best practice.

**Trade-offs:**
- **Pro:** Prevents Traefik compromise from escalating to host root access
- **Pro:** Principle of least privilege - Traefik only gets required permissions
- **Pro:** Minimal performance overhead
- **Con:** Additional container to manage
- **Con:** Requires privileged mode for socket proxy itself

**Example:**
```yaml
services:
  socket-proxy:
    image: tecnativa/docker-socket-proxy
    restart: unless-stopped
    privileged: true
    environment:
      - CONTAINERS=1
      - NETWORKS=1
      - SERVICES=0
      - TASKS=0
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - socket_proxy_network

  traefik:
    image: traefik:v3.2
    environment:
      - DOCKER_HOST=tcp://socket-proxy:2375
    networks:
      - socket_proxy_network
      - proxy
```

## Data Flow

### Request Flow: Internet → Application

```
1. HTTPS Request (example.com)
   ↓
2. DNS Resolution (Let's Encrypt wildcard *.yourdomain.com)
   ↓
3. Traefik Entry Point (port 443)
   ↓
4. Traefik Router Matching
   - Checks Host() rule from Docker labels
   - Matches to service
   ↓
5. Middleware Chain Execution
   - Security headers (@file provider)
   - Rate limiting (@file provider)
   - Authentication (optional)
   ↓
6. TLS Termination
   - Let's Encrypt certificate loaded
   - HTTPS → HTTP
   ↓
7. Service Load Balancer
   - Routes to container on proxy network
   - Port from traefik.http.services.<name>.loadbalancer.server.port label
   ↓
8. Application Container
   - Receives HTTP request
   - Returns response
   ↓
9. Response Path (reverse)
   - Container → Traefik → TLS encryption → Client
```

### Request Flow: Tailscale → Application

```
1. Tailscale Client (laptop/phone)
   ↓
2. Tailscale Mesh Network
   - Encrypted WireGuard tunnel
   - Direct connection or DERP relay
   ↓
3. Homelab Tailscale Node
   - Subnet router mode OR sidecar container
   ↓
4. Local Network Access
   ↓ (Option A: via Traefik)
   Traefik on proxy network → Application

   ↓ (Option B: direct)
   Application container (if sidecar pattern)
```

### Service Discovery Flow

```
1. New Container Starts
   ↓
2. Docker Engine Emits Event
   ↓
3. Socket Proxy Filters Event
   - Forwards container.list, network.list to Traefik
   - Blocks write operations
   ↓
4. Traefik Docker Provider Receives Event
   ↓
5. Traefik Extracts Labels
   - traefik.enable=true?
   - traefik.http.routers.* labels
   - traefik.http.services.* labels
   ↓
6. Traefik Updates Routing Configuration
   - Creates router
   - Creates or updates service backend
   - Attaches middleware
   ↓
7. Configuration Hot Reload
   - No Traefik restart required
   - New routes immediately active
```

### Certificate Acquisition Flow (DNS-01 Challenge)

```
1. Traefik Detects New Domain
   - From router rule or main/sans config
   ↓
2. Let's Encrypt ACME Request
   ↓
3. DNS-01 Challenge Issued
   ↓
4. Traefik Calls DNS Provider API
   - Cloudflare, DuckDNS, etc.
   - Creates _acme-challenge TXT record
   ↓
5. Let's Encrypt Verifies DNS
   ↓
6. Certificate Issued
   ↓
7. Traefik Stores Certificate
   - Writes to acme.json
   - Loads into memory
   ↓
8. Automatic Renewal (30 days before expiry)
   - Traefik handles automatically
   - No manual intervention
```

## Network Topology

### Docker Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      Docker Host                         │
│                                                          │
│  ┌────────────────────────────────────────────────┐     │
│  │  proxy (bridge, subnet: 192.168.90.0/24)       │     │
│  │                                                 │     │
│  │  ┌─────────┐  ┌──────┐  ┌──────┐  ┌──────┐    │     │
│  │  │ Traefik │  │ App1 │  │ App2 │  │ AppN │    │     │
│  │  └────┬────┘  └──┬───┘  └──┬───┘  └──┬───┘    │     │
│  └───────┼──────────┼─────────┼─────────┼─────────┘     │
│          │          │         │         │               │
│  ┌───────┼──────────┼─────────┼─────────┼─────────┐     │
│  │ socket_proxy_network (192.168.91.0/24)         │     │
│  │       │                                         │     │
│  │  ┌────▼──────┐                                  │     │
│  │  │  Traefik  │                                  │     │
│  │  └────┬──────┘                                  │     │
│  │       │                                         │     │
│  │  ┌────▼────────────┐                            │     │
│  │  │  Socket Proxy   │                            │     │
│  │  └────┬────────────┘                            │     │
│  └───────┼───────────────────────────────────────┘      │
│          │                                               │
│     /var/run/docker.sock (Unix socket)                   │
│                                                          │
│  ┌─────────────────────────────────────────────────┐    │
│  │  app_internal (per-app private networks)        │    │
│  │                                                  │    │
│  │  ┌──────┐        ┌──────────┐                   │    │
│  │  │ App3 │◄──────►│ Database │                   │    │
│  │  └──────┘        └──────────┘                   │    │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
└──────────────────────────────────────────────────────────┘

Tailscale Overlay Network (WireGuard)
┌─────────────────────────────────────────────────────┐
│  100.x.x.x/32 addresses assigned to:                 │
│  - Homelab node (subnet router or individual nodes) │
│  - Client devices (laptop, phone, etc.)             │
│  Routes: 192.168.90.0/24, 192.168.91.0/24 advertised│
└──────────────────────────────────────────────────────┘
```

### Network Design Principles

1. **Isolation by function:**
   - `proxy`: Only Traefik and apps needing HTTP routing
   - `socket_proxy_network`: Only Traefik and socket proxy (security boundary)
   - `app_internal`: App-specific networks for backend services (databases, caches)

2. **Minimal exposure:**
   - Applications NOT on `proxy` network are unreachable via Traefik
   - Socket proxy network prevents apps from accessing Docker API
   - Internal networks prevent cross-app communication

3. **External networks:**
   - Created once: `docker network create proxy`
   - Shared across all compose files with `external: true`
   - Persist across `docker-compose down`

## Tailscale Integration Patterns

### Pattern A: Subnet Router (Recommended for Homelab)

**Architecture:**
```
Tailscale Device → Tailscale Mesh → Homelab Subnet Router → Docker Networks
```

**Characteristics:**
- One Tailscale node advertises entire Docker network subnets
- Apps accessed via `http://192.168.90.x:port` or via Traefik hostname
- Minimal node count (doesn't consume tailnet quota)
- Can combine with Traefik for friendly hostnames

**Implementation:**
```yaml
services:
  tailscale:
    image: tailscale/tailscale:latest
    hostname: homelab-gateway
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_ROUTES=192.168.90.0/24,192.168.91.0/24
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
    volumes:
      - ./tailscale/state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    network_mode: host
```

### Pattern B: Traefik + Tailscale Hybrid

**Architecture:**
```
Public traffic → Traefik (ports 80/443) → Apps
Private traffic → Tailscale → Traefik (MagicDNS) → Apps
```

**Characteristics:**
- Traefik accessible via both Internet and Tailscale
- Use different entrypoints or routers for public vs private
- Middleware can enforce Tailscale-only access for sensitive apps

**Implementation:**
- Traefik container on host network or joined to Tailscale network
- Routers with `ClientIP` middleware to restrict access
- MagicDNS provides `<hostname>.tailnet-name.ts.net` resolution

### Pattern C: Per-Service Sidecar (Advanced)

**Architecture:**
```
Tailscale Device → Service-specific Tailscale node → Application container
```

**Characteristics:**
- Each app gets its own `<service>.tailnet.ts.net` hostname
- Bypasses Traefik entirely
- Maximum isolation and control

**Use case:** High-security services or when bypassing reverse proxy is desired

## Configuration Management

### Environment Variable Hierarchy

```
1. Host system environment
   ↓
2. .env file in project root (global secrets)
   ↓
3. .env file in app directory (app-specific overrides)
   ↓
4. docker-compose.yml environment: section
   ↓
5. Runtime environment injection
```

### Secrets Management Approaches

| Approach | Security | Complexity | Pi 5 Suitable |
|----------|----------|------------|---------------|
| `.env` files (gitignored) | Low | Very Low | Yes - good for homelab |
| Docker Secrets (Compose) | Medium | Low | Yes - recommended |
| File-based secrets (`/run/secrets`) | Medium | Low | Yes - best practice |
| HashiCorp Vault | High | High | Overkill for single-node homelab |
| External secret managers | High | Medium | Possible but complex |

**Recommended for RagnaLab:**
```yaml
# docker-compose.yml
secrets:
  cf_api_token:
    file: ./secrets/cf_api_token.txt
  ts_authkey:
    file: ./secrets/ts_authkey.txt

services:
  traefik:
    secrets:
      - cf_api_token
    environment:
      - CF_API_EMAIL_FILE=/run/secrets/cf_api_token
```

### Configuration Hot Reload

**File Provider:**
```yaml
# traefik.yml
providers:
  file:
    directory: /etc/traefik/config
    watch: true  # Automatically reload on file changes
```

**Docker Provider:**
- Automatically watches Docker events
- No restart needed when containers start/stop
- Labels updated → routes updated within seconds

## Build Order and Dependencies

### Phase 1: Foundation (Critical Path)

```
1. Docker Networks (prerequisite for everything)
   docker network create proxy
   docker network create socket_proxy_network

2. Traefik Base (no apps yet)
   - Traefik container with static config
   - Socket proxy container
   - File provider directory structure
   - Initial middleware definitions

   Dependencies: Docker networks
   Validation: Access Traefik dashboard, verify API connectivity

3. Let's Encrypt Configuration
   - DNS provider credentials in secrets
   - Certificate resolver config
   - Wildcard certificate request

   Dependencies: Traefik base, DNS API access
   Validation: acme.json populated, certificate issued
```

### Phase 2: VPN Layer (Parallel to Apps)

```
4. Tailscale Integration
   - Tailscale container (subnet router or sidecar)
   - MagicDNS configuration
   - Route advertisement

   Dependencies: Docker networks (if using bridge mode)
   Validation: Ping homelab from Tailscale device
```

### Phase 3: Application Services (Can Parallelize)

```
5. First Application (whoami or homepage)
   - Validate label-based routing
   - Verify middleware application
   - Test HTTPS and certificate

   Dependencies: Traefik + Let's Encrypt working
   Validation: Access via HTTPS, certificate valid

6. Subsequent Applications
   - Copy template from successful first app
   - Modify labels for new hostname
   - Add app-specific middleware as needed

   Dependencies: Traefik routing proven
   Validation: Each app accessible independently
```

### Critical Path Dependencies

```
Docker Networks
    ↓
Socket Proxy ← → Traefik (base)
    ↓              ↓
Docker API    Let's Encrypt
              ↓
         Wildcard Cert
              ↓
    First Application
              ↓
    Additional Apps (parallel)

Tailscale (parallel to apps, after networks)
```

### Recommended Order Rationale

1. **Networks first:** Can't start any containers without networks defined
2. **Security layer early:** Socket proxy protects before apps added
3. **Traefik before apps:** Service discovery requires Traefik listening
4. **Certificates before apps:** Avoid browser warnings, validate DNS-01 flow
5. **Test with simple app:** Validate entire stack before complex apps
6. **Tailscale in parallel:** Not blocking path, can be added anytime

## Integration Points

### Adding New Services (Template Pattern)

**Step 1: Create service directory**
```bash
mkdir -p apps/myapp/{data,config}
cd apps/myapp
```

**Step 2: Create docker-compose.yml with standard labels**
```yaml
services:
  myapp:
    image: org/myapp:latest
    container_name: myapp
    restart: unless-stopped
    environment:
      - TZ=America/New_York
    volumes:
      - ./data:/data
      - ./config:/config
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.yourdomain.com`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls=true"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      - "traefik.http.routers.myapp.middlewares=security-headers@file"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
    networks:
      - proxy

networks:
  proxy:
    external: true
```

**Step 3: Deploy**
```bash
docker-compose up -d
```

**Step 4: Verify**
- Check Traefik logs for service discovery
- Access via `https://myapp.yourdomain.com`
- Verify certificate validity

### External Service Integration

| Service Type | Integration Method | Notes |
|--------------|-------------------|-------|
| **DNS Provider** | Traefik environment variables or secrets | Cloudflare, DuckDNS, Route53, etc. |
| **Authentication** | Traefik middleware (ForwardAuth) | Authelia, Authentik, Google OAuth |
| **Monitoring** | Prometheus scraping Traefik metrics | Traefik exposes /metrics endpoint |
| **Logging** | Traefik file provider, Docker log drivers | JSON or access log format |
| **Backup Services** | Volume mounts, cron jobs | Restic, Borg, rsync to external storage |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **Traefik ↔ Socket Proxy** | TCP over socket_proxy_network | Restricted Docker API subset |
| **Traefik ↔ Applications** | HTTP over proxy network | Container port (not host port) |
| **App ↔ Database** | TCP over app-specific internal network | Not accessible via Traefik |
| **Tailscale ↔ Docker Networks** | IP routing (subnet router) or shared network (sidecar) | Depends on pattern chosen |

## Pi 5-Specific Considerations

### Storage Architecture

**Avoid SD Card Wear:**
```bash
# Move Docker data to USB SSD
sudo systemctl stop docker
sudo mv /var/lib/docker /mnt/ssd/docker
sudo ln -s /mnt/ssd/docker /var/lib/docker
sudo systemctl start docker
```

**Persistent volumes on SSD:**
- All `./data` directories in apps should mount to SSD
- Traefik `acme.json` on SSD (frequent writes during renewals)
- Database volumes always on SSD

### Resource Limits

**Memory constraints (4GB or 8GB models):**
```yaml
services:
  myapp:
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

**Monitoring recommendations:**
- Watch for OOM kills: `dmesg | grep -i kill`
- Use lightweight images (alpine-based)
- Avoid running heavy databases (Elasticsearch, large Postgres) on 4GB model

### Cooling and Thermal Throttling

**Active cooling recommended for:**
- Traefik + 5+ applications
- Transcoding workloads (Plex, Jellyfin)
- Continuous high network throughput

**Monitor temperatures:**
```bash
vcgencmd measure_temp
```

### ARM64 Image Availability

**Always check image platform:**
```yaml
services:
  myapp:
    image: org/myapp:latest
    platform: linux/arm64  # Explicit platform
```

**Common ARM64-compatible images:**
- traefik: Official ARM64 support
- tailscale/tailscale: Official ARM64 support
- Most modern applications: Check Docker Hub tags for `arm64v8` or multi-arch

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| **1-5 services** | Single Traefik instance, no major optimization needed, default bridge networks sufficient |
| **5-15 services** | Consider splitting middleware to file provider for reusability, monitor Pi resource usage, add Docker resource limits to prevent single app consuming all memory |
| **15+ services** | May hit Pi hardware limits - consider multiple Traefik instances for internal/external split, Prometheus monitoring essential, evaluate migrating heavy services to separate hardware |

### Scaling Priorities

1. **First bottleneck: Memory (Pi 5 with 4GB)**
   - Symptom: OOM kills, swap thrashing
   - Fix: Resource limits, upgrade to 8GB model, migrate databases to NAS

2. **Second bottleneck: Network throughput**
   - Symptom: Slow response times under load, Traefik CPU spike
   - Fix: Enable HTTP/2, add caching middleware, consider CDN for static assets

3. **Third bottleneck: Storage I/O**
   - Symptom: Slow database queries, high iowait
   - Fix: Already using SSD (good), reduce log verbosity, tune database configs

## Anti-Patterns

### Anti-Pattern 1: Exposing Docker Socket Directly to Traefik

**What people do:**
```yaml
traefik:
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock:ro
```

**Why it's wrong:** Even read-only socket access allows privilege escalation. If Traefik is compromised, attacker can create privileged containers and escape to host root.

**Do this instead:** Always use socket proxy (Tecnativa or FluenceLab) as API firewall:
```yaml
traefik:
  environment:
    - DOCKER_HOST=tcp://socket-proxy:2375
```

### Anti-Pattern 2: Using Default Bridge Network

**What people do:** Not specifying networks, letting all containers join default `docker0` bridge.

**Why it's wrong:**
- No network isolation between services
- All containers can communicate with each other
- Traefik can't distinguish which services to proxy
- Breaks when using multiple compose files

**Do this instead:** Define user-defined bridge networks with `external: true`:
```yaml
networks:
  proxy:
    external: true
```

### Anti-Pattern 3: Storing Secrets in Environment Variables in Compose Files

**What people do:**
```yaml
environment:
  - CF_API_TOKEN=abc123xyz  # NEVER DO THIS
```

**Why it's wrong:**
- Visible in `docker inspect`
- Logged in process listings
- Committed to git by accident
- Passed to child processes

**Do this instead:** Use Docker secrets or file-based secrets:
```yaml
secrets:
  cf_api_token:
    file: ./secrets/cf_api_token.txt

services:
  traefik:
    secrets:
      - cf_api_token
    environment:
      - CF_API_TOKEN_FILE=/run/secrets/cf_api_token
```

### Anti-Pattern 4: Not Using `traefik.enable=false` as Default

**What people do:** Set Traefik config with `exposedByDefault=true`, expecting all containers to be auto-proxied.

**Why it's wrong:**
- Exposes internal services unintentionally
- Every new container is immediately publicly accessible
- No conscious security decision per service
- Leads to exposed databases, admin panels

**Do this instead:** Set `exposedByDefault=false` and explicitly opt-in per service:
```yaml
# traefik.yml
providers:
  docker:
    exposedByDefault: false

# Per-service opt-in
labels:
  - "traefik.enable=true"
```

### Anti-Pattern 5: HTTP-Only Internal Services

**What people do:** Only enable HTTPS for public-facing apps, use HTTP for "internal" services.

**Why it's wrong:**
- Tailscale/VPN access still sends passwords in cleartext
- Defeats purpose of Let's Encrypt wildcard cert
- No consistency in security posture

**Do this instead:** HTTPS everywhere with automatic cert management:
```yaml
labels:
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls=true"
  - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
```

### Anti-Pattern 6: Running Containers as Root

**What people do:** Use default container user (often root).

**Why it's wrong:**
- If container is compromised, attacker has root inside container
- Easier to escape to host
- Files written to volumes owned by root on host

**Do this instead:** Specify user in compose file or Dockerfile:
```yaml
services:
  myapp:
    user: "1000:1000"  # Match host user UID:GID
```

### Anti-Pattern 7: Not Pinning Image Versions

**What people do:**
```yaml
image: traefik:latest
```

**Why it's wrong:**
- Breaking changes on auto-update
- Non-reproducible builds
- Debugging nightmares when "it worked yesterday"

**Do this instead:** Pin to specific versions:
```yaml
image: traefik:v3.2.0
```

### Anti-Pattern 8: Traefik and Apps in Same Compose File

**What people do:** Define Traefik and all applications in one giant docker-compose.yml.

**Why it's wrong:**
- Restarting one app restarts Traefik (downtime for all services)
- No modularity - can't manage apps independently
- Harder to version control changes
- Difficult to troubleshoot

**Do this instead:** Separate infrastructure (Traefik) from applications:
```
infrastructure/docker-compose.yml  # Traefik, socket-proxy
apps/app1/docker-compose.yml       # Independent
apps/app2/docker-compose.yml       # Independent
```

## Sources

### Official Documentation
- [Traefik Docker Provider](https://doc.traefik.io/traefik/providers/docker/)
- [Tailscale Docker Integration](https://tailscale.com/kb/1282/docker)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Docker Compose Secrets](https://docs.docker.com/compose/how-tos/use-secrets/)

### Architecture Guides (2025-2026)
- [UDMS Part 18: Ultimate Traefik Docker Compose Guide [2025]](https://www.simplehomelab.com/udms-18-traefik-docker-compose-guide/)
- [Ultimate Traefik v3 Docker Compose Guide [2024]](https://www.simplehomelab.com/traefik-v3-docker-compose-guide-2024/)
- [Traefik 3 and FREE Wildcard Certificates with Docker](https://technotim.com/posts/traefik-3-docker-certificates/)
- [Communication Between Multiple Docker Compose Projects](https://www.baeldung.com/ops/docker-compose-communication)

### Security Best Practices
- [20 Docker Security Best Practices - Hardening Traefik Docker Stack](https://www.simplehomelab.com/traefik-docker-security-best-practices/)
- [Traefik File Provider Documentation](https://doc.traefik.io/traefik/providers/file/)
- [Managing Secrets in Docker Compose](https://phase.dev/blog/docker-compose-secrets/)

### Raspberry Pi 5 Homelab
- [HomeLab with Docker and Raspberry Pi 5](https://darthseldon.net/homelab-with-docker-and-raspberry-pi-5/)
- [Raspberry Pi Docker: From Installation to Advanced Usage](https://www.sunfounder.com/blogs/news/raspberry-pi-docker-from-installation-to-advanced-usage-and-troubleshooting)
- [Raspberry Pi 5 Performance Benchmarks](https://www.whypi.org/raspberry-pi-5-performance-benchmarks/)

### Community Resources
- [GitHub: SimpleHomelab/Docker-Traefik](https://github.com/SimpleHomelab/Docker-Traefik)
- [GitHub: almeidapaulopt/tsdproxy - Tailscale Docker Proxy](https://github.com/almeidapaulopt/tsdproxy)
- [Docker Compose Modularity with include](https://www.docker.com/blog/improve-docker-compose-modularity-with-include/)

---
*Architecture research for: RagnaLab Homelab Infrastructure*
*Researched: 2026-01-16*
