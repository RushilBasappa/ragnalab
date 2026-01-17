# Phase 4: Applications & Templates - Context

**Gathered:** 2026-01-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Core applications deployed with modular structure and dead-simple process for adding new apps. Delivers Homepage dashboard, Vaultwarden password manager, and an app template for deploying future services. New apps automatically appear in Traefik routing and Homepage dashboard.

</domain>

<decisions>
## Implementation Decisions

### Homepage layout
- Group services by category (Infrastructure, Apps, etc.)
- Each service shows: icon + name + status indicator + brief description
- Include a bookmarks section for external links (GitHub, cloud providers, etc.)

### Vaultwarden config
- Signup policy: Invite only — admin sends invite links, users self-register
- Admin panel enabled, protected by admin token in env
- INSTALL.md includes browser extension setup (Bitwarden extension pointing to vault.ragnalab.xyz)

### App template structure
- Template lives at `apps/_template/`
- Contains: docker-compose.yml with placeholders + README.md explaining how to customize
- Includes Homepage labels for auto-discovery (placeholders to fill in)
- Includes backup.stop label so new apps back up automatically
- README inside template folder — gets copied when user copies template

### New app discovery
- Makefile workflow required: `make start APPS=myapp` — consistent with existing workflow
- Template README reminds user to add Uptime Kuma monitor
- Validation checklist: verify Traefik dashboard, Homepage, and valid HTTPS

### Claude's Discretion
- Homepage categories — pick sensible defaults based on deployed services (Infrastructure, Apps, Bookmarks)
- Homepage discovery method — Docker labels vs config file based on what works best
- Vaultwarden 2FA policy — pick based on security best practices

</decisions>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-applications-templates*
*Context gathered: 2026-01-17*
