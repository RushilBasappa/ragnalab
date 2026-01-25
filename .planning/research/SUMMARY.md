# Research Summary: v3.0 SSO & Apps

**Researched:** 2026-01-24
**Domain:** Homelab SSO with Authelia + Traefik
**Overall Confidence:** HIGH

## Executive Summary

Authelia v4.39.x is the right choice for RagnaLab SSO: it's lightweight (~30MB RAM), supports passkeys/WebAuthn, and has native ARM64 images. Integration with existing Traefik v3.6 uses forwardAuth middleware—requests are intercepted, delegated to Authelia for auth decisions, then forwarded with user identity headers.

**Critical insight:** Apps fall into four integration categories with different complexity levels. The safest deployment strategy is incremental rollout—deploy Authelia, test on one service, then expand gradually. The biggest risk is "big-bang" rollout that breaks all 22 services at once.

**Passkeys are straightforward** but the RP ID must be set correctly from day one (`ragnalab.xyz`, not `auth.ragnalab.xyz`)—it cannot be changed without breaking existing passkeys.

## Key Findings by Dimension

### Stack
- **Authelia v4.39.14**: Passkey support, ARM64 images, lightweight
- **No Redis needed**: In-memory sessions acceptable for 4 users, SQLite for persistent storage
- **Traefik integration**: ForwardAuth middleware, file-based definition recommended
- **Pin versions**: Avoid `latest` tag, v4.39.15 has LDAP regression

### Features
- **Four integration categories**: ForwardAuth-only, External auth mode (*arr), trusted headers (Paperless), OIDC (Jellyseerr)
- **Critical bypasses needed**: Plex (breaks client apps), API endpoints (mobile apps), Vaultwarden API
- **Complexity gradient**: Homepage/Dozzle (trivial) → *arr apps (config edit) → Jellyfin (plugin required)
- **User groups map cleanly**: Admin (two_factor), Power/Family/Guests (one_factor with different domains)

### Architecture
- **Request flow**: Traefik → ForwardAuth subrequest → Authelia → 200/401/403 → Backend
- **Session cookie**: Domain must be `ragnalab.xyz` (parent) for SSO across all subdomains
- **Build order**: Redis → Authelia config → Authelia container → Test one service → ACL rules → Full rollout

### Pitfalls
| Pitfall | Severity | Prevention |
|---------|----------|------------|
| ForwardAuth on Authelia itself | CRITICAL | Authelia router has NO auth middleware |
| Cookie domain mismatch | CRITICAL | Use `.ragnalab.xyz`, not `auth.ragnalab.xyz` |
| Big-bang rollout | CRITICAL | Deploy to 1 service first, expand gradually |
| Rule ordering wrong | CRITICAL | Bypass rules FIRST, default deny LAST |
| Mobile apps break | HIGH | Bypass API endpoints for Jellyfin, *arr, Vaultwarden |
| RP ID change | HIGH | Set correctly day one, cannot change later |
| Argon2id too slow | MEDIUM | Tune for ARM64: memory=256, parallelism=2 |

## Confidence Assessment

| Area | Level | Notes |
|------|-------|-------|
| Authelia + Traefik integration | HIGH | Official docs + verified config patterns |
| ARM64 compatibility | HIGH | Docker Hub confirms multi-arch |
| *Arr external auth | HIGH | Servarr wiki + community verified |
| Passkey configuration | MEDIUM | Feature is new (May 2025), less community validation |
| Jellyfin SSO plugin | MEDIUM | Works but requires plugin + account linking |
| Pi-hole v6 auth | LOW | Known reverse proxy issues |

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 8: Authelia SSO Foundation
**Goal:** Deploy Authelia with Traefik integration, test on single service

- Deploy Authelia v4.39.14 container
- Configure session cookies for `ragnalab.xyz`
- Add forwardAuth middleware to Traefik
- Test protection on Traefik dashboard (one service)
- Configure user/group file with 4 access levels

**Addresses:** Stack setup, critical pitfall prevention (incremental rollout)
**Avoids:** Big-bang deployment, cookie domain mismatch
**Uses:** Authelia v4.39.14, SQLite, file-based middleware

### Phase 9: Access Control & App Integration
**Goal:** Configure ACL rules, integrate existing apps

- Configure bypass rules for API endpoints (mobile apps)
- Set up Plex bypass (critical)
- Configure *arr apps with External auth mode
- Roll out protection to remaining services gradually
- Configure passkey/WebAuthn authentication

**Implements:** Access control rules, app integration
**Avoids:** Mobile app breakage, double authentication
**Uses:** Authelia ACL, *arr External auth mode

### Phase 10: New App Deployment
**Goal:** Deploy Paperless-ngx, Dozzle, IT-Tools with SSO from day one

- Deploy Paperless-ngx with trusted headers
- Deploy Dozzle with forward-proxy auth
- Deploy IT-Tools with forwardAuth
- Add to Homepage dashboard
- Configure Autokuma monitors

**Implements:** New app expansion (SSO-protected from start)
**Uses:** Trusted header SSO, forwardAuth middleware

### Phase ordering rationale

1. **Authelia must be stable before protecting services** (Phase 8 first)
2. **ACL rules must be correct before full rollout** (Phase 9 sequential)
3. **New apps can be parallel** with SSO integration (Phase 10 after SSO stable)

### Research flags for phases

- **Phase 8**: Low risk - standard Authelia deployment patterns
- **Phase 9**: Medium risk - test API bypass rules thoroughly, have rollback plan
- **Phase 10**: Low risk - new apps, no migration concerns

### Open questions (resolve during implementation)

1. SMTP provider for password reset emails (or disable password reset, passkey-only)
2. Exact Tailscale IP range for network-based rules
3. Per-service bypass decisions (which services keep native auth + Authelia layer)
4. Jellyfin SSO plugin: verify mobile app compatibility before committing

## Files Created

| File | Purpose |
|------|---------|
| `STACK.md` | Technology stack with versions, rationale, configuration approach |
| `FEATURES.md` | Authelia features, app integration matrix, complexity assessment |
| `ARCHITECTURE.md` | Request flows, session handling, build order |
| `PITFALLS.md` | Common mistakes with prevention strategies |
| `SUMMARY.md` | This file - executive summary with roadmap implications |

---

## Next Step

`/gsd:define-requirements` — Define detailed requirements for v3.0 phases

<sub>`/clear` first → fresh context window</sub>
