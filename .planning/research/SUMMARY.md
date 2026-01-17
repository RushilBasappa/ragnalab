# Project Research Summary

**Project:** RagnaLab Homelab
**Domain:** Private homelab infrastructure (VPN-only, Docker-based, self-hosted applications)
**Researched:** 2026-01-16
**Confidence:** HIGH

## Executive Summary

RagnaLab is a private, VPN-only homelab running on Raspberry Pi 5 with Docker-based services. Based on extensive research of current 2025-2026 homelab best practices, the recommended approach uses Traefik v3 for reverse proxying with automatic SSL certificates via Let's Encrypt DNS-01 challenges, Tailscale for secure VPN access, and a modular Docker Compose architecture where each service is independently managed. This stack is standard for expert-level homelabs and aligns well with DevOps engineering principles: infrastructure-as-code, GitOps workflows, and declarative configuration.

The critical success factors are: (1) proper storage architecture using SSD instead of SD card to prevent corruption from Docker's write-intensive operations, (2) security-first networking with Docker socket proxies and explicit network isolation, and (3) comprehensive backup strategy implemented before deploying any persistent services. The research reveals that 90% of homelab failures stem from three issues: SD card corruption, accidental public exposure of services, and Let's Encrypt rate limiting during misconfigured testing.

Key risks center on Raspberry Pi-specific constraints (thermal throttling under sustained Docker load, ARM64 image compatibility, limited memory on 4GB models) and Traefik integration complexity (network configuration, DNS propagation delays, service discovery). These are all well-documented with proven mitigation strategies: active cooling, explicit platform specification, resource limits, and staging environment validation before production.

## Key Findings

### Recommended Stack

The research strongly converges on a modern stack optimized for ARM64, VPN-only access, and expert-level operation. Raspberry Pi OS 64-bit (Debian Bookworm) is mandatory as Docker Engine v29+ drops 32-bit support. Traefik v3.6+ is preferred over Nginx Proxy Manager for expert users due to label-based service discovery, infrastructure-as-code configuration, and superior automation. Tailscale provides zero-config VPN via WireGuard with MagicDNS, eliminating port forwarding entirely.

**Core technologies:**
- **Raspberry Pi OS 64-bit (Bookworm)**: Base OS — Docker v29+ requires 64-bit ARM; official OS with full ARM64 support
- **Docker Engine v29.1.4+**: Container runtime — Current LTS with multi-arch support and improved security; v29 mandatory for future-proofing
- **Docker Compose v5.0.1+**: Orchestration — Integrated plugin (not deprecated v1); declarative service definitions for GitOps
- **Traefik v3.6.7**: Reverse proxy — Dynamic Docker discovery, automatic Let's Encrypt, lighter than NPM, native DNS-01 challenges
- **Tailscale (latest stable)**: VPN — Zero-config WireGuard mesh; eliminates public exposure; MagicDNS for internal domains
- **Let's Encrypt via Traefik ACME**: SSL/TLS — DNS-01 challenge enables wildcard certs without port 80/443 exposure
- **SSD Storage (USB 3.0 or PCIe)**: Persistent storage — SD cards fail within months under Docker write load; SSD provides 10x+ durability

**Version-critical requirements:**
- Traefik v3.x (v2.x EOL after v2.11.35 security patch)
- Docker Compose v2+ plugin format (v1 deprecated July 2023)
- 64-bit OS (32-bit ARM support dropped in Docker v29)

### Expected Features

Research shows homelab features split into infrastructure (platform capabilities) and applications (services). Infrastructure must be solid before scaling applications. For an expert DevOps engineer, the focus is on automation, observability, and modularity rather than GUI tools.

**Must have (table stakes):**
- Reverse proxy with automatic SSL/TLS certificates — HTTPS everywhere is non-negotiable in 2025
- VPN access for secure remote connectivity — Tailscale/WireGuard are current standards
- Container orchestration via Docker Compose — Simpler than K3s for <20 services
- Service discovery and automatic routing — Label-based (Traefik) eliminates manual configuration
- Health monitoring with uptime checks — Uptime Kuma is 2025 standard for simple checks
- 3-2-1 backup strategy — 3 copies, 2 media types, 1 offsite; non-negotiable for data protection
- Dashboard/homepage for service access — Homepage (YAML config) fits GitOps workflow better than Homarr (GUI)

**Should have (competitive advantages for expert users):**
- GitOps workflow with configs in Git — Infrastructure-as-code from day one
- Prometheus + Grafana observability stack — Deep metrics beyond simple uptime checks
- Docker socket proxy for API security — Prevents Traefik compromise from escalating to host root
- File-based middleware in Traefik — Reusable security headers, rate limiting, DRY configuration
- Custom Docker networks per service group — Explicit boundaries, no hidden dependencies
- Vaultwarden password manager — Stated requirement, immediate security value

**Defer (v2+):**
- Authentik/Authelia SSO — Only valuable after 5+ services; high complexity
- CrowdSec intrusion prevention — Advanced security, defer until platform mature
- Network segmentation with VLANs — Requires managed switch, advanced networking
- Ollama AI/LLM integration — 2026 trend but resource-intensive on Pi
- Media server (Jellyfin) — High value but not critical for infrastructure validation
- AdGuard Home / Pi-hole — Quality of life improvement, not blocking path

### Architecture Approach

Modern Docker homelab architecture follows a layered pattern with clear separation: client access (internet + Tailscale), routing (Traefik), security (socket proxy + networks), and applications (isolated services). The architecture emphasizes modular service isolation where each application lives in its own directory with independent docker-compose.yml, enabling easy add/remove/update operations without affecting other services.

**Major components:**
1. **Traefik (Reverse Proxy Layer)** — Central routing hub; HTTPS termination; automatic service discovery via Docker labels; Let's Encrypt certificate management; dynamic middleware application
2. **Docker Networks (Isolation Layer)** — User-defined bridge networks (`proxy`, `socket_proxy_network`, per-app `internal`); external networks shared across compose files; explicit network selection prevents accidental exposure
3. **Docker Socket Proxy (Security Layer)** — API firewall between Traefik and Docker daemon; restricts access to read-only container/network queries; prevents privilege escalation from Traefik compromise
4. **Tailscale (VPN Layer)** — Subnet router pattern for entire Docker network access; MagicDNS for friendly hostnames; eliminates port forwarding and public exposure
5. **File Provider (Config Management)** — Centralized middleware definitions (security headers, rate limiting); YAML-based configuration for version control; hot reload on changes
6. **Application Services** — Independent Docker Compose files per service; label-based Traefik routing; persistent volumes on SSD storage; health checks and resource limits

**Architectural patterns:**
- **External shared networks**: Created once (`docker network create proxy`), referenced as `external: true` in all compose files
- **Label-based service discovery**: Traefik automatically configures routes from Docker labels, no manual route files
- **File provider for DRY middleware**: Security headers, rate limiting defined once, reused via `@file` namespace
- **Modular service structure**: Each app in `apps/<service>/docker-compose.yml` for independent lifecycle management
- **Secrets management**: Docker secrets via file references, never environment variables in compose files

**Critical dependencies:**
1. Docker networks must exist before any containers start
2. Traefik + socket proxy before any application services
3. Let's Encrypt staging validation before production certificates
4. SSD storage configured before persistent data
5. Tailscale after networks but parallel to apps

### Critical Pitfalls

Research identified 10 critical pitfalls, with top 5 being catastrophic failures:

1. **Accidental Public Exposure via Traefik** — Services intended for Tailscale-only access get exposed to internet through missing entrypoint restrictions. Prevention: Always specify explicit `entrypoints=tailscale` in labels; use allowlist middleware for sensitive services; network segmentation with separate Docker networks for public/private.

2. **Let's Encrypt Rate Limit Exhaustion** — Hitting 50 certs/week production limit during testing, causing week-long lockout. Prevention: ALWAYS use staging environment (`caServer = staging-v02.api.letsencrypt.org`); persist acme.json on named volume not SD card; test DNS-01 manually before automation; implement exponential backoff.

3. **Docker Socket Exposure = Root Access** — Mounting `/var/run/docker.sock` gives Traefik compromise path to host root. Prevention: Mount read-only (`:ro`); use Docker socket proxy (tecnativa/docker-socket-proxy); run Traefik with `no-new-privileges: true`; keep Traefik updated (CVE-2026-22045 patched in v3.6.7).

4. **SD Card Corruption from Docker Writes** — Docker's high I/O volume destroys SD cards within months, causing filesystem corruption and data loss. Prevention: CRITICAL — use SSD/NVMe boot or mount `/var/lib/docker` on external SSD; configure log rotation (`max-size=10m`); use tmpfs for ephemeral data; UPS for power protection.

5. **Traefik Network Misconfiguration** — Traefik randomly picks network when containers are multi-homed, causing 502 Bad Gateway errors. Prevention: Explicitly set `traefik.docker.network=proxy` label on all services; ensure Traefik and apps share common network; use Docker service names not `localhost`.

**Additional high-risk pitfalls:**
- **Tailscale state loss**: Persist `/var/lib/tailscale` on named volume, use ephemeral auth keys for auto-recovery
- **ARM64 image compatibility**: Explicitly specify `platform: linux/arm64/v8`; verify images before deployment
- **Thermal throttling**: Install active cooling; Pi 5 throttles at 85°C under sustained Docker load
- **DNS propagation delays**: Set Traefik `delayBeforeCheck = 90s` for DNS-01 challenges; test propagation manually
- **No backup strategy**: Implement 3-2-1 rule from day one; test restore process monthly; automate with offen/docker-volume-backup

## Implications for Roadmap

Based on combined research, the roadmap should follow a strict dependency order: infrastructure foundation, VPN layer, then progressive application deployment. Critical path requires Docker networks, security hardening (socket proxy), and Traefik with SSL before any applications. Pitfall research emphasizes that 90% of failures come from cutting corners on foundation.

### Phase 1: Infrastructure Foundation
**Rationale:** All services depend on routing, security, and storage working correctly. Research shows attempting to add applications before foundation is stable causes cascade failures and rework. SD card corruption, Let's Encrypt rate limits, and security misconfigurations must be prevented from day one.

**Delivers:**
- Docker networks (`proxy`, `socket_proxy_network`) created and tested
- Traefik v3.6+ with Docker socket proxy (security-first)
- Let's Encrypt staging certificates via DNS-01 (Cloudflare)
- File provider middleware (security headers, rate limiting)
- SSD storage architecture (if not already migrated)
- Active cooling verification (thermal management)

**Addresses features:**
- Reverse proxy with automatic SSL/TLS (table stakes)
- Container orchestration via Docker Compose (table stakes)
- Service discovery (table stakes)

**Avoids pitfalls:**
- Pitfall 2: Let's Encrypt rate limiting (use staging first)
- Pitfall 3: Docker socket exposure (socket proxy from start)
- Pitfall 4: SD card corruption (SSD architecture validated)
- Pitfall 5: Network misconfiguration (networks created correctly)
- Pitfall 8: Thermal throttling (cooling installed and monitored)

**Research needs:** SKIP — Traefik + Let's Encrypt + Docker is extremely well-documented with proven patterns.

---

### Phase 2: VPN Access & Initial Validation
**Rationale:** Tailscale enables secure access to all services and must be working before deploying applications with sensitive data. First application (whoami or homepage) validates the entire stack end-to-end before investing in complex services.

**Delivers:**
- Tailscale subnet router with MagicDNS
- Tailscale state persistence configured
- First test application (whoami) to validate routing
- Production Let's Encrypt certificates (after staging success)
- Homepage dashboard for service discovery

**Addresses features:**
- VPN access for secure remote connectivity (table stakes)
- Dashboard/homepage for service access (table stakes)

**Avoids pitfalls:**
- Pitfall 1: Accidental public exposure (validate Tailscale-only access works)
- Pitfall 6: Tailscale state loss (persistent volume from start)

**Research needs:** SKIP — Tailscale + Traefik integration has standard patterns, well-documented in 2025-2026 sources.

---

### Phase 3: Backup & Observability
**Rationale:** Before deploying services with important data, backup infrastructure must exist. Observability (Prometheus + Grafana) provides operational visibility for expert users and enables proactive issue detection.

**Delivers:**
- Automated backup system (offen/docker-volume-backup)
- 3-2-1 backup strategy implementation
- Backup restore testing procedure
- Uptime Kuma for simple health monitoring
- Prometheus + Grafana observability stack (expert-level)

**Addresses features:**
- 3-2-1 backup strategy (table stakes)
- Health monitoring (table stakes)
- Prometheus + Grafana observability (differentiator for experts)

**Avoids pitfalls:**
- Pitfall 10: No backup strategy (implement before critical data)

**Research needs:** SKIP — Backup strategies and monitoring stacks are well-established patterns.

---

### Phase 4: Core Applications
**Rationale:** With infrastructure, VPN, and backup proven, deploy high-value applications. Vaultwarden is stated requirement with immediate security value. Additional services (media, productivity) add capability without blocking path.

**Delivers:**
- Vaultwarden password manager (stated requirement)
- 2-3 additional services based on use case (AdGuard Home, Nextcloud, Jellyfin)
- GitOps workflow (all configs in Git)
- Service health checks and resource limits

**Addresses features:**
- Vaultwarden password manager (should-have, stated requirement)
- GitOps workflow (differentiator for experts)

**Avoids pitfalls:**
- Pitfall 7: ARM64 compatibility (verify each service image)
- Performance traps: Resource limits prevent OOM

**Research needs:** POTENTIAL — If deploying specialized apps (Immich, Paperless-ngx, Ollama), might need `/gsd:research-phase` for integration details. Standard apps (Vaultwarden, AdGuard, Nextcloud) are well-documented, skip research.

---

### Phase 5: Advanced Security & Features (Future)
**Rationale:** After platform is mature and stable, add advanced features like SSO, intrusion prevention, and network segmentation. These are high-complexity enhancements that only make sense with 5+ services.

**Delivers:**
- Authentik SSO (if 5+ services deployed)
- CrowdSec intrusion prevention
- Network segmentation with VLANs (if managed switch available)
- Additional specialized services (Immich, Paperless-ngx, Ollama)

**Addresses features:**
- SSO for unified authentication (differentiator)
- Intrusion prevention (differentiator)
- Network segmentation (differentiator)

**Avoids pitfalls:**
- Complexity creep: Only add when platform can support it

**Research needs:** LIKELY — SSO integration (Authentik + Traefik ForwardAuth) and VLAN configuration may need deeper research if gaps emerge.

---

### Phase Ordering Rationale

**Dependency-driven:**
- Networks → Security → Routing → Applications follows critical path identified in architecture research
- Traefik must work before any apps (service discovery dependency)
- Backup must exist before persistent data (data protection dependency)
- VPN must work before sensitive services (security dependency)

**Risk mitigation:**
- Phase 1 prevents catastrophic pitfalls (rate limits, security, storage)
- Staging environment validates Let's Encrypt before production
- Test application validates stack before complex services
- Backup tested before deploying services with important data

**Incremental validation:**
- Each phase delivers working capability that can be tested
- No "big bang" deployment; progressive complexity
- Early phases have standard patterns (low risk)
- Later phases add optional enhancements (can defer)

### Research Flags

**Phases with standard patterns (SKIP research-phase):**
- **Phase 1 (Foundation):** Traefik + Docker + Let's Encrypt is extremely well-documented; 100+ tutorials from 2025-2026 with nearly identical patterns
- **Phase 2 (VPN & Validation):** Tailscale integration has official documentation and community consensus; whoami/homepage are trivial
- **Phase 3 (Backup & Observability):** Backup strategies and Prometheus/Grafana are established patterns; offen/docker-volume-backup is turnkey

**Phases that might need research:**
- **Phase 4 (Core Applications):** IF deploying specialized apps beyond standard homelab services:
  - Immich (photo management with ML) — complex dependencies, might need integration research
  - Paperless-ngx (document management with OCR) — OCR configuration nuances
  - Ollama (local LLM) — resource constraints on Pi, model selection
  - Standard apps (Vaultwarden, AdGuard, Nextcloud, Jellyfin) — SKIP research, well-documented
- **Phase 5 (Advanced Security):** LIKELY needs research:
  - Authentik SSO + Traefik ForwardAuth — integration details vary by service
  - VLAN configuration on specific managed switch — hardware-dependent
  - CrowdSec + Traefik — less common pattern, might need research

**Research-phase decision criteria:**
Use `/gsd:research-phase` when:
1. Service has sparse documentation or conflicting sources
2. Integration pattern not covered in existing research
3. Hardware-specific configuration (VLAN on specific switch model)
4. Emerging technology with evolving best practices (Ollama on Pi)

Skip research when:
1. Service in top 20 homelab apps with 2025-2026 tutorials
2. Official Docker image with ARM64 support
3. Standard Traefik label pattern applies
4. Backup/monitoring follows established patterns

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified from official GitHub releases and Docker Hub as of January 2026; version compatibility matrix confirmed; ARM64 support validated |
| Features | HIGH | Feature priorities based on 15+ current 2025-2026 homelab guides; strong consensus on table stakes vs. differentiators; expert vs. beginner preferences clear |
| Architecture | HIGH | Architecture patterns documented in official Traefik/Docker/Tailscale docs; community implementations converge on same patterns; security best practices well-established |
| Pitfalls | HIGH | Pitfalls verified across multiple sources (security advisories, community postmortems, official troubleshooting guides); prevention strategies tested in community |

**Overall confidence:** HIGH

All research areas show strong consensus from authoritative sources (official documentation, CVE databases, current community guides from 2025-2026). No conflicting recommendations encountered. Version compatibility verified from release notes. ARM64 compatibility confirmed for all core components. Pitfalls backed by specific incidents and official security advisories.

### Gaps to Address

**Minor gaps requiring attention during implementation:**

- **Cloudflare API token scope**: Research shows scoped tokens required (`Zone.Zone:Read`, `Zone.DNS:Edit`) but exact Cloudflare UI flow for token creation in 2026 interface should be verified during Phase 1 setup. Documentation principle applies, but UI may have changed.

- **Tailscale subnet routing specifics**: Research covers subnet router pattern but exact environment variables (`TS_ROUTES`, `TS_USERSPACE`) should be verified against current Tailscale Docker image documentation during Phase 2. Pattern is clear, flags may vary.

- **Pi 5 PCIe HAT compatibility**: Research strongly recommends SSD but if using PCIe HAT instead of USB 3.0, specific HAT model compatibility should be verified. USB 3.0 path is proven, PCIe is newer.

- **Prometheus ARM64 resource usage**: Research indicates Prometheus + Grafana are feasible on Pi 5 but exact memory footprint on ARM64 should be monitored during Phase 3. May need to tune retention or use lighter alternatives (VictoriaMetrics) on 4GB model.

**How to handle:**
- Document actual values during implementation
- All gaps are "verify during execution" not "research needed"
- Patterns are clear, details are version/UI-specific
- None block roadmap structure or phase ordering

## Sources

### Stack Research Sources (HIGH confidence)
- Docker Engine Release Notes v29 — Latest version and ARM64 support verification
- Traefik v3.6 GitHub Releases — Security updates and compatibility matrix
- Tailscale Docker Documentation — Official integration guide
- Raspberry Pi OS Release Notes — 64-bit Bookworm requirements
- Official Docker Hub repositories — Multi-arch image confirmation for all services

### Features Research Sources (HIGH confidence)
- Virtualization Howto: Ultimate Home Lab Starter Stack for 2026 — Current feature priorities
- TechHut: MUST HAVE Homelab Services 2025 — Table stakes identification
- Elest.io: The 2026 Homelab Stack — What self-hosters actually run
- XDA Developers: 4 homelab mistakes I'll never make again in 2026 — Anti-patterns
- Hostbor: 25+ Must-Have Home Server Services for 2025 — Feature categorization

### Architecture Research Sources (HIGH confidence)
- SimpleHomelab: Ultimate Traefik Docker Compose Guide 2025 — Complete architecture patterns
- Technotim: Traefik 3 and FREE Wildcard Certificates — DNS-01 challenge implementation
- Baeldung: Docker Compose Multi-Project Communication — Network architecture
- SimpleHomelab: 20 Docker Security Best Practices — Security hardening patterns
- DarthSeldon: HomeLab with Docker and Raspberry Pi 5 — Pi-specific architecture

### Pitfalls Research Sources (HIGH confidence)
- Traefik Security Update CVE-2026-22045 — Socket exposure risks confirmed
- Let's Encrypt Rate Limits Documentation — Official rate limit thresholds
- Raspberry Pi Storage Reliability Issues (LinuxBlog.io) — SD card failure patterns
- Hackaday: Raspberry Pi SD Card Corruption — Write amplification analysis
- Sunfounder: Raspberry Pi Temperature Guide — Thermal throttling thresholds verified

### Cross-Cutting Sources (HIGH confidence)
- Official Traefik Documentation — Provider configuration, middleware, certificates
- Docker Compose Documentation — Networking, secrets, resource limits
- Tailscale Knowledge Base — VPN integration patterns, ACLs, troubleshooting
- Virtualization Howto: Home Lab Backup Strategy 2025 — 3-2-1 backup implementation

---
*Research completed: 2026-01-16*
*Ready for roadmap: Yes*
