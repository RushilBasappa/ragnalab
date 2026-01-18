# Gluetun VPN Installation

WireGuard VPN tunnel for torrent privacy. All qBittorrent traffic routes through this container.

---

## Prerequisites

- VPN account with WireGuard support (ProtonVPN, Mullvad, NordVPN, etc.)
- Media stack `.env` configured

---

## Installation

### 1. Configure VPN Credentials

Edit `apps/media/.env`:

**For ProtonVPN:**
```
VPN_SERVICE_PROVIDER=protonvpn
WIREGUARD_PRIVATE_KEY=your-private-key
WIREGUARD_ADDRESSES=10.2.0.2/32
SERVER_COUNTRIES=United States
```

**Get ProtonVPN credentials:**
1. Go to https://account.protonvpn.com/downloads
2. Click "WireGuard configuration"
3. Select server location
4. Copy private key and address

**For other providers:** See https://github.com/qdm12/gluetun-wiki/tree/main/setup/providers

### 2. Deploy

```bash
docker compose -f apps/media/gluetun/docker-compose.yml up -d
```

### 3. Verify

```bash
# Check health status
docker inspect gluetun --format='{{.State.Health.Status}}'
# Should show: healthy

# Check VPN IP
docker exec gluetun wget -qO- ifconfig.me
# Should show VPN IP, not your home IP

# Check your home IP for comparison
curl -s ifconfig.me
```

---

## Manual Steps

**None** - Gluetun is fully automated once credentials are configured.

---

## How It Works

Gluetun creates a WireGuard VPN tunnel. Other containers (qBittorrent) use `network_mode: container:gluetun` to route all their traffic through this tunnel.

```
qBittorrent → Gluetun → VPN Server → Internet
                ↓
        Your real IP hidden
```

---

## Port Forwarding

qBittorrent WebUI is exposed through Gluetun on port 8080:
- Access: `http://localhost:8080` or `http://<pi-ip>:8080`

---

## Files

| File | Purpose |
|------|---------|
| `apps/media/gluetun/docker-compose.yml` | Container configuration |
| `apps/media/.env` | VPN credentials |

---

## Troubleshooting

### Container unhealthy

```bash
docker logs gluetun
```

Common issues:
- Invalid WireGuard key format
- Wrong provider name
- Server unavailable

### VPN keeps disconnecting

Check if provider limits connections. Some VPN plans have device limits.

### Can't reach port 8080

Gluetun must be healthy first. Check: `docker inspect gluetun --format='{{.State.Health.Status}}'`
