# RagnaLab

## What This Is

A private, VPN-only homelab platform running on Raspberry Pi 5 that hosts multiple self-contained Docker applications behind a Traefik reverse proxy with real HTTPS certificates. All services are accessible only to authorized devices on a Tailscale VPN network, with wildcard DNS routing through ragnalab.xyz.

## Core Value

Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Traefik reverse proxy infrastructure with Let's Encrypt DNS-01 via Cloudflare
- [ ] Wildcard DNS (`*.ragnalab.xyz`) pointing to Tailscale IP with automatic subdomain routing
- [ ] Private-only access (Traefik bound to Tailscale interface, unreachable from public internet)
- [ ] Shared Docker networking model with automatic service discovery via labels
- [ ] Homepage dashboard with beautiful widgets at home.ragnalab.xyz
- [ ] Vaultwarden password manager at vault.ragnalab.xyz
- [ ] Modular repository structure (each app in own folder with compose file)
- [ ] Template and documentation for adding new apps with single compose file
- [ ] Backup strategy for app data and configuration
- [ ] ARM64-compatible Docker images for all services

### Out of Scope

- Public internet exposure — explicitly designed to be unreachable without Tailscale
- Individual DNS records per app — using wildcard DNS for simplicity
- Complex authentication layer beyond app-level auth — Tailscale provides network-level security
- High availability / clustering — single Pi deployment
- Port forwarding or dynamic DNS — Tailscale handles networking

## Context

**Hardware:**
- Raspberry Pi 5 (ARM64 architecture)
- SD card storage (requires backup strategy)
- Already configured with SSH access

**Software Environment:**
- Tailscale already installed and connected to Tailnet
- Docker Engine already installed
- Raspberry Pi OS (assumed Debian-based)

**Domain & DNS:**
- Owns ragnalab.xyz domain
- DNS managed in Cloudflare
- Cloudflare API access available for Let's Encrypt DNS-01 challenges

**Planned Future Expansion:**
- Media servers (Plex, Jellyfin)
- Productivity apps (Nextcloud, Paperless)
- Monitoring tools (Uptime Kuma, Grafana)

**User Experience Level:**
- Expert with Docker and Traefik
- Understands reverse proxy concepts
- Comfortable with YAML and command line

## Constraints

- **Hardware**: Raspberry Pi 5, SD card storage only — must use ARM64 Docker images, be mindful of I/O limitations
- **Network**: Tailscale VPN only, no public exposure — all access must route through Tailnet
- **DNS**: Cloudflare-managed ragnalab.xyz — requires API token for Let's Encrypt DNS-01
- **Architecture**: ARM64 only — all Docker images must support aarch64/arm64
- **Storage**: SD card reliability — requires backup strategy and careful volume management

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Wildcard DNS `*.ragnalab.xyz → Tailscale IP` | Single DNS record covers all subdomains, easy to add new apps without touching Cloudflare | — Pending |
| Let's Encrypt DNS-01 via Cloudflare | Real HTTPS certificates without exposing ports to public internet | — Pending |
| Homepage dashboard | Modern, widget-based, beautiful UI matches user requirement | — Pending |
| Traefik bound to Tailscale interface | Physical impossibility of public access, defense in depth | — Pending |
| Modular folder structure (proxy/, apps/*) | Clean separation, easy to add/remove apps independently | — Pending |
| Docker label-based service discovery | Zero manual routing config, apps self-register with Traefik | — Pending |

---
*Last updated: 2026-01-16 after initialization*
