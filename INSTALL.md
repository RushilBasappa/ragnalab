# RagnaLab Installation Guide

Complete setup guide for installing RagnaLab on a fresh Raspberry Pi 5.

**Time required:** ~45 minutes
**Prerequisites:** Raspberry Pi 5 with Raspberry Pi OS, domain name, Cloudflare account

---

## Quick Start

1. [Prepare your Pi](#1-prerequisites--accounts)
2. [Configure host system](#2-host-system-configuration)
3. [Deploy infrastructure](#3-deploy-infrastructure)
4. [Deploy applications](#4-deploy-applications)

---

## 1. Prerequisites & Accounts

### Hardware Requirements

- Raspberry Pi 5 (4GB+ RAM recommended)
- SSD storage (SD cards fail frequently with Docker)
- Active cooling (fan/heatsink)
- Ethernet connection (recommended)

### Accounts Needed

Before starting, create accounts for:

| Service | Purpose | Link |
|---------|---------|------|
| Cloudflare | DNS management, SSL certificates | [cloudflare.com](https://cloudflare.com) |
| Tailscale | VPN access to services | [tailscale.com](https://tailscale.com) |
| VPN Provider | Torrent privacy (ProtonVPN recommended) | [protonvpn.com](https://protonvpn.com) |

### Cloudflare Setup

1. Add your domain to Cloudflare
2. Update registrar nameservers to Cloudflare's
3. Create API token:
   - Go to https://dash.cloudflare.com/profile/api-tokens
   - Use "Edit zone DNS" template
   - Permissions: `Zone → DNS → Edit`
   - Save the token for later

4. Create wildcard DNS record (after getting Tailscale IP):

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | `*` | `<tailscale-ip>` | DNS only (gray cloud) |

---

## 2. Host System Configuration

SSH into your Raspberry Pi.

### Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### Enable cgroup Memory Limits

```bash
sudo nano /boot/firmware/cmdline.txt
```

Append to the **existing single line** (do not add a new line):
```
cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
```

### Enable IP Forwarding

```bash
sudo tee /etc/sysctl.d/99-tailscale.conf << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

### Reboot

```bash
sudo reboot
```

### Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Get your Tailscale IP and add it to Cloudflare DNS:
```bash
tailscale ip -4
```

### Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Log out and back in for group changes.

---

## 3. Deploy Infrastructure

### Clone Repository

```bash
cd ~
git clone https://github.com/yourusername/ragnalab.git
cd ragnalab
```

### Deploy Order

Infrastructure must be deployed in this order:

| Step | Component | Install Guide |
|------|-----------|---------------|
| 1 | **Proxy (Traefik)** | [proxy/INSTALL.md](proxy/INSTALL.md) |
| 2 | **Uptime Kuma** | [apps/uptime-kuma/INSTALL.md](apps/uptime-kuma/INSTALL.md) |
| 3 | **Backup System** | [apps/backup/INSTALL.md](apps/backup/INSTALL.md) |

Or use the Makefile:
```bash
make networks
make up
```

---

## 4. Deploy Applications

After infrastructure is running, deploy applications:

| Application | Install Guide | URL |
|-------------|---------------|-----|
| Homepage | [apps/homepage/INSTALL.md](apps/homepage/INSTALL.md) | home.ragnalab.xyz |
| Vaultwarden | [apps/vaultwarden/INSTALL.md](apps/vaultwarden/INSTALL.md) | vault.ragnalab.xyz |
| Pi-hole | [apps/pihole/INSTALL.md](apps/pihole/INSTALL.md) | pihole.ragnalab.xyz |
| **Media Stack** | [apps/media/INSTALL.md](apps/media/INSTALL.md) | Various |

---

## 5. Adding New Applications

See [apps/whoami/docker-compose.yml](apps/whoami/docker-compose.yml) as a template.

Key labels for auto-discovery:

```yaml
labels:
  # Traefik routing
  - "traefik.enable=true"
  - "traefik.http.routers.myapp.rule=Host(`myapp.ragnalab.xyz`)"
  - "traefik.http.routers.myapp.entrypoints=websecure"
  - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
  - "traefik.http.services.myapp.loadbalancer.server.port=8080"

  # Homepage dashboard
  - "homepage.group=Applications"
  - "homepage.name=My App"
  - "homepage.href=https://myapp.ragnalab.xyz"
```

---

## Quick Reference

### Commands

| Command | Description |
|---------|-------------|
| `make up` | Start all infrastructure |
| `make down` | Stop all infrastructure |
| `make ps` | Show running containers |
| `make backup` | Trigger manual backup |
| `make restore SERVICE=name` | Restore a service |

### URLs

| Service | URL |
|---------|-----|
| Traefik Dashboard | https://traefik.ragnalab.xyz |
| Uptime Kuma | https://status.ragnalab.xyz |
| Homepage | https://home.ragnalab.xyz |
| Vaultwarden | https://vault.ragnalab.xyz |
| Pi-hole | https://pihole.ragnalab.xyz |
| Prowlarr | https://prowlarr.ragnalab.xyz |
| Sonarr | https://sonarr.ragnalab.xyz |
| Radarr | https://radarr.ragnalab.xyz |
| Bazarr | https://bazarr.ragnalab.xyz |
| Jellyfin | https://jellyfin.ragnalab.xyz |
| Jellyseerr | https://requests.ragnalab.xyz |

---

## Troubleshooting

### Certificates not working

1. Check Cloudflare DNS is "DNS only" (gray cloud, not orange)
2. Wait 2-5 minutes for Let's Encrypt
3. Check Traefik logs: `docker logs traefik`

### Container won't start

```bash
docker logs <container-name>
```

### Tailscale not connecting

```bash
sudo systemctl restart tailscaled
tailscale status
```

---

*Last updated: 2026-01-18*
