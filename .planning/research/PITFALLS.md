# Pitfalls Research: Authelia SSO Deployment

**Domain:** Homelab SSO with Authelia + Traefik
**Researched:** 2026-01-24
**Confidence:** HIGH (verified against official Authelia documentation and community issues)

## Summary

Adding Authelia SSO to an existing 22-service homelab has several critical failure modes: session cookie misconfiguration causing infinite login loops, access control rule ordering that locks you out of everything, and mobile/API app breakage when services are protected. The VPN-only context simplifies some concerns (no public exposure) but introduces others (recovery access when VPN is down). The most catastrophic mistake is deploying to all services at once without a rollback path.

---

## Critical Pitfalls

| Pitfall | Warning Signs | Prevention | Phase | Severity |
|---------|---------------|------------|-------|----------|
| **Applying forwardAuth to Authelia itself** | Infinite redirect, Authelia login page never loads | Ensure Authelia router has NO auth middleware | Phase 1 (Deploy) | CRITICAL |
| **Session cookie domain mismatch** | Login succeeds, then redirects back to login | Cookie domain must be `.ragnalab.xyz` (matches all subdomains) | Phase 1 (Deploy) | CRITICAL |
| **Access control rule ordering** | Wrong services accessible, or everything blocked | Bypass rules FIRST, then specific rules, default `deny` last | Phase 2 (Access Control) | CRITICAL |
| **Big-bang rollout** | All 22 services break simultaneously, no fallback | Deploy to 1 test service first, verify, then expand gradually | Phase 1 (Deploy) | CRITICAL |
| **No recovery/bypass path** | Locked out of all services after misconfiguration | Keep at least one service unprotected OR SSH bypass rule | Phase 1 (Deploy) | CRITICAL |
| **X-Forwarded headers overwritten** | Network-based bypass rules fail, wrong IP detected | Verify Traefik passes correct headers to Authelia `/api/authz` | Phase 1 (Deploy) | CRITICAL |

---

## Traefik-Specific Issues

### Middleware Must NOT Apply to Authelia

**What goes wrong:** Authelia itself gets the forwardAuth middleware applied, creating an infinite loop where Authelia asks Authelia to authenticate the login page.

**Warning signs:**
- Browser shows "too many redirects"
- Authelia login page never renders
- Traefik logs show repeated requests to `/api/authz`

**Prevention:**
```yaml
# WRONG: Don't apply auth middleware to Authelia
traefik.http.routers.authelia.middlewares=authelia@docker

# CORRECT: Authelia router has NO auth middleware
traefik.http.routers.authelia.middlewares=  # empty or only rate-limiting
```

**Phase:** Phase 1 (Initial Deployment)

---

### forwardAuth vs authelia-forwardauth Middleware

**What goes wrong:** Using Traefik's generic `forwardAuth` middleware instead of Authelia's specific endpoint (`/api/authz/forward-auth`).

**Warning signs:**
- Authentication seems to work but headers not passed to backend
- User identity not available to protected services
- Random 403 errors

**Prevention:** Use Authelia's recommended authz endpoint:
```yaml
# Traefik dynamic config
http:
  middlewares:
    authelia:
      forwardAuth:
        address: "http://authelia:9091/api/authz/forward-auth"
        trustForwardHeader: true
        authResponseHeaders:
          - Remote-User
          - Remote-Groups
          - Remote-Email
```

**Phase:** Phase 1 (Initial Deployment)

---

### Middleware Chain Order

**What goes wrong:** When chaining middlewares (e.g., headers + forwardAuth), error responses from forwardAuth don't get the security headers applied.

**Warning signs:**
- Login page missing security headers
- Inconsistent CSP behavior between auth and post-auth

**Prevention:** Accept this limitation or apply headers at Authelia container level. Not critical for VPN-only setup.

**Phase:** Phase 1 (Initial Deployment) - Minor

---

### Traefik v3 forwardAuth Changes

**What goes wrong:** Traefik v3.6+ has different forwardAuth behavior and recent CVE fixes that change opt-in behavior.

**Warning signs:**
- Works in v3.5, breaks after upgrade
- 500 errors with only DEBUG-level logging

**Prevention:**
- Pin Traefik version during SSO rollout
- Check Traefik v3 migration guide before upgrading
- Set Traefik log level to DEBUG during initial deployment for better error visibility

**Phase:** Phase 1 (Initial Deployment)

**Source:** [Traefik forwardAuth middleware changes](https://github.com/traefik/traefik/issues/12234)

---

## Session/Cookie Issues

### Session Cookie Domain Must Match Service Domains

**What goes wrong:** Authelia session cookie domain doesn't cover all protected service subdomains, causing infinite login loops.

**Warning signs:**
- Login appears successful (logs show authentication)
- Immediately redirected back to login page
- Works for some services, not others

**Prevention:**
```yaml
session:
  cookies:
    - domain: 'ragnalab.xyz'  # Covers *.ragnalab.xyz
      authelia_url: 'https://auth.ragnalab.xyz'
      default_redirection_url: 'https://home.ragnalab.xyz'
```

**Phase:** Phase 1 (Initial Deployment)

**Source:** [Authelia Session Configuration](https://www.authelia.com/configuration/session/introduction/)

---

### Authelia Requires HTTPS (No Exceptions)

**What goes wrong:** Trying to run Authelia over HTTP, even for "just testing."

**Warning signs:**
- Authelia refuses to start
- Session cookies not set (browsers block insecure cookies)

**Prevention:** Always use HTTPS. Your Traefik + Let's Encrypt setup already handles this. Do NOT try to bypass for testing.

**Phase:** Phase 1 (Initial Deployment)

**Source:** [Authelia Get Started](https://www.authelia.com/integration/prologue/get-started/)

---

### Single Domain Limitation

**What goes wrong:** Trying to protect services across multiple root domains with one Authelia instance.

**Warning signs:**
- Works for `*.ragnalab.xyz` but not `*.otherdomain.com`

**Prevention:** Not applicable - you only have `ragnalab.xyz`. But if you add another domain later, you need a second Authelia instance.

**Phase:** N/A for current scope

---

## Access Control Issues

### Rule Order Determines Policy (First Match Wins)

**What goes wrong:** More specific rules placed after general rules, causing wrong policy to apply.

**Warning signs:**
- Bypass rules not working
- Everything requires 2FA when only some services should
- `authelia access-control check-policy` shows unexpected rule matching

**Prevention:**
```yaml
access_control:
  default_policy: deny  # MUST be deny for security
  rules:
    # 1. Bypass rules FIRST (most specific)
    - domain: 'jellyfin.ragnalab.xyz'
      resources: ['^/api.*', '^/socket.*']
      policy: bypass

    # 2. Then specific service rules
    - domain: 'sonarr.ragnalab.xyz'
      subject: 'group:powerusers'
      policy: one_factor

    # 3. General rules last
    - domain: '*.ragnalab.xyz'
      subject: 'group:admin'
      policy: two_factor
```

**Debugging:** Use `authelia access-control check-policy` CLI tool to test rules before deploying.

**Phase:** Phase 2 (Access Control Configuration)

**Source:** [Authelia Access Control Rule Guide](https://www.authelia.com/reference/guides/rule-operators/)

---

### Network-Based Bypass Requires Correct Headers

**What goes wrong:** VPN bypass rules don't work because Traefik isn't passing the correct client IP.

**Warning signs:**
- Network bypass rules ignored
- Authelia logs show wrong source IP (Docker internal IP instead of VPN IP)

**Prevention:**
```yaml
# In Traefik static config, ensure:
entryPoints:
  websecure:
    forwardedHeaders:
      trustedIPs:
        - "100.64.0.0/10"  # Tailscale CGNAT range
```

**Phase:** Phase 1 (Initial Deployment)

---

## Passkey/WebAuthn Issues

### Relying Party ID Must Be Domain, Not Full URL

**What goes wrong:** Configuring WebAuthn RP ID as `https://auth.ragnalab.xyz` instead of `ragnalab.xyz`.

**Warning signs:**
- Passkey registration fails
- Browser console shows WebAuthn errors about invalid RP ID
- Passkeys work on one subdomain but not others

**Prevention:**
```yaml
webauthn:
  disable: false
  display_name: 'RagnaLab'
  rp_id: 'ragnalab.xyz'  # Domain only, no protocol or subdomain
```

**Phase:** Phase 3 (Passkey Configuration)

**Source:** [Passkey Best Practices](https://www.hanko.io/blog/the-dos-and-donts-of-integrating-passkeys)

---

### Domain/RP ID Changes Break Existing Passkeys

**What goes wrong:** Changing the WebAuthn RP ID after users have registered passkeys.

**Warning signs:**
- All existing passkeys stop working
- Users must re-register devices

**Prevention:**
- Set RP ID correctly from day one
- Document that RP ID cannot be changed without breaking passkeys
- If domain changes, all users must re-enroll passkeys

**Phase:** Phase 3 (Passkey Configuration)

---

### Device Loss Recovery Path Required

**What goes wrong:** User loses device with passkey, no recovery mechanism configured.

**Warning signs:**
- User locked out completely
- Only option is admin database manipulation

**Prevention:**
- Configure TOTP as backup second factor (user registers both)
- Enable password reset via email notification
- Document admin recovery procedure (delete from `webauthn_devices` table)
- Consider: "Lost your device?" workflow (but this can bypass 2FA if email compromised)

**Phase:** Phase 3 (Passkey Configuration)

**Source:** [Authelia Lost Device Issue](https://github.com/authelia/authelia/issues/3353)

---

### Passkeys Don't Work Cross-Origin

**What goes wrong:** Authelia on `auth.ragnalab.xyz` trying to create passkeys for services on different subdomains.

**Warning signs:**
- Passkey registration works, but authentication fails from some services
- Browser security errors in console

**Prevention:** Your setup should work because all services share the `ragnalab.xyz` root domain and RP ID. Just ensure RP ID is the root domain.

**Phase:** Phase 3 (Passkey Configuration)

---

## Migration Issues (Adding SSO to Existing Services)

### Mobile Apps Break When Services Protected

**What goes wrong:** Jellyfin/Plex mobile apps, LunaSea, nzb360 cannot authenticate through Authelia.

**Warning signs:**
- Apps show "connection refused" or "unauthorized"
- Apps worked before SSO, broken after
- Web interface works fine

**Prevention:** Bypass API endpoints for services with mobile apps:
```yaml
access_control:
  rules:
    # Jellyfin API bypass for mobile apps
    - domain: 'jellyfin.ragnalab.xyz'
      resources:
        - '^/api.*'
        - '^/socket.*'
        - '^/System/Info.*'
        - '^/Users/AuthenticateByName.*'
      policy: bypass

    # Sonarr/Radarr API bypass (for mobile apps using API keys)
    - domain: ['sonarr.ragnalab.xyz', 'radarr.ragnalab.xyz']
      resources: ['^/api.*']
      policy: bypass
```

**Important:** These services have their own authentication (API keys). Bypass is safe because the service authenticates the request.

**Phase:** Phase 2 (Access Control Configuration)

**Source:** [Authelia Securing Apps with Basic Auth](https://www.authelia.com/integration/guides/securing-apps-with-basic-auth/)

---

### Vaultwarden Special Case

**What goes wrong:** Vaultwarden clients (browser extensions, mobile) cannot connect through Authelia.

**Warning signs:**
- Bitwarden apps show "Cannot connect to server"
- Web vault works, apps don't

**Prevention:** Bypass Vaultwarden API and identity endpoints:
```yaml
- domain: 'vault.ragnalab.xyz'
  resources:
    - '^/api([/?].*)?$'
    - '^/notifications([/?].*)?$'
    - '^/identity([/?].*)?$'
  policy: bypass
```

**Note:** Vaultwarden has its own strong authentication. SSO protecting the web vault entrance is optional but API must be bypassed.

**Phase:** Phase 2 (Access Control Configuration)

**Source:** [Vaultwarden Authelia Discussion](https://github.com/dani-garcia/vaultwarden/discussions/3970)

---

### Services With Built-in Auth Conflict

**What goes wrong:** Service requires login, then Authelia also requires login (double authentication).

**Warning signs:**
- Users must log in twice
- Confusing UX

**Prevention per service:**

| Service | Strategy |
|---------|----------|
| **Sonarr/Radarr/Prowlarr** | Set Authentication to "External" (trust proxy headers) |
| **Jellyfin** | Cannot disable auth easily; accept double login OR bypass Authelia |
| **qBittorrent** | Set "Bypass authentication for clients on localhost" and trust Authelia |
| **Uptime Kuma** | Disable built-in auth, rely on Authelia |
| **Homepage** | No auth needed (dashboard is read-only) |
| **Traefik Dashboard** | Currently no auth; add Authelia protection |
| **Pi-hole** | Has its own admin password; accept double login OR bypass |

**Phase:** Phase 4 (Service Integration)

---

### Arr Apps "External" Auth Requires Specific Headers

**What goes wrong:** Setting Arr apps to "External" auth but they don't receive user identity.

**Warning signs:**
- Arr apps show "unauthorized" even after Authelia login
- Logs show "No user found in headers"

**Prevention:** Ensure Authelia middleware passes required headers:
```yaml
authResponseHeaders:
  - Remote-User
  - Remote-Groups
  - Remote-Email
  - Remote-Name
```

And Arr apps configured to read from `Remote-User` header.

**Phase:** Phase 4 (Service Integration)

---

## VPN-Only Considerations

### Recovery When VPN Is Down

**What goes wrong:** VPN service (Tailscale) has issues, you're locked out of everything including the tools to fix it.

**Warning signs:**
- Cannot SSH to Pi (Tailscale down)
- Cannot access any service
- Cannot fix Authelia config

**Prevention:**
1. **Local network bypass:** Configure access control to bypass auth from local network (`192.168.x.x/24`)
2. **SSH not through Traefik:** Ensure SSH access doesn't depend on Authelia (it doesn't by default)
3. **Local console access:** Physical access to Pi for emergency recovery

```yaml
access_control:
  networks:
    - name: local
      networks:
        - '192.168.0.0/16'  # Adjust to your local network
  rules:
    # Emergency local access (no auth required from LAN)
    - domain: '*.ragnalab.xyz'
      networks: [local]
      policy: bypass  # Or one_factor if you want minimal auth
```

**Phase:** Phase 1 (Initial Deployment)

---

### VPN IP Range for Network Rules

**What goes wrong:** Using wrong IP range for Tailscale network in access control rules.

**Warning signs:**
- VPN-based rules don't match
- Authelia logs show unexpected source IPs

**Prevention:** Tailscale uses CGNAT range `100.64.0.0/10`. Your specific Tailnet IPs are in this range.

**Phase:** Phase 1 (Initial Deployment)

---

### No Public Exposure Simplifies Some Concerns

**What helps:**
- No need for rate limiting against internet attacks
- Brute force protection less critical (attackers need VPN access first)
- Can be more permissive with session timeouts

**But still important:**
- Defense in depth (assume VPN could be compromised)
- Still use strong passwords/passkeys
- Still enable 2FA for sensitive services

**Phase:** Overall design consideration

---

## Recovery Scenarios

### Scenario 1: Locked Out Due to Misconfiguration

**Symptoms:** Cannot access any service, Authelia login fails or loops

**Recovery steps:**
1. SSH to Pi directly (doesn't go through Traefik/Authelia)
2. Edit Authelia config: `nano /path/to/authelia/configuration.yml`
3. Set `default_policy: bypass` temporarily
4. Restart Authelia: `docker restart authelia`
5. Fix actual issue
6. Restore `default_policy: deny`

---

### Scenario 2: Lost 2FA Device

**Symptoms:** User can enter password but cannot complete 2FA

**Recovery steps:**
1. Admin connects to Authelia database (SQLite or PostgreSQL)
2. Delete user's TOTP/WebAuthn entries:
   ```sql
   DELETE FROM totp_configurations WHERE username = 'user';
   DELETE FROM webauthn_devices WHERE username = 'user';
   ```
3. User logs in with password only (if one_factor allowed)
4. User re-registers 2FA devices

**Prevention:** Configure backup 2FA method (both TOTP and passkey)

---

### Scenario 3: Authelia Container Won't Start

**Symptoms:** Container crashes on startup, services return 500 errors

**Recovery steps:**
1. Check logs: `docker logs authelia`
2. Common issues:
   - Configuration syntax error (YAML)
   - Missing secrets file
   - Database connection failed
3. Temporarily remove forwardAuth middleware from critical services
4. Fix Authelia config
5. Re-enable middleware

**Prevention:** Validate config before applying: `authelia validate-configuration`

---

### Scenario 4: Database Corrupted

**Symptoms:** Random auth failures, inconsistent state

**Recovery steps:**
1. Stop Authelia
2. Restore database from backup (Backrest)
3. Start Authelia
4. If no backup: delete database, users must re-register 2FA

**Prevention:** Include Authelia data in Backrest backup plan

---

## Raspberry Pi ARM64 Considerations

### Argon2id Password Hashing Performance

**What goes wrong:** Default Argon2id settings too intensive for Pi, causing 3-4 minute login delays.

**Warning signs:**
- Login takes minutes instead of seconds
- Pi CPU pegged at 100% during login
- `top` shows Authelia using excessive resources

**Prevention:** Tune Argon2id for ARM64:
```yaml
authentication_backend:
  file:
    password:
      algorithm: argon2id
      iterations: 1
      memory: 256  # Reduced from default 512
      parallelism: 2  # Reduced from 4
      key_length: 32
      salt_length: 16
```

**Phase:** Phase 1 (Initial Deployment)

**Source:** [Authelia Login Delay Issue](https://github.com/authelia/authelia/issues/1707)

---

### Redis Memory Warnings

**What goes wrong:** Redis (optional session store) complains about memory overcommit on Pi.

**Warning signs:**
- Redis logs: "Memory overcommit must be enabled!"
- Potential auth failures under load

**Prevention:** For single-user homelab, Redis is optional. If using Redis:
```bash
echo 'vm.overcommit_memory = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Phase:** Phase 1 (Initial Deployment) - if using Redis

---

### Pin Docker Image Versions

**What goes wrong:** `latest` tag brings breaking changes, crashes setup.

**Warning signs:**
- Authelia worked yesterday, broken today
- Unexpected configuration errors

**Prevention:**
```yaml
services:
  authelia:
    image: authelia/authelia:4.38.19  # Pin specific version
```

Check release notes before upgrading.

**Phase:** Phase 1 (Initial Deployment)

---

## Phase-Specific Warning Summary

| Phase | Critical Pitfalls | Pre-Phase Checklist |
|-------|-------------------|---------------------|
| **Phase 1: Deploy Authelia** | forwardAuth on Authelia itself, cookie domain, no recovery path | Verify Traefik headers, plan rollback, test on one service |
| **Phase 2: Access Control** | Rule ordering, API bypass for mobile apps | Map all services needing bypass, test with CLI tool |
| **Phase 3: Passkeys** | RP ID configuration, device loss recovery | Set RP ID correctly first time, configure TOTP backup |
| **Phase 4: Service Integration** | Double auth, header passing | Document per-service auth strategy |
| **Phase 5: Production Hardening** | Backup strategy, version pinning | Include Authelia in Backrest, pin versions |

---

## Sources

- [Authelia Traefik Integration](https://www.authelia.com/integration/proxies/traefik/)
- [Authelia Access Control Configuration](https://www.authelia.com/configuration/security/access-control/)
- [Authelia Session Configuration](https://www.authelia.com/configuration/session/introduction/)
- [Authelia Get Started Guide](https://www.authelia.com/integration/prologue/get-started/)
- [Authelia Troubleshooting](https://www.authelia.com/reference/guides/troubleshooting/)
- [Authelia Access Control Check-Policy CLI](https://www.authelia.com/reference/cli/authelia/authelia_access-control_check-policy/)
- [Traefik ForwardAuth Middleware](https://doc.traefik.io/traefik/middlewares/http/forwardauth/)
- [GitHub: Authelia Problems with Traefik](https://github.com/authelia/authelia/discussions/9333)
- [GitHub: Vaultwarden Authelia Bypass](https://github.com/dani-garcia/vaultwarden/discussions/3970)
- [GitHub: Authelia Login Delay Issue](https://github.com/authelia/authelia/issues/1707)
- [GitHub: Authelia Lost Device Feature Request](https://github.com/authelia/authelia/issues/3353)
- [Passkey Best Practices (Hanko)](https://www.hanko.io/blog/the-dos-and-donts-of-integrating-passkeys)
