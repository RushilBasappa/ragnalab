# App Template for RagnaLab

Use this template to deploy new applications with automatic Traefik routing and Homepage integration.

## Quick Start

1. **Copy the template:**
   ```bash
   cp -r apps/_template apps/myapp
   ```

2. **Edit docker-compose.yml:**
   - Replace all `TODO` items
   - Set your image, subdomain, port, and descriptions

3. **Find an icon:**
   - Browse: https://github.com/walkxcode/dashboard-icons
   - Use the icon filename (e.g., `nextcloud.png`)

4. **Deploy:**
   ```bash
   docker compose -f apps/myapp/docker-compose.yml up -d
   ```

5. **Verify:**
   - Traefik dashboard shows route: https://traefik.ragnalab.xyz
   - Homepage shows service: https://home.ragnalab.xyz
   - HTTPS works: https://myapp.ragnalab.xyz

## Deployment Checklist

Before considering your app deployed, verify:

- [ ] Subdomain chosen and unique (not used by another app)
- [ ] Port matches the service's actual listening port
- [ ] Homepage group set (`Infrastructure`, `Apps`, or new category)
- [ ] Homepage name and description filled in
- [ ] Icon found (or use default generic icon)
- [ ] Traefik dashboard shows healthy route (green)
- [ ] Homepage shows the service with correct link
- [ ] HTTPS works with valid certificate
- [ ] Uptime Kuma monitor created (if critical service)
- [ ] Backup label added (if persistent data in volume)

## Common Ports

| Application | Default Port |
|-------------|-------------|
| Web apps (generic) | 8080 |
| Node.js | 3000 |
| Python (Flask/Django) | 5000 |
| Grafana | 3000 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| MinIO | 9000 |

## Tips

- **Container name:** Use the same name for service, container, and router for consistency
- **Memory limits:** Start with 256M, adjust based on actual usage
- **Volumes:** Only add if the app needs to persist data across restarts
- **Backup label:** Always add if you have volumes with important data
- **Widget support:** Some apps support Homepage widgets (see Homepage docs)
