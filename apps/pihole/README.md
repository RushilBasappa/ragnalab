# Pi-hole Network-Wide DNS Ad Blocking

Pi-hole provides network-wide DNS-based ad blocking by acting as a DNS sinkhole.

## Architecture

Pi-hole uses **macvlan networking** to get its own LAN IP address (10.0.0.200), enabling DHCP capability without port conflicts with Traefik on the host.

```
LAN Network (10.0.0.0/24)
       |
+------+------+
|  10.0.0.200 |  <-- Pi-hole (macvlan)
+------+------+
       |
+------+------+
|  10.0.0.201 |  <-- macvlan-shim (host routing)
+------+------+
       |
   Raspberry Pi (10.0.0.245)
```

## System-Level Configuration

The following files are installed at the system level (not in git):

### /usr/local/bin/pihole-macvlan.sh

Script to create/destroy macvlan-shim interface for host-to-container communication:

```bash
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
```

### /etc/systemd/system/pihole-macvlan.service

Systemd service to persist macvlan-shim across reboots:

```ini
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
```

## Setup

1. Copy `.env.example` to `.env` and set passwords:
   ```bash
   cp .env.example .env
   # Edit .env with your PIHOLE_PASSWORD
   ```

2. Ensure macvlan-shim service is running:
   ```bash
   sudo systemctl status pihole-macvlan.service
   ```

3. Start Pi-hole:
   ```bash
   docker compose up -d
   ```

4. Access web UI at https://pihole.ragnalab.xyz

## Verification

```bash
# Check DNS resolution from host
dig @10.0.0.200 google.com +short

# Check ad blocking
dig @10.0.0.200 doubleclick.net +short
# Should return 0.0.0.0

# Check macvlan-shim
ip link show macvlan-shim
ip route | grep 10.0.0.200
```

## Uptime Kuma Monitors

Create these monitors in Uptime Kuma (https://status.ragnalab.xyz):

### Pi-hole Web UI
- **Type:** HTTP(s)
- **URL:** `http://pihole:80/admin`
- **Heartbeat Interval:** 60 seconds
- **Retries:** 3

### Pi-hole DNS
- **Type:** DNS
- **Hostname:** `google.com`
- **Resolver Server:** `10.0.0.200`
- **Port:** 53
- **Record Type:** A
- **Heartbeat Interval:** 60 seconds
- **Retries:** 2

## API Key for Homepage Widget

After Pi-hole is running, get the API key:
1. Log into Pi-hole web UI
2. Settings > API > Show API Token
3. Add to `.env` as `PIHOLE_API_KEY`
