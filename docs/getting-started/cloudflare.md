# Cloudflare Setup

Configure DNS and create API token for automatic SSL certificates.

---

## 1. Add Domain to Cloudflare

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click **Add a Domain**
3. Enter your domain (e.g., `ragnalab.xyz`)
4. Select **Free plan**
5. Cloudflare shows nameservers to use

---

## 2. Update Registrar Nameservers

At your domain registrar (where you bought the domain):

1. Find DNS/Nameserver settings
2. Replace existing nameservers with Cloudflare's:
   ```
   ns1.cloudflare.com
   ns2.cloudflare.com
   ```
3. Save changes
4. Wait 5-30 minutes for propagation

---

## 3. Create API Token

Traefik needs an API token to create SSL certificates via DNS challenge.

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click **Create Token**
3. Use **Edit zone DNS** template
4. Configure permissions:
   - **Zone → DNS → Edit**
5. Zone Resources:
   - **Include → Specific zone → your domain**
6. Click **Continue to summary** → **Create Token**
7. **Copy and save the token** — you won't see it again!

---

## 4. Create Wildcard DNS Record

After installing Tailscale (you'll get an IP), add this DNS record:

| Type | Name | Content | Proxy Status |
|------|------|---------|--------------|
| A | `*` | `<your-tailscale-ip>` | **DNS only** (gray cloud) |

**Important:** Must be "DNS only" (gray cloud), NOT "Proxied" (orange cloud).

The wildcard means `*.ragnalab.xyz` all point to your Pi's Tailscale IP.

---

## What You'll Need Later

Save these for the installation:

- [ ] Cloudflare email address
- [ ] API token (from step 3)
- [ ] Domain name

---

## Next Step

→ [Host Setup](host-setup.md)
