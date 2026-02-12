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
make sonarr            # TV shows — auto-adds qBittorrent download client
make radarr            # Movies — auto-adds qBittorrent download client
make prowlarr          # Indexer manager — auto-adds Sonarr + Radarr
make bazarr            # Subtitles — connects to Sonarr + Radarr
make jellyfin          # Media server — run setup wizard at jellyfin.ragnalab.xyz
make jellyseerr        # Request portal — run setup wizard at requests.ragnalab.xyz
```

## Managing secrets
Edit `compose/.env` freely — the pre-commit hook auto-encrypts to `ansible/vars/secrets.yml` on every commit.
