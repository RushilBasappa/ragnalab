# Authelia User Management

## Overview

RagnaLab uses Authelia for SSO authentication. Users are defined in a YAML file with password hashes and group memberships.

**User database location:** `stack/infra/authelia/config/users_database.yml`

## User Groups

| Group | Access Level | Services |
|-------|--------------|----------|
| admin | Full access + 2FA | All services including Traefik, Backrest, Pi-hole |
| powerusers | Media management | Sonarr, Radarr, Prowlarr, qBittorrent, Maintainerr |
| family | Media consumption | Jellyfin, Jellyseerr |
| guests | View-only | Jellyfin only |

## Adding a New User

### Step 1: Generate password hash

```bash
# Generate argon2id hash (tuned for Raspberry Pi)
docker exec authelia authelia crypto hash generate argon2 --password 'UserPassword123!'
```

Copy the output hash (starts with `$argon2id$...`).

### Step 2: Add user to database

Edit `stack/infra/authelia/config/users_database.yml`:

```yaml
users:
  # ... existing users ...

  newuser:
    disabled: false
    displayname: 'New User'
    email: 'newuser@ragnalab.xyz'
    groups:
      - family  # Choose appropriate groups
    password: '$argon2id$v=19$m=256,t=1,p=2$...'  # Paste hash here
```

### Step 3: Restart Authelia

```bash
cd /home/rushil/workspace/ragnalab
docker compose --profile infra restart authelia
```

### Step 4: User registers passkey (recommended)

1. User logs in with password at https://auth.ragnalab.xyz
2. User navigates to Settings > Security Keys
3. User clicks "Add" and follows browser prompts
4. User can now use passkey instead of password

## Removing a User

### Option A: Disable user (keeps history)

Edit `users_database.yml` and set:
```yaml
  username:
    disabled: true
```

### Option B: Delete user completely

1. Remove user entry from `users_database.yml`
2. Optionally clear their sessions and devices:
   ```bash
   docker exec authelia authelia storage user totp delete --user username
   docker exec authelia authelia storage user webauthn delete --user username
   ```
3. Restart Authelia

## Changing User Password

```bash
# Generate new hash
docker exec authelia authelia crypto hash generate argon2 --password 'NewPassword123!'

# Edit users_database.yml with new hash
# Restart Authelia
docker compose --profile infra restart authelia
```

## Recovering from Lost Passkey

If a user loses their device with the passkey:

1. User logs in with password (fallback still works)
2. User registers a new passkey
3. Optionally delete old passkey from Authelia storage:
   ```bash
   docker exec authelia authelia storage user webauthn delete --user username
   ```

## Backup and Recovery

Authelia data is backed up by Backrest from `/sources/authelia`:
- `configuration.yml` - Authelia settings
- `users_database.yml` - User accounts
- `db.sqlite3` - Sessions, WebAuthn devices, TOTP secrets

To restore: Copy files from backup to `stack/infra/authelia/config/` and restart Authelia.

## Troubleshooting

### User cannot login
- Check `docker logs authelia` for errors
- Verify password hash format (must start with `$argon2id$`)
- Check user is not `disabled: true`

### Passkey not working
- WebAuthn requires HTTPS (auth.ragnalab.xyz must be HTTPS)
- Check browser console for WebAuthn errors
- Try re-registering the passkey

### Session not persisting across subdomains
- Verify cookie domain is `ragnalab.xyz` in configuration.yml
- Check browser cookies - should see `authelia_session` with domain `.ragnalab.xyz`
