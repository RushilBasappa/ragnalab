# Phase 5: Pi-hole Network-Wide Ad Blocking - Research

**Researched:** 2026-01-17
**Domain:** DNS-based ad blocking, DHCP server, network infrastructure
**Confidence:** HIGH

## Summary

Pi-hole provides network-wide DNS-based ad blocking by acting as a DNS sinkhole. For the RagnaLab setup with an Xfinity gateway that has locked DNS settings, Pi-hole must run as the DHCP server to provide DNS to all network devices. The critical architectural decision is choosing between host network mode (simplest for DHCP but causes port 80 conflict with Traefik) and macvlan network mode (more complex but provides clean separation with its own IP address).

The recommended approach is **macvlan network mode** because it:
1. Gives Pi-hole its own LAN IP address, avoiding all port conflicts with existing infrastructure
2. Allows DHCP broadcasts to reach the LAN properly
3. Enables Traefik integration via the proxy network for the web UI
4. Maintains the existing Traefik-centric architecture

For fallback/high availability, the approach is to configure Pi-hole's DHCP to advertise a secondary public DNS (like 1.1.1.1 or 9.9.9.9) as a backup. This ensures existing devices with valid leases can still resolve DNS if Pi-hole goes down, with a typical 1-second delay.

**Primary recommendation:** Deploy Pi-hole with macvlan network for DHCP capability, separate web UI routing through Traefik, and configure secondary public DNS in DHCP options for resilience.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| pihole/pihole | 2025.08.0+ (v6) | DNS sinkhole and DHCP server | Official image, multi-arch including ARM64 |
| dnsmasq | Built into Pi-hole | DNS/DHCP backend | Integrated, battle-tested, highly configurable |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| systemd service | System | Macvlan persistence | Required for host-to-container communication after reboot |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Macvlan | Host network mode | Simpler but causes port 80 conflict with Traefik |
| Macvlan | Bridge + DHCP relay | More containers, added complexity |
| Pi-hole | AdGuard Home | Similar features, Pi-hole has larger community |

**Installation:**
```bash
# Pi-hole image pulls automatically via docker compose
docker pull pihole/pihole:latest
```

## Architecture Patterns

### Recommended Network Architecture

```
                    +------------------+
                    |  Xfinity Gateway |
                    |  (DHCP disabled) |
                    +--------+---------+
                             |
              LAN Network (192.168.1.0/24)
                             |
          +------------------+------------------+
          |                  |                  |
    +-----+-----+      +-----+-----+      +-----+-----+
    | Raspberry |      | Pi-hole   |      |  Other    |
    |   Pi 5    |      | (macvlan) |      |  Devices  |
    | .X (host) |      | .Y (own)  |      |           |
    +-----+-----+      +-----+-----+      +-----------+
          |                  |
    Docker Networks          |
    +--------------------+   |
    |     proxy          |<--+ (via docker network connect)
    |  (Traefik routing) |
    +--------------------+
    |   pihole_macvlan   |
    |  (separate LAN IP) |
    +--------------------+
```

### Pattern 1: Macvlan Network for DHCP

**What:** Pi-hole gets its own IP address on the LAN via macvlan, enabling DHCP broadcasts without port conflicts.

**When to use:** When running DHCP server in Docker alongside other services using port 80.

**Configuration:**
```yaml
# Source: Pi-hole Docker documentation + community patterns
# Create macvlan network
networks:
  pihole_net:
    driver: macvlan
    driver_opts:
      parent: eth0  # Physical interface
    ipam:
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
          ip_range: 192.168.1.200/32  # Single IP for Pi-hole
```

### Pattern 2: Web UI via Traefik with Macvlan

**What:** Connect Pi-hole to both macvlan (for DHCP/DNS) and proxy network (for Traefik routing).

**When to use:** Always - maintains consistent HTTPS access pattern.

**Configuration:**
```yaml
# Source: Community best practices
services:
  pihole:
    image: pihole/pihole:latest
    networks:
      pihole_net:
        ipv4_address: 192.168.1.200  # Static macvlan IP
      proxy:  # Traefik network for web UI routing
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole.rule=Host(`pihole.ragnalab.xyz`)"
      - "traefik.http.routers.pihole.entrypoints=websecure"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"
      - "traefik.docker.network=proxy"
```

### Pattern 3: Host-to-Container Communication Bridge

**What:** Create a local macvlan interface so the Raspberry Pi host can communicate with Pi-hole.

**When to use:** Required - without this, the Pi host cannot use Pi-hole for DNS.

**Configuration:**
```bash
# Source: macvlan documentation
# Create bridge interface
sudo ip link add macvlan-shim link eth0 type macvlan mode bridge
sudo ip addr add 192.168.1.201/32 dev macvlan-shim
sudo ip link set macvlan-shim up
sudo ip route add 192.168.1.200/32 dev macvlan-shim
```

### Anti-Patterns to Avoid

- **Using host network mode with Traefik:** Causes port 80 conflict; requires changing Pi-hole web port which adds complexity
- **Running two DHCP servers:** Never run Pi-hole DHCP alongside Xfinity gateway DHCP - causes IP conflicts and network instability
- **Proxying DNS through Traefik:** Defeats Pi-hole's client identification; all queries appear from localhost
- **Forgetting macvlan persistence:** Host communication breaks after reboot without systemd service

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DNS failover | Custom health check scripts | DHCP secondary DNS option | Built into dnsmasq, clients handle automatically |
| Blocklist management | Manual /etc/hosts entries | Pi-hole gravity + community lists | Automatic updates, categories, whitelisting UI |
| DHCP lease management | Static IP on every device | Pi-hole DHCP with reservations | Central management, automatic for most devices |
| DNS query logging | tcpdump scripts | Pi-hole Query Log | Built-in UI, statistics, per-client tracking |

**Key insight:** Pi-hole's value is the integrated UI for blocklist management, query logging, and DHCP lease viewing. Hand-rolling components loses the unified dashboard experience.

## Common Pitfalls

### Pitfall 1: Xfinity Gateway DHCP Conflict

**What goes wrong:** Running Pi-hole DHCP while Xfinity gateway DHCP is still active creates IP address conflicts.

**Why it happens:** Two DHCP servers respond to client requests; clients get conflicting leases.

**How to avoid:** Must disable Xfinity gateway DHCP completely before enabling Pi-hole DHCP. Access gateway admin at 10.0.0.1, disable DHCP service.

**Warning signs:** Devices getting IPs outside Pi-hole's configured range, intermittent connectivity.

### Pitfall 2: Macvlan Host Communication Failure

**What goes wrong:** Raspberry Pi host cannot reach Pi-hole container after deployment.

**Why it happens:** Macvlan containers cannot communicate with their host by design (Linux kernel limitation).

**How to avoid:** Create a macvlan-shim interface on the host with a separate IP and route to the container IP.

**Warning signs:** `ping 192.168.1.200` from Pi host times out, but other LAN devices can reach it.

### Pitfall 3: Macvlan Configuration Lost on Reboot

**What goes wrong:** Host loses DNS resolution after Pi reboots.

**Why it happens:** `ip link` and `ip route` commands are ephemeral.

**How to avoid:** Create systemd service to restore macvlan-shim on boot.

**Warning signs:** System works after manual setup, breaks after reboot.

### Pitfall 4: Pi-hole v6 Breaking Changes

**What goes wrong:** Upgrading from v5 (2024.07.0) to v6 (2025.x) breaks configuration.

**Why it happens:** Environment variable names changed, configuration files auto-migrated irreversibly.

**How to avoid:** Fresh v6 deployment (no migration needed for new install). Use `FTLCONF_*` prefix for all settings.

**Warning signs:** Container fails to start after image update, deprecated variable warnings.

### Pitfall 5: Secondary DNS "Leaking" Around Pi-hole

**What goes wrong:** Some ads still appear even with Pi-hole running.

**Why it happens:** Clients randomly use secondary DNS server, bypassing Pi-hole filtering.

**How to avoid:** Use secondary DNS only as true failover (accept some bypass), or run two Pi-holes for redundancy.

**Warning signs:** Query log shows fewer queries than expected, some clients never appear in logs.

### Pitfall 6: Traefik Cannot Route to Macvlan Container

**What goes wrong:** pihole.ragnalab.xyz returns 502 or timeout.

**Why it happens:** Container not connected to proxy network, or wrong network specified in labels.

**How to avoid:** Connect Pi-hole to both macvlan network AND proxy network. Use `traefik.docker.network=proxy` label.

**Warning signs:** Traefik dashboard shows no backend for Pi-hole router.

## Code Examples

Verified patterns from official sources:

### Docker Compose - Pi-hole with Macvlan and Traefik

```yaml
# Source: Pi-hole Docker docs + community patterns
# File: apps/pihole/docker-compose.yml

services:
  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    restart: unless-stopped
    hostname: pihole
    domainname: ragnalab.xyz
    cap_add:
      - NET_ADMIN  # Required for DHCP
    environment:
      TZ: 'America/Los_Angeles'
      FTLCONF_webserver_api_password: '${PIHOLE_PASSWORD}'
      FTLCONF_dns_listeningMode: 'all'
      # Upstream DNS (used by Pi-hole for recursion)
      FTLCONF_dns_upstreams: '1.1.1.1;9.9.9.9'
    volumes:
      - ./etc-pihole:/etc/pihole
      - ./etc-dnsmasq.d:/etc/dnsmasq.d
    networks:
      pihole_net:
        ipv4_address: 192.168.1.200
      proxy:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.pihole.rule=Host(`pihole.ragnalab.xyz`)"
      - "traefik.http.routers.pihole.entrypoints=websecure"
      - "traefik.http.routers.pihole.tls=true"
      - "traefik.http.routers.pihole.tls.certresolver=letsencrypt"
      - "traefik.http.services.pihole.loadbalancer.server.port=80"
      - "traefik.docker.network=proxy"
      # Homepage labels
      - "homepage.group=Network"
      - "homepage.name=Pi-hole"
      - "homepage.icon=pi-hole.png"
      - "homepage.href=https://pihole.ragnalab.xyz"
      - "homepage.description=DNS Ad Blocking"
      - "homepage.widget.type=pihole"
      - "homepage.widget.url=http://pihole:80"
      - "homepage.widget.version=6"
      - "homepage.widget.key=${PIHOLE_API_KEY}"
      - "homepage.server=my-docker"
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
  pihole_net:
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: 192.168.1.0/24
          gateway: 192.168.1.1
          ip_range: 192.168.1.200/32
  proxy:
    external: true
```

### Systemd Service for Macvlan Persistence

```ini
# Source: Community best practice
# File: /etc/systemd/system/pihole-macvlan.service

[Unit]
Description=Pi-hole macvlan host communication bridge
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/pihole-macvlan.sh up
ExecStop=/usr/local/bin/pihole-macvlan.sh down

[Install]
WantedBy=multi-user.target
```

```bash
# Source: Community best practice
# File: /usr/local/bin/pihole-macvlan.sh

#!/bin/bash
# Macvlan shim for host-to-container communication

INTERFACE="eth0"
SHIM_NAME="macvlan-shim"
SHIM_IP="192.168.1.201"
PIHOLE_IP="192.168.1.200"

case "$1" in
  up)
    ip link add ${SHIM_NAME} link ${INTERFACE} type macvlan mode bridge
    ip addr add ${SHIM_IP}/32 dev ${SHIM_NAME}
    ip link set ${SHIM_NAME} up
    ip route add ${PIHOLE_IP}/32 dev ${SHIM_NAME}
    ;;
  down)
    ip link del ${SHIM_NAME}
    ;;
esac
```

### DHCP Configuration with Fallback DNS

```conf
# Source: Pi-hole dnsmasq documentation
# File: apps/pihole/etc-dnsmasq.d/05-custom-dhcp.conf

# DHCP range: .100 to .199, 24 hour leases
dhcp-range=192.168.1.100,192.168.1.199,24h

# Advertise Pi-hole as primary DNS, public DNS as fallback
# Note: Some clients may use either randomly, not as true failover
dhcp-option=option:dns-server,192.168.1.200,1.1.1.1

# Gateway
dhcp-option=option:router,192.168.1.1

# Domain
dhcp-option=option:domain-name,local

# Static IP reservations (add as needed)
# dhcp-host=aa:bb:cc:dd:ee:ff,hostname,192.168.1.50
```

### Homepage Widget Configuration

```yaml
# Source: Homepage Pi-hole widget docs
# Addition to apps/homepage/config/services.yaml

- Network:
    - Pi-hole:
        icon: pi-hole.png
        href: https://pihole.ragnalab.xyz
        description: DNS Ad Blocking
        widget:
          type: pihole
          url: http://pihole:80
          version: 6
          key: "{{HOMEPAGE_VAR_PIHOLE_API_KEY}}"
```

### Uptime Kuma Monitor Configuration

```
# Source: Uptime Kuma + Pi-hole community docs
# Configure in Uptime Kuma UI

Monitor 1: Pi-hole Web Interface
- Type: HTTP(s)
- URL: http://pihole:80/admin
- Expected Status Code: 200

Monitor 2: Pi-hole DNS Resolution
- Type: DNS
- Hostname: google.com
- Resolver Server: 192.168.1.200 (Pi-hole macvlan IP)
- Record Type: A
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Pi-hole v5 environment vars | `FTLCONF_*` prefix (v6) | February 2025 | All env vars renamed, config migration |
| Host network mode for DHCP | Macvlan network | Current best practice | Cleaner architecture, no port conflicts |
| Single DNS server in DHCP | Primary + fallback DNS | Resilience requirement | Network survives Pi-hole downtime |
| Manual gravity update | Automatic cron updates | Default in Pi-hole | Set-and-forget blocklists |

**Deprecated/outdated:**
- `WEBPASSWORD` environment variable: Replaced by `FTLCONF_webserver_api_password` in v6
- `ServerIP` environment variable: Replaced by automatic detection in v6
- `DHCP_ACTIVE` environment variable: Configure via web UI or dnsmasq.d files in v6

## DHCP Cutover Procedure

Critical sequence for transitioning DHCP from Xfinity gateway to Pi-hole:

### Pre-Cutover Checklist
1. Verify Pi-hole container is running and DNS resolution works
2. Document current Xfinity DHCP range and any static reservations
3. Ensure Pi-hole has DHCP configured but NOT yet enabled
4. Test Pi-hole web UI is accessible via Traefik

### Cutover Steps
1. **Disable Xfinity DHCP** (via 10.0.0.1 admin)
2. **Enable Pi-hole DHCP** (via Pi-hole admin Settings > DHCP)
3. **Verify on one test device** - release/renew DHCP, confirm gets Pi-hole as DNS
4. **Gradually refresh other devices** - or wait for lease expiry

### Rollback Procedure
If issues occur:
1. Disable Pi-hole DHCP
2. Re-enable Xfinity gateway DHCP
3. Release/renew on affected devices

### Fallback Behavior
With secondary DNS configured (e.g., 1.1.1.1):
- If Pi-hole is down, existing leases continue to work
- Clients with active leases fall back to secondary DNS after ~1 second timeout
- Internet access continues (without ad blocking)
- Once Pi-hole recovers, ad blocking resumes

## Open Questions

Things that couldn't be fully resolved:

1. **Exact Xfinity gateway DHCP disable procedure**
   - What we know: Access via 10.0.0.1, DHCP settings exist
   - What's unclear: Exact menu path varies by gateway model (XB6/XB7/XB8)
   - Recommendation: Document actual procedure during implementation

2. **Optimal DHCP lease time**
   - What we know: 24 hours is common default
   - What's unclear: Best balance between quick changes and stability
   - Recommendation: Start with 24h, adjust based on experience

3. **Pi-hole v6 App Password vs Admin Password**
   - What we know: Both can be used for API authentication
   - What's unclear: Security implications of each approach
   - Recommendation: Use dedicated App Password for Homepage integration

## Sources

### Primary (HIGH confidence)
- [Pi-hole Docker Documentation](https://docs.pi-hole.net/docker/) - Official setup guide
- [Pi-hole Docker DHCP Modes](https://docs.pi-hole.net/docker/dhcp/) - Network mode comparison
- [Pi-hole GitHub docker-pi-hole](https://github.com/pi-hole/docker-pi-hole) - Official image, environment variables
- [Homepage Pi-hole Widget](https://gethomepage.dev/widgets/services/pihole/) - Widget configuration

### Secondary (MEDIUM confidence)
- [Self-Hosting Pi-hole with Docker and Traefik](https://codecaptured.com/blog/self-hosting-pi-hole-with-docker-and-traefik/) - Traefik integration patterns
- [Pi-hole behind Traefik](https://jurian.slui.mn/posts/pi-hole-web-interface-behind-traefik/) - Web UI routing
- [Setting up Pi-hole in MacVlans](https://thomaswildetech.com/blog/2025/06/03/setting-up-adguardhome-and-pihole-in-macvlans/) - Macvlan setup guide
- [Pi-hole Secondary DNS Configuration](https://discourse.pi-hole.net/t/secondary-dns-server-for-dhcp/1874) - Fallback DNS setup

### Tertiary (LOW confidence)
- [Xfinity Gateway DHCP Disable](https://forums.xfinity.com/) - Community reports, may vary by gateway model
- [DNS Failover Behavior](https://discourse.pi-hole.net/) - Client behavior varies by OS

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Pi-hole Docker image well-documented for ARM64
- Architecture (macvlan): MEDIUM - Community-validated but requires careful setup
- DHCP cutover: HIGH - Standard procedure, well-documented
- Fallback strategy: MEDIUM - Works but not true failover (clients may use secondary randomly)
- Traefik integration: HIGH - Standard pattern matching existing RagnaLab services
- Homepage widget: HIGH - Official widget documentation for v6

**Research date:** 2026-01-17
**Valid until:** ~60 days (Pi-hole v6 stable, patterns well-established)
