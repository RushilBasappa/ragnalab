# RagnaLab

## What This Is

A private, VPN-only homelab platform running on Raspberry Pi 5 that hosts multiple self-contained Docker applications behind a Traefik reverse proxy with real HTTPS certificates. All services are accessible only to authorized devices on a Tailscale VPN network, with wildcard DNS routing through ragnalab.xyz.

## Core Value

Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.

## Requirements

### Validated (v1.0)

- [x] Traefik reverse proxy infrastructure with Let's Encrypt DNS-01 via Cloudflare
- [x] Wildcard DNS (`*.ragnalab.xyz`) pointing to Tailscale IP with automatic subdomain routing
- [x] Private-only access (Traefik bound to Tailscale interface, unreachable from public internet)
- [x] Shared Docker networking model with automatic service discovery via labels
- [x] Homepage dashboard with beautiful widgets at home.ragnalab.xyz
- [x] Vaultwarden password manager at vault.ragnalab.xyz
- [x] Modular repository structure (each app in own folder with compose file)
- [x] Template and documentation for adding new apps with single compose file
- [x] Backup strategy for app data and configuration
- [x] ARM64-compatible Docker images for all services

### Active

(None — v1.0 complete)

### Out of Scope

- Public internet exposure — explicitly designed to be unreachable without Tailscale
- Individual DNS records per app — using wildcard DNS for simplicity
- Complex authentication layer beyond app-level auth — Tailscale provides network-level security
- High availability / clustering — single Pi deployment
- Port forwarding or dynamic DNS — Tailscale handles networking

## Context

**Hardware:**
- Raspberry Pi 5 (ARM64 architecture)
- SSD storage via USB (SD card for boot only)
- Already configured with SSH access

**Software Environment:**
- Tailscale already installed and connected to Tailnet
- Docker Engine already installed
- Raspberry Pi OS (assumed Debian-based)

**Domain & DNS:**
- Owns ragnalab.xyz domain
- DNS managed in Cloudflare
- Cloudflare API access available for Let's Encrypt DNS-01 challenges

**Deployed Services (v1.0):**
- Traefik reverse proxy at traefik.ragnalab.xyz
- Uptime Kuma monitoring at status.ragnalab.xyz
- Homepage dashboard at home.ragnalab.xyz
- Vaultwarden password manager at vault.ragnalab.xyz

**User Experience Level:**
- Expert with Docker and Traefik
- Understands reverse proxy concepts
- Comfortable with YAML and command line

## Constraints

- **Hardware**: Raspberry Pi 5, SSD storage — must use ARM64 Docker images
- **Network**: Tailscale VPN only, no public exposure — all access must route through Tailnet
- **DNS**: Cloudflare-managed ragnalab.xyz — requires API token for Let's Encrypt DNS-01
- **Architecture**: ARM64 only — all Docker images must support aarch64/arm64

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Wildcard DNS `*.ragnalab.xyz → Tailscale IP` | Single DNS record covers all subdomains, easy to add new apps without touching Cloudflare | ✓ Validated v1.0 |
| Let's Encrypt DNS-01 via Cloudflare | Real HTTPS certificates without exposing ports to public internet | ✓ Validated v1.0 |
| Homepage dashboard | Modern, widget-based, beautiful UI matches user requirement | ✓ Validated v1.0 |
| Traefik bound to Tailscale interface | Physical impossibility of public access, defense in depth | ✓ Validated v1.0 |
| Modular folder structure (proxy/, apps/*) | Clean separation, easy to add/remove apps independently | ✓ Validated v1.0 |
| Docker label-based service discovery | Zero manual routing config, apps self-register with Traefik | ✓ Validated v1.0 |
| Host-level Tailscale (not container) | Simpler, more robust; Tailscale is infrastructure like OS | ✓ Validated v1.0 |
| Dual access (local + VPN) | User prefers local network access; VPN for remote only | ✓ Validated v1.0 |

---
*Last updated: 2026-01-17 after v1.0 milestone completion*
