# Requirements: RagnaLab v3.0 SSO & Apps

**Defined:** 2026-01-25
**Core Value:** Unified single sign-on with passkey support and per-user access control, plus lightweight app expansion.

## v3.0 Requirements

Requirements for v3.0 milestone. Each maps to roadmap phases.

### SSO Foundation

- [ ] **SSO-01**: User can authenticate via passkey/fingerprint (WebAuthn)
- [ ] **SSO-02**: User can authenticate via username/password as fallback
- [ ] **SSO-03**: Admin users are configured in Authelia user file
- [ ] **SSO-04**: Power users group exists with media management access
- [ ] **SSO-05**: Family group exists with media consumption access
- [ ] **SSO-06**: Guests group exists with view-only Jellyfin access
- [ ] **SSO-07**: Session persists across ragnalab.xyz subdomains
- [ ] **SSO-08**: Authelia cookie domain set to `.ragnalab.xyz`

### Access Control

- [ ] **ACL-01**: Admin services (Traefik, Backrest, Pi-hole, Dozzle) require two-factor auth
- [ ] **ACL-02**: Power user services (*arr apps, qBittorrent) require one-factor auth
- [ ] **ACL-03**: Family services (Jellyfin, Jellyseerr) require one-factor auth
- [ ] **ACL-04**: API endpoints bypass auth for mobile apps and widgets
- [ ] **ACL-05**: Plex bypasses auth completely (client app compatibility)
- [ ] **ACL-06**: Default policy is deny (explicit allow required)

### Existing App Integration

- [ ] **APP-01**: Homepage protected via Authelia middleware
- [ ] **APP-02**: Traefik dashboard protected via Authelia middleware
- [ ] **APP-03**: Glances protected (no password mode + middleware)
- [ ] **APP-04**: Uptime Kuma protected (disable built-in auth + middleware)
- [ ] **APP-05**: Backrest protected (disable built-in auth + middleware)
- [ ] **APP-06**: Sonarr configured with External auth mode
- [ ] **APP-07**: Radarr configured with External auth mode
- [ ] **APP-08**: Prowlarr configured with External auth mode
- [ ] **APP-09**: qBittorrent configured with IP whitelist + reverse proxy setting

### New App Deployment

- [ ] **NEW-01**: Paperless-ngx deployed at docs.ragnalab.xyz with trusted header SSO
- [ ] **NEW-02**: Dozzle deployed at logs.ragnalab.xyz with forward-proxy auth
- [ ] **NEW-03**: IT-Tools deployed at tools.ragnalab.xyz with forwardAuth
- [ ] **NEW-04**: New apps added to Homepage dashboard
- [ ] **NEW-05**: New apps have Autokuma monitoring labels

### Operations

- [ ] **OPS-01**: Authelia config included in Backrest backup
- [ ] **OPS-02**: User management documented (add/remove users)
- [ ] **OPS-03**: Authelia has Autokuma monitoring

## v4.0 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Complex Integrations

- **CMPLX-01**: Jellyfin SSO plugin (requires plugin install + account linking)
- **CMPLX-02**: Jellyseerr OIDC (preview branch stability unknown)
- **CMPLX-03**: Vaultwarden OIDC (mobile app 2FA issues)
- **CMPLX-04**: Pi-hole auth integration (v6 reverse proxy issues)

### Additional Apps

- **APPS-01**: Immich photo backup
- **APPS-02**: Tandoor recipes
- **APPS-03**: ntfy notifications
- **APPS-04**: Stirling-PDF tools
- **APPS-05**: Additional apps from BACKLOG.md

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| LDAP/Active Directory | Overkill for 4 users, file-based simpler |
| OAuth providers (Google, GitHub) | Users are known family, not public |
| Public internet exposure | Tailscale-only by design |
| TOTP as backup MFA | Passkeys sufficient, simplify setup |
| Bazarr External auth | Keep native auth, SSO layer optional |

## Traceability

Which phases cover which requirements.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SSO-01 | Phase 9 | Pending |
| SSO-02 | Phase 9 | Pending |
| SSO-03 | Phase 9 | Pending |
| SSO-04 | Phase 9 | Pending |
| SSO-05 | Phase 9 | Pending |
| SSO-06 | Phase 9 | Pending |
| SSO-07 | Phase 9 | Pending |
| SSO-08 | Phase 9 | Pending |
| ACL-01 | Phase 9 | Pending |
| ACL-02 | Phase 9 | Pending |
| ACL-03 | Phase 9 | Pending |
| ACL-04 | Phase 9 | Pending |
| ACL-05 | Phase 9 | Pending |
| ACL-06 | Phase 9 | Pending |
| OPS-01 | Phase 9 | Pending |
| OPS-02 | Phase 9 | Pending |
| OPS-03 | Phase 9 | Pending |
| APP-01 | Phase 10 | Pending |
| APP-02 | Phase 10 | Pending |
| APP-03 | Phase 10 | Pending |
| APP-04 | Phase 10 | Pending |
| APP-05 | Phase 10 | Pending |
| APP-06 | Phase 10 | Pending |
| APP-07 | Phase 10 | Pending |
| APP-08 | Phase 10 | Pending |
| APP-09 | Phase 10 | Pending |
| NEW-01 | Phase 11 | Pending |
| NEW-02 | Phase 11 | Pending |
| NEW-03 | Phase 11 | Pending |
| NEW-04 | Phase 11 | Pending |
| NEW-05 | Phase 11 | Pending |

**Coverage:**
- v3.0 requirements: 31 total
- Mapped to phases: 31
- Unmapped: 0 ✓

---
*Requirements defined: 2026-01-25*
*Last updated: 2026-01-25 after roadmap creation*
