# Pi-hole Installation

Network-wide DNS-based ad blocking.

**URL:** https://pihole.ragnalab.xyz
**DNS IP:** 10.0.0.200

---

## Prerequisites

- Traefik running (see [proxy/INSTALL.md](../../proxy/INSTALL.md))
- Network interface: `eth0` (adjust if using WiFi)

---

## Installation

### 1. Install Macvlan Service

Pi-hole needs its own LAN IP via macvlan network. This requires a host service.

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

### 2. Configure Environment

```bash
cp apps/pihole/.env.example apps/pihole/.env
nano apps/pihole/.env
```

Set your password:
```
PIHOLE_PASSWORD=your-secure-password
PIHOLE_API_KEY=your-secure-password
```

### 3. Deploy

```bash
docker compose -f apps/pihole/docker-compose.yml up -d
```

### 4. Verify

```bash
# Check DNS resolution
dig @10.0.0.200 google.com +short

# Check ad blocking (should return 0.0.0.0)
dig @10.0.0.200 doubleclick.net +short

# Check web UI
curl -I https://pihole.ragnalab.xyz
```

---

## Manual Steps

### Configure Devices to Use Pi-hole

Pi-hole runs in **DNS-only mode** (Xfinity gateway doesn't allow disabling DHCP).

Configure each device manually:

**iPhone/iPad:**
Settings → Wi-Fi → (your network) → Configure DNS → Manual → 10.0.0.200

**Mac:**
System Settings → Network → Wi-Fi → Details → DNS → 10.0.0.200

**Windows:**
Network settings → Change adapter options → IPv4 Properties → DNS: 10.0.0.200

**Android:**
Settings → Network → Wi-Fi → (your network) → IP settings → Static → DNS: 10.0.0.200

### Add Blocklists (Optional)

1. Open https://pihole.ragnalab.xyz/admin
2. Go to Adlists
3. Add popular lists:
   - `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`
   - `https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt`

---

## Architecture

```
Device → Pi-hole (10.0.0.200) → Upstream DNS (Cloudflare/Google)
              ↓
         Ad blocked (0.0.0.0)
```

Pi-hole uses macvlan to get its own IP on your LAN, separate from the Pi's IP.

The macvlan-shim (10.0.0.201) allows the Pi host to communicate with Pi-hole.

---

## Files

| File | Purpose |
|------|---------|
| `apps/pihole/docker-compose.yml` | Container configuration |
| `apps/pihole/.env` | Web UI password |
| `apps/pihole/etc-pihole/` | Pi-hole configuration |
| `apps/pihole/etc-dnsmasq.d/` | DNS configuration |

---

## Troubleshooting

### Can't reach Pi-hole from host

Check macvlan-shim service:
```bash
sudo systemctl status pihole-macvlan.service
ip addr show macvlan-shim
```

### DNS not working

```bash
# Check Pi-hole container
docker logs pihole

# Test from another device (not the Pi)
dig @10.0.0.200 google.com
```

### Ads still showing

1. Clear browser cache
2. Verify device DNS is set to 10.0.0.200
3. Some ads use HTTPS/encrypted DNS that bypass Pi-hole
