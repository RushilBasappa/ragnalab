# Phase 2: VPN & Production Readiness - Research

**Researched:** 2026-01-17
**Domain:** Tailscale VPN, Docker networking, Let's Encrypt production certificates, SSD storage, thermal monitoring
**Confidence:** HIGH

## Summary

Phase 2 secures the RagnaLab infrastructure by binding Traefik exclusively to the Tailscale VPN interface, migrating to production Let's Encrypt certificates, configuring container resource limits, and validating storage/thermal architecture on the Raspberry Pi 5.

The standard approach uses:
1. Tailscale running in a Docker container with `network_mode: host` for subnet routing
2. Traefik sharing the Tailscale container's network via `network_mode: service:tailscale` (all traffic flows through VPN)
3. OAuth client secrets (not auth keys) for non-expiring, reusable container authentication
4. State persistence via named Docker volumes to survive restarts without re-authentication
5. Production Let's Encrypt via clean acme.json migration (staging certificates must be purged)
6. Container resource limits via `deploy.resources` (now works in standalone Docker Compose)

**Primary recommendation:** Use the Tailscale container as the network gateway for Traefik, binding all ports through Tailscale's interface. This architecture guarantees services are unreachable from public internet because Traefik never binds to the host's physical interfaces.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| tailscale/tailscale | latest (multi-arch) | VPN container, subnet router | Official Docker image, supports ARM64, handles authentication and routing |
| Traefik | v3.6 (existing) | Reverse proxy, SSL termination | Already deployed in Phase 1, just needs network binding change |
| Let's Encrypt | Production ACME | SSL certificates | Staging validated in Phase 1, ready for production |
| vcgencmd | System util | Thermal monitoring | Pi-native tool for temperature and throttling status |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| Tailscale Admin Console | Web UI | Route approval, key management | Approve subnet routes, create OAuth clients |
| docker stats | CLI | Resource monitoring | Baseline container usage before setting limits |
| /sys/class/thermal | Sysfs | Temperature monitoring | Alternative to vcgencmd for scripting |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| network_mode: service:tailscale | Tailscale on host + Docker port binding | Host install simpler but less isolated; container approach follows Phase 1 patterns |
| OAuth client secrets | Reusable auth keys | Auth keys expire (max 90 days); OAuth secrets never expire |
| Named volume for state | Bind mount | Named volume more portable; bind mount easier to inspect |

**Installation:**
```bash
# Tailscale image (multi-arch, auto-selects ARM64)
docker pull tailscale/tailscale:latest

# No additional packages needed - vcgencmd pre-installed on Pi OS
```

## Architecture Patterns

### Recommended Project Structure
```
ragnalab/
├── proxy/
│   ├── docker-compose.yml      # Add Tailscale + modify Traefik networking
│   ├── .env                    # Add TS_AUTHKEY (OAuth client secret)
│   ├── traefik/
│   │   ├── traefik.yml         # Remove port bindings (handled by Docker)
│   │   ├── acme/
│   │   │   └── acme.json       # Fresh file after staging→production
│   │   └── ...
│   └── tailscale/              # NEW: State persistence
│       └── state/              # Mounted to container, persists auth
├── apps/
│   └── ...
└── Makefile                    # Add Tailscale network commands
```

### Pattern 1: Tailscale as Network Gateway for Traefik
**What:** Traefik shares Tailscale container's network namespace via `network_mode: service:tailscale`
**When to use:** Always - guarantees VPN-only access
**Example:**
```yaml
# Source: https://www.robert-jensen.dk/posts/2025/securely-exposing-services-with-traefik-and-tailscale/
services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    hostname: ragnalab  # Name in Tailscale admin
    restart: unless-stopped
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY}  # OAuth client secret
      - TS_EXTRA_ARGS=--advertise-tags=tag:server
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
      - TS_ROUTES=172.22.0.0/16  # Docker proxy network
    volumes:
      - tailscale_state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    ports:
      # Ports exposed on Tailscale IP only
      - "80:80"
      - "443:443"
    networks:
      - proxy

  traefik:
    image: traefik:v3.6
    container_name: traefik
    restart: unless-stopped
    depends_on:
      - tailscale
      - socket-proxy
    network_mode: service:tailscale  # Share Tailscale's network
    # NO ports section - handled by tailscale container
    # NO networks section - inherited from tailscale
    security_opt:
      - no-new-privileges:true
    environment:
      - CF_API_EMAIL=${CF_API_EMAIL}
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
    volumes:
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik/dynamic:/etc/traefik/dynamic:ro
      - ./traefik/acme:/etc/traefik/acme
    deploy:
      resources:
        limits:
          memory: 256M
          cpus: '0.5'
        reservations:
          memory: 128M
```

### Pattern 2: State Persistence for Tailscale
**What:** Named volume preserves authentication state across restarts
**When to use:** Always - prevents re-authentication on every restart
**Example:**
```yaml
# Source: https://tailscale.com/kb/1282/docker
services:
  tailscale:
    environment:
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_AUTH_ONCE=true  # Only authenticate if not already logged in
    volumes:
      - tailscale_state:/var/lib/tailscale

volumes:
  tailscale_state:
    name: tailscale_state
```

### Pattern 3: OAuth Client for Non-Expiring Authentication
**What:** Use OAuth client secret instead of auth key for permanent container authentication
**When to use:** Always for long-running containers
**Setup steps:**
1. Go to Tailscale Admin Console > Settings > OAuth Clients
2. Create new OAuth client with "Devices: Write" scope
3. Add tags (e.g., `tag:server`) that match your ACL policy
4. Copy client secret (starts with `tskey-client-...`)
5. Use as `TS_AUTHKEY` with `?ephemeral=false` suffix for permanent nodes

```bash
# .env file
TS_AUTHKEY=tskey-client-kXXX-XXXXXXXXXX?ephemeral=false
```

### Pattern 4: Resource Limits in Docker Compose
**What:** Memory and CPU limits via `deploy.resources` (works in standalone mode since Compose v2)
**When to use:** All containers on resource-constrained Pi 5
**Example:**
```yaml
# Source: https://docs.docker.com/reference/compose-file/deploy/
services:
  whoami:
    image: traefik/whoami:latest
    deploy:
      resources:
        limits:
          memory: 64M
          cpus: '0.25'
        reservations:
          memory: 32M
```

### Pattern 5: Staging to Production Certificate Migration
**What:** Clean migration from Let's Encrypt staging to production
**When to use:** After validating staging certificates work
**Example:**
```bash
# Source: https://community.letsencrypt.org/t/switching-from-lets-encrypt-staging-to-production/69587
# 1. Stop Traefik
docker compose -f proxy/docker-compose.yml stop traefik

# 2. Remove staging certificates
rm proxy/traefik/acme/acme.json
touch proxy/traefik/acme/acme.json
chmod 600 proxy/traefik/acme/acme.json

# 3. Update traefik.yml to production CA server
# Comment: caServer: https://acme-staging-v02.api.letsencrypt.org/directory
# (or remove caServer entirely - production is default)

# 4. Start Traefik
docker compose -f proxy/docker-compose.yml start traefik
```

### Anti-Patterns to Avoid
- **Auth keys for containers:** Max 90-day expiration; use OAuth client secrets instead
- **Missing TS_STATE_DIR:** Without persistent state, containers get new IP on every restart
- **network_mode: host on Traefik:** Exposes services on all interfaces; use service network mode
- **Keeping staging acme.json:** Traefik won't request production certs if staging certs exist
- **Missing cgroup memory support:** Limits silently ignored without kernel parameter

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| VPN-only access | iptables rules, firewall config | Tailscale network_mode | Traefik physically cannot bind to public interface |
| Key rotation | Manual key replacement, cron jobs | OAuth client secrets | Never expire, automatically handled by Tailscale |
| Certificate migration | Script to copy/convert certs | Delete acme.json, restart | Traefik handles all certificate management |
| Thermal monitoring | Custom temperature scripts | vcgencmd + get_throttled | Built-in, provides throttling history |
| Resource monitoring | Custom metrics collection | docker stats + limits | Docker handles enforcement |

**Key insight:** The Tailscale network_mode pattern is superior to firewall rules because it provides physical isolation - Traefik's ports literally don't exist on the host's public interface.

## Common Pitfalls

### Pitfall 1: Tailscale Container Restart Loop
**What goes wrong:** Container enters restart loop with auth failures after Tailscale update
**Why it happens:** Known issue in Tailscale v1.83+ (May 2025); regression in container auth
**How to avoid:**
- Pin to specific version if experiencing issues: `tailscale/tailscale:v1.82`
- Ensure `TS_STATE_DIR` and volume mount are correctly configured
- Use `TS_AUTH_ONCE=true` to prevent re-auth attempts on healthy state
**Warning signs:** Logs show "failed to auth tailscale: tailscale up failed: exit status 2"

### Pitfall 2: Docker Network Subnet Not Routable
**What goes wrong:** Tailscale clients can't reach Docker containers via subnet routing
**Why it happens:** IP forwarding not enabled on host, or routes not approved in admin console
**How to avoid:**
- Enable IP forwarding: `echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf && sudo sysctl -p`
- Approve routes in Tailscale Admin Console > Machines > [node] > Subnet Routes
- Verify Docker network CIDR: `docker network inspect proxy | grep Subnet`
**Warning signs:** Tailscale shows "waiting for approval" on routes; ping to container IPs times out

### Pitfall 3: Production Certificates Not Issued
**What goes wrong:** After switching caServer, browser still shows "Fake LE Intermediate X1"
**Why it happens:** Traefik reuses cached staging certificates from acme.json
**How to avoid:**
- Stop Traefik completely before migration
- Delete acme.json (don't just edit it)
- Create fresh empty file with chmod 600
- Restart and verify in Traefik dashboard
**Warning signs:** No new certificate requests in Traefik logs after config change

### Pitfall 4: Memory Limits Silently Ignored
**What goes wrong:** `docker stats` shows container using more memory than configured limit
**Why it happens:** Raspberry Pi OS kernel doesn't enable cgroup memory by default
**How to avoid:**
- Edit `/boot/firmware/cmdline.txt`, add: `cgroup_enable=memory swapaccount=1 cgroup_memory=1`
- Reboot and verify: `docker info | grep -i memory`
- Should not show "No memory limit support" warning
**Warning signs:** `docker info` shows "WARNING: No memory limit support"

### Pitfall 5: Traefik Can't Reach Socket Proxy
**What goes wrong:** After network_mode change, Traefik can't discover containers
**Why it happens:** network_mode: service:tailscale removes Traefik from socket_proxy_network
**How to avoid:**
- Add Tailscale container to socket_proxy_network as well
- OR use Docker socket mount directly in Tailscale container
- Verify connectivity: `docker exec tailscale nc -zv socket-proxy 2375`
**Warning signs:** Traefik logs show "connection refused" to socket-proxy:2375

### Pitfall 6: Thermal Throttling Under Load
**What goes wrong:** Services become slow/unresponsive during sustained load
**Why it happens:** Pi 5 throttles CPU at 80C, heavy throttling at 85C
**How to avoid:**
- Use official Raspberry Pi Active Cooler (fan activates at 60C)
- Monitor with: `vcgencmd measure_temp && vcgencmd get_throttled`
- Throttled flag 0x0 = no throttling; any other value indicates current or past throttling
**Warning signs:** Temperature >70C at idle, `get_throttled` returns non-zero

## Code Examples

Verified patterns from official sources:

### Complete Tailscale + Traefik Docker Compose
```yaml
# Source: https://tailscale.com/kb/1282/docker
# Source: https://www.robert-jensen.dk/posts/2025/securely-exposing-services-with-traefik-and-tailscale/

services:
  # Tailscale VPN Gateway
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    hostname: ragnalab
    restart: unless-stopped
    environment:
      # OAuth client secret (never expires)
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_EXTRA_ARGS=--advertise-tags=tag:server --accept-routes
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=false
      - TS_AUTH_ONCE=true
      # Advertise Docker proxy network for subnet routing
      - TS_ROUTES=172.22.0.0/16
    volumes:
      - tailscale_state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    ports:
      - "80:80"
      - "443:443"
    networks:
      - proxy
      - socket_proxy_network
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.25'
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  # Docker Socket Proxy (unchanged from Phase 1)
  socket-proxy:
    image: tecnativa/docker-socket-proxy:latest
    container_name: socket-proxy
    restart: unless-stopped
    privileged: true
    environment:
      - CONTAINERS=1
      - NETWORKS=1
      - POST=0
      # ... rest of Phase 1 config
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - socket_proxy_network
    deploy:
      resources:
        limits:
          memory: 64M
          cpus: '0.1'

  # Traefik (modified to use Tailscale network)
  traefik:
    image: traefik:v3.6
    container_name: traefik
    restart: unless-stopped
    depends_on:
      - tailscale
      - socket-proxy
    network_mode: service:tailscale
    security_opt:
      - no-new-privileges:true
    environment:
      - CF_API_EMAIL=${CF_API_EMAIL}
      - CF_DNS_API_TOKEN=${CF_DNS_API_TOKEN}
    volumes:
      - ./traefik/traefik.yml:/etc/traefik/traefik.yml:ro
      - ./traefik/dynamic:/etc/traefik/dynamic:ro
      - ./traefik/acme:/etc/traefik/acme
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
  socket_proxy_network:
    external: true

volumes:
  tailscale_state:
    name: tailscale_state
```

### Updated Environment File (.env)
```bash
# Cloudflare (existing)
CF_API_EMAIL=your-email@example.com
CF_DNS_API_TOKEN=your-cloudflare-token

# Tailscale OAuth Client (new)
# Create at: https://login.tailscale.com/admin/settings/oauth
# Scope: devices:write
# Tags: tag:server
TS_AUTHKEY=tskey-client-kXXX-XXXXXXXXXX?ephemeral=false
```

### IP Forwarding Setup Script
```bash
#!/bin/bash
# Source: https://tailscale.com/kb/1019/subnets

# Enable IP forwarding for subnet routing
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf

# Verify
sysctl net.ipv4.ip_forward
# Should output: net.ipv4.ip_forward = 1
```

### Enable Memory Limits on Raspberry Pi
```bash
#!/bin/bash
# Source: https://dalwar23.com/how-to-fix-no-memory-limit-support-for-docker-in-raspberry-pi/

# Add cgroup parameters to boot config
CMDLINE="/boot/firmware/cmdline.txt"
PARAMS="cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset"

# Check if already configured
if ! grep -q "cgroup_enable=memory" "$CMDLINE"; then
  sudo sed -i "s/$/ $PARAMS/" "$CMDLINE"
  echo "Added cgroup parameters. Reboot required."
else
  echo "cgroup parameters already configured."
fi

# After reboot, verify with:
# docker info | grep -i "memory"
```

### Thermal Monitoring Commands
```bash
# Source: https://www.raspberrypi.com/news/heating-and-cooling-raspberry-pi-5/

# Current temperature (millidegrees)
cat /sys/class/thermal/thermal_zone0/temp
# Divide by 1000 for Celsius

# Or use vcgencmd (human readable)
vcgencmd measure_temp
# Output: temp=63.7'C

# Throttling status (bit flags)
vcgencmd get_throttled
# Output: throttled=0x0 (no throttling)
#
# Bit meanings:
# 0: Under-voltage detected
# 1: Arm frequency capped
# 2: Currently throttled
# 3: Soft temperature limit active
# 16: Under-voltage has occurred
# 17: Arm frequency capping has occurred
# 18: Throttling has occurred
# 19: Soft temperature limit has occurred
```

### Staging to Production Migration Script
```bash
#!/bin/bash
# Migrate Let's Encrypt from staging to production

set -e
cd /home/rushil/workspace/ragnalab

echo "Stopping Traefik..."
docker compose -f proxy/docker-compose.yml stop traefik

echo "Backing up staging certificates..."
cp proxy/traefik/acme/acme.json proxy/traefik/acme/acme-staging-backup.json 2>/dev/null || true

echo "Removing staging certificates..."
rm -f proxy/traefik/acme/acme.json
touch proxy/traefik/acme/acme.json
chmod 600 proxy/traefik/acme/acme.json

echo "Update traefik.yml to remove/comment staging caServer..."
echo "Then run: docker compose -f proxy/docker-compose.yml start traefik"
```

### Service Accessibility Verification
```bash
#!/bin/bash
# Verify services only accessible via Tailscale

# Get Pi's public/local IP
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Get Tailscale IP
TS_IP=$(tailscale ip -4 2>/dev/null || docker exec tailscale tailscale ip -4)

echo "Local IP: $LOCAL_IP"
echo "Tailscale IP: $TS_IP"

# Test from VPN client (should work)
echo "Testing via Tailscale IP..."
curl -sk "https://whoami.ragnalab.xyz" --resolve "whoami.ragnalab.xyz:443:$TS_IP" | head -5

# Test from local network (should fail/timeout)
echo "Testing via Local IP (should timeout)..."
timeout 5 curl -sk "https://$LOCAL_IP:443" 2>&1 || echo "Connection refused/timeout - EXPECTED"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Tailscale auth keys | OAuth client secrets | 2023 | No expiration, better for automation |
| iptables for VPN-only | network_mode: service | 2024 | Physical isolation, simpler config |
| deploy.resources Swarm-only | Works in standalone Compose | Compose v2 (2023) | Resource limits without Swarm |
| Manual thermal monitoring | vcgencmd integration | Pi 5 (2023) | Official fan control, detailed throttle history |

**Deprecated/outdated:**
- `mem_limit` top-level compose key: Use `deploy.resources.limits.memory` instead
- Auth keys for long-running containers: OAuth client secrets are preferred
- Pi 4 cooling solutions: Pi 5 has different thermal profile and official Active Cooler

## Open Questions

Things that couldn't be fully resolved:

1. **Socket proxy network connectivity with network_mode**
   - What we know: `network_mode: service:tailscale` removes Traefik from its original networks
   - What's unclear: Best approach to maintain socket proxy connectivity
   - Recommendation: Add Tailscale container to socket_proxy_network, OR mount Docker socket to Tailscale container and have Traefik connect via localhost

2. **Docker data root migration to SSD**
   - What we know: Pi is running from 117GB SD card (/dev/mmcblk0p2), Docker root at /var/lib/docker
   - What's unclear: Whether SSD is available/connected (no /dev/sd* or /dev/nvme* detected)
   - Recommendation: Validate SSD hardware status first; if present, use `daemon.json` data-root migration

3. **Optimal resource limits per service**
   - What we know: Pi 5 has 8GB RAM, 4 cores; current containers running without limits
   - What's unclear: Actual baseline usage for Traefik, socket-proxy, Tailscale
   - Recommendation: Run `docker stats` under load, set limits 20-30% above peak

## Sources

### Primary (HIGH confidence)
- [Tailscale Docker Docs](https://tailscale.com/kb/1282/docker) - TS_STATE_DIR, TS_ROUTES, container configuration
- [Tailscale Subnet Routers](https://tailscale.com/kb/1019/subnets) - IP forwarding, route approval
- [Tailscale Auth Keys](https://tailscale.com/kb/1085/auth-keys) - Key types, OAuth clients, ephemeral behavior
- [Docker Resource Constraints](https://docs.docker.com/engine/containers/resource_constraints/) - Memory/CPU limits
- [Docker Compose Deploy Spec](https://docs.docker.com/reference/compose-file/deploy/) - deploy.resources syntax
- [Raspberry Pi Thermal](https://www.raspberrypi.com/news/heating-and-cooling-raspberry-pi-5/) - Throttle temps, Active Cooler
- [Let's Encrypt Staging Migration](https://community.letsencrypt.org/t/switching-from-lets-encrypt-staging-to-production/69587) - acme.json handling

### Secondary (MEDIUM confidence)
- [Securely Exposing Services with Traefik and Tailscale](https://www.robert-jensen.dk/posts/2025/securely-exposing-services-with-traefik-and-tailscale/) - network_mode architecture
- [Pi Docker Memory Limits Fix](https://dalwar23.com/how-to-fix-no-memory-limit-support-for-docker-in-raspberry-pi/) - cgroup kernel params
- [Docker Data Root Migration](https://thesmarthomejourney.com/2021/02/11/moving-docker-data-to-an-external-ssd/) - daemon.json approach

### Tertiary (LOW confidence - needs validation)
- Tailscale v1.83+ container auth regression - Mentioned in GitHub issues, not officially confirmed fixed
- socket_proxy_network workaround - Logical inference, not tested

## Metadata

**Confidence breakdown:**
- Tailscale Docker setup: HIGH - Official documentation, verified environment variables
- Traefik network binding: HIGH - Multiple authoritative sources agree on pattern
- Let's Encrypt migration: HIGH - Official community guidance, known behavior
- Resource limits: MEDIUM - Works in Compose v2+ but documentation unclear
- Thermal monitoring: HIGH - Tested on actual Pi 5 during research (temp=63.7C, throttled=0x0)
- SSD storage: MEDIUM - Guidance clear but hardware availability unknown

**Research date:** 2026-01-17
**Valid until:** ~30 days (Tailscale stable, infrastructure slow-moving)

---
*Phase 2 research for: RagnaLab Homelab Infrastructure*
