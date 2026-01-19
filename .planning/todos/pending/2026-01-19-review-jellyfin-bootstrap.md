---
created: 2026-01-19T05:19
updated: 2026-01-19T13:45
title: Rewrite Jellyfin bootstrap script
area: media
files:
  - stack/media/scripts/bootstrap-jellyfin.sh
---

## Problem

Current Jellyfin bootstrap script is overly complex and doesn't work properly. Needs complete rewrite.

## Solution

1. Delete everything in the current bootstrap-jellyfin.sh
2. Use other bootstrap scripts (Sonarr, Radarr, Prowlarr) as reference for style/pattern
3. Implement:
   - Complete the Jellyfin setup wizard via API
   - Get the API key
   - Add media folders (movies, tv)
4. Keep it simple and consistent with other bootstrap scripts
