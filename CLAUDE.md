# Claude Code Instructions

## Current Project: RagnaLab Homelab

### Active Task: Fresh Installation Documentation

We are doing a fresh installation of the entire RagnaLab stack from scratch and documenting every step.

**IMPORTANT:** When helping with installation or deployment of any service:
1. Add the installation steps to `INSTALL.md` in the repo root
2. Keep instructions clear and sequential
3. Update the "Next Steps" checklist as services are completed

### Installation Progress

Check `INSTALL.md` for current progress. Mark services as complete with [x] as they are deployed.

### Key Files
- `INSTALL.md` - Installation guide being built (UPDATE THIS)
- `stack/infra/` - Infrastructure services
- `stack/apps/` - Application services
- `stack/media/` - Media stack services

### Deployment Order
1. socket-proxy (done)
2. traefik (done)
3. authelia (in progress)
4. uptime-kuma
5. homepage
6. ... continue per INSTALL.md
