---
status: resolved
trigger: "Bazarr API POST to /api/system/settings doesn't update use_sonarr and use_radarr settings"
created: 2026-01-18T00:00:00Z
updated: 2026-01-18T00:02:00Z
---

## Current Focus

hypothesis: CONFIRMED - Bazarr API only accepts lowercase 'true'/'false' strings for boolean settings
test: POST with lowercase 'true' instead of 'True'
expecting: Settings should update correctly
next_action: COMPLETE - Fix verified

## Symptoms

expected: POST to /api/system/settings with form data settings-general-use_sonarr=True should enable Sonarr integration
actual: API returns 200 but settings remain unchanged in config.yaml
errors: None - API accepts request but doesn't apply changes
reproduction: |
  ```bash
  API_KEY=$(docker exec bazarr sed -n 's/.*apikey:\s*\([a-f0-9]*\).*/\1/p' /config/config/config.yaml)
  docker exec bazarr curl -s -X POST "http://localhost:6767/api/system/settings" \
    -H "X-API-KEY: $API_KEY" \
    -d "settings-general-use_sonarr=True" \
    -d "settings-general-use_radarr=True"
  # Check - still false:
  docker exec bazarr grep -E "use_sonarr|use_radarr" /config/config/config.yaml
  ```
started: Testing bootstrap automation for media stack

## Eliminated

## Evidence

- timestamp: 2026-01-18T00:00:30Z
  checked: Bazarr source code /app/bazarr/bin/bazarr/app/config.py
  found: |
    Lines 696-699 show boolean conversion:
    ```python
    if value == 'true':
        value = True
    elif value == 'false':
        value = False
    ```
    Only lowercase 'true'/'false' are converted to boolean True/False
  implication: Capitalized 'True' is passed as string, fails type validation

- timestamp: 2026-01-18T00:00:45Z
  checked: API call with capitalized 'True'
  found: |
    Response: "general.use_sonarr must is_type_of <class 'bool'> but it is True"
    Settings remain unchanged
  implication: Validates hypothesis - string 'True' fails bool type check

- timestamp: 2026-01-18T00:01:00Z
  checked: API call with lowercase 'true'
  found: |
    Response: 204 (success)
    Config updated: use_sonarr: true, use_radarr: true
  implication: Confirms fix - lowercase 'true' works correctly

- timestamp: 2026-01-18T00:02:00Z
  checked: End-to-end bootstrap test
  found: |
    Before: use_radarr: false, use_sonarr: false
    After: use_radarr: true, use_sonarr: true
    Script output: "Bazarr configured. API key saved to .env"
  implication: Fix verified - pure API solution now works

## Resolution

root_cause: Bazarr's save_settings() function only converts lowercase 'true'/'false' strings to boolean values (lines 696-699 in config.py). Sending capitalized 'True' causes the value to remain as a string, which fails the is_type_of=bool validator with error 406.

fix: |
  Updated /home/rushil/workspace/ragnalab/stack/media/scripts/bootstrap-bazarr.sh:
  1. Changed API key extraction to avoid newlines in variable
  2. Added settings-general-use_sonarr=true and settings-general-use_radarr=true to API calls
  3. Removed sed config file modification (pure API solution)
  4. Removed unnecessary container restart (API persists immediately)

verification: |
  Tested end-to-end:
  1. Reset settings to false via API
  2. Ran bootstrap script
  3. Verified settings changed to true in config.yaml
  All tests passed.

files_changed:
  - /home/rushil/workspace/ragnalab/stack/media/scripts/bootstrap-bazarr.sh
