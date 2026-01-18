# RagnaLab Installation Guide

Complete setup guide for installing RagnaLab on a fresh Raspberry Pi 5.

**Time required:** ~30 minutes
**Prerequisites:** Raspberry Pi 5 with Raspberry Pi OS, domain name, Cloudflare account

---

## Table of Contents

1. [Hardware Requirements](#1-hardware-requirements)
2. [Accounts & Services](#2-accounts--services)
3. [Cloudflare DNS Setup](#3-cloudflare-dns-setup)
4. [Host System Configuration](#4-host-system-configuration)
5. [Install Tailscale](#5-install-tailscale)
6. [Install Docker](#6-install-docker)
7. [Clone Repository](#7-clone-repository)
8. [Configure Environment](#8-configure-environment)
9. [Deploy Infrastructure](#9-deploy-infrastructure)
10. [Uptime Kuma Setup (Manual)](#10-uptime-kuma-setup-manual)
11. [Verify Installation](#11-verify-installation)
12. [Homepage Setup](#12-homepage-setup)
13. [Vaultwarden Setup](#13-vaultwarden-setup)
14. [Pi-hole Setup](#14-pi-hole-setup)
15. [Media Automation Stack Setup](#15-media-automation-stack-setup)
16. [Adding New Applications](#16-adding-new-applications)

---

## 1. Hardware Requirements

- Raspberry Pi 5 (4GB+ RAM recommended)
- SSD storage (SD cards fail frequently with Docker)
- Active cooling (fan/heatsink)
- Ethernet connection (recommended) or WiFi

---

## 2. Accounts & Services

Before starting, ensure you have:

- [ ] Domain name (e.g., `ragnalab.xyz`)
- [ ] Cloudflare account with domain added
- [ ] Tailscale account (free tier works)

---

## 3. Cloudflare DNS Setup

### 3.1 Add Domain to Cloudflare

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click "Add a Domain"
3. Enter your domain (e.g., `ragnalab.xyz`)
4. Select Free plan
5. Update your registrar's nameservers to Cloudflare's
6. Wait for DNS propagation (usually 5-30 minutes)

### 3.2 Create API Token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use "Edit zone DNS" template
4. Permissions: `Zone → DNS → Edit`
5. Zone Resources: `Include → Specific zone → your domain`
6. Create and **save the token** (you'll need it later)

### 3.3 Create Wildcard DNS Record

In your domain's DNS settings, add:

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | `*` | `<your-tailscale-ip>` | DNS only (gray cloud) |

**Note:** You'll get the Tailscale IP in step 5. Come back here to add it.

**Important:** Must be "DNS only" (gray cloud), NOT "Proxied" (orange cloud).

---

## 4. Host System Configuration

SSH into your Raspberry Pi and run these commands.

### 4.1 Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 4.2 Enable cgroup Memory Limits

Edit boot config:
```bash
sudo nano /boot/firmware/cmdline.txt
```

Append to the **existing single line** (do not add a new line):
```
cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
```

### 4.3 Enable IP Forwarding

```bash
sudo tee /etc/sysctl.d/99-tailscale.conf << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

### 4.4 Reboot

```bash
sudo reboot
```

### 4.5 Verify After Reboot

```bash
# Check cgroup (should show NO warning about memory limits)
docker info 2>&1 | grep -i "memory"

# Check IP forwarding (should return 1)
sysctl net.ipv4.ip_forward
```

---

## 5. Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Follow the authentication URL to authorize the device.

**Get your Tailscale IP:**
```bash
tailscale ip -4
```

**Now go back to Cloudflare (step 3.3) and add this IP to your wildcard DNS record.**

Verify Tailscale persists on reboot:
```bash
sudo systemctl enable tailscaled
sudo systemctl status tailscaled
```

---

## 6. Install Docker

If Docker isn't already installed:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Log out and back in for group changes to take effect.

Verify:
```bash
docker --version
docker compose version
```

---

## 7. Clone Repository

```bash
cd ~
git clone https://github.com/yourusername/ragnalab.git
cd ragnalab
```

Or if setting up from scratch without git:
```bash
mkdir -p ~/ragnalab
cd ~/ragnalab
```

---

## 8. Configure Environment

### 8.1 Proxy Environment

```bash
cp proxy/.env.example proxy/.env
nano proxy/.env
```

Fill in your values:
```
CF_API_EMAIL=your-cloudflare-email@example.com
CF_DNS_API_TOKEN=your-api-token-from-step-3.2
ACME_EMAIL=your-email-for-letsencrypt@example.com
DOMAIN=ragnalab.xyz
```

### 8.2 Backup Environment

After Uptime Kuma is running (step 10), you'll need to add the push token:

```bash
nano apps/backup/.env
```

```
BACKUP_NOTIFICATION_URL=https://status.ragnalab.xyz/api/push/YOUR_TOKEN?status=up&msg=OK&ping=
```

---

## 9. Deploy Infrastructure

### 9.1 Create Networks and Start Services

```bash
make networks
make up
```

### 9.2 Verify Services Are Running

```bash
make ps
```

Expected output shows: `traefik`, `socket-proxy`, `whoami`, `uptime-kuma`, `backup`

### 9.3 Verify HTTPS Access

Wait 1-2 minutes for Let's Encrypt certificates, then test:

```bash
curl -I https://whoami.ragnalab.xyz
curl -I https://traefik.ragnalab.xyz
curl -I https://status.ragnalab.xyz
```

All should return `HTTP/2 200` or `HTTP/2 302` with valid certificates.

---

## 10. Uptime Kuma Setup (Manual)

Uptime Kuma requires one-time browser setup.

### 10.1 Initial Setup

1. Open https://status.ragnalab.xyz in your browser
2. Select **SQLite** as database
3. Create admin account (save credentials securely)

### 10.2 Add HTTP Monitors

Add these monitors (Type: HTTP(s), Interval: 300s):

| Friendly Name | URL |
|---------------|-----|
| Traefik Dashboard | https://traefik.ragnalab.xyz |
| whoami | https://whoami.ragnalab.xyz |
| Status Page | https://status.ragnalab.xyz |
| Pi-hole Web UI | http://pihole:80/admin |

### 10.3 Add Docker Host

1. Go to **Settings → Docker Hosts → Add**
2. Name: `Local Docker`
3. Connection Type: `Socket`
4. Docker Socket Path: `/var/run/docker.sock`
5. Save

### 10.4 Add Docker Container Monitors

Add these monitors (Type: Docker Container, Docker Host: Local Docker, Interval: 300s):

| Friendly Name | Container Name |
|---------------|----------------|
| traefik (container) | traefik |
| socket-proxy (container) | socket-proxy |
| uptime-kuma (container) | uptime-kuma |
| backup (container) | backup |
| pihole (container) | pihole |

### 10.5 Add DNS Monitor (Pi-hole)

Add this monitor (Type: DNS, Interval: 60s, Retries: 2):

| Setting | Value |
|---------|-------|
| Friendly Name | Pi-hole DNS |
| Hostname | `google.com` |
| Resolver Server | `10.0.0.200` |
| Port | `53` |
| Record Type | A |

This verifies Pi-hole is resolving DNS queries.

### 10.6 Create Backup Push Monitor

1. **Add New Monitor**
2. Monitor Type: **Push**
3. Friendly Name: `Daily Backup`
4. Heartbeat Interval: `86400` (seconds = 1 day)
5. Retries: `0`
6. **Save and copy the Push URL**

The URL looks like: `https://status.ragnalab.xyz/api/push/XXXXXXXX?status=up&msg=OK&ping=`

### 10.7 Configure Backup Notification

Add the push URL to backup config:

```bash
nano apps/backup/.env
```

```
BACKUP_NOTIFICATION_URL=https://status.ragnalab.xyz/api/push/XXXXXXXX?status=up&msg=OK&ping=
```

Restart backup service:
```bash
docker compose -f apps/backup/docker-compose.yml up -d
```

### 10.8 Organize Monitors (Optional)

Create groups for better organization:
- **Web Services** — HTTP monitors
- **Containers** — Docker container monitors
- **Network** — DNS monitors
- **Backups** — Push monitor

### 10.9 Create Status Page (Required for Homepage Widget)

1. Go to **Status Pages** in the sidebar
2. Click **New Status Page**
3. Name: `RagnaLab Status`
4. Slug: `status-page` (must be exactly this for Homepage widget)
5. Add your monitors to the status page
6. Save

This status page is used by the Homepage dashboard widget to display service status.

---

## 11. Verify Installation

### 11.1 Check All Services

```bash
make ps
```

All containers should show "Up" and "healthy".

### 11.2 Check Monitoring

- Open https://status.ragnalab.xyz
- All monitors should be green

### 11.3 Test Backup

```bash
make backup
ls -la backups/
```

Should show backup archive files.

### 11.4 Test Restore

```bash
make restore SERVICE=uptime-kuma
```

Follow prompts, then verify Uptime Kuma still has all monitors.

---

## 12. Homepage Setup

Homepage auto-discovers services via Docker labels - no manual configuration needed.

### 12.1 Access Homepage

Open https://home.ragnalab.xyz in your browser.

### 12.2 Verify Dashboard

You should see:

- **Infrastructure group:** Traefik (with route/service counts), Uptime Kuma (with monitoring status)
- **Apps group:** Vaultwarden
- **Bookmarks section:** External links (GitHub, Cloudflare, Tailscale)

If services are missing, they may need Homepage labels added to their docker-compose.yml.

---

## 13. Vaultwarden Setup

### 13.1 Generate Admin Token

```bash
docker run --rm -it vaultwarden/server /vaultwarden hash
```

Enter a secure password when prompted. **Save both the password and the hash.**

### 13.2 Create Environment File

```bash
cp apps/vaultwarden/.env.example apps/vaultwarden/.env
nano apps/vaultwarden/.env
```

Paste the hash from step 13.1 (include the single quotes around the hash).

### 13.3 Deploy Vaultwarden

```bash
docker compose -f apps/vaultwarden/docker-compose.yml up -d
```

### 13.4 Access Vaultwarden

- Main interface: https://vault.ragnalab.xyz
- Admin panel: https://vault.ragnalab.xyz/admin

Use the password (not the hash) to access the admin panel.

**Note:** Signups are disabled by default. Use the admin panel to invite users.

---

## 14. Pi-hole Setup

Pi-hole provides network-wide DNS-based ad blocking.

### 14.1 Install Macvlan Service

Pi-hole requires a macvlan network for its own LAN IP. Install the systemd service:

```bash
# Create the macvlan script
sudo tee /usr/local/bin/pihole-macvlan.sh << 'EOF'
#!/bin/bash
INTERFACE="eth0"
SHIM_NAME="macvlan-shim"
SHIM_IP="10.0.0.201"
PIHOLE_IP="10.0.0.200"

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
EOF

sudo chmod +x /usr/local/bin/pihole-macvlan.sh

# Create systemd service
sudo tee /etc/systemd/system/pihole-macvlan.service << 'EOF'
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
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable pihole-macvlan.service
sudo systemctl start pihole-macvlan.service
```

### 14.2 Configure Environment

```bash
cp apps/pihole/.env.example apps/pihole/.env
nano apps/pihole/.env
```

Set `PIHOLE_PASSWORD` and `PIHOLE_API_KEY` (can be the same value).

### 14.3 Deploy Pi-hole

```bash
docker compose -f apps/pihole/docker-compose.yml up -d
```

### 14.4 Verify

```bash
# Check DNS resolution
dig @10.0.0.200 google.com +short

# Check ad blocking
dig @10.0.0.200 doubleclick.net +short
# Should return 0.0.0.0
```

Access web UI: https://pihole.ragnalab.xyz

### 14.5 Configure Devices

Pi-hole runs in DNS-only mode. Configure devices to use `10.0.0.200` as their DNS server:

- **iPhone/iPad:** Settings > Wi-Fi > (network) > Configure DNS > Manual > 10.0.0.200
- **Mac:** System Settings > Network > Wi-Fi > Details > DNS > 10.0.0.200
- **Windows:** Network settings > Change adapter options > IPv4 > DNS: 10.0.0.200

---

## 15. Media Automation Stack Setup

The media stack provides automated TV and movie downloading with request management.

### 15.1 Prerequisites

**Required:** VPN account with WireGuard support (e.g., ProtonVPN, Mullvad)

### 15.2 Configure Environment

```bash
cp apps/media/.env.example apps/media/.env
nano apps/media/.env
```

Fill in your VPN credentials:
```
VPN_SERVICE_PROVIDER=protonvpn
OPENVPN_USER=your-protonvpn-username
OPENVPN_PASSWORD=your-protonvpn-password
WIREGUARD_PRIVATE_KEY=your-wireguard-private-key
SERVER_COUNTRIES=Netherlands
```

### 15.3 Deploy Media Stack

```bash
# Deploy in order (dependencies matter)
docker compose -f apps/media/gluetun/docker-compose.yml up -d
docker compose -f apps/media/qbittorrent/docker-compose.yml up -d
docker compose -f apps/media/prowlarr/docker-compose.yml up -d
docker compose -f apps/media/sonarr/docker-compose.yml up -d
docker compose -f apps/media/radarr/docker-compose.yml up -d
docker compose -f apps/media/bazarr/docker-compose.yml up -d
docker compose -f apps/media/unpackerr/docker-compose.yml up -d
docker compose -f apps/media/jellyfin/docker-compose.yml up -d
docker compose -f apps/media/jellyseerr/docker-compose.yml up -d
```

### 15.4 Verify VPN Protection

```bash
# Check VPN IP (should NOT be your home IP)
docker exec qbittorrent curl -s ifconfig.me

# Verify Gluetun is healthy
docker inspect gluetun --format='{{.State.Health.Status}}'
```

### 15.5 Configure Prowlarr Indexers

1. Open https://prowlarr.ragnalab.xyz
2. Navigate to: Indexers > Add Indexer
3. Add public indexers (no account needed):
   - YTS (movies)
   - EZTV (TV shows)
   - TorrentGalaxy
4. Test each indexer after adding
5. Verify sync to Sonarr/Radarr: Settings > Apps

### 15.6 Jellyfin Initial Setup

1. Open https://jellyfin.ragnalab.xyz
2. Complete the setup wizard
3. Create admin account
4. Libraries are pre-configured (Movies, TV Shows)
5. **Important:** Verify transcoding is DISABLED in Settings > Playback > Transcoding

### 15.7 Jellyseerr Initial Setup

1. Open https://requests.ragnalab.xyz
2. Select "Use your Jellyfin account"
3. Enter Jellyfin URL: `http://jellyfin:8096`
4. Log in with your Jellyfin admin account
5. Sonarr/Radarr connections are pre-configured

### 15.8 Add Uptime Kuma Monitors

Add these monitors to https://status.ragnalab.xyz:

**HTTP(s) Monitors** (Interval: 60s, Retries: 3):

| Friendly Name | URL |
|---------------|-----|
| Prowlarr | https://prowlarr.ragnalab.xyz |
| Sonarr | https://sonarr.ragnalab.xyz |
| Radarr | https://radarr.ragnalab.xyz |
| Bazarr | https://bazarr.ragnalab.xyz |
| Jellyfin | https://jellyfin.ragnalab.xyz |
| Jellyseerr | https://requests.ragnalab.xyz |

**Docker Container Monitors** (Type: Docker Container, Docker Host: Local Docker, Interval: 60s):

| Friendly Name | Container Name |
|---------------|----------------|
| gluetun (container) | gluetun |
| qbittorrent (container) | qbittorrent |
| prowlarr (container) | prowlarr |
| sonarr (container) | sonarr |
| radarr (container) | radarr |
| bazarr (container) | bazarr |
| unpackerr (container) | unpackerr |
| jellyfin (container) | jellyfin |
| jellyseerr (container) | jellyseerr |

**Organize into "Media" group** for better dashboard organization.

### 15.9 Service URLs

| URL | Service | Purpose |
|-----|---------|---------|
| https://prowlarr.ragnalab.xyz | Prowlarr | Indexer management |
| https://sonarr.ragnalab.xyz | Sonarr | TV show automation |
| https://radarr.ragnalab.xyz | Radarr | Movie automation |
| https://bazarr.ragnalab.xyz | Bazarr | Subtitle management |
| https://jellyfin.ragnalab.xyz | Jellyfin | Media server |
| https://requests.ragnalab.xyz | Jellyseerr | Request management |
| localhost:8080 | qBittorrent | Torrent client (VPN-only) |

---

## 16. Adding New Applications

Create a new app folder with a docker-compose.yml:

```bash
mkdir apps/myapp
```

Create `apps/myapp/docker-compose.yml`:

```yaml
services:
  myapp:
    image: your-image:tag
    container_name: myapp
    restart: unless-stopped
    networks:
      - proxy
    labels:
      # Traefik routing
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.ragnalab.xyz`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
      - "traefik.docker.network=proxy"
      # Homepage dashboard
      - "homepage.group=Applications"
      - "homepage.name=My App"
      - "homepage.icon=myapp.png"
      - "homepage.href=https://myapp.ragnalab.xyz"
      - "homepage.description=App description"

networks:
  proxy:
    external: true
```

Deploy and verify:

```bash
docker compose -f apps/myapp/docker-compose.yml up -d
```

The app will automatically appear in Traefik and Homepage.

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `make up` | Start all services |
| `make down` | Stop all services |
| `make ps` | Show running containers |
| `make logs` | View Traefik logs |
| `make backup` | Trigger manual backup |
| `make restore SERVICE=name` | Restore a service |

| URL | Service |
|-----|---------|
| https://traefik.ragnalab.xyz | Traefik Dashboard |
| https://status.ragnalab.xyz | Uptime Kuma |
| https://home.ragnalab.xyz | Homepage Dashboard |
| https://vault.ragnalab.xyz | Vaultwarden |
| https://pihole.ragnalab.xyz | Pi-hole Admin |
| https://prowlarr.ragnalab.xyz | Prowlarr (Indexers) |
| https://sonarr.ragnalab.xyz | Sonarr (TV) |
| https://radarr.ragnalab.xyz | Radarr (Movies) |
| https://bazarr.ragnalab.xyz | Bazarr (Subtitles) |
| https://jellyfin.ragnalab.xyz | Jellyfin (Media Server) |
| https://requests.ragnalab.xyz | Jellyseerr (Requests) |
| https://whoami.ragnalab.xyz | Test Service |

---

## Troubleshooting

### Certificates not working

1. Check Cloudflare DNS is "DNS only" (gray cloud)
2. Wait 2-5 minutes for Let's Encrypt
3. Check Traefik logs: `docker logs traefik`

### Container won't start

```bash
docker logs <container-name>
```

### Memory limit warnings

Ensure cgroup parameters are in `/boot/firmware/cmdline.txt` and reboot.

### Tailscale not connecting

```bash
sudo systemctl restart tailscaled
tailscale status
```

---

*Last updated: 2026-01-18*
*Covers: Phase 1-4 (v1.0), Phase 5 (Pi-hole), Phase 6 (Media Stack)*
