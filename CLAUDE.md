# RagnaLab - Project Rules

## Automation-First Workflow

Every change must be reproducible. Follow this workflow:

1. **Test directly first** — Run commands, edit configs, hit APIs directly to validate the fix works.
2. **Then automate** — Once verified, encode the change into the appropriate automation layer:
   - **Infrastructure/config changes** → Ansible tasks (`ansible/tasks/`)
   - **Service definitions** → Docker Compose (`compose/apps/`)
   - **Secrets/variables** → `.env` file + `.env.example`
   - **Shared helper logic** → Ansible helpers (`ansible/tasks/shared/helpers/`)
3. **Verify automation** — After updating automation, confirm it would work on a fresh setup. Think: "If I wipe this Pi and run `make deploy` from scratch, will this fix be applied automatically?"

Never leave a fix as only a manual command. If you changed a setting via API or CLI, ask yourself: "Is this persisted in Ansible so it survives a fresh deploy?"

## Docker Compose

- **Always deploy from the parent compose file** (`compose/docker-compose.yml`), never from individual service compose files directly.
  - Correct: `cd compose && docker compose up -d <service>`
  - Wrong: `docker compose -f apps/mediafusion/docker-compose.yml up -d`
  - The parent file includes all services and loads the shared `.env` file with secrets and variables.
