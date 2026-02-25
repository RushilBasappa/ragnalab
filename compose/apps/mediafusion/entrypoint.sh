#!/bin/sh
# MediaFusion v5 Beta — Entrypoint Patches
# Applied at container startup before exec-ing the real startup.sh

# Reduce gunicorn workers from 4 to 2 (v5 default OOMs on Pi 5 with 512M limit)
sed -i 's/-w 4/-w 2/' /mediafusion/deployment/startup.sh

# Fix Prowlarr Torznab validation: Prowlarr tests indexers by sending an empty
# search (no q/imdbid/tmdbid params). MediaFusion v5 returns <error code="200">
# for these, which Prowlarr treats as a hard failure. Patch to return empty
# results instead so the indexer test passes.
sed -i 's/return create_error_response(200, "Missing search parameters (q, imdbid, or tmdbid required)")/results = []/' \
  /mediafusion/api/routers/torznab/torznab.py

# Fix Prowlarr limit=0: Prowlarr sends limit=0 in search requests, but MediaFusion
# validates limit >= 1 (Pydantic ge=1). Allow 0 and coalesce to default 50.
sed -i 's/ge=1, le=100/ge=0, le=100/' /mediafusion/api/routers/torznab/torznab.py
sed -i '/# All other requests require authentication/i\    limit = limit or 50' \
  /mediafusion/api/routers/torznab/torznab.py

exec /mediafusion/deployment/startup.sh
