# Homepage Dashboard Installation

Service dashboard with auto-discovery via Docker labels.

**URL:** https://home.ragnalab.xyz

---

## Prerequisites

- Traefik running (see [Traefik](../infrastructure/traefik.md))
- Uptime Kuma running with status page created (see [Uptime Kuma](../infrastructure/uptime-kuma.md))

---

## Installation

### 1. Deploy

```bash
docker compose -f apps/homepage/docker-compose.yml up -d
```

### 2. Verify

```bash
curl -I https://home.ragnalab.xyz
```

Open https://home.ragnalab.xyz in browser.

---

## Manual Steps

**None** - Homepage auto-discovers services via Docker labels.

Services appear automatically when they have `homepage.*` labels in their docker-compose.yml.

---

## How Auto-Discovery Works

Any container with these labels appears in Homepage:

```yaml
labels:
  - "homepage.group=Applications"
  - "homepage.name=My App"
  - "homepage.icon=myapp.png"
  - "homepage.href=https://myapp.ragnalab.xyz"
  - "homepage.description=What it does"
```

### Widget Support

Some services support widgets showing live stats:

```yaml
labels:
  - "homepage.widget.type=sonarr"
  - "homepage.widget.url=http://sonarr:8989"
  - "homepage.widget.key={{HOMEPAGE_VAR_SONARR_API_KEY}}"
```

API keys are loaded from `apps/homepage/config/homepage.env`.

---

## Configuration Files

| File | Purpose |
|------|---------|
| `apps/homepage/docker-compose.yml` | Container configuration |
| `apps/homepage/config/settings.yaml` | Layout and groups |
| `apps/homepage/config/bookmarks.yaml` | External links |
| `apps/homepage/config/services.yaml` | Manual service entries |
| `apps/homepage/config/widgets.yaml` | Dashboard widgets |
| `apps/homepage/config/homepage.env` | API keys for widgets |

### Adding Groups

Edit `apps/homepage/config/settings.yaml`:

```yaml
layout:
  Infrastructure:
    style: row
    columns: 3
  Applications:
    style: row
    columns: 3
  Media:
    style: row
    columns: 4
```

---

## Troubleshooting

### Service not appearing

1. Check container has `homepage.*` labels
2. Verify container is on `proxy` network
3. Restart Homepage: `docker restart homepage`

### Widget showing error

1. Verify API key in `homepage.env`
2. Check service is reachable from Homepage container
3. Test: `docker exec homepage wget -qO- http://service:port/api/...`
