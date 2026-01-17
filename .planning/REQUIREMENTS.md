# Requirements: RagnaLab

**Defined:** 2026-01-16
**Core Value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Infrastructure Foundation

- [ ] **INFRA-01**: Docker networks created with proper isolation (proxy, socket_proxy_network)
- [ ] **INFRA-02**: Traefik v3.6+ reverse proxy deployed with Docker provider enabled
- [ ] **INFRA-03**: Docker socket proxy (tecnativa/docker-socket-proxy) restricts Traefik API access to read-only
- [ ] **INFRA-04**: Let's Encrypt wildcard certificate obtained via DNS-01 challenge (Cloudflare provider)
- [ ] **INFRA-05**: Traefik bound to Tailscale IP only, unreachable from public internet
- [ ] **INFRA-06**: File provider configured for reusable middleware (security headers, rate limiting)

### DNS & VPN

- [ ] **DNS-01**: Wildcard DNS record `*.ragnalab.xyz` points to Tailscale IP
- [ ] **DNS-02**: Cloudflare API token created with Zone.Zone:Read and Zone.DNS:Edit permissions
- [ ] **VPN-01**: Tailscale subnet router configured for Docker network access
- [ ] **VPN-02**: Tailscale state persisted on named volume for auto-recovery
- [ ] **VPN-03**: Services accessible only via Tailscale, unreachable from public internet

### Service Discovery & Routing

- [ ] **ROUTE-01**: Traefik automatically discovers services via Docker labels
- [ ] **ROUTE-02**: Each service accessible via subdomain (home.ragnalab.xyz, vault.ragnalab.xyz)
- [ ] **ROUTE-03**: All services use HTTPS with valid Let's Encrypt certificates
- [ ] **ROUTE-04**: HTTP automatically redirects to HTTPS
- [ ] **ROUTE-05**: Service routing works end-to-end from Tailscale client through Traefik to container

### Monitoring & Health

- [ ] **MON-01**: Uptime Kuma deployed for service health monitoring
- [ ] **MON-02**: All services have health check endpoints configured
- [ ] **MON-03**: Traefik dashboard accessible for routing inspection
- [ ] **MON-04**: Container resource limits configured to prevent OOM
- [ ] **MON-05**: Active cooling verified, thermal throttling monitored

### Backup & Recovery

- [ ] **BACKUP-01**: Automated backup system deployed (offen/docker-volume-backup)
- [ ] **BACKUP-02**: 3-2-1 backup strategy implemented (3 copies, 2 media, 1 offsite)
- [ ] **BACKUP-03**: Backup schedule configured for all persistent volumes
- [ ] **BACKUP-04**: Backup restore procedure documented and tested
- [ ] **BACKUP-05**: Critical configs (Traefik, compose files) in git with versioning

### Storage & Performance

- [ ] **STORAGE-01**: SSD storage architecture validated (or `/var/lib/docker` on external SSD)
- [ ] **STORAGE-02**: Docker log rotation configured (max-size=10m, max-file=3)
- [ ] **STORAGE-03**: Persistent volumes use named volumes on SSD storage
- [ ] **STORAGE-04**: Tmpfs mounts used for ephemeral data where appropriate

### Security Hardening

- [ ] **SEC-01**: Docker socket never exposed directly, only via socket proxy
- [ ] **SEC-02**: Traefik runs with no-new-privileges security option
- [ ] **SEC-03**: Security headers middleware applied to all services (HSTS, CSP, X-Frame-Options)
- [ ] **SEC-04**: Rate limiting middleware configured to prevent abuse
- [ ] **SEC-05**: Each service on dedicated Docker network, explicit network connections only
- [ ] **SEC-06**: Secrets managed via Docker secrets or environment files (never in compose files)

### Applications

- [ ] **APP-01**: Homepage dashboard deployed at home.ragnalab.xyz with beautiful widgets
- [ ] **APP-02**: Homepage configured with links to all services
- [ ] **APP-03**: Homepage shows service status via API integrations
- [ ] **APP-04**: Vaultwarden password manager deployed at vault.ragnalab.xyz
- [ ] **APP-05**: Vaultwarden persistent data backed up automatically
- [ ] **APP-06**: Vaultwarden admin panel configured securely

### Developer Experience

- [ ] **DX-01**: Modular repository structure (proxy/, apps/*, clear separation)
- [ ] **DX-02**: Template documentation for adding new apps with single compose file
- [ ] **DX-03**: Each app in own directory with dedicated docker-compose.yml
- [ ] **DX-04**: New apps automatically discovered by Traefik via labels
- [ ] **DX-05**: Environment-agnostic configs with .env.example template
- [ ] **DX-06**: README with setup instructions, troubleshooting, and architecture diagrams

### Operational Readiness

- [ ] **OPS-01**: GitOps workflow established (all configs in version control)
- [ ] **OPS-02**: Staging environment for Let's Encrypt validation before production
- [ ] **OPS-03**: All services use ARM64-compatible images verified on Pi 5
- [ ] **OPS-04**: Services start automatically on boot with restart policies
- [ ] **OPS-05**: Deployment playbook documented for disaster recovery

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Advanced Security

- **SEC-ADV-01**: Authentik SSO for unified authentication across services
- **SEC-ADV-02**: Traefik ForwardAuth middleware for SSO integration
- **SEC-ADV-03**: CrowdSec intrusion prevention with Traefik bouncer
- **SEC-ADV-04**: Network segmentation with VLANs (requires managed switch)
- **SEC-ADV-05**: Fail2ban or similar for brute force protection

### Advanced Monitoring

- **MON-ADV-01**: Prometheus metrics collection from all services
- **MON-ADV-02**: Grafana dashboards for infrastructure observability
- **MON-ADV-03**: Alert manager for proactive issue notification
- **MON-ADV-04**: Log aggregation (Loki or similar)

### Additional Applications

- **APP-ADV-01**: Jellyfin or Plex media server
- **APP-ADV-02**: Nextcloud file storage and collaboration
- **APP-ADV-03**: Paperless-ngx document management
- **APP-ADV-04**: Immich photo management
- **APP-ADV-05**: AdGuard Home DNS-level ad blocking
- **APP-ADV-06**: Portainer for Docker GUI management
- **APP-ADV-07**: Ollama for local LLM capabilities

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Public internet exposure | Explicitly designed for VPN-only access; public exposure contradicts core security model |
| Kubernetes (K3s, K8s) | Massive overhead for <20 services; Docker Compose sufficient for homelab scale |
| Multiple reverse proxies | Adds complexity; single Traefik instance handles all routing |
| GUI-only configuration | Breaks GitOps workflow; expert user prefers infrastructure-as-code |
| Individual DNS records per subdomain | Wildcard DNS simplifies management; no benefit to individual records |
| High availability / clustering | Single Pi deployment; complexity not justified for personal homelab |
| 32-bit ARM support | Pi 5 is ARM64; Docker v29+ drops 32-bit support |
| SD card as primary storage | Research shows catastrophic failure rate; SSD required for reliability |
| Production Let's Encrypt without staging validation | Risk of rate limiting; staging environment mandatory first |

## Traceability

Which phases cover which requirements. Updated by create-roadmap.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 1 | ✓ Complete |
| INFRA-02 | Phase 1 | ✓ Complete |
| INFRA-03 | Phase 1 | ✓ Complete |
| INFRA-04 | Phase 1 | ✓ Complete |
| INFRA-05 | Phase 2 | ✓ Complete |
| INFRA-06 | Phase 1 | ✓ Complete |
| DNS-01 | Phase 1 | ✓ Complete |
| DNS-02 | Phase 1 | ✓ Complete |
| VPN-01 | Phase 2 | ✓ Complete |
| VPN-02 | Phase 2 | ✓ Complete |
| VPN-03 | Phase 2 | ✓ Complete |
| ROUTE-01 | Phase 1 | ✓ Complete |
| ROUTE-02 | Phase 2 | ✓ Complete |
| ROUTE-03 | Phase 1 | ✓ Complete |
| ROUTE-04 | Phase 1 | ✓ Complete |
| ROUTE-05 | Phase 2 | ✓ Complete |
| MON-01 | Phase 3 | ✓ Complete |
| MON-02 | Phase 3 | ✓ Complete |
| MON-03 | Phase 3 | ✓ Complete |
| MON-04 | Phase 2 | ✓ Complete |
| MON-05 | Phase 2 | ✓ Complete |
| BACKUP-01 | Phase 3 | ✓ Complete |
| BACKUP-02 | Phase 3 | ✓ Complete |
| BACKUP-03 | Phase 3 | ✓ Complete |
| BACKUP-04 | Phase 3 | ✓ Complete |
| BACKUP-05 | Phase 3 | ✓ Complete |
| STORAGE-01 | Phase 2 | ✓ Complete |
| STORAGE-02 | Phase 1 | ✓ Complete |
| STORAGE-03 | Phase 1 | ✓ Complete |
| STORAGE-04 | Phase 1 | ✓ Complete |
| SEC-01 | Phase 1 | ✓ Complete |
| SEC-02 | Phase 1 | ✓ Complete |
| SEC-03 | Phase 1 | ✓ Complete |
| SEC-04 | Phase 1 | ✓ Complete |
| SEC-05 | Phase 1 | ✓ Complete |
| SEC-06 | Phase 1 | ✓ Complete |
| APP-01 | Phase 4 | ✓ Complete |
| APP-02 | Phase 4 | ✓ Complete |
| APP-03 | Phase 4 | ✓ Complete |
| APP-04 | Phase 4 | ✓ Complete |
| APP-05 | Phase 4 | ✓ Complete |
| APP-06 | Phase 4 | ✓ Complete |
| DX-01 | Phase 4 | ✓ Complete |
| DX-02 | Phase 4 | ✓ Complete |
| DX-03 | Phase 4 | ✓ Complete |
| DX-04 | Phase 4 | ✓ Complete |
| DX-05 | Phase 4 | ✓ Complete |
| DX-06 | Phase 4 | ✓ Complete |
| OPS-01 | Phase 3 | ✓ Complete |
| OPS-02 | Phase 1 | ✓ Complete |
| OPS-03 | Phase 2 | ✓ Complete |
| OPS-04 | Phase 2 | ✓ Complete |
| OPS-05 | Phase 3 | ✓ Complete |

**Coverage:**
- v1 requirements: 47 total
- Mapped to phases: 47
- Unmapped: 0

---
*Requirements defined: 2026-01-16*
*Last updated: 2026-01-16 after roadmap creation*
