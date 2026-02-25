# Media Stack — How Everything Works

> A complete guide to how torrents flow from TamilMV to your TV screen,
> and every piece of software in between.

---

## Table of Contents

1. [BitTorrent Fundamentals](#1-bittorrent-fundamentals)
2. [The Media Stack Overview](#2-the-media-stack-overview)
3. [Component Deep Dives](#3-component-deep-dives)
4. [The Complete Data Flow](#4-the-complete-data-flow)
5. [Network Architecture](#5-network-architecture)
6. [The Tracker Bug — Root Cause Analysis](#6-the-tracker-bug--root-cause-analysis)
7. [Glossary](#7-glossary)

---

## 1. BitTorrent Fundamentals

### What is a Torrent?

A torrent is a way to download files from **many people at once** instead of one server.
When someone uploads a file, it gets split into small pieces. Other people who already have
some pieces share them with you, and you share what you have with others.

```
Traditional Download:           BitTorrent:

   [Server] ───────> You          [Peer A] ──┐
                                  [Peer B] ──┼──> You
                                  [Peer C] ──┘
                                      ▲
                                      │
                                  You share back
```

Key terms:
- **Seeder** — Someone who has the complete file and is sharing it
- **Leecher** — Someone still downloading (but also sharing what they have so far)
- **Swarm** — All the seeders + leechers for a particular torrent
- **Info Hash** — A unique fingerprint (SHA1 hash) that identifies a torrent. Example: `05cd538fbd6a39f0975f13a6a598d18e9e2f883f`

### What is a Tracker?

A tracker is a **coordination server**. It doesn't host any files — it just keeps a list of
who has what, so peers can find each other.

```
                    ┌─────────────┐
   "I have torrent  │   TRACKER   │  "Here are 47 other
    abc123, who     │             │   people with abc123,
    else has it?"   │  ┌───────┐  │   connect to them"
        ──────────> │  │ Peer  │  │ >──────────
                    │  │ List  │  │
                    │  └───────┘  │
                    └─────────────┘
```

Without a tracker, your torrent client has no idea who to connect to. This is exactly
what broke in our setup — magnet links had no tracker URLs, so qBittorrent was blind.

### What is DHT?

**DHT (Distributed Hash Table)** is a backup discovery method. Instead of asking one tracker,
your client asks the entire DHT network — a massive peer-to-peer phonebook.

```
Tracker (centralized):          DHT (decentralized):

   ┌─────────┐                    You ──> Node A ──> Node D
   │ Tracker │                      │                  │
   └────┬────┘                      └──> Node B    Node E ──> Found peers!
        │                                  │
   All peers                          Node C
   registered here
```

DHT is slower and less reliable, especially through VPNs (many VPN nodes block DHT traffic).
That's why trackers are essential.

### Magnet Links vs .torrent Files

```
.torrent file:
  Contains: metadata + tracker URLs + piece hashes
  ✅ Everything needed to start downloading immediately

Magnet link (with trackers):
  magnet:?xt=urn:btih:<info_hash>&dn=<name>&tr=<tracker1>&tr=<tracker2>
  ✅ Contacts trackers → finds peers → downloads metadata → starts download

Magnet link (bare — OUR BUG):
  magnet:?xt=urn:btih:<info_hash>&dn=<name>
  ❌ No trackers! Must rely on DHT alone → often fails through VPN
```

---

## 2. The Media Stack Overview

Here's how a movie goes from "I want to watch this" to playing on Jellyfin:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CONTENT DISCOVERY                            │
│                                                                     │
│  TamilMV ──(scraped by)──> MediaFusion ──(indexed in)──> Prowlarr  │
│  (website)                 (torznab API)                 (indexer   │
│                                                           manager)  │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                    Prowlarr syncs indexers to
                    Sonarr (TV) and Radarr (Movies)
                              │
┌─────────────────────────────▼───────────────────────────────────────┐
│                        MEDIA MANAGEMENT                             │
│                                                                     │
│  Jellyseerr ──(request)──> Sonarr/Radarr ──(search)──> Prowlarr   │
│  (request UI)              (automation)     ◄──(results)──┘        │
│                                │                                    │
│                          Sends magnet link                          │
│                          to qBittorrent                             │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────────┐
│                        DOWNLOAD & VPN                                │
│                                                                     │
│  qBittorrent ──(all traffic via)──> Gluetun ──> ProtonVPN ──> Internet
│  (torrent client)                   (VPN container)                  │
│       │                                                             │
│  Downloads to /data/torrents/movies/ or /data/torrents/tv/          │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                    Sonarr/Radarr detect completion,
                    hardlink to /data/media/
                              │
┌─────────────────────────────▼───────────────────────────────────────┐
│                        PLAYBACK                                     │
│                                                                     │
│  Jellyfin ◄──(library scan)── Sonarr/Radarr trigger refresh        │
│  (media server)                                                     │
│       │                                                             │
│  Bazarr downloads subtitles for new media                           │
│       │                                                             │
│  You watch on any device via jellyfin.ragnalab.xyz                  │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Component Deep Dives

### TamilMV (Content Source)

TamilMV is a torrent website that indexes Tamil, Telugu, and other Indian language content.
It's not software you run — it's an external website that MediaFusion scrapes.

- Frequently changes domains (`.earth`, `.rsvp`, etc.)
- Protected by Cloudflare anti-bot (that's why we need FlareSolverr)
- Provides magnet links and .torrent files for movies and TV shows

### MediaFusion (Torznab Indexer)

MediaFusion is a self-hosted indexer that scrapes sites like TamilMV and Torrentio,
stores the results, and exposes them via a **Torznab API** that Prowlarr can consume.

```
┌──────────────────────────────────────────────────────────┐
│                      MediaFusion                          │
│                                                          │
│  ┌──────────┐    ┌──────────────┐    ┌───────────────┐  │
│  │   API    │    │    Worker    │    │  FlareSolverr │  │
│  │ (uvicorn)│    │  (dramatiq)  │    │  (CF bypass)  │  │
│  │ port 8000│    │              │    │  port 8191    │  │
│  └────┬─────┘    └──────┬───────┘    └───────────────┘  │
│       │                 │                                │
│  Serves Torznab    Runs background           Solves     │
│  XML to Prowlarr   scrape jobs              Cloudflare  │
│                                             challenges  │
│  ┌──────────┐  ┌────────────┐  ┌─────────────────────┐  │
│  │ Postgres │  │  MongoDB   │  │       Redis         │  │
│  │          │  │            │  │                     │  │
│  │ Torrents │  │ Stream     │  │ Cache + Job Queue   │  │
│  │ Trackers │  │ metadata   │  │ (dramatiq broker)   │  │
│  │ Users    │  │ TV streams │  │                     │  │
│  │ Media    │  │            │  │                     │  │
│  └──────────┘  └────────────┘  └─────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

**Why 3 databases?**
- **PostgreSQL** — Relational data: torrents, trackers (the link between them!), users, media metadata, ratings. This is where the tracker bug lived.
- **MongoDB** — Document store for flexible stream data (TV streams, torrent streams with varying metadata)
- **Redis** — Fast cache + message broker for the Dramatiq background worker

**The Torznab API** is the bridge between MediaFusion and Prowlarr:
```
Prowlarr: "Give me movies matching IMDB tt32362695"
    │
    ▼
GET /torznab/api?t=movie&imdbid=tt32362695&apikey=<key>
    │
    ▼
MediaFusion queries PostgreSQL:
  torrent_stream JOIN stream JOIN media JOIN media_external_id
  WHERE external_id = 'tt32362695'
  WITH selectinload(TorrentStream.trackers)  ◄── loads tracker URLs
    │
    ▼
Builds magnet link:
  magnet:?xt=urn:btih:<hash>&dn=<name>&tr=<tracker1>&tr=<tracker2>...
    │                                    ▲
    │                          THESE WERE MISSING!
    ▼
Returns Torznab XML with magnet links
```

### Prowlarr (Indexer Manager)

Prowlarr is the central hub that manages all your indexers (like MediaFusion) and syncs
them to your media managers (Sonarr/Radarr).

```
                    ┌───────────┐
                    │  Prowlarr │
                    │           │
          Indexers: │  ┌─────┐  │  Applications:
                    │  │ Sync│  │
   MediaFusion ──> │  │     │  │ ──> Sonarr (TV)
   (other indexers) │  └─────┘  │ ──> Radarr (Movies)
                    └───────────┘

When Prowlarr adds an indexer, it automatically configures that
indexer in both Sonarr and Radarr via their APIs (fullSync mode).
```

### Sonarr & Radarr (Media Automation)

These are the brains of the operation. They:
1. Know what media you want (your library + wanted list)
2. Search indexers (via Prowlarr) for matching torrents
3. Pick the best quality match
4. Send the magnet link to qBittorrent
5. Monitor the download
6. Hardlink completed files to the media library
7. Notify Jellyfin to refresh its library

```
Sonarr/Radarr decision flow:

  Wanted media → Search Prowlarr → Filter by quality profile
       │                                     │
       │                              Pick best match
       │                                     │
       ▼                                     ▼
  Send to qBittorrent ◄──── magnet:?xt=urn:btih:...&tr=...
       │
  Monitor download progress
       │
  Download complete → Hardlink to /data/media/
       │
  Notify Jellyfin → Library scan
```

### qBittorrent + Gluetun (Download + VPN)

qBittorrent runs inside Gluetun's network namespace — it literally cannot access the
internet without going through the VPN tunnel.

```
┌─────────────────────────────────────────┐
│              Gluetun Container           │
│                                         │
│  ┌─────────┐     ┌──────────────────┐  │
│  │ tun0    │     │   qBittorrent    │  │
│  │ (VPN    │◄────│   (shares this   │  │
│  │ tunnel) │     │    network)      │  │
│  └────┬────┘     └──────────────────┘  │
│       │                                 │
│       │  ProtonVPN + Port Forwarding    │
│       │  Port: 42739 (dynamic)          │
│       ▼                                 │
│   Internet (via VPN IP: 159.26.101.3)   │
└─────────────────────────────────────────┘

Why port forwarding matters:
  Without it: You can download FROM peers, but peers can't connect TO you
  With it:    Peers can directly connect, dramatically improving speeds
              and the ability to find peers for metadata
```

The `network_mode: service:gluetun` Docker setting means:
- qBittorrent has NO independent network interface
- All traffic (DNS, HTTP, BitTorrent) goes through Gluetun's tun0
- If Gluetun restarts, qBittorrent also restarts (configured via `restart: true` dependency)
- Traefik labels for qBittorrent live on the Gluetun container (since it owns the network)

### Jellyfin (Media Server)

The final destination. Jellyfin serves your media library to any device:
- Hardware transcoding via `/dev/video19` (Pi 5 V4L2)
- Libraries point to `/data/media/movies` and `/data/media/tv`
- Sonarr/Radarr send library refresh notifications on new imports

### Bazarr (Subtitles)

Monitors your media library and automatically downloads subtitles.
Reads from the same `/data/media/` paths that Jellyfin uses.

### Jellyseerr (Request Portal)

A user-friendly UI for requesting movies/TV shows. Authenticates via Jellyfin SSO,
then forwards requests to Sonarr/Radarr which handle the rest.

---

## 4. The Complete Data Flow

Here's the complete journey of a movie, step by step:

```
Step 1: SCRAPING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  TamilMV website
       │
       │  MediaFusion worker scrapes (via Torrentio or directly)
       │  FlareSolverr bypasses Cloudflare if needed
       ▼
  MediaFusion PostgreSQL
  ┌─────────────────────────────────────────────┐
  │ torrent_stream: info_hash, size, seeders    │
  │ tracker:        url, status                 │
  │ torrent_tracker_link: torrent_id ↔ tracker_id │
  │ media:          title, year, type           │
  │ media_external_id: imdb_id, tmdb_id         │
  └─────────────────────────────────────────────┘


Step 2: INDEXING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Prowlarr polls MediaFusion Torznab API (RSS + search)
       │
       │  GET /torznab/api?t=movie&imdbid=tt1234567
       │  Response: XML with magnet links (including tracker URLs)
       ▼
  Prowlarr syncs results to Sonarr and Radarr


Step 3: SELECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  User requests movie via Jellyseerr
       │
       │  OR Sonarr/Radarr automatically search for wanted media
       ▼
  Sonarr/Radarr evaluate available torrents:
    - Quality (4K > 1080p > 720p)
    - Size limits
    - Seeders count
    - Preferred words / language
       │
       ▼
  Best match selected


Step 4: DOWNLOADING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Sonarr/Radarr send magnet link to qBittorrent
  (via API at http://gluetun:8080)
       │
       ▼
  qBittorrent (inside Gluetun VPN):
    1. Parse magnet link
    2. Contact trackers: "Who has this torrent?"     ◄── NEEDS TRACKER URLs!
    3. Trackers respond with peer list
    4. Connect to peers, download metadata
    5. Start downloading pieces from multiple peers
    6. Save to /data/torrents/movies/ or /data/torrents/tv/
       │
       ▼
  Download complete


Step 5: IMPORTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Sonarr/Radarr detect completed download
       │
       ▼
  Hardlink (not copy!) from:
    /data/torrents/movies/Movie.Name.2025.mkv
  to:
    /data/media/movies/Movie Name (2025)/Movie Name (2025).mkv
       │
       │  Zero disk space used for the "copy"
       │  Both paths point to the same data on disk
       ▼
  Notify Jellyfin to scan library


Step 6: PLAYBACK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Jellyfin scans /data/media/movies/ and /data/media/tv/
       │
       ▼
  Fetches metadata (poster, synopsis, ratings)
  Bazarr downloads subtitles
       │
       ▼
  Ready to watch on any device via jellyfin.ragnalab.xyz
```

---

## 5. Network Architecture

### Docker Networks

```
┌─────────────────── traefik_public (external) ──────────────────────┐
│                                                                     │
│  Traefik ◄──► Gluetun/qBit ◄──► Prowlarr ◄──► Sonarr              │
│     │              │                │              │                │
│     │              │                │              ▼                │
│     ├──► MediaFusion API            └──────► Radarr                 │
│     │                                          │                    │
│     ├──► Jellyfin                               │                   │
│     ├──► Jellyseerr                             │                   │
│     └──► Bazarr                                 │                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌──── mediafusion_internal (bridge, isolated) ────┐
│                                                  │
│  MediaFusion API ◄──► Worker                     │
│       │                  │                       │
│       ├──► PostgreSQL    ├──► PostgreSQL          │
│       ├──► MongoDB       ├──► MongoDB             │
│       ├──► Redis         ├──► Redis               │
│       └──► FlareSolverr                          │
│                                                  │
└──────────────────────────────────────────────────┘
```

### External Access (via Traefik + Cloudflare)

```
Internet ──► Cloudflare DNS (ragnalab.xyz)
                │
                ▼
         Traefik (port 443, HTTPS)
                │
        ┌───────┴────────────────────────────────────┐
        │              Authelia SSO                   │
        │  (protects: qbit, prowlarr, sonarr,        │
        │   radarr, bazarr, mediafusion)              │
        └───────┬────────────────────────────────────┘
                │
    ┌───────────┼──────────────────────────┐
    │           │                          │
    ▼           ▼                          ▼
 qbit.*    prowlarr.*              jellyfin.*
 sonarr.*  radarr.*                jellyseerr.* (requests.*)
 bazarr.*  mediafusion.*           (own auth, no Authelia)
```

### Filesystem (Shared `/srv` mount)

```
Host: /srv ──(bind mount)──► Container: /data

/srv (host) = /data (container)
├── torrents/
│   ├── incomplete/          qBittorrent writes here during download
│   ├── movies/              qBittorrent moves completed movies here
│   └── tv/                  qBittorrent moves completed TV here
└── media/
    ├── movies/              Radarr hardlinks from ../torrents/movies/
    │   └── Movie (2025)/
    │       └── Movie (2025).mkv  ◄── same inode as torrents/movies/Movie.mkv
    └── tv/                  Sonarr hardlinks from ../torrents/tv/
        └── Show (2025)/
            └── Season 01/
                └── S01E01.mkv

Containers with /srv:/data mount:
  qBittorrent, Sonarr, Radarr, Bazarr, Jellyfin
  (all see the same filesystem = hardlinks work across containers)
```

---

## 6. The Tracker Bug — Root Cause Analysis

### What Happened

Downloads from TamilMV (via MediaFusion) were stuck at "downloading metadata" in qBittorrent.

### Root Cause

```
The Problem Chain:

  1. MediaFusion's PostgreSQL `tracker` table was EMPTY (0 rows)
                    │
  2. When scraping TamilMV torrents, no tracker URLs were stored
     because there was no tracker data to associate
                    │
  3. Torznab API builds magnet links:
     trackers = [t.url for t in torrent.trackers]  ──► returns []
                    │
  4. Magnet link generated WITHOUT &tr= parameters:
     magnet:?xt=urn:btih:05cd538f...&dn=Movie+Name
                    │
  5. Prowlarr passes this bare magnet to Sonarr/Radarr
                    │
  6. Sonarr/Radarr sends it to qBittorrent
                    │
  7. qBittorrent has NO trackers to contact
     Falls back to DHT only
                    │
  8. DHT through ProtonVPN is unreliable
     Many VPN nodes throttle or block DHT
                    │
  9. Result: stuck at "downloading metadata" forever
     (0 seeds, 0 leeches, empty tracker field)
```

### Why Was the Tracker Table Empty?

MediaFusion ships with a built-in `trackers.json` file containing 28 public trackers.
This file is used as a **runtime fallback** in the seeder-update worker:

```python
# In scrapers/trackers.py — seeder update job
urls = [t.url for t in torrent.trackers] if torrent.trackers else TRACKERS
#                                                                  ▲
#                                              Falls back to trackers.json
```

But the **torznab API** (which generates magnet links) does NOT have this fallback:

```python
# In db/crud/torznab.py — search results
trackers = [t.url for t in torrent.trackers] if torrent.trackers else []
#                                                                     ▲
#                                                          Empty list! No fallback!
```

MediaFusion expects trackers to be populated in the database via scraping.
But the scrapers that populate trackers (TamilMV spider, etc.) need to actually
encounter tracker URLs in the scraped data. If the source (Torrentio) doesn't
include trackers, they never get stored.

**The automation gap:** Our Ansible playbook (`mediafusion.yml`) correctly sets up
MediaFusion, registers a user, and configures Prowlarr — but never seeds the tracker
table with the built-in tracker list.

### The Fix

1. **Immediate:** Populated the `tracker` table with 28 public trackers from
   MediaFusion's built-in `trackers.json`
2. **Immediate:** Linked all 3,179 existing torrents to 8 reliable public trackers
3. **Immediate:** Added trackers to the 3 stuck torrents directly in qBittorrent
4. **Permanent:** Added an Ansible task to seed the tracker table on fresh setup
   (see `ansible/tasks/apps/mediafusion.yml`)

---

## 7. Glossary

| Term | What it is |
|------|-----------|
| **BitTorrent** | Protocol for peer-to-peer file sharing |
| **Magnet link** | A URI containing a torrent's info hash (and optionally tracker URLs) |
| **Info hash** | Unique SHA1 fingerprint identifying a torrent |
| **Tracker** | Server that coordinates peers (who has what) |
| **DHT** | Distributed Hash Table — decentralized peer discovery (backup to trackers) |
| **PEX** | Peer Exchange — peers share their known peers with each other |
| **Seeder** | Peer with the complete file |
| **Leecher** | Peer still downloading |
| **Torznab** | Standardized API for torrent indexers (Torrent + Newznab) |
| **MediaFusion** | Self-hosted indexer that scrapes TamilMV/Torrentio and serves Torznab API |
| **Prowlarr** | Indexer manager — aggregates multiple indexers, syncs to Sonarr/Radarr |
| **Sonarr** | TV show automation — searches, downloads, organizes TV content |
| **Radarr** | Movie automation — same as Sonarr but for movies |
| **Bazarr** | Subtitle automation — finds and downloads subtitles |
| **qBittorrent** | Torrent client that does the actual downloading |
| **Gluetun** | VPN container — routes all qBittorrent traffic through ProtonVPN |
| **Jellyfin** | Media server — streams your library to any device |
| **Jellyseerr** | Request portal — users request content, forwarded to Sonarr/Radarr |
| **FlareSolverr** | Cloudflare challenge solver — helps scrape protected sites |
| **Dramatiq** | Python background task framework (MediaFusion's worker) |
| **Redis** | In-memory cache + message broker for Dramatiq jobs |
| **Hardlink** | Filesystem feature — two paths pointing to same data, zero extra disk space |
| **Port forwarding** | VPN feature allowing inbound peer connections (improves speeds) |
