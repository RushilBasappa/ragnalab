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
```

## 5. Apps
```bash
make rustdesk
make homepage
```

## Managing secrets
Edit `compose/.env` freely — the pre-commit hook auto-encrypts to `ansible/vars/secrets.yml` on every commit.
