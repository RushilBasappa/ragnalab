---
status: resolved
trigger: "Fix the Gluetun + ProtonVPN + qBittorrent integration"
created: 2026-01-19T15:35:00-08:00
updated: 2026-01-19T15:50:00-08:00
---

## Resolution Summary

**Root Cause:** qBittorrent 5.x doesn't properly resolve interface names (like "tun0") to IP addresses for binding. The API setting `current_network_interface=tun0` was accepted but qBittorrent failed to bind, resulting in:
- connection_status: "disconnected"
- dht_nodes: 0
- UDP trackers failing with "Operation not permitted"

**Fix Applied:** Changed the `VPN_PORT_FORWARDING_UP_COMMAND` to:
1. Dynamically get the tun0 IP address using BusyBox-compatible commands
2. Set `current_interface_address` instead of `current_network_interface`

**Verification Results:**
- connection_status: "connected"
- dht_nodes: 188
- dl_info_speed: 46.7 MB/s
- total_peer_connections: 132
- Both test torrents downloading successfully

## Root Cause Analysis

**The Problem:** qBittorrent's `current_network_interface` setting accepts interface name "tun0", but qBittorrent 5.x doesn't properly resolve the interface name to an IP address for binding. When set to "tun0", qBittorrent silently fails to bind (no "Successfully listening" log entries appear).

**Why It Happened:** The original configuration used:
```
"current_network_interface":"tun0"
```

qBittorrent received this setting but couldn't map "tun0" to its IP address (10.2.0.2), so it didn't bind to the VPN interface at all. This meant:
1. No torrent traffic could flow through the VPN tunnel
2. DHT bootstrap nodes couldn't be reached
3. UDP tracker announces failed

**The Fix:** Use `current_interface_address` with the actual IP address:
```
"current_network_interface":"","current_interface_address":"10.2.0.2"
```

## Evidence

### qBittorrent Log - Before Fix (Failure)
```
(N) 2026-01-19T15:38:16 - Trying to listen on the following list of IP addresses: "tun0:58841"
# NO "Successfully listening" messages follow - binding failed silently
```

### qBittorrent Log - After Fix (Success)
```
(N) 2026-01-19T15:44:03 - Trying to listen on the following list of IP addresses: "10.2.0.2:58841"
(I) 2026-01-19T15:44:03 - Successfully listening on IP. IP: "10.2.0.2". Port: "TCP/58841"
(I) 2026-01-19T15:44:03 - Successfully listening on IP. IP: "10.2.0.2". Port: "UTP/58841"
(I) 2026-01-19T15:44:04 - Detected external IP. IP: "205.147.16.235"
```

### Status Comparison

| Metric | Before | After |
|--------|--------|-------|
| connection_status | disconnected | connected |
| dht_nodes | 0 | 188 |
| dl_info_speed | 0 | 46.7 MB/s |
| total_peer_connections | 0 | 132 |
| UDP socket on forwarded port | No | Yes (10.2.0.2:58841) |

## Files Changed

### `/home/rushil/workspace/ragnalab/stack/media/gluetun/docker-compose.yml`

**Old (broken):**
```yaml
- VPN_PORT_FORWARDING_UP_COMMAND=/bin/sh -c 'for i in 1 2 3 4 5 6 7 8 9 10; do wget -qO- --post-data "json={\"listen_port\":{{PORT}},\"current_network_interface\":\"tun0\"}" "http://127.0.0.1:8080/api/v2/app/setPreferences" && exit 0; sleep 5; done; exit 1'
```

**New (working):**
```yaml
- VPN_PORT_FORWARDING_UP_COMMAND=/bin/sh -c 'TUN_IP=$$(ip -4 addr show tun0 | grep -o "inet [0-9.]*" | cut -d" " -f2); for i in 1 2 3 4 5 6 7 8 9 10; do wget -qO- --post-data "json={\"listen_port\":{{PORT}},\"current_network_interface\":\"\",\"current_interface_address\":\"$$TUN_IP\"}" "http://127.0.0.1:8080/api/v2/app/setPreferences" && exit 0; sleep 5; done; exit 1'
```

**Key Changes:**
1. Added `TUN_IP=$$(ip -4 addr show tun0 | grep -o "inet [0-9.]*" | cut -d" " -f2)` to get tun0 IP dynamically
2. Changed `"current_network_interface":"tun0"` to `"current_network_interface":"","current_interface_address":"$$TUN_IP"`
3. Used BusyBox-compatible grep (`grep -o` instead of `grep -oP`) since gluetun uses Alpine/BusyBox

## Additional Notes

### Why BusyBox-compatible commands?
Gluetun uses Alpine Linux with BusyBox, which doesn't support:
- `grep -P` (Perl regex)
- `grep -oP` with lookahead patterns

The fix uses basic POSIX-compatible grep and cut instead.

### Port Forwarding Flow
1. Gluetun starts and establishes WireGuard VPN tunnel
2. ProtonVPN NAT-PMP assigns forwarded port (e.g., 58841)
3. Gluetun's port forwarding callback executes `VPN_PORT_FORWARDING_UP_COMMAND`
4. Command extracts tun0 IP and calls qBittorrent API to set port + interface
5. qBittorrent re-binds to the VPN IP on the forwarded port
6. DHT bootstrap and tracker announces now work through VPN
