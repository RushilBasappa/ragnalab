# Prerequisites

What you need before starting RagnaLab installation.

---

## Hardware

| Component | Requirement | Notes |
|-----------|-------------|-------|
| Raspberry Pi | Pi 5 (4GB+ RAM) | Pi 4 works but slower |
| Storage | SSD | SD cards fail with Docker |
| Cooling | Active (fan/heatsink) | Required for sustained load |
| Network | Ethernet | WiFi works but less reliable |

---

## Accounts

Create these accounts before starting:

| Service | Purpose | Sign Up |
|---------|---------|---------|
| **Cloudflare** | DNS management, SSL certificates | [cloudflare.com](https://cloudflare.com) |
| **Tailscale** | VPN access to services | [tailscale.com](https://tailscale.com) |
| **VPN Provider** | Torrent privacy (optional) | [protonvpn.com](https://protonvpn.com) |

---

## Domain Name

You need a domain name (e.g., `ragnalab.xyz`).

**Options:**
- Purchase from Namecheap, Cloudflare, Google Domains, etc.
- Use a free domain from Freenom (less reliable)

The domain will be added to Cloudflare for DNS management.

---

## Network Requirements

| Requirement | Why |
|-------------|-----|
| Static LAN IP for Pi | Or DHCP reservation |
| Router access | To set DHCP reservation (optional) |
| Port 443 outbound | For Let's Encrypt validation |

**Note:** No inbound ports needed — all access is via Tailscale VPN.

---

## Next Step

→ [Cloudflare Setup](cloudflare.md)
