#!/bin/bash
set -e

# Recyclarr needs a config file to know which services to sync
# This creates a basic config pointing to Sonarr and Radarr

source "$(dirname "$0")/../.env"

# Create recyclarr.yml config
docker exec recyclarr cat > /config/recyclarr.yml << EOF
# Recyclarr Configuration
# Docs: https://recyclarr.dev/wiki/yaml/config-reference/

sonarr:
  main:
    base_url: http://sonarr:8989
    api_key: $SONARR_API_KEY
    quality_definition:
      type: series
    custom_formats:
      - trash_ids:
          - 32b367365729d530ca1c124a0b180c64  # Bad Dual Groups
          - 82d40da2bc6923f41e14394075dd4b03  # No-RlsGroup
          - e1a997ddb54e3ecbfe06341ad323c458  # Obfuscated
          - 06d66ab109d4d2eddb2794d21526d140  # Retags
        assign_scores_to:
          - name: Any

radarr:
  main:
    base_url: http://radarr:7878
    api_key: $RADARR_API_KEY
    quality_definition:
      type: movie
    custom_formats:
      - trash_ids:
          - b6832f586342ef70d9c128d40c07b872  # Bad Dual Groups
          - 90cedc1fea7ea5d11298bebd3d1d3223  # EVO (no WEBDL)
          - ae9b7c9ebde1f3bd336a8cbd1ec4c5e5  # No-RlsGroup
          - 7357cf5161efbf8c4d5d0c30b4815ee2  # Obfuscated
          - 5c44f52a8714fdd79bb4d98e2673be1f  # Retags
        assign_scores_to:
          - name: Any
EOF

echo "Recyclarr configured with basic TRaSH custom formats"
echo "Run 'docker exec recyclarr recyclarr sync' to apply settings"
echo "REMINDER: Customize /config/recyclarr.yml for more quality profiles"
