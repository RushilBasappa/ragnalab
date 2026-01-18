# Vaultwarden Installation

Self-hosted Bitwarden-compatible password manager.

**URL:** https://vault.ragnalab.xyz

---

## Prerequisites

- Traefik running (see [Traefik](../infrastructure/traefik.md))

---

## Installation

### 1. Generate Admin Token

```bash
docker run --rm -it vaultwarden/server /vaultwarden hash
```

Enter a secure password when prompted. **Save both:**
- The password (for admin login)
- The hash (for .env file)

### 2. Configure Environment

```bash
cp apps/vaultwarden/.env.example apps/vaultwarden/.env
nano apps/vaultwarden/.env
```

Paste the hash (include the single quotes):
```
ADMIN_TOKEN='$argon2id$v=19$m=65540,t=3,p=4$...'
```

### 3. Deploy

```bash
docker compose -f apps/vaultwarden/docker-compose.yml up -d
```

### 4. Verify

```bash
curl -I https://vault.ragnalab.xyz
```

---

## Manual Steps

### First-Time Setup

1. Open https://vault.ragnalab.xyz
2. Click "Create Account"
3. Register your admin account

### Admin Panel

1. Go to https://vault.ragnalab.xyz/admin
2. Enter the **password** (not hash) from step 1
3. Configure settings:
   - Disable public signups (Settings → General → Allow new signups: OFF)
   - Invite users via email or admin panel

---

## Security Notes

- Signups are disabled by default in docker-compose.yml
- Admin panel requires the password you chose when generating the hash
- All data is encrypted at rest
- Backup the `vaultwarden` volume regularly

---

## Files

| File | Purpose |
|------|---------|
| `apps/vaultwarden/docker-compose.yml` | Container configuration |
| `apps/vaultwarden/.env` | Admin token |
| Volume: `vaultwarden` | Encrypted database and attachments |

---

## Backup & Restore

Vaultwarden volume is included in automatic backups.

Manual backup:
```bash
docker run --rm -v vaultwarden:/data -v $(pwd):/backup alpine tar czf /backup/vaultwarden-backup.tar.gz /data
```

Restore:
```bash
docker compose -f apps/vaultwarden/docker-compose.yml down
docker run --rm -v vaultwarden:/data -v $(pwd):/backup alpine tar xzf /backup/vaultwarden-backup.tar.gz -C /
docker compose -f apps/vaultwarden/docker-compose.yml up -d
```

---

## Troubleshooting

### Can't access admin panel

Verify ADMIN_TOKEN in .env includes the single quotes around the hash.

### Forgot admin password

Regenerate the hash with a new password and update .env:
```bash
docker run --rm -it vaultwarden/server /vaultwarden hash
```
