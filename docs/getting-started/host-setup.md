# Host Setup

Configure Raspberry Pi OS for Docker and Tailscale.

---

## 1. Update System

SSH into your Raspberry Pi:

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 2. Enable cgroup Memory Limits

Docker needs cgroup memory limits enabled.

```bash
sudo nano /boot/firmware/cmdline.txt
```

**Append to the existing single line** (do not add a new line):

```
cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset
```

The file should be one long line.

---

## 3. Enable IP Forwarding

Required for Tailscale networking:

```bash
sudo tee /etc/sysctl.d/99-tailscale.conf << 'EOF'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF

sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

---

## 4. Reboot

```bash
sudo reboot
```

---

## 5. Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Follow the authentication URL to authorize the device.

**Get your Tailscale IP:**

```bash
tailscale ip -4
```

**Save this IP** — add it to Cloudflare DNS (see [Cloudflare Setup](cloudflare.md#4-create-wildcard-dns-record)).

**Enable on boot:**

```bash
sudo systemctl enable tailscaled
```

---

## 6. Install Docker

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

**Log out and back in** for group changes to take effect.

**Verify:**

```bash
docker --version
docker compose version
```

---

## 7. Verify Setup

```bash
# Check cgroup (should show NO warnings)
docker info 2>&1 | grep -i "memory"

# Check IP forwarding (should return 1)
sysctl net.ipv4.ip_forward

# Check Tailscale
tailscale status
```

---

## 8. Clone Repository

```bash
cd ~
git clone https://github.com/yourusername/ragnalab.git
cd ragnalab
```

---

## Next Step

→ [Deploy Infrastructure](../infrastructure/traefik.md)
