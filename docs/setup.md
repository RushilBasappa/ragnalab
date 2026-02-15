# RagnaLab Setup Guide

Complete deployment guide from bare Raspberry Pi to fully operational homelab.

---

## Prerequisites

### Hardware
- **Raspberry Pi 5** (4GB or 8GB RAM recommended)
- **MicroSD card** (32GB minimum, 64GB+ recommended)
- **Ethernet connection** (recommended for stability)
- **External storage** (optional, for media library)

### Software
- **Raspberry Pi OS 64-bit** (Bookworm or later)
  - Use [Raspberry Pi Imager](https://www.raspberrypi.com/software/)
  - Select "Raspberry Pi OS (64-bit)"
  - Configure hostname, user, SSH, WiFi in advanced settings

### External Accounts
- **Cloudflare account** with domain DNS hosted there
- **ProtonVPN account** (or other WireGuard VPN provider)
- **GitHub account** (optional, for repository access)

---

## Phase 1: First Boot

### 1. Flash SD Card
```bash
# Using Raspberry Pi Imager:
# 1. Choose "Raspberry Pi OS (64-bit)"
# 2. Click gear icon for advanced settings:
#    - Set hostname: ragnalab
#    - Enable SSH (use password or public key)
#    - Set username and password
#    - Configure WiFi (optional)
# 3. Write to SD card
```

### 2. Initial Connection
```bash
# SSH into the Pi (from your workstation)
ssh pi@ragnalab.local   # or use the IP address

# Update the system (if not done via Imager)
sudo apt update && sudo apt upgrade -y
```

### 3. Clone Repository
```bash
# Install git if not present
sudo apt install -y git

# Clone the repo
cd ~
git clone https://github.com/yourusername/ragnalab_v2.git
cd ragnalab_v2
```

### 4. Configure Cloudflare DNS

Traefik uses Cloudflare DNS challenge for wildcard SSL certificates. Set up the Cloudflare account and API token now. You'll add the DNS A records after Phase 2 Step 5 once you have your Tailscale IP.

```bash
# In Cloudflare Dashboard:
# 1. Add your domain (e.g. ragnalab.xyz) to Cloudflare
# 2. Set nameservers at your registrar to Cloudflare's
# 3. Add DNS records (after you have your Tailscale IP from Phase 2 Step 5):
#    - Type: A    | Name: @    | Content: <your-tailscale-ip> | Proxy: OFF
#    - Type: A    | Name: *    | Content: <your-tailscale-ip> | Proxy: OFF
#
# 4. Create API token:
#    My Profile → API Tokens → Create Token → Custom Token
#    Permissions:
#      - Zone → DNS → Edit
#      - Zone → Zone → Read
#    Zone Resources:
#      - Include → Specific zone → ragnalab.xyz
#    Save the token — you'll need it for CF_DNS_API_TOKEN in .env
```

---

## Phase 2: Bootstrap System

### 1. Install Prerequisites
```bash
# Fix locale and install Ansible
make fix-locale
make install-ansible
```

### 2. Set Up Vault Password
```bash
# If you have the vault password (existing member):
echo 'your-vault-password-here' > .vault_pass
chmod 600 .vault_pass

# If starting fresh (new deployment):
# 1. Generate a strong password:
openssl rand -base64 32

# 2. Save it securely (password manager):
echo 'your-generated-password' > .vault_pass
chmod 600 .vault_pass
```

### 3. Configure Secrets

**Option A: Existing Deployment** (you have access to encrypted secrets)
```bash
# Decrypt secrets from Ansible Vault
make init   # Creates compose/.env from ansible/vars/secrets.yml
```

**Option B: New Deployment** (first time setup)
```bash
# Copy example file
cp compose/.env.example compose/.env

# Edit with your values
nano compose/.env

# Required secrets (generate these):
openssl rand -base64 32   # For Authelia secrets (run 3 times)
openssl rand -base64 48   # For other secrets

# Fill in:
# - DOMAIN (your domain, e.g. ragnalab.xyz)
# - Cloudflare API token and email
# - ProtonVPN WireGuard credentials
# - Pi-hole password
# - All application admin passwords
# - Generated secrets for Authelia, Paperless, Vaultwarden, Tandoor
# (Authelia user password hash will be set after bootstrap — requires Docker)

# Encrypt to Ansible Vault
make sync   # Creates ansible/vars/secrets.yml from compose/.env
```

### 4. Install Git Hooks
```bash
# Enable automatic .env encryption on commit
make hooks
```

### 5. Run Bootstrap
```bash
# Full system bootstrap (installs Docker, Tailscale, Zsh, etc.)
make bootstrap

# This will:
# 1. Update system packages
# 2. Generate GitHub SSH key (you'll need to add it to GitHub)
# 3. Install and configure Tailscale (you'll need to authenticate)
# 4. Install Docker with cgroup memory limits
# 5. REBOOT the system (happens automatically)
# 6. Install Zsh + Starship prompt
```

**Important Notes:**
- During bootstrap, you'll be prompted to add the SSH key to GitHub
- The system will reboot automatically after Docker installation
- After reboot, re-run `make bootstrap` to complete the remaining steps

**Tailscale Authentication:**
After bootstrap installs Tailscale, authenticate it:
```bash
sudo tailscale up

# This prints a URL like: https://login.tailscale.com/a/abc123
# Open that URL in a browser and sign in to your Tailscale account
# Once authenticated, the Pi appears in your Tailscale admin console

# Verify it's connected:
tailscale ip -4   # Should print your Tailscale IP (e.g. 100.x.x.x)

# Use this IP for your Cloudflare DNS A records (see Phase 1 Step 4)
```

### 6. Set Up Authelia User (Option B only)

Docker is now installed, so you can generate the Authelia password hash:
```bash
# Generate argon2 hash for your login password:
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'your-password'

# Edit the users database:
nano compose/services/authelia/users_database.yml

# Replace the password field with your generated hash:
# users:
#   yourname:
#     displayname: Your Name
#     password: "$argon2id$v=19$m=65536,t=3,p=4$..."
#     email: you@example.com
#     groups:
#       - admins
```

---

## Phase 3: Deploy Services

### Option A: Deploy Everything
```bash
# Deploy entire stack in order (infrastructure → media → apps)
make deploy-all
```

This runs:
1. Infrastructure (socket-proxy → authelia → traefik → pihole)
2. Media stack (qbittorrent → sonarr → radarr → prowlarr → bazarr → jellyfin → jellyseerr)
3. All utility apps

**Time:** ~30-45 minutes (depends on internet speed and Pi model)

### Option B: Deploy Incrementally

#### Step 1: Core Infrastructure
```bash
make deploy-infra
```

Deploys in order:
1. **socket-proxy** - Docker API gateway
2. **authelia** - SSO authentication
3. **traefik** - Reverse proxy (pulls SSL certificate)
4. **pihole** - DNS and ad blocking

Verify:
- https://traefik.ragnalab.xyz - Dashboard (login via Authelia)
- https://auth.ragnalab.xyz - Authentication portal
- https://pihole.ragnalab.xyz - Pi-hole admin

#### Step 2: Media Stack
```bash
make deploy-media
```

Deploys in dependency order:
1. **qbittorrent** + Gluetun VPN (download client)
2. **sonarr** (TV automation)
3. **radarr** (movie automation)
4. **prowlarr** (indexer manager)
5. **bazarr** (subtitles)
6. **jellyfin** (media server)
7. **jellyseerr** (request portal)

Each service is auto-configured to connect to the previous ones.

Verify:
- https://qbit.ragnalab.xyz - qBittorrent
- https://sonarr.ragnalab.xyz - TV shows
- https://radarr.ragnalab.xyz - Movies
- https://prowlarr.ragnalab.xyz - Indexers
- https://jellyfin.ragnalab.xyz - Media server

#### Step 3: Utility Apps
```bash
make deploy-apps
```

Deploys all remaining services:
- **Monitoring:** uptime-kuma, dozzle, beszel, speedtest-tracker
- **Productivity:** vaultwarden, paperless-ngx, tandoor, freshrss, actual-budget
- **Sync/Storage:** obsidian-livesync, syncthing, filebrowser, backrest
- **Other:** rustdesk, homeassistant, ntfy, homepage

#### Step 4: Single Service Deployment
```bash
# Deploy or update a specific service
make service TAGS=sonarr

# Deploy multiple services
make service TAGS=sonarr,radarr,prowlarr
```

---

## Phase 4: Post-Deployment Configuration

### 1. Jellyfin Initial Setup
```bash
# Open Jellyfin web interface
https://jellyfin.ragnalab.xyz

# Complete setup wizard:
# 1. Set language
# 2. Create admin account (save credentials in Vaultwarden)
# 3. Add media libraries:
#    - Movies: /data/media/movies
#    - TV Shows: /data/media/tv
# 4. Skip metadata settings (defaults are fine)
# 5. Finish setup

# Generate API key (needed for Homepage and *arr apps):
# Settings → Advanced → API Keys → New API Key
# Copy key and add to compose/.env:
nano compose/.env
# Add: JELLYFIN_API_KEY=your-key-here
make sync   # Re-encrypt secrets
```

### 2. Jellyseerr Configuration
```bash
# Open Jellyseerr
https://requests.ragnalab.xyz

# Step 1: Sign in with Jellyfin
# - Select "Use your Jellyfin account"
# - Jellyfin URL: http://jellyfin:8096
# - Enter your Jellyfin admin credentials

# Step 2: Configure Jellyfin
# - Click "Sync Libraries"
# - Enable "Movies" and "TV Shows"
# - Save changes

# Step 3: Add Radarr
# - Go to Settings → Services → Radarr
# - Default server: Yes
# - Server name: Radarr
# - Hostname: radarr
# - Port: 7878
# - API key: (run `make keys` to get it)
# - Quality profile: 4K Minimal
# - Root folder: /data/media/movies
# - Click "Test" then "Add Server"

# Step 4: Add Sonarr
# - Go to Settings → Services → Sonarr
# - Default server: Yes
# - Server name: Sonarr
# - Hostname: sonarr
# - Port: 8989
# - API key: (run `make keys` to get it)
# - Quality profile: 4K Minimal
# - Root folder: /data/media/tv
# - Click "Test" then "Add Server"

# Step 5: Finish
# - Click "Finish" to complete setup
```

### 3. Verify Homepage Dashboard

API keys are automatically extracted and written to `.env` during deployment.
```bash
# Open Homepage — all widgets should be working:
https://home.ragnalab.xyz

# If any widget shows "API Error":
# 1. Check the service is running: make status
# 2. Redeploy homepage: make service TAGS=homepage

# To manually inspect API keys:
make keys
```

### 4. Prowlarr Indexers
```bash
# Open Prowlarr
https://prowlarr.ragnalab.xyz

# Add indexers:
# Settings → Indexers → Add Indexer
# - Search for your preferred trackers
# - Configure authentication (if required)
# - Save each indexer

# Verify sync to Sonarr/Radarr:
# - Indexers should automatically appear in both apps
# - Check Sonarr → Settings → Indexers
# - Check Radarr → Settings → Indexers
```

### 5. Vaultwarden Setup
```bash
# Open Vaultwarden
https://vault.ragnalab.xyz

# Create account:
# - Click "Create Account"
# - Enter email and master password
# - Complete registration

# Note: Signups are disabled after first account creation
# To enable signups temporarily:
# Edit compose/apps/vaultwarden/docker-compose.yml
# Change SIGNUPS_ALLOWED to "true"
# Run: make service TAGS=vaultwarden
```

### 6. Paperless-ngx Setup
```bash
# Open Paperless-ngx
https://paperless.ragnalab.xyz

# Login with credentials from .env:
# - Username: PAPERLESS_ADMIN_USER
# - Password: PAPERLESS_ADMIN_PASSWORD

# Initial configuration:
# 1. Settings → General → Set timezone
# 2. Settings → OCR → Enable OCR (already enabled by default)
# 3. Create document types, tags, correspondents as needed

# Upload documents:
# - Use web interface: Documents → Upload
# - Or use Paperless-ngx mobile app
# - Or mount consume folder via SMB/NFS
```

### 7. Pi-hole Configuration
```bash
# Open Pi-hole
https://pihole.ragnalab.xyz

# Login with password from .env (PIHOLE_WEBPASSWORD)

# Recommended settings:
# Settings → DNS:
# - Upstream DNS: Cloudflare (1.1.1.1, 1.0.0.1)
# - Enable DNSSEC
# - Conditional forwarding (for local DNS)

# Add blocklists:
# Group Management → Adlists
# - Add additional blocklists (optional)
# - Tools → Update Gravity

# Configure clients:
# - Set Pi's IP as DNS server on router
# - Or configure per-device
```

### 8. Homepage Dashboard
```bash
# Homepage should be auto-configured with all services
# Open: https://home.ragnalab.xyz

# Customize (optional):
# - Edit compose/apps/homepage/config/services.yaml
# - Edit compose/apps/homepage/config/widgets.yaml
# - Restart: make service TAGS=homepage
```

### 9. Verify Backups
```bash
# Backrest is auto-configured by Ansible with:
# - Local restic repo at /backups (encrypted)
# - Daily backup at 3 AM for all Docker volumes
# - Retention: 15 daily, 4 weekly, 3 monthly

# Open Backrest UI to verify:
https://backups.ragnalab.xyz

# Trigger a manual backup:
make backup

# Restore: use Backrest UI → select snapshot → restore files
```

---

## Phase 5: Verification & Testing

### 1. Check All Services
```bash
# View running containers
make status

# Should show 34 containers running
# Check memory usage, ensure no OOM issues
```

### 2. Test Authentication
```bash
# Test Authelia SSO:
# - Open any protected service (e.g., https://sonarr.ragnalab.xyz)
# - Should redirect to Authelia login
# - Login with credentials from users_database.yml
# - Should redirect back to service

# Test bypassed services (should NOT require login):
# - https://vault.ragnalab.xyz
# - https://jellyfin.ragnalab.xyz
# - https://requests.ragnalab.xyz
# - https://ntfy.ragnalab.xyz
```

### 3. Test Media Stack
```bash
# Test Jellyseerr → Sonarr/Radarr → qBittorrent flow:
# 1. Open Jellyseerr: https://requests.ragnalab.xyz
# 2. Search for a TV show or movie
# 3. Request it
# 4. Check Sonarr/Radarr → Activity (should show searching)
# 5. Check qBittorrent → should show download
# 6. Wait for download → should auto-import to library
# 7. Check Jellyfin → should appear in library
```

### 4. Test VPN
```bash
# Verify qBittorrent is behind VPN:
# 1. Open https://qbit.ragnalab.xyz
# 2. Add this torrent: https://torguard.net/checkmytorrentipaddress.php
# 3. Check the IP shown in peers
# 4. Should be your VPN IP, NOT your home IP
```

### 5. Test Monitoring
```bash
# Check Uptime Kuma:
# https://uptime.ragnalab.xyz
# - Should auto-discover all services via Autokuma
# - All services should show "Up"

# Check Dozzle:
# https://logs.ragnalab.xyz
# - Should show logs for all containers
# - Test filtering and search

```

---

## Phase 6: Tailscale Network Access

### 1. Configure Tailscale
```bash
# On the Pi (if not done during bootstrap):
sudo tailscale up

# Authenticate via URL shown
# Pi will appear in Tailscale admin console

# Get Tailscale IP:
tailscale ip -4
# Example: 100.110.120.130
```

### 2. Update DNS Resolution
```bash
# Option A: Use MagicDNS (recommended)
# In Tailscale admin console:
# - DNS → Enable MagicDNS
# - Add nameserver: 100.100.100.100
# - Your Pi will be accessible as: ragnalab.tail-scale.ts.net

# Option B: Manual hosts file
# On your workstation, add to /etc/hosts:
100.110.120.130    ragnalab.xyz
100.110.120.130    traefik.ragnalab.xyz
100.110.120.130    auth.ragnalab.xyz
# ... (add all subdomains)
```

### 3. Configure Pi-hole for Tailscale
```bash
# Set Pi-hole as DNS for Tailscale network:
# Tailscale admin → DNS → Nameservers
# - Add: 100.110.120.130 (Pi's Tailscale IP)
# - Clients will use Pi-hole for DNS
```

---

## Common Operations

### Update a Single Service
```bash
# Pull latest image and recreate container
docker compose -f compose/docker-compose.yml pull <service>
docker compose -f compose/docker-compose.yml up -d <service>

# Or use Ansible:
make service TAGS=<service>
```

### Add a New Service
```bash
# 1. Create compose file:
mkdir -p compose/apps/newapp
nano compose/apps/newapp/docker-compose.yml

# 2. Create Ansible task:
nano ansible/tasks/apps/newapp.yml

# 3. Add to site.yml:
nano ansible/site.yml

# 4. Add to main compose file:
nano compose/docker-compose.yml

# 5. Deploy:
make service TAGS=newapp
```

### Remove a Service
```bash
# Stop and remove container (keeps volumes)
make teardown APP=<service>

# Remove completely (including volumes):
docker compose -f compose/docker-compose.yml down <service> -v
```

### View Logs
```bash
# Via Dozzle (web UI):
https://logs.ragnalab.xyz

# Via CLI:
docker compose -f compose/docker-compose.yml logs <service> -f

# All services:
docker compose -f compose/docker-compose.yml logs -f
```

### Manage Secrets
```bash
# Edit secrets:
nano compose/.env

# Re-encrypt to Ansible Vault:
make sync

# Decrypt secrets:
make init

# Rotate Ansible Vault password:
ansible-vault rekey ansible/vars/secrets.yml
# Update .vault_pass with new password
```

### System Maintenance
```bash
# Check system resources:
make status

# Prune unused Docker resources:
docker system prune -a

# Update all containers (manual):
cd compose
docker compose pull
docker compose up -d
```

---

## Troubleshooting

### Container Won't Start
```bash
# Check logs:
docker logs <container-name>

# Check resource limits:
docker stats <container-name>

# Check dependencies:
docker compose -f compose/docker-compose.yml ps
```

### Out of Memory (OOM)
```bash
# Check which container was killed:
dmesg | grep -i "out of memory"

# Increase memory limit in docker-compose.yml:
deploy:
  resources:
    limits:
      memory: 1G   # Increase this
```

### DNS Issues
```bash
# Test Pi-hole:
dig @127.0.0.1 google.com

# Check Pi-hole logs:
docker logs pihole

# Restart Pi-hole:
docker restart pihole
```

### Traefik SSL Issues
```bash
# Check Traefik logs:
docker logs traefik

# Verify Cloudflare API token:
# Should have Zone:DNS:Edit permissions

# Force cert regeneration:
docker exec traefik rm /acme/acme.json
docker restart traefik
```

### Authelia Authentication Loop
```bash
# Check Authelia logs:
docker logs authelia

# Verify session cookies:
# Browser → Dev Tools → Application → Cookies
# Clear all ragnalab.xyz cookies

# Restart Authelia:
docker restart authelia
```

---

## Backup & Disaster Recovery

### Critical Data Locations
```bash
# Docker volumes:
/var/lib/docker/volumes/

# Critical volumes (backup priority):
# - vaultwarden_data (passwords)
# - paperless_data (documents - includes app, media, export, consume, redis)
# - authelia_data (users and sessions)
# - *_data volumes (all service data - unified naming convention)
# - jellyfin_data (watch history, metadata)
```

### Manual Backup
```bash
# Backup all volumes to tarball:
sudo tar -czf ragnalab-backup-$(date +%Y%m%d).tar.gz \
  -C /var/lib/docker/volumes .

# Restore:
sudo tar -xzf ragnalab-backup-DATE.tar.gz \
  -C /var/lib/docker/volumes
```

### Automated Backup (via Backrest)
Auto-configured by Ansible. Daily at 3 AM, restic-encrypted. UI at `backups.ragnalab.xyz`.

### Disaster Recovery
```bash
# Total loss scenario:
# 1. Flash new SD card with Raspberry Pi OS
# 2. Clone repository
# 3. Restore .vault_pass
# 4. Run: make bootstrap
# 5. Run: make init
# 6. Restore volume backups to /var/lib/docker/volumes/
# 7. Run: make deploy-all
# 8. Verify all services

# RTO (Recovery Time Objective): 2-4 hours
# RPO (Recovery Point Objective): 24 hours (with daily backups)
```

---

## Security Checklist

- [ ] Changed all default passwords in `.env`
- [ ] Ansible Vault password is strong (32+ characters)
- [ ] `.vault_pass` has 600 permissions
- [ ] Vaultwarden admin token is set and strong
- [ ] Pi-hole web password is strong
- [ ] Authelia user passwords are hashed with argon2
- [ ] Traefik SSL certificate is valid and auto-renewing
- [ ] qBittorrent is behind VPN (IP test passed)
- [ ] Docker socket is only accessible via socket-proxy
- [ ] Tailscale authentication is enabled
- [ ] SSH is key-based (password auth disabled)
- [ ] Regular backups are configured and tested

---

## Performance Tuning

### Raspberry Pi 5 Specific
```bash
# Enable hardware video acceleration (for Jellyfin):
# Already configured via /dev/video19 device mapping

# Optimize swap:
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile
# Set: CONF_SWAPSIZE=2048
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Overclock (optional, voids warranty):
sudo nano /boot/firmware/config.txt
# Add:
# over_voltage=6
# arm_freq=2800
```

### Docker Performance
```bash
# Enable log rotation:
sudo nano /etc/docker/daemon.json
# Add:
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
sudo systemctl restart docker
```

---

## Additional Resources

- **RagnaLab Documentation:** See [services.md](services.md) for detailed service descriptions
- **Ansible Automation:** See ansible/tasks/ for task details
- **Docker Compose:** See compose/apps/ for service definitions
- **Traefik Docs:** https://doc.traefik.io/traefik/
- **Authelia Docs:** https://www.authelia.com/
- **Servarr Wiki:** https://wiki.servarr.com/

---

## Support & Contributing

For issues, questions, or contributions:
- Check existing issues in the repository
- Review [audit.md](audit.md) for known limitations
- Submit PRs with improvements

**Note:** This is a personal homelab setup. Adapt configurations to your needs and security requirements.
