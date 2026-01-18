# Phase 6: Media Automation Stack - Research

**Researched:** 2026-01-17
**Domain:** Docker-based media automation (arr stack, VPN, media server)
**Confidence:** HIGH

## Summary

This research covers a complete media automation stack for Raspberry Pi 5 running ARM64 Docker. The stack consists of: Gluetun VPN container (WireGuard recommended), qBittorrent download client, Prowlarr indexer manager, Sonarr/Radarr media automation, Bazarr subtitles, Unpackerr extraction, Jellyfin media server, and Jellyseerr request management.

All components have verified ARM64 support through LinuxServer.io or official multi-arch images. The critical architectural decision is using a single `/data` volume structure that enables hardlinks between downloads and media libraries, preventing double storage usage. The arr applications should use consistent PUID/PGID with a shared group and umask 002.

**Primary recommendation:** Use WireGuard (not OpenVPN) for Gluetun on Pi 5 (14% faster, 4-5x better throughput), configure all arr apps with identical volume paths for hardlinks, and accept that Jellyfin will be direct-play only (Pi 5 lacks hardware encoder for transcoding).

## Standard Stack

The established libraries/tools for this domain:

### Core

| Component | Image | Version | Purpose | Why Standard |
|-----------|-------|---------|---------|--------------|
| Gluetun | `qmcgaw/gluetun` | latest | VPN container with kill switch | Only multi-provider VPN container, built-in healthcheck |
| qBittorrent | `lscr.io/linuxserver/qbittorrent` | latest | Torrent client | LinuxServer ARM64 support, arr integration |
| Prowlarr | `lscr.io/linuxserver/prowlarr` | latest | Indexer manager | Syncs indexers to all arr apps automatically |
| Sonarr | `lscr.io/linuxserver/sonarr` | latest | TV automation | Industry standard, LinuxServer ARM64 |
| Radarr | `lscr.io/linuxserver/radarr` | latest | Movie automation | Industry standard, LinuxServer ARM64 |
| Jellyfin | `lscr.io/linuxserver/jellyfin` | latest | Media server | Open source, no licensing, ARM64 support |

### Supporting

| Component | Image | Version | Purpose | When to Use |
|-----------|-------|---------|---------|-------------|
| Bazarr | `lscr.io/linuxserver/bazarr` | latest | Subtitle automation | If non-English content or hearing impaired |
| Unpackerr | `hotio/unpackerr` | latest | Archive extraction | If indexers provide RAR archives |
| Jellyseerr | `fallenbagel/jellyseerr` | latest | Request management | If multiple users request media |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Jellyfin | Plex | Plex requires account, has licensing; Jellyfin is fully open |
| Jellyseerr | Overseerr | Overseerr is Plex-only; Jellyseerr forks for Jellyfin support |
| hotio/unpackerr | golift/unpackerr | hotio uses PUID/PGID env vars (matches LinuxServer); golift uses --user flag |
| qBittorrent | Transmission | qBittorrent has better arr integration and web UI |

**Installation (all services):**
```bash
# All images auto-select ARM64 via docker manifest
docker pull qmcgaw/gluetun
docker pull lscr.io/linuxserver/qbittorrent
docker pull lscr.io/linuxserver/prowlarr
docker pull lscr.io/linuxserver/sonarr
docker pull lscr.io/linuxserver/radarr
docker pull lscr.io/linuxserver/bazarr
docker pull lscr.io/linuxserver/jellyfin
docker pull hotio/unpackerr
docker pull fallenbagel/jellyseerr
```

## Architecture Patterns

### Recommended Storage Structure

The single-volume approach enables hardlinks (instant moves, no double storage):

```
/media/                          # Single volume mount point
├── downloads/                   # qBittorrent complete folder
│   ├── movies/                  # Radarr category
│   └── tv/                      # Sonarr category
├── library/                     # Final media location
│   ├── movies/                  # Radarr root folder
│   └── tv/                      # Sonarr root folder
└── incomplete/                  # qBittorrent temp folder
```

**Critical:** All containers must mount `/media` at the same path. Using different paths (e.g., `/downloads` in qBit, `/media` in Sonarr) breaks hardlinks.

### Docker Compose Project Structure

```
apps/media/
├── gluetun/
│   └── docker-compose.yml       # VPN container (runs first)
├── qbittorrent/
│   └── docker-compose.yml       # Routes through gluetun
├── prowlarr/
│   └── docker-compose.yml       # Indexer manager
├── sonarr/
│   └── docker-compose.yml       # TV automation
├── radarr/
│   └── docker-compose.yml       # Movie automation
├── bazarr/
│   └── docker-compose.yml       # Subtitles (optional)
├── unpackerr/
│   └── docker-compose.yml       # Extraction (optional)
├── jellyfin/
│   └── docker-compose.yml       # Media server
└── jellyseerr/
    └── docker-compose.yml       # Request management
```

### Pattern 1: VPN Network Isolation

qBittorrent routes ALL traffic through Gluetun. Other arr apps do NOT need VPN.

```yaml
# gluetun/docker-compose.yml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=${VPN_PROVIDER}
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
      - TZ=America/Los_Angeles
    ports:
      # qBittorrent WebUI (exposed through gluetun)
      - "8080:8080"
    volumes:
      - gluetun-data:/gluetun
    restart: unless-stopped
    # Built-in healthcheck: queries http://127.0.0.1:9999/

# qbittorrent/docker-compose.yml
services:
  qbittorrent:
    image: lscr.io/linuxserver/qbittorrent:latest
    container_name: qbittorrent
    network_mode: "container:gluetun"  # Routes through VPN
    depends_on:
      gluetun:
        condition: service_healthy
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Los_Angeles
      - WEBUI_PORT=8080
    volumes:
      - qbittorrent-config:/config
      - /media:/media  # Same path as arr apps
    restart: unless-stopped
```

### Pattern 2: Arr App Standard Configuration

All arr apps follow identical pattern with consistent volumes:

```yaml
# sonarr/docker-compose.yml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Los_Angeles
    volumes:
      - sonarr-config:/config
      - /media:/media  # MUST match qbittorrent path
    ports:
      - "8989:8989"
    networks:
      - proxy
    restart: unless-stopped
    labels:
      - "traefik.enable=true"
      # ... standard traefik labels
```

### Pattern 3: Jellyfin Direct-Play Configuration

Pi 5 lacks hardware encoder. Configure for direct-play only:

```yaml
# jellyfin/docker-compose.yml
services:
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Los_Angeles
      - JELLYFIN_PublishedServerUrl=https://jellyfin.ragnalab.xyz
    volumes:
      - jellyfin-config:/config
      - /media/library:/data/media:ro  # Read-only media access
    ports:
      - "8096:8096"
    # V4L2 hardware decode (optional, limited support)
    devices:
      - /dev/video10:/dev/video10
      - /dev/video11:/dev/video11
      - /dev/video12:/dev/video12
    networks:
      - proxy
    restart: unless-stopped
```

### Anti-Patterns to Avoid

- **Separate volume mounts:** Using `-v /downloads:/downloads` and `-v /movies:/movies` breaks hardlinks
- **VPN for all containers:** Only qBittorrent needs VPN; arr apps accessing qBit via internal network
- **Exposing qBittorrent ports directly:** Ports must be exposed through gluetun container
- **Using Portainer for setup:** Servarr wiki explicitly recommends against this
- **Different PUID/PGID per container:** Causes permission issues between services

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Indexer management | Manual config per app | Prowlarr | Syncs indexers to all arr apps automatically |
| VPN kill switch | iptables rules | Gluetun built-in | Tested, maintained, auto-healing |
| Subtitle matching | Manual download | Bazarr | Integrates with arr apps, auto-sync |
| Archive extraction | Bash scripts | Unpackerr | Watches arr apps, handles edge cases |
| Media requests | Shared lists | Jellyseerr | User auth, approval workflow, notifications |
| Container healthchecks | Custom scripts | Gluetun built-in | `condition: service_healthy` works out of box |

**Key insight:** The arr ecosystem is mature and tightly integrated. Custom solutions create maintenance burden and miss edge cases that years of community development have solved.

## Common Pitfalls

### Pitfall 1: Hardlinks Not Working

**What goes wrong:** Media copied instead of hardlinked, using 2x storage
**Why it happens:** Different volume paths between containers, or volumes on different filesystems
**How to avoid:**
- Mount single `/media` volume at identical path in ALL containers
- Keep downloads and library on same filesystem
- Verify with `ls -i` that source and destination have same inode
**Warning signs:** Slow imports, storage usage doubles

### Pitfall 2: VPN Connection Issues

**What goes wrong:** qBittorrent can't connect, or leaks real IP
**Why it happens:** Gluetun not healthy before qBittorrent starts
**How to avoid:**
- Use `depends_on: gluetun: condition: service_healthy`
- Gluetun has built-in healthcheck (queries http://127.0.0.1:9999/)
- Test: `docker exec qbittorrent curl ifconfig.me` should show VPN IP
**Warning signs:** qBittorrent shows "No connection", real IP in torrent peers

### Pitfall 3: Permission Denied Errors

**What goes wrong:** Containers can't read/write each other's files
**Why it happens:** Inconsistent PUID/PGID across containers
**How to avoid:**
- Use same PUID/PGID for ALL media containers
- Find your user's IDs: `id $USER`
- Ensure host directories owned by that user
**Warning signs:** Import failures, empty libraries despite downloads

### Pitfall 4: Jellyfin Transcoding Failures

**What goes wrong:** Buffering, playback errors on remote devices
**Why it happens:** Pi 5 lacks hardware encoder; software transcoding too slow
**How to avoid:**
- Disable transcoding in Jellyfin settings
- Use clients that support direct play (Jellyfin Media Player, Apple TV, Shield)
- Encode media to widely-compatible formats (H.264/AAC) beforehand
**Warning signs:** High CPU usage, "Server not powerful enough" errors

### Pitfall 5: qBittorrent Port Conflicts

**What goes wrong:** WebUI inaccessible or wrong container responding
**Why it happens:** qBittorrent ports exposed on gluetun, not qbittorrent container
**How to avoid:**
- Define ports in gluetun docker-compose, NOT qbittorrent
- qBittorrent container should have NO ports section
- Access via gluetun's exposed port
**Warning signs:** Connection refused, wrong WebUI appearing

## Code Examples

### Complete Gluetun Configuration (ProtonVPN WireGuard)

```yaml
# apps/media/gluetun/docker-compose.yml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=protonvpn
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
      - SERVER_COUNTRIES=United States
      - TZ=America/Los_Angeles
    ports:
      # qBittorrent WebUI
      - "8080:8080"
      # qBittorrent incoming connections (if port forwarding)
      - "6881:6881"
      - "6881:6881/udp"
    volumes:
      - gluetun-data:/gluetun
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.25'
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    # Built-in healthcheck:
    # HEALTHCHECK --interval=5s --timeout=5s --start-period=10s --retries=1

volumes:
  gluetun-data:
```

### Complete Sonarr with Traefik and Homepage

```yaml
# apps/media/sonarr/docker-compose.yml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Los_Angeles
    volumes:
      - sonarr-config:/config
      - /media:/media
    networks:
      - proxy
    labels:
      # Traefik
      - "traefik.enable=true"
      - "traefik.http.routers.sonarr.rule=Host(`sonarr.ragnalab.xyz`)"
      - "traefik.http.routers.sonarr.entrypoints=websecure"
      - "traefik.http.routers.sonarr.tls=true"
      - "traefik.http.routers.sonarr.tls.certresolver=letsencrypt"
      - "traefik.http.services.sonarr.loadbalancer.server.port=8989"
      - "traefik.docker.network=proxy"
      # Homepage
      - "homepage.group=Media"
      - "homepage.name=Sonarr"
      - "homepage.icon=sonarr.png"
      - "homepage.href=https://sonarr.ragnalab.xyz"
      - "homepage.description=TV Shows"
      - "homepage.widget.type=sonarr"
      - "homepage.widget.url=http://sonarr:8989"
      - "homepage.widget.key=${SONARR_API_KEY}"
      - "homepage.server=my-docker"
      # Backup
      - "docker-volume-backup.stop-during-backup=sonarr"
    deploy:
      resources:
        limits:
          memory: 512M
          cpus: '0.5'
        reservations:
          memory: 256M
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  sonarr-config:

networks:
  proxy:
    external: true
```

### Unpackerr Configuration (hotio)

```yaml
# apps/media/unpackerr/docker-compose.yml
services:
  unpackerr:
    image: hotio/unpackerr:latest
    container_name: unpackerr
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/Los_Angeles
      # Sonarr
      - UN_SONARR_0_URL=http://sonarr:8989
      - UN_SONARR_0_API_KEY=${SONARR_API_KEY}
      - UN_SONARR_0_PATHS_0=/media/downloads/tv
      # Radarr
      - UN_RADARR_0_URL=http://radarr:7878
      - UN_RADARR_0_API_KEY=${RADARR_API_KEY}
      - UN_RADARR_0_PATHS_0=/media/downloads/movies
    volumes:
      - /media:/media
    networks:
      - default
    deploy:
      resources:
        limits:
          memory: 128M
          cpus: '0.25'
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

networks:
  default:
    name: media-internal
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Jackett indexer | Prowlarr | 2021 | Native arr integration, syncs automatically |
| OpenVPN in Gluetun | WireGuard in Gluetun | 2022+ | 14% faster on Pi, 4-5x better throughput |
| Overseerr | Jellyseerr | 2022 | Native Jellyfin support (fork) |
| Jellyfin V4L2 transcoding | Direct play only | 2024 | Pi 5 lacks encoder; V4L2 deprecated |
| golift/unpackerr | hotio/unpackerr | Preference | PUID/PGID env vars match LinuxServer style |

**Deprecated/outdated:**
- **Jackett:** Replaced by Prowlarr which integrates natively with arr apps
- **Jellyfin V4L2 transcoding:** Deprecated by Jellyfin team; Pi 5 has no encoder
- **OpenMAX (MMAL):** Legacy Pi GPU acceleration, not available on Pi 5

## Raspberry Pi 5 Specific Considerations

### Hardware Transcoding Reality

The Pi 5 **cannot** hardware transcode:
- Hardware encoder removed from Pi 5 SoC
- V4L2 support deprecated by Jellyfin
- Software transcoding too slow for real-time
- **Solution:** Direct play only with compatible clients

### WireGuard Performance

WireGuard strongly recommended over OpenVPN:
- 14% download bandwidth increase on Pi (Gluetun benchmarks)
- 4-5x throughput in independent testing (197Mbps vs 43Mbps)
- Lower CPU usage (12% vs 55% at load)
- ChaCha20 encryption faster on ARM without AES acceleration

### Resource Allocation

Recommended limits for Pi 5 (8GB model):

| Service | Memory Limit | CPU Limit | Notes |
|---------|--------------|-----------|-------|
| Gluetun | 128M | 0.25 | Lightweight VPN tunnel |
| qBittorrent | 512M | 0.5 | Scales with active torrents |
| Prowlarr | 256M | 0.25 | Indexer queries |
| Sonarr | 512M | 0.5 | Database operations |
| Radarr | 512M | 0.5 | Database operations |
| Bazarr | 256M | 0.25 | Subtitle matching |
| Unpackerr | 128M | 0.25 | Archive extraction |
| Jellyfin | 1G | 1.0 | Media serving (direct play) |
| Jellyseerr | 512M | 0.5 | Request management |

**Total:** ~4GB reserved, leaves headroom on 8GB Pi 5

## Open Questions

Things that couldn't be fully resolved:

1. **VPN Port Forwarding on Pi**
   - What we know: Some providers (ProtonVPN, AirVPN, PIA) support port forwarding
   - What's unclear: Automatic port forwarding sync to qBittorrent on ARM64
   - Recommendation: Start without port forwarding; add gluetun-qbittorrent-port-manager if seeding ratios need improvement

2. **Jellyfin Hardware Decode (V4L2)**
   - What we know: V4L2 decode technically possible, but deprecated by Jellyfin
   - What's unclear: Whether it provides meaningful benefit for direct-play scenarios
   - Recommendation: Start without V4L2 devices mounted; add if specific decode issues arise

3. **External Storage Migration**
   - What we know: Roadmap mentions future external storage
   - What's unclear: USB vs network storage, impact on hardlinks
   - Recommendation: Design `/media` structure now; physical location can change later if same mount point preserved

## Sources

### Primary (HIGH confidence)

- [GitHub - qdm12/gluetun](https://github.com/qdm12/gluetun) - VPN container documentation
- [LinuxServer.io Sonarr](https://docs.linuxserver.io/images/docker-sonarr/) - ARM64 docker images
- [LinuxServer.io Radarr](https://docs.linuxserver.io/images/docker-radarr/) - ARM64 docker images
- [LinuxServer.io Prowlarr](https://docs.linuxserver.io/images/docker-prowlarr/) - ARM64 docker images
- [LinuxServer.io Jellyfin](https://docs.linuxserver.io/images/docker-jellyfin/) - ARM64 and V4L2 info
- [Jellyfin Hardware Selection](https://jellyfin.org/docs/general/administration/hardware-selection/) - Pi 5 limitations
- [Servarr Wiki Docker Guide](https://wiki.servarr.com/docker-guide) - PUID/PGID and hardlink patterns
- [Gluetun Healthcheck Wiki](https://github.com/qdm12/gluetun-wiki/blob/main/faq/healthcheck.md) - Built-in healthcheck details

### Secondary (MEDIUM confidence)

- [TRaSH Guides - Hardlinks](https://trash-guides.info/File-and-Folder-Structure/Hardlinks-and-Instant-Moves/) - Folder structure best practices
- [Gluetun Bandwidth FAQ](https://github.com/qdm12/gluetun-wiki/blob/main/faq/bandwidth.md) - WireGuard vs OpenVPN performance
- [Pi My Life Up - Gluetun](https://pimylifeup.com/docker-gluetun/) - Raspberry Pi specific setup
- [Homepage Widgets - Jellyfin](https://gethomepage.dev/widgets/services/jellyfin/) - Widget configuration
- [Homepage Widgets - Sonarr](https://gethomepage.dev/widgets/services/sonarr/) - Widget configuration
- [Docker Compose Deploy](https://docs.docker.com/reference/compose-file/deploy/) - Resource limits syntax

### Tertiary (LOW confidence)

- Community benchmark: WireGuard 197Mbps vs OpenVPN 43Mbps on Pi (forum posts)
- Hotio vs golift unpackerr preference (community consensus, not official)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All images verified on LinuxServer.io and Docker Hub with ARM64 tags
- Architecture: HIGH - Servarr wiki and TRaSH guides are authoritative community sources
- VPN configuration: HIGH - Gluetun wiki is comprehensive and maintained
- Jellyfin transcoding: HIGH - Official Jellyfin docs explicitly state Pi 5 limitations
- Resource limits: MEDIUM - Based on general recommendations, not Pi 5-specific benchmarks
- Port forwarding: LOW - Provider-specific, needs testing

**Research date:** 2026-01-17
**Valid until:** 2026-02-17 (30 days - stack is stable)
