# Stack Research

**Domain:** Private Homelab Infrastructure (VPN-Only, Docker-Based)
**Researched:** 2026-01-16
**Confidence:** HIGH

## Recommended Stack

### Core Infrastructure

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Raspberry Pi OS (64-bit) | Debian Bookworm | Base Operating System | Official 64-bit OS with full ARM64 support; Docker Engine v29+ drops 32-bit support, making 64-bit mandatory for future updates |
| Docker Engine | v29.1.4+ | Container Runtime | Latest stable with full ARM64 support; v29 is current LTS with multi-arch image support and improved security |
| Docker Compose | v5.0.1+ | Multi-Container Orchestration | Compose v2 (now v5.x) integrated into Docker Engine; uses plugin architecture; v1 deprecated July 2023 |
| Traefik | v3.6.7 | Reverse Proxy & HTTPS | Dynamic service discovery via Docker labels; automatic Let's Encrypt certificates; lighter weight than Nginx Proxy Manager (no database required); native DNS-01 challenge support for Cloudflare |
| Tailscale | latest (stable) | VPN Mesh Network | Zero-config WireGuard-based VPN; official Docker image at `tailscale/tailscale:stable`; eliminates port forwarding; built-in MagicDNS |
| Let's Encrypt | via Traefik ACME | SSL/TLS Certificates | Industry standard free certificates; DNS-01 challenge enables wildcard certs via Cloudflare API |

**Confidence:** HIGH - All versions verified from official sources (GitHub releases, Docker Hub) as of January 2026.

### Supporting Services

| Service | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Homepage | latest (ghcr.io/gethomepage/homepage) | Dashboard UI | Essential for homelab - single pane of glass with Docker auto-discovery and 100+ service integrations; ARM64 supported |
| Vaultwarden | 2025.1.1+ | Password Manager | Lightweight Bitwarden alternative; multi-arch image auto-detects ARM64; unified database support (SQLite/MySQL/PostgreSQL) |
| Portainer CE | v2.33.6+ | Docker Management UI | Optional but recommended - visual container/image/network management; ARM64 native; helpful for debugging |
| Watchtower | latest | Automated Container Updates | Optional - auto-updates containers on schedule; official image: `containrrr/watchtower`; use `WATCHTOWER_MONITOR_ONLY=true` for critical services |

**Confidence:** HIGH - Versions from official Docker Hub and GitHub releases.

### Development & Monitoring Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| docker-volume-backup (offen) | Volume Backup Automation | Backs up Docker volumes to local/S3/WebDAV/etc with graceful container shutdown; essential for data protection on SD card |
| Cloudflare API Token | DNS-01 Challenge | Create scoped token with `Zone.Zone:Read` + `Zone.DNS:Edit` for specific zone; never use global API key |
| Active Cooling (Required) | Thermal Management | Pi 5 thermal throttles at 80-85°C under sustained Docker loads; active cooling maintains <50°C for 24/7 operation |

**Confidence:** HIGH - Best practices verified across multiple 2025/2026 sources.

## Installation

### Initial Setup (Raspberry Pi OS 64-bit Bookworm)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker Engine (following Debian arm64 instructions)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group (avoid sudo for docker commands)
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker installation
docker --version  # Should show v29.x
docker compose version  # Should show v5.x (integrated plugin)

# Verify ARM64 architecture
docker info | grep Architecture  # Should show aarch64 or arm64
```

### Core Stack Deployment

```bash
# Create directory structure
mkdir -p ~/homelab/{traefik,homepage,vaultwarden}
mkdir -p ~/homelab/traefik/{config,acme}

# Deploy with Docker Compose (example structure)
cd ~/homelab
# Place docker-compose.yml with Traefik, Homepage, Vaultwarden services
docker compose up -d
```

### Cloudflare API Token Setup

1. Go to Cloudflare Dashboard → Profile → API Tokens → Create Token
2. Use "Edit zone DNS" template
3. Permissions: `Zone.Zone:Read`, `Zone.DNS:Edit`
4. Zone Resources: Include → Specific zone → `ragnalab.xyz`
5. Store token in `.env` file: `CF_DNS_API_TOKEN=your_token_here`
6. Set file permissions: `chmod 600 .env`

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Traefik | Nginx Proxy Manager | If you need a GUI for proxy configuration and have <20 services; NPM easier for beginners but requires MariaDB database and has slower security patch cycle |
| Docker Rootful | Docker Rootless | If security is paramount and you don't need host networking or ports <1024; rootless prevents privileged containers but adds complexity |
| SD Card Storage | SSD via USB 3.0/PCIe HAT | **STRONGLY RECOMMENDED** - SD cards wear out quickly with Docker's constant writes; SSD provides 10x+ durability and better I/O performance |
| Tailscale Official Image | Tailscale Host Install | Use Docker image for easier management; host install if you need subnet routing or exit node functionality |
| Watchtower | Manual Updates | Skip Watchtower for critical services (Traefik, Vaultwarden); use `WATCHTOWER_MONITOR_ONLY=true` or manual updates for production-critical containers |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Docker Compose v1 (docker-compose) | Deprecated July 2023; no longer receives updates or security patches | Docker Compose v2 plugin (`docker compose` - note the space, not hyphen) |
| Raspberry Pi OS 32-bit | Docker Engine v29 drops 32-bit ARM support; no future updates | Raspberry Pi OS 64-bit (Debian Bookworm) |
| Traefik v2.x | EOL after v3.x releases; v2.11.35 is last security update; no ongoing support | Traefik v3.6+ (breaking changes documented in migration guide) |
| Global Cloudflare API Key | Security risk - grants full account access; violates principle of least privilege | Scoped API Token with Zone-specific DNS edit permissions |
| Passive Cooling Only | Pi 5 thermal throttles under Docker loads (80-85°C); reduces CPU frequency and causes instability | Active cooling (official Active Cooler or equivalent fan) for 24/7 operation |
| SD Card for Production | High failure rate with constant Docker writes; logs, databases, and volumes wear out cards in months | SSD storage via USB 3.0 or PCIe HAT for reliability and performance |
| HTTP-01 Challenge | Requires port 80/443 exposed publicly; incompatible with VPN-only access and doesn't support wildcard certs | DNS-01 Challenge via Cloudflare (enables wildcard *.ragnalab.xyz) |

## Stack Patterns by Variant

**If running on SD card (not recommended):**
- Use `offen/docker-volume-backup` with daily backups to external storage
- Enable `log2ram` to reduce SD writes by storing logs in RAM
- Accept higher failure risk and plan for replacement every 6-12 months
- Monitor with `iostat` to track write amplification

**If migrating to SSD (recommended):**
- Use 256GB+ SSD via USB 3.0 (Pi 4) or PCIe HAT (Pi 5)
- Boot from SD card, mount SSD at `/mnt/ssd`, symlink Docker data dir
- Or boot directly from SSD (requires bootloader update on Pi 4)
- Enables reliable 24/7 operation with better I/O performance

**If running rootless Docker (advanced):**
- Install rootless Docker following official instructions
- Accept limitations: no host networking, no ports <1024, no privileged containers
- Traefik must bind to port 8080/8443 instead of 80/443 (use iptables redirect)
- Better security isolation but adds complexity

**If scaling beyond single Pi:**
- Consider Docker Swarm (multi-node orchestration) or K3s (lightweight Kubernetes)
- Traefik supports both with native service discovery
- Tailscale mesh network handles inter-node communication securely

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| Traefik v3.6.7 | Docker Engine v20.10+ | Requires Docker API v1.41+; fully compatible with v29 |
| Docker Compose v5.0.1 | Docker Engine v27.0+ | Integrated plugin; part of Docker Engine installation |
| Tailscale (stable) | Docker Engine v20.10+ | Userspace networking by default (TS_USERSPACE=true) |
| Vaultwarden 2025.1.1 | Docker multi-arch | Auto-detects ARM64; requires persistent volume for data |
| Homepage (latest) | Docker Engine v20.10+ | Requires `/var/run/docker.sock` mount for auto-discovery |
| Portainer CE 2.33.6 | Docker Engine 29.x | Known issue with Docker 29.0.0-rc.2 on ARM64 (resolved in stable) |

## Architecture-Specific Notes (ARM64)

**Multi-Arch Images (Recommended):**
Most modern images are multi-arch and auto-detect ARM64:
- `traefik:v3.6` (official, multi-arch)
- `tailscale/tailscale:stable` (official, multi-arch)
- `vaultwarden/server:latest` (community, multi-arch)
- `ghcr.io/gethomepage/homepage:latest` (community, multi-arch)

**Explicit ARM64 Images (Legacy):**
Older tutorials reference explicit ARM64 tags - avoid these:
- `arm64v8/traefik` (deprecated - use `traefik:latest` instead)
- `portainer/portainer-ce:linux-arm64-X.X.X` (use `portainer/portainer-ce:latest`)

**Verification:**
```bash
# Check image architecture before pulling
docker manifest inspect traefik:v3.6 | grep architecture

# Verify running container architecture
docker inspect <container> | grep Architecture
```

## Thermal Management (Pi 5 Specific)

**Required for 24/7 Docker Operation:**
- Official Raspberry Pi Active Cooler (recommended)
- Aftermarket 5V PWM fan with heatsink
- Monitor temps: `vcgencmd measure_temp` (target: <60°C under load)

**Thermal Throttling Indicators:**
```bash
# Check for throttling events
vcgencmd get_throttled

# Bit meanings:
# 0x50000: Currently throttled
# 0x80000: Soft temperature limit reached

# Monitor real-time temperature during load
watch -n 1 vcgencmd measure_temp
```

**Performance Impact:**
- Without cooling: 80-85°C under Docker load → CPU throttling → degraded performance
- With active cooling: 42-50°C under same load → sustained high clocks → stable 24/7 operation

## Sources

### Official Documentation
- [Docker Engine Release Notes v29](https://docs.docker.com/engine/release-notes/29/) - Latest version and ARM64 support
- [Docker Compose Release Notes](https://docs.docker.com/compose/release-notes/) - v5.0.1 release info
- [Traefik v3.6 Releases](https://github.com/traefik/traefik/releases) - v3.6.7 security update (Jan 2026)
- [Tailscale Docker Documentation](https://tailscale.com/kb/1282/docker) - Official Docker integration guide
- [Docker Rootless Mode](https://docs.docker.com/engine/security/rootless/) - Security and limitations

### ARM64 Compatibility
- [Traefik Docker Hub](https://hub.docker.com/_/traefik) - Multi-arch image confirmation
- [Vaultwarden Releases](https://github.com/dani-garcia/vaultwarden/releases) - v2025.1.1 multi-arch support
- [Homepage GitHub](https://github.com/gethomepage/homepage) - ARM64/ARM v6/v7 build support
- [Portainer CE Releases](https://github.com/portainer/portainer/releases) - v2.33.6 ARM64 images

### Best Practices & Comparisons
- [Traefik vs Nginx Proxy Manager - Virtualization Howto (2025)](https://www.virtualizationhowto.com/2025/09/i-replaced-nginx-proxy-manager-with-traefik-in-my-home-lab-and-it-changed-everything/) - Infrastructure-as-code vs GUI comparison
- [Ultimate Home Lab Backup Strategy (2025)](https://www.virtualizationhowto.com/2025/10/ultimate-home-lab-backup-strategy-2025-edition/) - Volume backup best practices
- [Docker Volume Backup Tool](https://github.com/offen/docker-volume-backup) - Automated backup solution
- [Traefik Let's Encrypt Cloudflare Guide](https://medium.com/@svenvanginkel/traefik-letsencrypt-dns01-challenge-with-ovhcloud-52f2a2c6d08a) - DNS-01 challenge configuration

### Raspberry Pi Specific
- [Raspberry Pi 5 Cooling Performance (2025)](https://medium.com/@rachad.abi.chahine/raspberry-pi-5-with-vs-without-a-cooler-real-logs-real-performance-2ec94e778f2e) - Thermal benchmarks with Docker
- [Docker on Raspberry Pi Bookworm](https://www.pisugar.com/blogs/tutorial/install-docker-on-raspberry-pi-os) - Installation guide for 64-bit OS
- [Raspberry Pi Docker Forums](https://forums.raspberrypi.com/viewtopic.php?t=358413) - Community best practices for Debian Bookworm
- [7 Raspberry Pi HomeLab Projects (2025)](https://berkem.xyz/blog/raspberry-pi-homelab-projects/) - SD card vs SSD recommendations

### Security & Configuration
- [Cloudflare Let's Encrypt DNS Challenge Best Practices](https://runtipi.io/docs/guides/dns-challenge-cloudflare) - Scoped API token setup
- [Let's Encrypt DNS-01 Challenge Types](https://letsencrypt.org/docs/challenge-types/) - Official documentation
- [Docker Rootless on Raspberry Pi](https://docs.docker.com/engine/security/rootless/) - Security considerations and trade-offs

---
*Stack research for: RagnaLab Homelab Infrastructure*
*Researched: 2026-01-16*
*Next step: Use this research to inform roadmap phase structure*
