---
status: investigating
trigger: "qBittorrent web UI returns 404 Not Found, likely related to Gluetun VPN container and port-manager sidecar configuration"
created: 2026-01-19T00:00:00Z
updated: 2026-01-19T00:00:00Z
---

## Current Focus

hypothesis: Initial investigation - need to examine gluetun and qbittorrent configuration
test: Read docker-compose and check container status
expecting: Find misconfiguration in networking or port exposure
next_action: Read gluetun docker-compose.yml and check container status

## Symptoms

expected: qBittorrent web UI accessible, all trackers reachable
actual: Browser returns 404 when visiting qBittorrent web UI URL
errors: 404 Not Found
reproduction: Access qBittorrent web UI URL
started: Unknown

## Eliminated

## Evidence

## Resolution

root_cause:
fix:
verification:
files_changed: []
