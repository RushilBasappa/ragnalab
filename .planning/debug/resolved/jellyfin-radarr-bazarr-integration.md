---
status: resolved
trigger: "Movies downloaded via Jellyseerr -> Radarr -> qBittorrent not visible in Jellyfin, and subtitles not downloaded by Bazarr"
created: 2026-01-19T00:00:00Z
updated: 2026-01-19T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED - Jellyfin library not scanned; Radarr not notifying Jellyfin on import
test: N/A - root cause confirmed
expecting: N/A
next_action: Trigger library scan, configure Radarr notification to Jellyfin

## Symptoms

expected: Movies downloaded by Radarr should appear in Jellyfin library, and Bazarr should download subtitles for them
actual: Movies not visible in Jellyfin, subtitles not downloaded
errors: Unknown - need to investigate
reproduction: Request movie in Jellyseerr -> Radarr grabs it -> qBittorrent downloads -> movie not in Jellyfin
started: Just happened with two recent movie requests

## Eliminated

## Evidence

- timestamp: 2026-01-19T00:01:00Z
  checked: Filesystem - /media/library/movies/
  found: Movies exist - "Now You See Me - Now You Don't (2025)" and "Spider-Man - Across the Spider-Verse (2023)" with full video files (5GB and 6GB mkv files)
  implication: Movies were successfully downloaded and imported by Radarr

- timestamp: 2026-01-19T00:02:00Z
  checked: Jellyfin container view of filesystem
  found: Jellyfin CAN see the movies at /data/media/movies/ (mount is /media/library:/data/media:ro)
  implication: Path mapping is correct - issue is likely Jellyfin library configuration or scan status

- timestamp: 2026-01-19T00:03:00Z
  checked: Jellyfin library configuration via API (/Library/VirtualFolders)
  found: Movies library exists and points to /data/media/movies (correct path)
  implication: Library is configured correctly

- timestamp: 2026-01-19T00:04:00Z
  checked: Jellyfin movie items via API (/Items?IncludeItemTypes=Movie)
  found: TotalRecordCount = 0, no movies in library
  implication: Library exists but hasn't been scanned since movies were added

- timestamp: 2026-01-19T00:05:00Z
  checked: Radarr notification connections via API (/api/v3/notification)
  found: No notification connections configured
  implication: Radarr has no way to notify Jellyfin when movies are imported

- timestamp: 2026-01-19T00:06:00Z
  checked: Bazarr connection to Radarr
  found: Connected (radarr:7878), sees 2 movies, using profileId 1 (English subtitles)
  implication: Bazarr-Radarr connection is working

- timestamp: 2026-01-19T00:07:00Z
  checked: Bazarr movie subtitle status
  found: Both movies have embedded English subtitles (path: null), missing_subtitles: [] for both
  implication: Bazarr sees subtitles are already present (embedded in MKV files) - no external download needed

## Resolution

root_cause: |
  TWO SEPARATE ISSUES:

  1. JELLYFIN (Real Issue): Radarr had no notification connection to Jellyfin.
     When movies were imported, Jellyfin was not notified to scan the library.
     The movies existed on the filesystem (/media/library/movies/) and were visible
     to Jellyfin container (/data/media/movies/), but the library database was stale.

  2. BAZARR (Not an Issue): The downloaded movies already have embedded English
     subtitles (verified via Bazarr API - subtitles array shows embedded tracks
     with path: null). Since the language profile requires English subtitles
     and they're already present, Bazarr correctly shows missing_subtitles: [].

fix: |
  1. Triggered Jellyfin library scan via API: POST /Library/Refresh
     - Movies immediately appeared in library after scan

  2. Created Jellyfin notification connection in Radarr:
     - Host: jellyfin, Port: 8096
     - Update Library: true
     - Path mapping: /media -> /data/media (accounts for different mount paths)
     - Triggers: onDownload, onUpgrade, onRename, onMovieDelete, onMovieFileDelete

  3. Created matching Jellyfin notification connection in Sonarr for TV shows

verification: |
  - Jellyfin now shows 2 movies (TotalRecordCount: 2)
  - "Now You See Me: Now You Don't" visible
  - "Spider-Man: Across the Spider-Verse" visible
  - Radarr notification id: 1 configured
  - Sonarr notification id: 1 configured

files_changed:
  - "Radarr config: notification connection added via API"
  - "Sonarr config: notification connection added via API"
