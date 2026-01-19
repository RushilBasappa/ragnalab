---
status: resolved
trigger: "Automate Jellyfin initial setup via API instead of requiring manual wizard"
created: 2026-01-18T12:00:00Z
updated: 2026-01-19T00:00:00Z
resolved: 2026-01-19T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED - Full API-based setup is possible
test: Tested all endpoints against running Jellyfin instance
expecting: All endpoints work for automated setup
next_action: Implement new bootstrap script with verified API calls

## Symptoms

expected: Fully automated Jellyfin setup via API (create admin user, add libraries, get API key)
actual: Current script just checks if setup is complete and extracts API key after manual setup
errors: None - need to research and implement
reproduction: See current script at /home/rushil/workspace/ragnalab/stack/media/scripts/bootstrap-jellyfin.sh
started: Building automated bootstrap for media stack

## Eliminated

## Evidence

- timestamp: 2026-01-18T12:00:00Z
  checked: Current bootstrap script
  found: Script only checks StartupWizardCompleted status and extracts existing API key from system.xml
  implication: Need to implement actual setup automation via API

- timestamp: 2026-01-18T12:01:00Z
  checked: Jellyfin System/Info/Public endpoint
  found: StartupWizardCompleted: false - wizard not yet done
  implication: Can test full setup flow

- timestamp: 2026-01-18T12:02:00Z
  checked: Jellyfin Startup API endpoints
  found: /Startup/Configuration and /Startup/User endpoints exist and respond
  implication: API endpoints are available for programmatic setup

- timestamp: 2026-01-18T12:03:00Z
  checked: Web search for Jellyfin CLI setup
  found: Full setup via curl - POST to /Startup/Configuration with UICulture/MetadataCountryCode/PreferredMetadataLanguage,
         POST to /Startup/User with Name/Password, then /Startup/Complete
  implication: Can automate entire wizard flow via API

- timestamp: 2026-01-18T12:04:00Z
  checked: Tested POST /Startup/Configuration
  found: Returns 204 No Content on success with JSON body {"UICulture":"en-US","MetadataCountryCode":"US","PreferredMetadataLanguage":"en"}
  implication: Configuration endpoint works

- timestamp: 2026-01-18T12:05:00Z
  checked: Tested POST /Startup/User
  found: Returns 204 No Content on success with JSON body {"Name":"admin","Password":"safehaven"}
  implication: User creation endpoint works

- timestamp: 2026-01-18T12:06:00Z
  checked: Tested POST /Startup/Complete
  found: Returns 204 No Content on success, then StartupWizardCompleted becomes true
  implication: Wizard completion endpoint works

- timestamp: 2026-01-18T12:07:00Z
  checked: Tested POST /Users/AuthenticateByName
  found: Returns AccessToken in response, requires X-Emby-Authorization header with Client/Device/DeviceId/Version
  implication: Can get access token for subsequent authenticated requests

- timestamp: 2026-01-18T12:08:00Z
  checked: Tested POST /Library/VirtualFolders
  found: Works with query params name=X&collectionType=movies|tvshows and JSON body with LibraryOptions including PathInfos
  implication: Can add libraries programmatically

- timestamp: 2026-01-18T12:09:00Z
  checked: Tested POST /Auth/Keys?app=X
  found: Creates API key, then GET /Auth/Keys returns Items array with AccessToken field
  implication: Can create and retrieve API key programmatically

## Resolution

root_cause: Original script had no implementation - just placeholder that checked status and extracted existing API key. Full API-based setup is possible via Jellyfin's Startup, Users, Library, and Auth endpoints.
fix: Implement complete bootstrap script using verified API endpoints
verification: Tested each endpoint individually against running Jellyfin instance
files_changed:
  - stack/media/scripts/bootstrap-jellyfin.sh
