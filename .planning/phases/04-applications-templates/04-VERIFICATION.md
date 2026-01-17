---
phase: 04-applications-templates
verified: 2026-01-17T09:30:00Z
status: passed
score: 5/5 must-haves verified
human_verification:
  - test: "Access Homepage dashboard"
    expected: "Dark theme dashboard with Infrastructure group (Traefik, Uptime Kuma with widgets) and Apps group (Vaultwarden)"
    why_human: "Visual layout and widget functionality cannot be verified programmatically"
  - test: "Store a password in Vaultwarden"
    expected: "User can register (via admin invite), log in, create a vault entry, and retrieve it"
    why_human: "End-to-end user flow with browser extension or web vault"
  - test: "Vaultwarden admin panel access"
    expected: "Admin panel at /admin accepts password and shows settings"
    why_human: "Interactive authentication with hashed token"
---

# Phase 4: Applications & Templates Verification Report

**Phase Goal:** Core applications deployed with modular structure and dead-simple process for adding new apps
**Verified:** 2026-01-17T09:30:00Z
**Status:** passed
**Re-verification:** No - initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can access Homepage at home.ragnalab.xyz | VERIFIED | `apps/homepage/docker-compose.yml` exists with correct Traefik labels (line 23: `Host(\`home.ragnalab.xyz\`)`) |
| 2 | User can access Vaultwarden at vault.ragnalab.xyz | VERIFIED | `apps/vaultwarden/docker-compose.yml` exists with Traefik labels (line 32: `Host(\`vault.ragnalab.xyz\`)`) |
| 3 | Vaultwarden data backs up automatically | VERIFIED | `apps/backup/docker-compose.yml` includes `vaultwarden-data:/backup/vaultwarden:ro` (line 30) and external volume reference (lines 51-53) |
| 4 | User can deploy new app via template | VERIFIED | `apps/_template/docker-compose.yml` (60 lines) and `apps/_template/README.md` (63 lines) provide complete boilerplate with TODO markers |
| 5 | New apps auto-appear in routing and dashboard | VERIFIED | Template includes Traefik labels (lines 25-31) and Homepage labels with `homepage.server=my-docker` (line 38) |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `apps/homepage/docker-compose.yml` | Homepage container config | EXISTS + SUBSTANTIVE (44 lines) | Contains `ghcr.io/gethomepage/homepage`, Traefik labels, proxy network |
| `apps/homepage/config/settings.yaml` | Theme and layout settings | EXISTS + SUBSTANTIVE (44 lines) | Contains `title: RagnaLab`, dark theme, layout groups |
| `apps/homepage/config/docker.yaml` | Docker socket config | EXISTS + SUBSTANTIVE (7 lines) | Contains `socket: /var/run/docker.sock` |
| `apps/homepage/config/services.yaml` | Service discovery docs | EXISTS + SUBSTANTIVE (20 lines) | Explains Docker label discovery |
| `apps/homepage/config/bookmarks.yaml` | External links | EXISTS + SUBSTANTIVE (16 lines) | Contains Cloudflare, Tailscale, GitHub |
| `apps/homepage/config/widgets.yaml` | Dashboard widgets | EXISTS + SUBSTANTIVE (46 lines) | DateTime, weather, system resources, search |
| `apps/vaultwarden/docker-compose.yml` | Vaultwarden container | EXISTS + SUBSTANTIVE (65 lines) | `vaultwarden/server`, security settings, backup label |
| `apps/vaultwarden/.env.example` | Secrets template | EXISTS + SUBSTANTIVE (21 lines) | Token generation instructions |
| `apps/vaultwarden/.gitignore` | Exclude secrets | EXISTS (5 bytes) | Contains `.env` |
| `apps/backup/docker-compose.yml` | Backup with Vaultwarden volume | EXISTS + SUBSTANTIVE (54 lines) | External volume `vaultwarden_vaultwarden-data` |
| `apps/_template/docker-compose.yml` | App boilerplate | EXISTS + SUBSTANTIVE (60 lines) | Traefik + Homepage labels with TODOs |
| `apps/_template/README.md` | Template instructions | EXISTS + SUBSTANTIVE (63 lines) | Checklist and common ports reference |
| `proxy/docker-compose.yml` | Traefik with Homepage labels | EXISTS + WIRED | Homepage widget labels at lines 93-100 |
| `apps/uptime-kuma/docker-compose.yml` | Uptime Kuma with Homepage labels | EXISTS + WIRED | Homepage widget labels at lines 24-33 |
| `INSTALL.md` | Phase 4 documentation | EXISTS + WIRED (505 lines) | Sections 12-14 cover Homepage, Vaultwarden, template |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `apps/homepage/docker-compose.yml` | Traefik | `traefik.http.routers.homepage` labels | WIRED | Lines 22-28, rule for home.ragnalab.xyz |
| `apps/homepage/docker-compose.yml` | proxy network | external network declaration | WIRED | Lines 42-44: `proxy: external: true` |
| `apps/vaultwarden/docker-compose.yml` | Traefik | `traefik.http.routers.vaultwarden` labels | WIRED | Lines 30-37 |
| `apps/vaultwarden/docker-compose.yml` | Homepage | `homepage.*` labels | WIRED | Lines 39-44 with `homepage.server=my-docker` |
| `apps/vaultwarden/docker-compose.yml` | Backup | `docker-volume-backup.stop-during-backup` label | WIRED | Line 46 |
| `apps/backup/docker-compose.yml` | Vaultwarden volume | external volume mount | WIRED | Lines 30, 51-53 |
| `apps/_template/docker-compose.yml` | Traefik | placeholder labels | WIRED | Lines 25-31 with TODO markers |
| `apps/_template/docker-compose.yml` | Homepage | placeholder labels | WIRED | Lines 33-38 with `homepage.server=my-docker` |
| `proxy/docker-compose.yml` | Homepage | `homepage.widget.type=traefik` | WIRED | Lines 93-100 |
| `apps/uptime-kuma/docker-compose.yml` | Homepage | `homepage.widget.type=uptimekuma` | WIRED | Lines 24-33 |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| APP-01: Homepage dashboard | SATISFIED | Artifact exists and wired |
| APP-02: Vaultwarden deployment | SATISFIED | Artifact exists with security config |
| APP-03: Vaultwarden backup | SATISFIED | Volume in backup service |
| APP-04: App template | SATISFIED | Template with complete boilerplate |
| DX-01: Auto Traefik routing | SATISFIED | Labels in template |
| DX-02: Auto Homepage discovery | SATISFIED | `homepage.server=my-docker` pattern |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `apps/_template/docker-compose.yml` | 13-40 | TODO markers | INFO | Intentional - template for user customization |

No blocking anti-patterns found. TODOs in template are by design.

### Human Verification Required

The following items require human testing:

### 1. Homepage Dashboard Visual Verification

**Test:** Open https://home.ragnalab.xyz in browser
**Expected:**
- Dark theme with "RagnaLab" title
- Infrastructure group shows Traefik (with route/service counts) and Uptime Kuma (with monitoring status)
- Apps group shows Vaultwarden
- Bookmarks section shows external links
- Widgets display datetime, weather, and system resources
**Why human:** Visual layout, widget data, and theme cannot be verified programmatically

### 2. Vaultwarden Admin Panel Access

**Test:** Open https://vault.ragnalab.xyz/admin, enter admin password
**Expected:** Admin panel loads showing Users, Diagnostics, and other admin sections
**Why human:** Interactive authentication with password (not hash)

### 3. Vaultwarden Password Storage Flow

**Test:** Create account (via admin invite), log in to vault, add a login entry, retrieve it
**Expected:** Entry saved and retrievable with all fields (username, password, URL)
**Why human:** Full user flow with browser or mobile client

### 4. New App Deployment Flow

**Test:** Copy template, edit TODOs, run `docker compose up -d`
**Expected:** New app appears in Traefik dashboard and Homepage within 30 seconds
**Why human:** Full deployment flow verification

## Summary

Phase 4 goal achieved. All artifacts exist, are substantive, and are properly wired:

1. **Homepage** deployed at home.ragnalab.xyz with Docker label auto-discovery
2. **Vaultwarden** deployed at vault.ragnalab.xyz with backup integration
3. **App template** ready at apps/_template/ with complete boilerplate
4. **Infrastructure services** have Homepage labels with widgets
5. **INSTALL.md** updated with Phase 4 setup instructions

The modular structure enables "dead-simple" app deployment:
```bash
cp -r apps/_template apps/newapp
# Edit docker-compose.yml, replace TODOs
docker compose -f apps/newapp/docker-compose.yml up -d
```

---

*Verified: 2026-01-17T09:30:00Z*
*Verifier: Claude (gsd-verifier)*
