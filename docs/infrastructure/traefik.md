# Traefik Reverse Proxy Installation

Traefik provides HTTPS routing with automatic Let's Encrypt certificates for all services.

**URL:** https://traefik.ragnalab.xyz

---

## Prerequisites

- Cloudflare API token (see [Cloudflare Setup](../getting-started/cloudflare.md))
- Docker networks created

---

## Installation

### 1. Create Docker Networks

```bash
docker network create proxy
docker network create socket_proxy_network
```

Or use:
```bash
make networks
```

### 2. Configure Environment

```bash
cp proxy/.env.example proxy/.env
nano proxy/.env
```

Fill in:
```
CF_API_EMAIL=your-cloudflare-email@example.com
CF_DNS_API_TOKEN=your-cloudflare-api-token
ACME_EMAIL=your-email-for-letsencrypt@example.com
DOMAIN=ragnalab.xyz
```

### 3. Deploy

```bash
docker compose -f proxy/docker-compose.yml up -d
```

### 4. Verify

```bash
# Check containers are running
docker ps | grep -E "traefik|socket-proxy"

# Check HTTPS is working (wait 1-2 min for certificates)
curl -I https://traefik.ragnalab.xyz

# Check logs if issues
docker logs traefik
```

---

## Manual Steps

**None** - Traefik is fully automated once environment is configured.

---

## Architecture

```
Internet → Cloudflare DNS → Tailscale → Traefik → Services
                                           ↓
                                    Socket Proxy (read-only Docker API)
```

- **Traefik** - Reverse proxy, SSL termination, routing
- **Socket Proxy** - Protects Docker socket (read-only access)

---

## Files

| File | Purpose |
|------|---------|
| `proxy/docker-compose.yml` | Traefik + Socket Proxy containers |
| `proxy/.env` | Cloudflare credentials |
| `proxy/traefik/traefik.yml` | Static configuration |
| `proxy/traefik/dynamic/` | Dynamic configuration (middleware) |

---

## Troubleshooting

### Certificate errors

1. Check DNS is "DNS only" (gray cloud) in Cloudflare
2. Verify API token has correct permissions
3. Check logs: `docker logs traefik`

### 404 errors

Service may not be connected to `proxy` network:
```bash
docker network inspect proxy
```

### Dashboard not loading

Check Traefik is healthy:
```bash
docker inspect traefik --format='{{.State.Health.Status}}'
```
