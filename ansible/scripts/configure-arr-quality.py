#!/usr/bin/env python3
"""Configure *arr quality profile: 4K Minimal with x265 preference.

Usage: configure-arr-quality.py <container> <port> <api_key>

Creates:
  - "Prefer x265" custom format (scores x265/HEVC releases higher)
  - "4K Minimal" quality profile (WEB 2160p + WEB 1080p fallback, upgrades enabled)

Idempotent — safe to run multiple times.
"""

import json
import subprocess
import sys


def api(container, port, api_key, method, path, data=None):
    cmd = ["docker", "exec"]
    if data is not None:
        cmd.append("-i")
    cmd.extend([container, "curl", "-sf"])
    if method != "GET":
        cmd.extend(["-X", method])
    cmd.extend([
        "-H", "Content-Type: application/json",
        "-H", f"X-Api-Key: {api_key}",
    ])
    if data is not None:
        cmd.extend(["-d", "@-"])
    cmd.append(f"http://localhost:{port}/api/v3{path}")

    result = subprocess.run(
        cmd,
        input=json.dumps(data) if data is not None else None,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"API error on {method} {path}: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return json.loads(result.stdout) if result.stdout.strip() else None


def main():
    container = sys.argv[1]
    port = sys.argv[2]
    api_key = sys.argv[3]

    call = lambda method, path, data=None: api(container, port, api_key, method, path, data)
    changed = False

    # --- Custom format: Prefer x265 ---
    formats = call("GET", "/customformat")
    x265_id = next((f["id"] for f in formats if f["name"] == "Prefer x265"), None)

    if x265_id is None:
        result = call("POST", "/customformat", {
            "name": "Prefer x265",
            "includeCustomFormatWhenRenaming": False,
            "specifications": [{
                "name": "x265/HEVC",
                "implementation": "ReleaseTitleSpecification",
                "negate": False,
                "required": False,
                "fields": [{"name": "value", "value": "[xh]\\.?265|HEVC"}],
            }],
        })
        x265_id = result["id"]
        changed = True
        print(f"Created 'Prefer x265' custom format (id={x265_id})")
    else:
        print(f"'Prefer x265' custom format already exists (id={x265_id})")

    # --- Quality profile: 4K Minimal ---
    profiles = call("GET", "/qualityprofile")
    if any(p["name"] == "4K Minimal" for p in profiles):
        print("'4K Minimal' quality profile already exists — nothing to do")
        sys.exit(0)

    # Clone Ultra-HD profile as template (has correct quality items for this *arr)
    template = next((p for p in profiles if p["name"] == "Ultra-HD"), None)
    if template is None:
        print("ERROR: 'Ultra-HD' profile not found to use as template", file=sys.stderr)
        sys.exit(1)

    template.pop("id", None)
    template["name"] = "4K Minimal"
    template["upgradeAllowed"] = True
    template["cutoff"] = 1003  # WEB 2160p group

    # Only allow WEB 2160p (target) and WEB 1080p (fallback)
    allowed_groups = {"WEB 1080p", "WEB 2160p"}
    for item in template["items"]:
        is_allowed_group = "name" in item and item["name"] in allowed_groups
        if is_allowed_group:
            item["allowed"] = True
            for sub in item.get("items", []):
                sub["allowed"] = True
        else:
            item["allowed"] = False
            for sub in item.get("items", []):
                sub["allowed"] = False

    # Score x265 releases higher → picks smaller files
    template["formatItems"] = [
        {"format": x265_id, "name": "Prefer x265", "score": 100},
    ]
    template["minFormatScore"] = 0
    template["cutoffFormatScore"] = 0
    template["minUpgradeFormatScore"] = 1

    call("POST", "/qualityprofile", template)
    changed = True
    print("Created '4K Minimal' quality profile")

    sys.exit(0 if not changed else 2)  # exit 2 = changed (for Ansible)


if __name__ == "__main__":
    main()
