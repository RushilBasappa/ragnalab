# Pitfalls Research

**Domain:** Homelab Infrastructure (Raspberry Pi 5 + Traefik + Tailscale + Docker)
**Researched:** 2026-01-16
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Accidental Public Exposure via Traefik Misconfiguration

**What goes wrong:**
Services intended to be private via Tailscale get accidentally exposed to the public internet through improper Traefik router configuration. This is the most catastrophic security failure in homelab setups.

**Why it happens:**
- Traefik automatically discovers Docker containers and creates routes based on labels
- Default Traefik behavior exposes services on all available networks unless explicitly restricted
- Developers forget that Traefik listens on multiple entry points (80/443 for public, Tailscale interface for private)
- Missing or incorrect router rules allow traffic from both public and Tailscale networks

**How to avoid:**
- Always specify explicit entry points in Traefik labels: `traefik.http.routers.{service}.entrypoints=tailscale`
- Use Traefik's allowlist middleware to restrict access by IP range
- Never expose Traefik's public entry points (80/443) unless you intentionally want public services
- Implement network segmentation: separate Docker networks for public vs. private services
- Use `traefik.enable=false` by default and explicitly enable only services that should be routed

**Warning signs:**
- Traefik dashboard shows routers attached to multiple entry points unexpectedly
- Running `curl http://your-public-ip:80` returns a response from services that should be private
- Shodan or similar services show your IP serving unexpected web content
- Logs show connection attempts from IPs outside your Tailscale network

**Phase to address:**
Phase 1 (Foundation) - Must be prevented from day one. No service should ever accidentally be public.

---

### Pitfall 2: Let's Encrypt Rate Limit Exhaustion During Testing

**What goes wrong:**
Hitting Let's Encrypt production rate limits (50 certificates per registered domain per week) during development/testing, locking you out of obtaining certificates for up to a week with no override possible.

**Why it happens:**
- Developers test certificate acquisition using production Let's Encrypt servers instead of staging
- Traefik misconfiguration causes certificate re-requests on every container restart
- SD card corruption or Docker volume loss causes acme.json to be deleted, triggering mass re-issuance
- Crash-looping containers repeatedly request new certificates
- DNS-01 challenge failures cause retries that count against rate limits (5 failures per hour per identifier)

**How to avoid:**
- ALWAYS use Let's Encrypt staging environment (`caServer = "https://acme-staging-v02.api.letsencrypt.org/directory"`) during initial setup
- Persist acme.json on a named Docker volume, NEVER use bind mounts to SD card
- Back up acme.json before making configuration changes
- Implement health checks to prevent crash-looping containers
- Use exponential backoff for certificate renewal retries
- Test DNS-01 challenges manually before enabling automatic certificate issuance
- Allow sufficient DNS propagation time (use Traefik's `delayBeforeCheck` option, 60+ seconds recommended)

**Warning signs:**
- Traefik logs show repeated ACME challenge failures
- Error messages mentioning "too many certificates" or "rate limit exceeded"
- Traefik issues new certificates on every restart instead of reusing existing ones
- acme.json file is empty or missing after container restarts
- DNS TXT records for _acme-challenge not propagating within 60 seconds

**Phase to address:**
Phase 1 (Foundation) - Certificate infrastructure must be configured correctly from the start. Add flag for Phase 2+ if migrating from staging to production certificates.

---

### Pitfall 3: Docker Socket Exposure Granting Root Access

**What goes wrong:**
Mounting the Docker socket (`/var/run/docker.sock`) into the Traefik container gives anyone who compromises Traefik root access to the host system. This turns a container escape into a full host compromise.

**Why it happens:**
- Traefik's Docker provider requires access to the Docker socket to discover containers
- Documentation often shows socket mounting without security warnings
- Developers prioritize convenience over security during initial setup
- Not understanding that socket access = root access to host

**How to avoid:**
- Mount Docker socket read-only: `/var/run/docker.sock:/var/run/docker.sock:ro`
- Run Traefik container with `no-new-privileges: true` security option
- Consider using Docker Socket Proxy (tecnativa/docker-socket-proxy) to restrict socket API access
- Use least-privilege filtering: only expose necessary Docker API endpoints (/containers, /networks, /services)
- Implement container runtime security scanning (Trivy, Grype) to detect Traefik vulnerabilities
- Keep Traefik updated to latest stable version (CVE-2026-22045 patched in v2.11.35/v3.6.7)
- Never expose Traefik dashboard publicly without authentication

**Warning signs:**
- Docker socket mounted without `:ro` flag in docker-compose.yml
- Traefik container running with privileged flags
- No security_opt configuration in Traefik service definition
- Outdated Traefik version with known CVEs
- Traefik dashboard accessible without authentication

**Phase to address:**
Phase 1 (Foundation) - Security posture must be correct from initial deployment.

---

### Pitfall 4: SD Card Corruption from Docker Write Amplification

**What goes wrong:**
SD cards fail catastrophically within months due to Docker's high write volume (logs, container layers, volumes). Filesystem corruption causes data loss and service outages requiring full reinstallation.

**Why it happens:**
- Docker logs, container layer writes, and volume operations generate massive write I/O
- SD cards have limited write endurance (typically 10,000-100,000 write cycles per cell)
- Journaling filesystems (ext4) amplify writes through metadata updates
- Power loss during writes corrupts filesystem structures
- Container crash loops generate continuous log writes
- No write-reduction strategies implemented

**How to avoid:**
- CRITICAL: Use SSD/NVMe boot instead of SD card for any production homelab (Pi 5 supports NVMe)
- If SD card required: use high-endurance cards (Samsung PRO Endurance, SanDisk High Endurance)
- Configure Docker logging driver to limit size: `--log-driver json-file --log-opt max-size=10m --log-opt max-file=3`
- Mount Docker data directory (`/var/lib/docker`) on external SSD via USB 3.0
- Store application data volumes on external storage, not SD card
- Use tmpfs mounts for ephemeral data: logs, caches, temp files
- Consider F2FS filesystem instead of ext4 (designed for flash storage)
- Disable swap or move swap to external storage
- Implement automated backup rotation to external storage
- Use UPS or quality power supply to prevent corruption from power loss

**Warning signs:**
- File I/O errors in system logs (`/var/log/syslog`)
- Docker daemon fails to start after reboot
- "Read-only file system" errors
- Containers randomly exiting with exit code 137 (SIGKILL, often memory/I/O related)
- `fsck` finds errors during boot
- System becomes unresponsive during heavy Docker operations
- SD card less than 6 months old showing performance degradation

**Phase to address:**
Phase 1 (Foundation) - Storage architecture must be resilient from day one. Flag for immediate migration if deployed on SD card.

---

### Pitfall 5: Traefik Docker Network Misconfiguration (Wrong Network Selection)

**What goes wrong:**
Traefik connects to the wrong Docker network or randomly picks one when containers are on multiple networks, breaking service discovery and causing "502 Bad Gateway" or "404 Not Found" errors.

**Why it happens:**
- When a container is on multiple Docker networks, Traefik randomly picks one unless told otherwise
- Docker Compose prefixes network names with project name, but labels reference unprefixed names
- Traefik and backend containers aren't on the same network
- Using `localhost` in service labels instead of Docker service names
- Missing `traefik.docker.network` label when containers are multi-homed

**How to avoid:**
- Always specify the network explicitly in labels: `traefik.docker.network=traefik_public`
- Use `docker inspect <container_id>` to verify actual network names (include project prefix)
- Ensure Traefik container and backend containers share at least one common network
- Define external networks in docker-compose.yml: `networks: traefik_public: external: true`
- Use Docker service names (from docker-compose.yml) in loadBalancer URLs, never `localhost`
- Set `traefik.http.services.{service}.loadbalancer.server.port` to container internal port (not published port)
- For multi-network setups, use `docker network inspect` to verify connectivity

**Warning signs:**
- 502 Bad Gateway errors from Traefik
- Traefik dashboard shows service as healthy but returns errors
- Traefik logs: "no service found" or "unable to reach backend"
- `docker exec traefik ping <service-name>` fails
- Services work when accessed directly by IP but fail through Traefik
- Traefik randomly routes to different container instances with different success rates

**Phase to address:**
Phase 1 (Foundation) - Network topology must be correct before adding services. Add verification step in each subsequent phase when adding new services.

---

### Pitfall 6: Tailscale State Loss Breaking VPN Access

**What goes wrong:**
Tailscale container loses its state (auth keys, node identity) due to missing volume persistence, requiring re-authentication and breaking all private service access. Old node remains in Tailscale admin console as zombie.

**Why it happens:**
- Tailscale state directory not persisted via Docker volume
- Default Tailscale container configurations don't specify `--statedir` mount
- SD card corruption destroys state files
- Container recreation without volume causes fresh Tailscale identity
- Misconfigured IAM permissions (if using cloud state storage)

**How to avoid:**
- Mount persistent volume for Tailscale state: `/var/lib/tailscale:/var/lib/tailscale`
- Use named Docker volumes, not bind mounts to SD card
- Configure Tailscale with ephemeral auth keys for automatic re-auth after state loss
- Enable Tailscale Lock (tailnet lock) for zero-trust authentication
- Store backup of Tailscale state alongside acme.json backups
- Use `--statedir=/persistent/path` when running tailscaled
- Implement monitoring to alert when Tailscale node appears offline
- Document recovery process: remove old node from admin console, re-authenticate

**Warning signs:**
- Tailscale admin console shows multiple nodes for same device
- `tailscale status` shows "Logged out" after container restart
- Services accessible before restart become unreachable
- Tailscale container logs show "no state" or authentication requests
- New device fingerprint on every container restart

**Phase to address:**
Phase 1 (Foundation) - VPN persistence is critical for reliable access. Test recovery in Phase 2.

---

### Pitfall 7: ARM64 Image Compatibility Issues ("exec format error")

**What goes wrong:**
Docker containers fail to start with "exec format error" because images are built for AMD64 (x86_64) instead of ARM64, a common problem on Raspberry Pi.

**Why it happens:**
- Many Docker images default to AMD64 or don't publish ARM64 variants
- docker-compose.yml doesn't specify platform architecture
- Developers pull images on AMD64 dev machine and push compose file without testing on Pi
- Multi-arch manifests not properly configured
- Build process doesn't target ARM64 architecture

**How to avoid:**
- Explicitly specify platform in docker-compose.yml: `platform: linux/arm64/v8`
- Verify image supports ARM64 before using: check Docker Hub tags for arm64 variant
- Use multi-arch images that support both AMD64 and ARM64
- Prefer official images which typically have ARM support
- For custom builds, use Docker buildx with `--platform linux/arm64/v8`
- Test all services on actual Pi hardware before deploying
- Use Docker manifest inspection: `docker manifest inspect image:tag`
- Consider arm64-specific image variants (e.g., `image:tag-arm64`)

**Warning signs:**
- Container exits immediately after creation with "exec format error"
- `docker logs <container>` shows "cannot execute binary file: Exec format error"
- `docker inspect <image>` shows Architecture: amd64 instead of arm64
- Container works on developer's laptop but fails on Pi
- Extremely slow container performance (QEMU emulation as fallback)

**Phase to address:**
Phase 1 (Foundation) - Image selection must be ARM64-compatible from start. Add verification checklist for each new service added in later phases.

---

### Pitfall 8: Raspberry Pi Thermal Throttling Under Docker Load

**What goes wrong:**
CPU temperature exceeds 85°C under sustained Docker workload, triggering thermal throttling that reduces performance by 40%+ and causes unpredictable service degradation. Container response times spike, health checks fail, orchestration becomes unreliable.

**Why it happens:**
- Docker container overhead (cgroups, overlay networking, storage drivers) generates 15-30% more CPU load than native
- Multiple containers running simultaneously create sustained high CPU utilization
- Raspberry Pi 5 has significantly higher power draw than Pi 4, generating more heat
- No active cooling installed (fans, heatsinks)
- Poor case ventilation or enclosed spaces
- Ambient temperature in server closet exceeds room temperature
- Docker's default cgroups configuration allows unlimited CPU contention

**How to avoid:**
- Install active cooling: minimum heatsink + fan, ideally official Raspberry Pi Active Cooler
- Use official Raspberry Pi 5 power supply (5V/5A, 27W) - undervoltage causes throttling
- Monitor temperature: `vcgencmd measure_temp` and set up alerts at 70°C
- Configure Docker CPU limits per service to prevent CPU contention
- Use `--cpuset-cpus` to pin critical services to specific cores
- Ensure adequate ventilation: open case or case with ventilation holes
- Consider underclocking if passive cooling required (at cost of performance)
- Implement CPU throttling detection: `vcgencmd get_throttled` in monitoring
- Use Docker resource constraints: `deploy.resources.limits.cpus`

**Warning signs:**
- `vcgencmd get_throttled` returns non-zero (bit 1 = currently throttled, bit 17 = throttled since boot)
- Temperature above 80°C during normal operation: `vcgencmd measure_temp`
- Container CPU usage shows spikes but actual work isn't proportional
- Health check timeouts increase during high load
- System becomes unresponsive under load
- Logs show service timeouts correlating with high CPU temperature
- Performance degrades over time as heat accumulates

**Phase to address:**
Phase 1 (Foundation) - Thermal management must be in place before deploying multiple services. Add load testing in Phase 2 to verify cooling adequacy.

---

### Pitfall 9: DNS Propagation Delays Breaking Let's Encrypt DNS-01 Challenges

**What goes wrong:**
Let's Encrypt DNS-01 challenges fail because ACME client checks for TXT record before DNS propagation completes (typically 20-180 seconds depending on provider), triggering failure counter and potentially rate limiting.

**Why it happens:**
- DNS providers have varying propagation times (20 seconds to 20 minutes)
- Default Traefik delayBeforeCheck (2 seconds) too short for most DNS providers
- Anycast DNS means different servers may have different record states
- High TTL values slow propagation to recursive resolvers
- DNS provider API delays not accounted for
- Let's Encrypt checks from multiple vantage points, some may not see updated records yet

**How to avoid:**
- Configure Traefik `delayBeforeCheck` to 60-120 seconds minimum: `[certificatesResolvers.letsencrypt.acme.dnsChallenge] delayBeforeCheck = "90s"`
- Use DNS provider with fast propagation (Cloudflare: ~20s, some providers: 5+ minutes)
- Test DNS propagation time manually before enabling auto-renewal
- Verify TXT record using multiple DNS checkers (Google 8.8.8.8, Cloudflare 1.1.1.1, authoritative nameserver)
- Reduce TTL values on DNS records (300 seconds or lower)
- Use staging environment first to validate DNS-01 configuration
- Implement DNS provider monitoring to detect propagation delays

**Warning signs:**
- Traefik logs show DNS-01 challenge failures: "no TXT record found"
- Certificate requests fail but running `dig _acme-challenge.domain.com TXT` shows correct record
- Intermittent certificate issuance failures (succeeds on retry)
- Different DNS resolvers return different results for TXT record
- Certificate issuance takes multiple attempts before succeeding
- Authorization failures incrementing towards 5/hour limit

**Phase to address:**
Phase 1 (Foundation) - Must be configured correctly during initial certificate setup. Test with staging before production.

---

### Pitfall 10: No Backup Strategy Leading to Catastrophic Data Loss

**What goes wrong:**
Homelab experiences SD card failure, accidental `docker-compose down -v`, or misconfiguration that destroys data (acme.json, application databases, configuration files). Without backups, complete rebuild required with data loss.

**Why it happens:**
- "It's just a homelab" mentality - treating it as disposable when it contains important data
- Delayed implementation: "I'll add backups later"
- Backup complexity overwhelms quick setup
- SD card failures happen suddenly without warning
- Testing doesn't include restore validation (backups work but restores don't)
- Backups stored on same device as primary data (both lost in hardware failure)

**How to avoid:**
- Implement 3-2-1 backup rule: 3 copies, 2 different media types, 1 offsite
- Use automated backup solution: offen/docker-volume-backup container
- Schedule automatic backups: daily for critical data (acme.json, databases), weekly for volumes
- Store backups on external storage: NAS, external USB drive, cloud (B2, S3)
- Version control infrastructure: store docker-compose.yml, Traefik config in Git repository
- Encrypt offsite backups (Restic, Borg Backup)
- Implement backup rotation: keep 7 daily, 4 weekly, 12 monthly
- CRITICAL: Test restore process monthly - verify backups actually work
- Document recovery procedures in runbook
- Separate configuration (reproducible via IaC) from data (must be backed up)

**Warning signs:**
- No automated backup schedule configured
- Last backup older than 7 days
- Backups never been tested/restored
- Backup stored only on same Pi as primary data
- acme.json, database files not in backup manifest
- No monitoring/alerts for backup job failures
- Backup size hasn't changed despite adding new services (incomplete backup)

**Phase to address:**
Phase 1 (Foundation) - Backup infrastructure must exist before storing any important data. Verify in each subsequent phase that new services are included in backup scope.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using SD card instead of SSD/NVMe | Lower cost ($20 vs $80), no USB/NVMe adapter needed | Frequent corruption, service outages, data loss, full rebuilds every 3-6 months | Acceptable for disposable test environments only, never for persistent services |
| Binding Traefik to 0.0.0.0 (all interfaces) | Simpler configuration, fewer network rules | Services accidentally exposed publicly, security incident risk | Never acceptable - always bind to specific interfaces or use firewall rules |
| Skipping Let's Encrypt staging environment | Faster initial setup (no switching from staging to production certs later) | Rate limit lockout for up to 7 days if misconfigured | Never acceptable - staging validation prevents production rate limits |
| Using Docker socket without proxy | Simpler setup, no additional container | Root access to host if Traefik compromised, wider attack surface | Never acceptable for production, marginally acceptable for isolated test environments |
| Disabling Traefik access logs | Reduced SD card wear, better performance | No visibility into security incidents, difficult troubleshooting | Acceptable if logs shipped to external syslog server, never acceptable otherwise |
| Running without UPS/power loss protection | Lower cost ($0 vs $60+) | Frequent SD card corruption, filesystem damage requiring reinstall | Acceptable only with SSD storage + tested backup/restore process |
| Using basic auth instead of OAuth/SSO for Traefik dashboard | Simple configuration, no external dependencies | Credentials potentially exposed, no audit trail, shared credentials | Acceptable for single-user homelabs with complex passwords and Tailscale-only access |
| Storing secrets in docker-compose.yml | Simple configuration management, easy to version control | Secrets in Git history, exposed in process listings | Never acceptable - use Docker secrets or environment files in .gitignore |
| Not setting resource limits on containers | Simpler configuration, maximum performance when available | Single container can OOM kill entire system, difficult capacity planning | Acceptable for single-service deployments only |

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Let's Encrypt DNS-01 | Using root DNS provider API token with full account access | Create restricted API token with only DNS edit permissions for specific zones |
| Tailscale + Traefik | Running Traefik in bridge network instead of sharing Tailscale network | Use `network_mode: service:tailscale` to share network namespace with Tailscale container |
| Traefik + Docker | Referencing services by localhost instead of Docker service name | Always use service name from docker-compose.yml (e.g., `http://app:3000` not `http://localhost:3000`) |
| Cloudflare DNS | Enabling Cloudflare proxy (orange cloud) for services behind Tailscale | Keep DNS records in DNS-only mode (grey cloud) - proxying breaks Tailscale routing |
| Docker Compose networks | Not specifying network in Traefik labels when container on multiple networks | Add `traefik.docker.network=network_name` label explicitly |
| Tailscale ACLs | Allowing all traffic instead of implementing least-privilege rules | Define specific ACL rules per service: `{"action": "accept", "src": ["group:admins"], "dst": ["tag:homelab:*"]}` |
| Docker volumes | Using bind mounts to SD card for critical data | Use named volumes managed by Docker: `volumes: acme_data:` with external storage driver |
| DNS provider APIs | Hardcoding DNS provider credentials in Traefik static config | Use environment variables or Docker secrets: `DNS_PROVIDER_API_KEY_FILE=/run/secrets/dns_key` |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Running all services without CPU/memory limits | Initial deployment works fine | Set explicit resource limits: `deploy.resources.{limits,reservations}` | 5+ containers, or 1-2 memory-intensive containers (databases) |
| Using overlay2 storage driver on SD card | Fast initial performance | Use external SSD with fstrim, or consider btrfs/zfs on external storage | 10+ GB of container data, frequent layer changes |
| Bridge networking for all containers | Simple configuration, works initially | Use custom bridge networks with network isolation per service group | 10+ containers causing network contention |
| No Docker log rotation | Logs work initially | Configure log driver with size limits: `--log-opt max-size=10m max-file=3` | After 1-2 weeks, logs fill SD card causing failures |
| Single Traefik instance handling all traffic | Simple architecture, low resource use | Consider dedicated Traefik instances for public vs. private if needed | 20+ services or high-traffic services (media streaming) |
| Synchronous Docker Compose operations | Fast deployments with 2-3 services | Use health checks and depends_on to parallelize startup | 8+ services with dependencies causing slow cascading startup |
| No reverse proxy connection limits | All requests processed | Configure Traefik rate limiting: `rateLimit.average`, `inFlightReq.amount` | Public-facing services receiving bot traffic |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Exposing Traefik dashboard without authentication | Full visibility of all routes, backends, and configuration to internet | Always require authentication: use basicAuth middleware minimum, forwardAuth with SSO preferred |
| Using Tailscale without ACLs | Any device on tailnet can access any service | Implement least-privilege ACLs: group users by role, tag services by sensitivity |
| Mounting Docker socket read-write | Container escape = host root access | Mount read-only (`:ro`) and use Docker socket proxy (tecnativa/docker-socket-proxy) |
| Storing Let's Encrypt account key in Git | Anyone with repo access can issue certificates for your domains | Store acme.json outside Git, use .gitignore, encrypt backups |
| Not enabling Tailscale Lock | Compromised auth allows unauthorized nodes | Enable Tailnet Lock for cryptographic node authorization |
| Using default passwords for services | Dictionary attacks succeed immediately | Generate random passwords, store in password manager, use Docker secrets |
| Running containers as root | Privilege escalation from container vulnerability | Use USER directive in Dockerfile, or `user: 1000:1000` in compose |
| Exposing Docker API port (2375/2376) | Remote code execution as root | Never expose Docker API, use SSH tunneling if remote access needed |
| No firewall rules on Raspberry Pi | All ports accessible from LAN | Use ufw to allow only necessary ports: 22 (SSH), Tailscale, deny all else |
| Traefik ACME storage permissions too permissive | Anyone on system can steal certificates and keys | chmod 600 acme.json, owned by Traefik process user only |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Traefik routing:** Container responds to requests — verify service ONLY accessible via intended entry point (Tailscale vs public), test from outside Tailscale network
- [ ] **Let's Encrypt certificates:** Certificate issued successfully — verify renewal works (force renewal test), acme.json persisted on reboot, staging certificate removed before production
- [ ] **Docker volumes:** Data persists across container recreates — verify volume on external storage not SD card, test `docker-compose down && docker-compose up` restores data
- [ ] **Tailscale access:** Can reach service via Tailscale hostname — verify ACLs restrict access to authorized users only, test from different Tailscale user account
- [ ] **Backup system:** Backup job runs successfully — verify restore actually works (test on separate system), offsite copy exists, backup includes all critical data (acme.json, databases, config)
- [ ] **Monitoring:** Dashboard shows green status — verify alerts actually fire (test by stopping service), alert routing to notification channel works (test send)
- [ ] **Resource limits:** Containers start successfully — verify limits prevent OOM under load (stress test), limits match actual usage patterns
- [ ] **High availability:** Service accessible — verify graceful degradation when dependency fails, health checks detect failures, automatic restart works
- [ ] **Security hardening:** HTTPS works — verify HTTP redirects to HTTPS, certificate valid (not self-signed), Tailscale-only services reject public requests, dashboard requires authentication

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Hit Let's Encrypt rate limit | MEDIUM (7 day wait) | 1. Switch to staging certificates for testing 2. Wait for rate limit window to expire (check exact time via LE API) 3. If urgent, use different domain or subdomain 4. Consider ZeroSSL as alternative CA |
| SD card corrupted | HIGH (4-8 hours rebuild) | 1. Boot from fresh SD card or migrate to SSD 2. Restore docker-compose.yml from Git 3. Restore volumes from backup 4. Restore acme.json from backup 5. Restart services and verify |
| Docker socket compromised | HIGH (assume full compromise) | 1. Disconnect from network immediately 2. Audit all containers for backdoors 3. Check host for persistence mechanisms 4. Rebuild from known-good backup 5. Rotate all credentials 6. Review logs for IOCs |
| Traefik exposed services publicly | MEDIUM (2-4 hours) | 1. Immediately stop Traefik container 2. Audit all router configurations for entryPoint settings 3. Add explicit Tailscale entryPoint to all private services 4. Test routing from outside Tailscale before restart 5. Check logs for unauthorized access |
| Lost Tailscale state | LOW (15-30 minutes) | 1. Remove old node from Tailscale admin console 2. Generate new auth key (ephemeral or reusable) 3. Recreate Tailscale container with persistent volume 4. Re-authenticate using new key 5. Verify connectivity |
| ARM64 compatibility issue | LOW (1-2 hours) | 1. Search for official ARM64 image variant on Docker Hub 2. If unavailable, find arm64 fork or community image 3. Last resort: build from source using buildx with --platform linux/arm64 4. Test thoroughly before deploying |
| DNS propagation timeout | LOW (30 minutes) | 1. Increase delayBeforeCheck in Traefik config to 120s 2. Force certificate renewal with longer delay 3. Verify DNS provider API credentials 4. Test TXT record propagation manually using dig 5. Consider switching DNS provider if consistently slow |
| Thermal throttling | MEDIUM (2-4 hours) | 1. Immediate: reduce Docker container CPU limits 2. Install active cooling (fan + heatsink) - requires Pi shutdown 3. Improve case ventilation 4. Monitor temperature after changes 5. Consider underclocking if cooling insufficient |
| Backup restore fails | HIGH (depends on data loss) | 1. Verify backup file integrity (checksum) 2. Test restore to temporary location 3. Check backup includes all necessary files 4. If partial recovery possible, restore what you can 5. Rebuild from scratch if total loss 6. Improve backup testing going forward |
| Traefik wrong network | LOW (15 minutes) | 1. Run `docker inspect <container>` to see actual network names 2. Add `traefik.docker.network=correct_network_name` label 3. Ensure Traefik container connected to same network 4. Restart Traefik to reload config 5. Verify with `docker exec traefik ping service-name` |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Accidental public exposure | Phase 1 (Foundation) | Test from external IP: `curl -I http://public-ip` returns nothing, Tailscale-only test succeeds |
| Let's Encrypt rate limits | Phase 1 (Foundation) | Verify staging certificates work, check acme.json persists across restarts, manual renewal succeeds |
| Docker socket exposure | Phase 1 (Foundation) | Verify socket mounted `:ro`, security_opt includes no-new-privileges, socket proxy configured if used |
| SD card corruption | Phase 1 (Foundation) | Verify /var/lib/docker on external storage, Docker volumes use named volumes, test I/O to external storage |
| Traefik network misconfiguration | Phase 1 (Foundation), verify each service phase | Test service accessible via Traefik, verify Traefik can ping service name, check correct network in labels |
| Tailscale state loss | Phase 1 (Foundation) | Restart Tailscale container, verify state persists, check volume mount configuration |
| ARM64 compatibility | Phase 1 (Foundation), verify each service phase | Inspect image architecture: `docker image inspect image:tag \| grep Architecture`, verify no exec format errors |
| Thermal throttling | Phase 1 (Foundation) | Monitor temperature under load: `vcgencmd measure_temp`, check throttle status: `vcgencmd get_throttled` |
| DNS propagation delays | Phase 1 (Foundation) | Time DNS propagation manually: `watch -n 5 dig TXT _acme-challenge.domain.com`, verify delayBeforeCheck sufficient |
| No backup strategy | Phase 1 (Foundation) | Perform test restore on separate system, verify all critical data included, check offsite backup exists |

## Sources

### Security & CVEs
- [Traefik Security Update CVE-2026-22045 (Jan 2026)](https://community.traefik.io/t/new-security-update-for-traefik-2-11-2-11-35-and-3-6-3-6-7/29579)
- [Docker Socket Security Risk Discussion](https://github.com/traefik/traefik/issues/4174)
- [Tailscale Security Best Practices](https://tailscale.com/kb/1196/security-hardening)
- [Traefik TLS Verification Bug (eSecurity Planet)](https://www.esecurityplanet.com/cloud-security/news-tls-disabled-traefik-bug/)
- [Homelab Accidental Exposure Mistakes (XDA Developers)](https://www.xda-developers.com/4-homelab-mistakes-ill-never-make-again-in-2026/)

### Infrastructure & Performance
- [Raspberry Pi Storage Reliability Issues](https://linuxblog.io/raspberry-pi-storage-reliability/)
- [SD Card Corruption on Raspberry Pi (Hackaday)](https://hackaday.com/2022/03/09/raspberry-pi-and-the-story-of-sd-card-corruption/)
- [Raspberry Pi Thermal Throttling Guide (Sunfounder)](https://www.sunfounder.com/blogs/news/raspberry-pi-temperature-guide-how-to-check-throttling-limits-cooling-tips)
- [Docker Performance on Edge Devices (arXiv Research)](https://arxiv.org/html/2505.02082v2)
- [Raspberry Pi Power Supply Issues (Seeed Studio)](https://www.seeedstudio.com/blog/2025/12/01/raspberry-pi-power-supply-guide/)

### Docker & Traefik Configuration
- [Docker Networks and Nginx Reverse Proxy Pitfalls](https://www.heyjordn.com/docker-networks-and-nginx-proxy-pitfalls)
- [Traefik Docker Provider Documentation](https://doc.traefik.io/traefik/providers/docker/)
- [Docker Compose Volume Permissions](https://forums.docker.com/t/bind-mount-permissions/146262)
- [Raspberry Pi ARM64 Docker Compatibility](https://github.com/iv-org/invidious/issues/4786)
- [Docker Desktop on Raspberry Pi 5 Regression](https://github.com/docker/desktop-linux/issues/306)

### Let's Encrypt & Certificates
- [Let's Encrypt Rate Limits](https://letsencrypt.org/docs/rate-limits/)
- [Let's Encrypt DNS-01 Challenge Types](https://letsencrypt.org/docs/challenge-types/)
- [Traefik ACME Certificate Storage](https://doc.traefik.io/traefik/https/acme/)
- [DNS-01 Propagation Challenges (IPng Networks)](https://ipng.ch/s/articles/2023/03/24/case-study-lets-encrypt-dns-01/)

### Tailscale Integration
- [Traefik-Tailscale Integration Guide](https://traefik.io/blog/exploring-the-tailscale-traefik-proxy-integration)
- [Securely Exposing Services with Traefik and Tailscale](https://www.robert-jensen.dk/posts/2025/securely-exposing-services-with-traefik-and-tailscale/)
- [Tailscale Troubleshooting Guide](https://tailscale.com/kb/1023/troubleshooting)

### Backup & Disaster Recovery
- [Ultimate Home Lab Backup Strategy 2025](https://www.virtualizationhowto.com/2025/10/ultimate-home-lab-backup-strategy-2025-edition/)
- [Best Way to Backup Docker Containers](https://www.virtualizationhowto.com/2024/11/best-way-to-backup-docker-containers-volumes-and-home-server/)
- [Docker Volume Backup Tool](https://nicholaswilde.io/homelab/tools/docker-volume-backup/)
- [Homelab Disaster Recovery](https://blog.leechpepin.com/posts/longhorn-recovery/)

---
*Pitfalls research for: RagnaLab Homelab Infrastructure*
*Researched: 2026-01-16*
