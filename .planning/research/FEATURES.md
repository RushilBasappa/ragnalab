# Feature Landscape: Homelab Platform

**Domain:** Self-hosted homelab infrastructure and applications
**Researched:** 2026-01-16
**Confidence:** HIGH

## Feature Categories Overview

Homelab features split into four distinct categories:

1. **Infrastructure Features** - Core technical capabilities that make the platform work
2. **Core Applications** - Essential self-hosted services most homelabs deploy first
3. **Advanced Applications** - Nice-to-have services for expansion
4. **Anti-Features** - Patterns to explicitly avoid

## Table Stakes: Infrastructure Features

Features users expect from any homelab platform. Missing these = incomplete infrastructure.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| **Reverse Proxy** | Route traffic to services by domain name, eliminate port numbers | MEDIUM | None | Traefik/Caddy/NPM - automatic SSL is critical |
| **SSL/TLS Certificates** | Eliminate browser warnings, enable HTTPS everywhere | MEDIUM | Reverse proxy, DNS | Let's Encrypt automation is standard in 2025 |
| **Container Orchestration** | Deploy and manage services consistently | LOW | Docker installed | Docker Compose is preferred over K3s for simplicity |
| **VPN Access** | Secure remote access without exposing services publicly | MEDIUM | None | Tailscale/WireGuard are 2025 standards |
| **DNS Resolution** | Internal domain names for services | LOW | None | Local DNS or hosts file |
| **Backup System** | Protect against data loss | HIGH | Storage | 3-2-1 rule (3 copies, 2 media, 1 offsite) is non-negotiable |
| **Service Discovery** | Automatically detect and configure new services | MEDIUM | Reverse proxy | Label-based discovery (Traefik) or file-based config |
| **Health Monitoring** | Know when services are down | LOW | None | Uptime Kuma is 2025 standard for simple checks |
| **Dashboard/Homepage** | Single entry point to all services | LOW | None | Homepage or Homarr in 2025 |
| **Log Management** | Debug issues and track events | MEDIUM | Storage | Centralized logging (file-based acceptable for small labs) |

### Infrastructure Complexity Notes

- **LOW**: 1-2 hours setup, minimal ongoing maintenance
- **MEDIUM**: 4-8 hours initial setup, periodic configuration updates
- **HIGH**: 1-2 days setup, ongoing maintenance required

## Core Applications: First Deployments

Services most homelabs deploy in first 30 days. Common initial use cases.

| Application | Category | Why Core | Complexity | Notes |
|------------|----------|----------|------------|-------|
| **Dashboard** (Homepage/Homarr) | Management | Entry point to all services | LOW | Homepage = YAML config, Homarr = GUI |
| **Password Manager** (Vaultwarden) | Security | Most wanted self-hosted app, immediate value | LOW | Vaultwarden uses <50MB RAM, Bitwarden-compatible |
| **Ad Blocker** (AdGuard Home/Pi-hole) | Network | Network-wide ad blocking | LOW | AdGuard Home preferred in 2026 |
| **File Storage** (Nextcloud/Syncthing) | Productivity | Replace Dropbox/Google Drive | MEDIUM | Nextcloud=full suite, Syncthing=sync only |
| **Media Server** (Jellyfin) | Media | Replace Plex, fully open source | MEDIUM | Jellyfin won vs Plex in 2025 due to monetization issues |
| **Container Management** (Portainer) | Management | GUI for Docker if not using CLI | LOW | Portainer CE for beginners, pros use CLI |
| **Monitoring** (Uptime Kuma) | Observability | Status checks with notifications | LOW | Clean UI, push notifications standard |

### Application Priority Tiers

**P1 (Deploy Week 1):**
- Dashboard - needs to exist before other apps make sense
- Password Manager - immediate security value
- Uptime Kuma - know when things break

**P2 (Deploy Month 1):**
- Ad Blocker - quality of life improvement
- File Storage - practical daily use
- Container Management - if using GUI approach

**P3 (Post-MVP):**
- Media Server - high value but not critical
- Additional services based on use case

## Differentiators: Advanced Features

Features that make homelabs powerful. Not expected, but highly valued by experienced users.

| Feature | Value Proposition | Complexity | Dependencies | Notes |
|---------|-------------------|------------|--------------|-------|
| **GitOps Workflow** | Infrastructure as code, version controlled configs | MEDIUM | Git repo | Homepage/Traefik configs in Git |
| **Single Sign-On** (Authentik/Authelia) | One login for all services, proper 2FA | HIGH | Reverse proxy | Authentik=full features, Authelia=lighter |
| **Observability Stack** (Prometheus + Grafana) | Deep metrics and dashboards | HIGH | Storage, monitoring | Beyond simple uptime checks |
| **Intrusion Prevention** (CrowdSec) | Share threat intel, block bad actors | MEDIUM | Reverse proxy | Modernizes fail2ban approach in 2025 |
| **AI/LLM Integration** (Ollama) | Run local language models | HIGH | GPU recommended | 2026 trend - local AI for homelabs |
| **Photo Management** (Immich) | Self-hosted Google Photos replacement | MEDIUM | Storage, ML | ML features without cloud privacy concerns |
| **Document Management** (Paperless-ngx) | OCR and searchable document archive | MEDIUM | Storage | Transform physical docs to digital |
| **Network Segmentation** (VLANs) | Isolate IoT, guests, services | HIGH | Managed switch | 3 VLANs minimum (trusted, IoT, guest) |
| **Automated Backups** | Scheduled, tested, verified backups | MEDIUM | Backup system | Proxmox Backup Server for VM-level |
| **Cloud Tunnel** (Cloudflare Tunnel) | Public access without exposing IP | MEDIUM | Domain, Cloudflare account | Alternative to port forwarding |

### Differentiator Categories

**Security Focused:**
- SSO (consolidate authentication)
- Intrusion Prevention (protect against threats)
- Network Segmentation (isolate attack surface)

**Developer Experience:**
- GitOps (infrastructure as code)
- Observability Stack (deep visibility)

**Capability Expansion:**
- AI/LLM (local models)
- Photo Management (family use case)
- Document Management (paperless office)

**Advanced Networking:**
- Cloud Tunnel (selective public access)
- Network Segmentation (proper isolation)

## Anti-Features: Deliberately Avoid

Patterns that seem valuable but create problems in homelab context.

| Anti-Feature | Why It Seems Good | Why Problematic | What To Do Instead |
|--------------|-------------------|-----------------|-------------------|
| **Kubernetes (K8s/K3s) for Small Labs** | "Industry standard, good to learn" | Massive complexity overhead for <20 services, requires constant maintenance | Docker Compose - simpler, adequate for 99% of homelabs |
| **Public Internet Exposure** | "Makes services accessible anywhere" | Security nightmare, constant attack surface, management overhead | Tailscale/WireGuard VPN - secure remote access without exposure |
| **Everything on One VLAN** | "Simple, just works" | IoT devices can reach sensitive services, no security boundaries | Minimum 3 VLANs (trusted/IoT/guest), firewall rules between |
| **No Backup Strategy** | "Can rebuild from scratch" | Data loss inevitable, hours of reconfiguration after failure | 3-2-1 backup rule from day one, test restores |
| **GUI-Only Configuration** | "Easier than config files" | Can't version control, hard to replicate, click-ops doesn't scale | Config files in Git (GitOps), GUI for visualization only |
| **Mixed Docker Networks** | "Default bridge works fine" | Services find each other unexpectedly, unclear dependencies | Custom Docker networks per service group, explicit networking |
| **Traefik + Nginx + Caddy** | "Use best tool for each job" | Multiple reverse proxies = complexity, cert conflicts, confused routing | Pick ONE reverse proxy, stick with it |
| **Self-Signed Certificates** | "Avoid Let's Encrypt complexity" | Browser warnings forever, trust issues, doesn't solve problem | Let's Encrypt automation (built into modern proxies) |
| **Portainer + Dockge + Docker CLI** | "Multiple management tools" | Conflicts between tools, state drift, confusion about source of truth | Pick ONE management approach (preferably CLI + compose files) |
| **200 Services From Day One** | "Deploy everything awesome" | Can't maintain, don't use 90%, overwhelming when broken | Start with 5-10 core services, add gradually with purpose |
| **RAID as Backup** | "Redundancy = backup" | RAID protects against drive failure, NOT data corruption, deletion, ransomware | RAID for uptime, separate backup for data protection |
| **No Documentation** | "I'll remember my setup" | Forget IP ranges, VLAN purposes, service dependencies after 2 months | Document as you build - IPs, VLANs, dependencies, decisions |
| **Temporary Quick Fixes** | "Just for today, will fix later" | Temporary ports, VMs, firewall rules become permanent technical debt | Do it right the first time, or schedule proper fix immediately |
| **WiFi for Critical Services** | "Wireless is convenient" | Inconsistent latency, unpredictable throughput, services flap | Wired Ethernet for Pi-hole, Home Assistant, NAS, servers |

### Anti-Feature Principles

1. **Complexity Budget**: Every feature has maintenance cost. Small homelabs can't afford K8s overhead.
2. **Security By Default**: Never expose services publicly when VPN exists. Never flat network when VLANs exist.
3. **Single Responsibility**: One reverse proxy. One container manager. One monitoring solution.
4. **Automation > Clicks**: If you can't commit it to Git, it's not infrastructure as code.
5. **Start Small, Grow Deliberately**: 5 well-maintained services > 50 neglected services.

## Feature Dependencies

```
Infrastructure Foundation:
[Docker]
    ├──> [Docker Compose] ──> [All Applications]
    └──> [Container Management] (optional GUI)

Networking Layer:
[Reverse Proxy]
    ├──> [SSL Certificates] ──> [HTTPS everywhere]
    ├──> [Service Discovery] ──> [Auto-configuration]
    └──> [Intrusion Prevention] (optional enhancement)

Access Layer:
[VPN] ──> [Remote Access to all services]
    └──enhances──> [Dashboard] (access from anywhere)

[DNS] ──> [Internal domain names]
    └──requires──> [Reverse Proxy] (for routing)

Observability:
[Health Monitoring] ──> [Know what's down]
[Log Management] ──> [Debug issues]
[Observability Stack] ──> [Deep metrics] (optional advanced)

Data Protection:
[Backup System] ──> [3-2-1 Rule]
    ├──> [Local Backups]
    ├──> [Different Media]
    └──> [Offsite Storage]

Advanced Security:
[Network Segmentation] ──> [VLANs + Firewall]
[SSO] ──> [Unified Authentication]
    └──requires──> [Reverse Proxy] (for auth forwarding)
```

### Dependency Notes

- **Docker Compose is the foundation**: All applications depend on this being stable
- **Reverse Proxy is the gateway**: Most features flow through or enhance this
- **VPN enables everything**: Without it, must expose services publicly (anti-pattern)
- **Backup is independent**: Can implement anytime, but should be day-one priority
- **SSO is late-stage**: Only makes sense after 5+ services deployed

## Infrastructure vs Application Split

### Infrastructure (Platform Features)
- Built once, benefit all services
- High impact on operations
- Changes require careful planning
- Examples: Reverse proxy, VPN, backup system, monitoring

### Applications (Services)
- Can be added/removed independently
- Low impact on other services
- Easy to experiment
- Examples: Password manager, media server, file storage, dashboard

**Implication for Roadmap**: Infrastructure must be solid before scaling applications.

## MVP Recommendation

For RagnaLab specifically (expert DevOps engineer, values modularity):

### Launch With (Phase 1 - Infrastructure Foundation)
- [ ] Docker Compose orchestration
- [ ] Traefik reverse proxy (expert-friendly, label-based)
- [ ] Let's Encrypt SSL automation
- [ ] Tailscale VPN access
- [ ] Uptime Kuma monitoring
- [ ] 3-2-1 backup strategy defined (not all implemented)

**Rationale**: Infrastructure must be solid. Traefik fits expert profile better than NPM.

### Launch With (Phase 1 - Initial Apps)
- [ ] Homepage dashboard (YAML = GitOps-friendly)
- [ ] Vaultwarden password manager (stated requirement)

**Rationale**: Minimal app set to validate infrastructure works.

### Add After Validation (Phase 2)
- [ ] AdGuard Home (network-level benefit)
- [ ] 2-3 additional services based on use case (media/productivity)
- [ ] GitOps workflow for configs
- [ ] Prometheus + Grafana observability stack (expert-level visibility)

**Rationale**: Infrastructure proven, expand capabilities deliberately.

### Future Consideration (Phase 3+)
- [ ] Authentik SSO (only valuable after 5+ services)
- [ ] CrowdSec intrusion prevention
- [ ] Network segmentation with VLANs
- [ ] AI/LLM integration (Ollama)

**Rationale**: Advanced features, high complexity, defer until platform mature.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Phase |
|---------|------------|---------------------|----------|-------|
| Docker Compose | HIGH | LOW | P1 | 1 |
| Traefik Proxy | HIGH | MEDIUM | P1 | 1 |
| SSL Automation | HIGH | LOW | P1 | 1 |
| Tailscale VPN | HIGH | MEDIUM | P1 | 1 |
| Homepage Dashboard | HIGH | LOW | P1 | 1 |
| Vaultwarden | HIGH | LOW | P1 | 1 |
| Uptime Kuma | MEDIUM | LOW | P1 | 1 |
| Backup Strategy | HIGH | MEDIUM | P1 | 1 |
| AdGuard Home | MEDIUM | LOW | P2 | 2 |
| GitOps Workflow | HIGH | MEDIUM | P2 | 2 |
| Prometheus + Grafana | MEDIUM | HIGH | P2 | 2 |
| Media Server (Jellyfin) | MEDIUM | MEDIUM | P2 | 2 |
| File Storage | MEDIUM | MEDIUM | P2 | 2 |
| Authentik SSO | LOW | HIGH | P3 | 3+ |
| CrowdSec | LOW | MEDIUM | P3 | 3+ |
| Network Segmentation | MEDIUM | HIGH | P3 | 3+ |
| Ollama AI | LOW | HIGH | P3 | 3+ |
| Immich Photos | MEDIUM | MEDIUM | P3 | 3+ |
| Paperless-ngx | LOW | MEDIUM | P3 | 3+ |

**Priority Key:**
- **P1**: Must have for MVP - core infrastructure + initial validation
- **P2**: Should have - expand capabilities after infrastructure proven
- **P3**: Nice to have - advanced features for mature platform

## Expert-Level Considerations

For DevOps engineers specifically:

### Infrastructure as Code
- Homepage YAML config in Git (not Homarr GUI)
- Traefik labels in docker-compose files
- All configs version controlled
- Declarative > imperative

### Modularity Requirements
- Custom Docker networks per service group
- Clear service boundaries
- Easy to add/remove services
- No hidden dependencies

### Operational Excellence
- Prometheus metrics from day one (even before Grafana)
- Structured logging (JSON logs)
- Health checks on every container
- Automated backup verification

### Anti-Patterns for Experts
- Don't use Portainer (GUI doesn't fit workflow)
- Don't use Homarr (YAML > GUI for version control)
- Don't use NPM (Traefik label-based is superior)
- Don't skip monitoring "until later" (build it in from start)

## Sources

### Essential Homelab Services
- [TechHut: MUST HAVE Homelab Services](https://techhut.tv/must-have-home-server-services-2025/)
- [Virtualization Howto: Ultimate Home Lab Starter Stack for 2026](https://www.virtualizationhowto.com/2025/12/ultimate-home-lab-starter-stack-for-2026-key-recommendations/)
- [Hostbor: 25+ Must-Have Home Server Services for 2025](https://hostbor.com/25-must-have-home-server-services/)
- [Elest.io: The 2026 Homelab Stack](https://blog.elest.io/the-2026-homelab-stack-what-self-hosters-are-actually-running-this-year/)

### Infrastructure & Networking
- [Virtualization Howto: Why Zoraxy Might Be the Best Reverse Proxy](https://www.virtualizationhowto.com/2025/12/why-zoraxy-might-be-the-best-reverse-proxy-for-home-labs/)
- [TheOrangeOne: Exposing your Homelab](https://theorangeone.net/posts/exposing-your-homelab/)
- [Lobsters: How do you secure access to your self-hosted services?](https://lobste.rs/s/rmenr4/how_do_you_secure_access_your_self_hosted)

### Docker Applications
- [Kextcache: Top 25 Must-Have Docker Apps for Your Home Server (2025)](https://kextcache.com/top-docker-apps-home-server/)
- [GitHub: jgwehr/homelab-docker](https://github.com/jgwehr/homelab-docker)
- [BitDoze: Best 100+ Docker Containers for Home Server](https://www.bitdoze.com/docker-containers-home-server/)
- [Virtualization Howto: 15 Docker Containers That Make Your Home Lab Instantly Better](https://www.virtualizationhowto.com/2025/11/15-docker-containers-that-make-your-home-lab-instantly-better/)

### Common Mistakes & Anti-Patterns
- [XDA: 4 homelab mistakes I'll never make again in 2026](https://www.xda-developers.com/4-homelab-mistakes-ill-never-make-again-in-2026/)
- [Virtualization Howto: Top Home lab Networking Mistakes to Avoid in 2025](https://www.virtualizationhowto.com/2025/08/top-home-lab-networking-mistakes-to-avoid-in-2025/)
- [Geeky Gadgets: 10 Common Home Lab Mistakes to Avoid in 2025](https://www.geeky-gadgets.com/common-home-lab-mistakes-to-avoid/)
- [Virtualization Howto: 10 Home Lab Mistakes I Made (So You Don't Have To)](https://www.virtualizationhowto.com/2025/09/10-home-lab-mistakes-i-made-so-you-dont-have-to/)

### Monitoring & Observability
- [Grafana Labs: How to monitor your homelab with eBPF and OpenTelemetry](https://grafana.com/blog/2025/08/22/how-to-monitor-your-homelab-with-beyla-ebpf-and-opentelemetry/)
- [Simple Observability: Home Lab Monitoring Made Simple](https://simpleobservability.com/homelab)

### Backup & Disaster Recovery
- [Virtualization Howto: Ultimate Home Lab Backup Strategy (2025 Edition)](https://www.virtualizationhowto.com/2025/10/ultimate-home-lab-backup-strategy-2025-edition/)
- [KenBinLab: Implementing a 3-2-1 Backup Strategy for Your Homelab](https://kenbinlab.com/backup-strategy-for-homelab/)
- [Excalibur's Sheath: Designing a Resilient Homelab](https://excalibursheath.com/guide/2025/08/10/designing-resilient-homelab-redundancy-availability.html)

### Specific Applications
- [Kubedo: Best Self-Hosted Password Managers 2025](https://kubedo.com/blog-best-self-hosted-password-managers-2025/)
- [XDA: I self-host Bitwarden and you should consider it too](https://www.xda-developers.com/i-self-host-bitwarden-and-heres-why-you-should-too/)
- [Road to Homelab: The Ultimate Homelab Homepage Guide](https://roadtohomelab.blog/homelab-homepage-guide/)
- [How To Geek: Homelab Dashboard: What It Is and Why You Need One](https://www.howtogeek.com/homelab-dashboard-what-it-is-and-why-you-need-one/)

### Reverse Proxy Comparisons
- [Programonaut: Reverse Proxy Comparison: Traefik vs. Caddy vs. Nginx](https://www.programonaut.com/reverse-proxies-compared-traefik-vs-caddy-vs-nginx-docker/)
- [Virtualization Howto: I Replaced Nginx Proxy Manager with Traefik](https://www.virtualizationhowto.com/2025/09/i-replaced-nginx-proxy-manager-with-traefik-in-my-home-lab-and-it-changed-everything/)
- [HomelabSec: Nginx vs Caddy vs Traefik Benchmark Results](https://homelabsec.com/posts/nginx-vs-caddy-vs-traefik-benchmark-results/)
- [Medium: NPM, Traefik, or Caddy? How to pick the reverse proxy you'll still like in months](https://medium.com/@thomas.byern/npm-traefik-or-caddy-how-to-pick-the-reverse-proxy-youll-still-like-in-6-months-1e1101815e07)

---
*Feature research for: RagnaLab Homelab Platform*
*Researched: 2026-01-16*
*Confidence: HIGH (based on current 2025-2026 homelab ecosystem sources)*
