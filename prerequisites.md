CF_DNS_API_TOKEN=your-scoped-token

  Create at: Cloudflare Dashboard → Profile → API Tokens → Create Token → "Edit zone DNS" template

  Token Permissions
  ┌─────────────┬─────────────┬────────────────────────────────────────────────┐
  │ Permission  │   Options   │                 What to Select                 │
  ├─────────────┼─────────────┼────────────────────────────────────────────────┤
  │ Zone - DNS  │ Read / Edit │ Edit (required to create TXT records for ACME) │
  ├─────────────┼─────────────┼────────────────────────────────────────────────┤
  │ Zone - Zone │ Read / Edit │ Read (optional, helps list zones)              │
  └─────────────┴─────────────┴────────────────────────────────────────────────┘
  ---
  Zone Resources
  Select: Include → Specific zone → ragnalab.xyz

====================================================================================================================

  Enable cgroup Memory Limits

  1. Edit the boot command line:
  sudo nano /boot/firmware/cmdline.txt

  2. Append to the existing single line (don't create a new line):
  cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset

  The file should remain one long line, something like:
  console=serial0,115200 console=tty1 root=PARTUUID=xxx rootfstype=ext4 ... cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset

  3. Reboot:
  sudo reboot

  4. Verify after reboot:
  docker info 2>&1 | grep -i "memory"

  Should show no warnings.

====================================================================================================================

Order of apps

socket proxy
traefik
authelia