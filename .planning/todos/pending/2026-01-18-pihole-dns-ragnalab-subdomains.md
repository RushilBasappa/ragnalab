---
created: 2026-01-18T11:48
title: Configure Pi-hole DNS for ragnalab.xyz subdomains
area: networking
files:
  - stack/apps/pihole/docker-compose.yml
---

## Problem

Devices using Pi-hole as their DNS server cannot resolve ragnalab.xyz subdomains (status.ragnalab.xyz, sonarr.ragnalab.xyz, etc.). Pi-hole doesn't have DNS records for these domains, so lookups fail with "server IP address could not be found."

Tailscale DNS (100.100.100.100) correctly resolves these to the Tailscale IP (100.75.173.7), but Pi-hole doesn't forward or know about them.

This forces users to either:
- Not use Pi-hole for DNS (losing ad blocking)
- Manually switch DNS when accessing ragnalab services

## Solution

Options (pick one):

1. **Add Local DNS records in Pi-hole** - Go to Pi-hole Admin → Local DNS → DNS Records, add entries for each subdomain pointing to 100.75.173.7

2. **Conditional forwarding** - Configure Pi-hole to forward `ragnalab.xyz` queries to Tailscale DNS (100.100.100.100)

3. **Use Tailscale DNS as upstream** - Add 100.100.100.100 as an upstream DNS server in Pi-hole settings
