# RagnaLab Fresh Installation Guide

Complete setup from a freshly formatted Raspberry Pi.

---

## 1. System Setup

### Update System
```bash
sudo apt update && sudo apt upgrade -y
```

### Install Zsh
```bash
sudo apt install zsh -y
chsh -s $(which zsh)
```

### Install Starship Prompt
```bash
curl -sS https://starship.rs/install.sh | sh
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

---

## 2. SSH Configuration

### Generate SSH Key (on your local machine)
```bash
ssh-keygen -t ed25519 -f ~/.ssh/ragnapi -C "ragnapi"
```

### Copy Key to Pi
```bash
ssh-copy-id -i ~/.ssh/ragnapi.pub ragna@ragnapi.local
```

### Add to SSH Config (on your local machine)
Edit `~/.ssh/config`:
```
Host ragnapi
    HostName ragnapi.local
    User ragna
    IdentityFile ~/.ssh/ragnapi
```

Now connect with just: `ssh ragnapi`

---

## 3. Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Note your Tailscale IP:
```bash
tailscale ip -4
```

---

## 4. Cloudflare Setup

### Add Domain to Cloudflare
1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click **Add a Domain**
3. Enter your domain (e.g., `ragnalab.xyz`)
4. Select **Free plan**
5. Update nameservers at your registrar to Cloudflare's

### Create DNS Records
Go to DNS → Records and add:

| Type | Name | Content | Proxy |
|------|------|---------|-------|
| A | `@` | `<tailscale-ip>` | DNS only (gray) |
| A | `*` | `<tailscale-ip>` | DNS only (gray) |

### Create API Token
Traefik needs this for automatic SSL certificates.

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token**
3. Select **Edit zone DNS** template
4. Configure:
   - **Permissions:** Zone → DNS → Edit
   - **Zone Resources:** Include → Specific zone → `ragnalab.xyz`
5. Click **Continue to summary** → **Create Token**
6. **Copy and save the token** (you won't see it again)

Save these for later:
- API Token: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- Email: `your-email@example.com`

---

## 5. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Log out and back in for group changes.

Verify:
```bash
docker --version
```

### Enable cgroup Memory Limits

1. Edit the boot command line:
   ```bash
   sudo nano /boot/firmware/cmdline.txt
   ```

2. Append to the existing single line (don't create a new line):
   ```
   cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
   ```

   The file should remain one long line, something like:
   ```
   console=serial0,115200 console=tty1 root=PARTUUID=xxx rootfstype=ext4 ... cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
   ```

3. Reboot:
   ```bash
   sudo reboot
   ```

4. Verify after reboot:
   ```bash
   docker info 2>&1 | grep -i "memory"
   ```

   Should show no warnings.

---

## 6. GitHub SSH Setup

### Generate Key (on Pi)
```bash
ssh-keygen -t ed25519 -f ~/.ssh/github -C "ragnapi-github"
```

### Add to SSH Config
Edit `~/.ssh/config`:
```
Host github.com
    IdentityFile ~/.ssh/github
```

### Add Public Key to GitHub
```bash
cat ~/.ssh/github.pub
```

Copy output → GitHub → Settings → SSH Keys → New SSH Key

### Test Connection
```bash
ssh -T git@github.com
```

---

## 7. Clone Repository

```bash
mkdir -p ~/Workspace
cd ~/Workspace
git clone git@github.com:RushilBasappa/ragnalab.git
cd ragnalab
```

---

## 8. Create Docker Networks

```bash
docker network create proxy
docker network create socket_proxy_network
docker network create media
```

---

## 9. Deploy Infrastructure

### 9.1 Socket Proxy
```bash
docker compose --profile infra up socket-proxy -d
```

Verify:
```bash
docker ps | grep socket-proxy
```

### 9.2 Traefik

Create environment file:
```bash
cat > stack/infra/traefik/.env << 'EOF'
CF_DNS_API_TOKEN=your-cloudflare-dns-api-token
CF_API_EMAIL=your-cloudflare-email
EOF
```

Start Traefik:
```bash
docker compose --profile infra up traefik -d
```

Wait ~60 seconds for SSL certificate, then verify:
```bash
docker logs traefik 2>&1 | grep -i certificate
```

### 9.3 Authelia

Create secrets:
```bash
mkdir -p stack/infra/authelia/config/secrets
openssl rand -hex 32 > stack/infra/authelia/config/secrets/jwt
openssl rand -hex 32 > stack/infra/authelia/config/secrets/session
openssl rand -hex 32 > stack/infra/authelia/config/secrets/storage
```

Generate password hash:
```bash
docker run --rm authelia/authelia:4.39.14 authelia crypto hash generate argon2 --password 'YOUR_PASSWORD'
```

Update `stack/infra/authelia/config/users_database.yml` with your username and hash.

Start Authelia:
```bash
docker compose --profile infra up authelia -d
```

Verify:
```bash
docker logs authelia 2>&1 | tail -10
```

---

## 10. Verify Core Services

- https://auth.ragnalab.xyz - Authelia login portal
- https://traefik.ragnalab.xyz - Traefik dashboard (requires login)

---

## Next Steps

Continue deploying services one by one:
- [ ] Uptime Kuma
- [ ] Homepage
- [ ] Pi-hole
- [ ] Backup
- [ ] Applications (Vaultwarden, etc.)
- [ ] Media stack

---

*Last updated: 2026-01-29*
