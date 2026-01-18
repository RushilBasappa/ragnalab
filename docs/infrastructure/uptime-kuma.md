# Uptime Kuma Installation

Service health monitoring dashboard with alerts.

**URL:** https://status.ragnalab.xyz

---

## Prerequisites

- Traefik running (see [Traefik](traefik.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/uptime-kuma/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://status.ragnalab.xyz
```

---

## Manual Setup Required

Uptime Kuma requires one-time browser configuration.

### Initial Setup

1. Open https://status.ragnalab.xyz
2. Select **SQLite** as database
3. Create admin account (save credentials securely!)

### Add Docker Host

1. Go to **Settings → Docker Hosts → Add**
2. Name: `Local Docker`
3. Connection Type: `Socket`
4. Docker Socket Path: `/var/run/docker.sock`
5. Save

### Add Monitors

**HTTP(s) Monitors** (Interval: 60s):

| Name | URL |
|------|-----|
| Traefik Dashboard | https://traefik.ragnalab.xyz |
| Homepage | https://home.ragnalab.xyz |
| Vaultwarden | https://vault.ragnalab.xyz |
| Pi-hole Web UI | https://pihole.ragnalab.xyz |
| Documentation | https://docs.ragnalab.xyz |

**Docker Container Monitors** (Docker Host: Local Docker):

| Name | Container |
|------|-----------|
| traefik | traefik |
| socket-proxy | socket-proxy |
| uptime-kuma | uptime-kuma |
| backup | backup |
| pihole | pihole |
| docs | docs |

### Create Status Page

1. Go to **Status Pages** in sidebar
2. Click **New Status Page**
3. Name: `RagnaLab Status`
4. Slug: `status-page` (required for Homepage widget)
5. Add monitors to the page
6. Save

### Create Backup Push Monitor

1. Add New Monitor
2. Type: **Push**
3. Name: `Daily Backup`
4. Heartbeat Interval: `86400` (1 day in seconds)
5. Save and **copy the Push URL**

Use this URL in [Backup Setup](backup.md).

---

## Files

| File | Purpose |
|------|---------|
| `apps/uptime-kuma/docker-compose.yml` | Container configuration |
| Volume: `uptime-kuma` | Database and settings |

---

## Troubleshooting

### Can't connect to Docker

Verify socket-proxy is running:
```bash
docker ps | grep socket-proxy
```

### Monitors showing down incorrectly

Check container names match exactly (case-sensitive).
