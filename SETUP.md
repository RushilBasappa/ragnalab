# RagnaLab Setup

## 1. First-time setup
```bash
make fix-locale
make install-ansible
make hooks
```

## 2. Bootstrap
```bash
make system-update
make github-ssh        # then add key to github.com/settings/ssh/new
make tailscale         # then run: sudo tailscale up
make docker            # reboot after
make zsh
```

## 3. Secrets

**Existing member:** Get the vault password, then:
```bash
echo '<password>' > .vault_pass
make init              # decrypts secrets.yml → compose/.env
```

**Starting fresh:** Replace `ansible/vars/secrets.yml` with your own credentials:
```bash
echo '<your-password>' > .vault_pass
cp compose/.env.example compose/.env   # fill in your keys
make sync
```

## 4. Services
```bash
make socket-proxy
make authelia
make traefik
make pihole
```

## 5. Apps
```bash
make rustdesk
make homepage
make uptime-kuma
make vaultwarden
make paperless-ngx
make ntfy
make tandoor
make dozzle
```

## 6. Media Stack
Deploy in order — each step auto-wires connections to previous services:
```bash
make qbittorrent       # Gluetun VPN + qBittorrent (fill in WireGuard creds in .env first)
make sonarr            # TV shows — auto-adds qBittorrent, root folder, 4K Minimal profile
make radarr            # Movies — auto-adds qBittorrent, root folder, 4K Minimal profile
make prowlarr          # Indexer manager — auto-adds Sonarr + Radarr
make bazarr            # Subtitles — connects to Sonarr + Radarr
make jellyfin          # Media server — run setup wizard at jellyfin.ragnalab.xyz
make jellyseerr        # Request portal — manual setup required (see below)
```

### Jellyseerr manual setup
After `make jellyseerr`, open https://requests.ragnalab.xyz and complete these steps:

1. **Sign in with Jellyfin** — select "Use your Jellyfin account", enter:
   - Jellyfin URL: `http://jellyfin:8096`
   - Email address (optional, can skip)
   - Username / password: your Jellyfin admin credentials
2. **Configure Jellyfin server** — click "Sync Libraries", enable Movies and TV Shows, then save
3. **Add Radarr** — under Services → Radarr:
   - Default server: yes
   - Server name: `Radarr`
   - Hostname: `radarr`
   - Port: `7878`
   - API key: run `make keys` to get it
   - Quality profile: `4K Minimal` (auto-created — prefers WEB-DL 2160p x265)
   - Root folder: `/data/media/movies`
   - Click "Test" then "Add Server"
4. **Add Sonarr** — under Services → Sonarr:
   - Default server: yes
   - Server name: `Sonarr`
   - Hostname: `sonarr`
   - Port: `8989`
   - API key: run `make keys` to get it
   - Quality profile: `4K Minimal` (auto-created — prefers WEB-DL 2160p x265)
   - Root folder: `/data/media/tv`
   - Click "Test" then "Add Server"
5. Click **Finish** to complete the setup

## Managing secrets
Edit `compose/.env` freely — the pre-commit hook auto-encrypts to `ansible/vars/secrets.yml` on every commit.
