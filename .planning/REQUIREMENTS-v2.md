# Requirements: RagnaLab v2.0

**Defined:** 2026-01-17
**Core Value:** Secure, private-only access to self-hosted applications with professional-grade HTTPS, automatic service discovery, and dead-simple process for adding new apps.

## v2.0 Requirements

Requirements for v2.0 milestone. Each maps to roadmap phases.

### DNS & Ad Blocking

- [ ] **DNS-01**: Pi-hole deployed as Docker container on ARM64
- [ ] **DNS-02**: Pi-hole web UI accessible at pihole.ragnalab.xyz via Traefik
- [ ] **DNS-03**: DNS queries blocked for ad/tracking domains network-wide
- [ ] **DNS-04**: Upstream DNS configured (Cloudflare 1.1.1.1 / Quad9 9.9.9.9)

### DHCP

- [ ] **DHCP-01**: Pi-hole configured as DHCP server for home network
- [ ] **DHCP-02**: DHCP disabled on Xfinity gateway
- [ ] **DHCP-03**: Pi has static IP (DHCP reservation or static config)
- [ ] **DHCP-04**: DHCP hands out Pi-hole as DNS server to all clients

### High Availability

- [ ] **HA-01**: Fallback DNS configured so internet works if Pi is down
- [ ] **HA-02**: DHCP lease time configured for resilience (not too short)
- [ ] **HA-03**: Recovery procedure documented

### Observability

- [ ] **OBS-01**: Uptime Kuma monitor for Pi-hole DNS (port 53)
- [ ] **OBS-02**: Uptime Kuma monitor for Pi-hole web UI
- [ ] **OBS-03**: Homepage widget showing Pi-hole statistics (queries blocked, percentage)

### Operations

- [ ] **OPS-01**: Pi-hole config included in automated backup
- [ ] **OPS-02**: Pi-hole added to Homepage dashboard
- [ ] **OPS-03**: Resource limits configured (memory, CPU)

## Future Requirements (v2.1+)

Deferred to future phases within v2.x. Can be added via `/gsd:add-phase`.

- **Additional network services** — Other services user decides to add
- **Advanced Pi-hole config** — Custom blocklists, regex filters, local DNS records

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Redundant Pi-hole instance | Single Pi deployment; complexity not justified |
| VLAN segmentation | Requires managed switch; out of scope for v2.0 |
| Pi-hole as recursive resolver (Unbound) | Adds complexity; standard upstream DNS sufficient |
| Public DNS exposure | Contradicts private-only design |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DNS-01 | Phase 5 | Pending |
| DNS-02 | Phase 5 | Pending |
| DNS-03 | Phase 5 | Pending |
| DNS-04 | Phase 5 | Pending |
| DHCP-01 | Phase 5 | Pending |
| DHCP-02 | Phase 5 | Pending |
| DHCP-03 | Phase 5 | Pending |
| DHCP-04 | Phase 5 | Pending |
| HA-01 | Phase 5 | Pending |
| HA-02 | Phase 5 | Pending |
| HA-03 | Phase 5 | Pending |
| OBS-01 | Phase 5 | Pending |
| OBS-02 | Phase 5 | Pending |
| OBS-03 | Phase 5 | Pending |
| OPS-01 | Phase 5 | Pending |
| OPS-02 | Phase 5 | Pending |
| OPS-03 | Phase 5 | Pending |

**Coverage:**
- v2.0 requirements: 17 total
- Mapped to phases: 17
- Unmapped: 0 ✓

---
*Requirements defined: 2026-01-17*
*Last updated: 2026-01-17 after initial definition*
