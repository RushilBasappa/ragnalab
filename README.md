# RagnaLab

Private homelab platform running on Raspberry Pi 5 with Traefik reverse proxy, automatic HTTPS, and Tailscale VPN access.

## Prerequisites

Complete these steps in order before deploying.

---

## 1. Cloudflare Setup

You need a domain with DNS managed by Cloudflare. Traefik uses Cloudflare's API for Let's Encrypt DNS-01 challenges (proves domain ownership without exposing ports to the internet).

### 1.1 Add Domain to Cloudflare

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click "Add a Domain"
3. Enter your domain (e.g., `yourdomain.xyz`)
4. Select the Free plan
5. Update your domain registrar's nameservers to Cloudflare's (shown after adding)
6. Wait for DNS propagation (can take up to 24 hours, usually faster)

Your domain is now a "zone" in Cloudflare.

### 1.2 Create API Token

Create an API token at https://dash.cloudflare.com/profile/api-tokens:

1. Click "Create Token"
2. Use "Edit zone DNS" template
3. **Permissions:** Zone → DNS → Edit
4. **Zone Resources:** Include → Specific zone → select your domain
5. Create and copy the token

The token only needs access to your specific zone, not your entire Cloudflare account.

### 1.3 Environment File

```bash
cd proxy
cp .env.example .env
```

Edit `proxy/.env` with your values:
```
CF_API_EMAIL=your-cloudflare-email@example.com
CF_DNS_API_TOKEN=your-api-token
ACME_EMAIL=your-email-for-letsencrypt@example.com
DOMAIN=yourdomain.xyz
```

### 1.4 Wildcard DNS Record

In your Cloudflare zone's DNS settings, create an A record:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `*` | `<your-tailscale-ip>` | DNS only (gray cloud) |

Get your Tailscale IP with: `tailscale ip -4`

**Important:** Must be "DNS only" (gray cloud), not "Proxied" (orange cloud). Traefik handles SSL termination directly.

This wildcard means `*.yourdomain.xyz` (e.g., `whoami.yourdomain.xyz`, `home.yourdomain.xyz`) all resolve to your Pi.

---

## 2. Host System Configuration

These configurations must be done on the Raspberry Pi.

### 2.1 Docker Memory Limits (cgroup)

Add these parameters to `/boot/firmware/cmdline.txt` (append to the existing single line, do not add a newline):

```
cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
```

**Why:** Enables Docker to enforce `mem_limit` and CPU constraints in compose files. Without this, resource limits are silently ignored.

### 2.2 IP Forwarding

Create `/etc/sysctl.d/99-tailscale.conf`:

```
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
```

Apply immediately:
```bash
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

---

## 3. Tailscale

Install and authenticate Tailscale on the host:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Follow the authentication URL printed to authorize the device.

---

## 4. Reboot

Reboot to apply the cgroup kernel parameters:

```bash
sudo reboot
```

**Verify after reboot:**
```bash
# Memory limits (should show NO warning)
docker info 2>&1 | grep -i "memory"

# IP forwarding
sysctl net.ipv4.ip_forward
# Should return: net.ipv4.ip_forward = 1

# Tailscale
tailscale status
```

---

## 5. Deploy

After completing all prerequisites:

```bash
# Create external Docker networks
make network

# Start proxy infrastructure (Traefik + socket proxy)
make proxy

# Start all apps
make up
```

Verify at `https://whoami.yourdomain.xyz`

---

## Structure

```
ragnalab/
├── proxy/          # Traefik reverse proxy
├── apps/           # Application stacks
│   └── whoami/     # Test service
├── Makefile        # Service management
└── .planning/      # GSD planning docs (not needed for deployment)
```
