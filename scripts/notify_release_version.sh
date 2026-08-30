#!/usr/bin/env bash
#
# scripts/notify_release_version.sh
#
# Component A of the in-app update notification feature
# (see version-notification-plan.md). Run this by hand right after your
# smoke-test open confirms a new build works — NOT part of the shipped app,
# and never bundled into it (it lives outside lib/ and isn't referenced by
# any Dart code).
#
# Writes app_versions.pending_version (+ pending_date) for one (app_id,
# platform) pair, but only if the new version is higher than both the
# current live_version and any existing pending_version. The background
# app-version-promotion Edge Function later promotes pending -> live once
# the store actually shows the new version live.
#
# Requires the Supabase SERVICE_ROLE key in the environment — never hardcode
# it here, never commit it:
#
#   export SUPABASE_SERVICE_ROLE_KEY=...
#
# Usage:
#   ./scripts/notify_release_version.sh <app_id> <ios|android> <version>
#
# Examples:
#   ./scripts/notify_release_version.sh medterms ios 2.24.0
#   ./scripts/notify_release_version.sh teasquiz android 2.24.0

set -euo pipefail

SUPABASE_URL="https://fxgbpemusuvplqumhcgi.supabase.co"

APP_ID="${1:-}"
PLATFORM="${2:-}"
VERSION="${3:-}"

if [[ -z "$APP_ID" || -z "$PLATFORM" || -z "$VERSION" ]]; then
  echo "Usage: $0 <app_id> <ios|android> <version>" >&2
  echo "Example: $0 medterms ios 2.24.0" >&2
  exit 1
fi

if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "android" ]]; then
  echo "Error: platform must be 'ios' or 'android', got '$PLATFORM'" >&2
  exit 1
fi

if [[ -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "Error: SUPABASE_SERVICE_ROLE_KEY is not set in the environment." >&2
  echo "Get it from Supabase Dashboard -> Project Settings -> API -> service_role," >&2
  echo "then: export SUPABASE_SERVICE_ROLE_KEY=..." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: this script requires jq (brew install jq / apt install jq)." >&2
  exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: version must look like x.y.z (got '$VERSION')" >&2
  exit 1
fi

# Returns 0 (true) if $1 > $2, using GNU sort -V for semver-ish comparison.
version_gt() {
  local a="$1" b="$2"
  [[ "$a" == "$b" ]] && return 1
  local higher
  higher="$(printf '%s\n%s\n' "$a" "$b" | sort -V | tail -n1)"
  [[ "$higher" == "$a" ]]
}

echo "Checking current status for app_id=$APP_ID platform=$PLATFORM..."

current_json="$(curl -sf \
  "$SUPABASE_URL/rest/v1/app_versions?app_id=eq.$APP_ID&platform=eq.$PLATFORM&select=live_version,pending_version" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY")"

row_count="$(echo "$current_json" | jq 'length')"
if [[ "$row_count" -eq 0 ]]; then
  echo "Error: no app_versions row found for app_id=$APP_ID platform=$PLATFORM." >&2
  echo "Insert one first (see version-notification-plan.md's table schema)." >&2
  exit 1
fi

live_version="$(echo "$current_json" | jq -r '.[0].live_version')"
pending_version="$(echo "$current_json" | jq -r '.[0].pending_version // "0.0.0"')"

echo "  live_version=$live_version pending_version=$pending_version"

if version_gt "$VERSION" "$live_version" && version_gt "$VERSION" "$pending_version"; then
  echo "  $VERSION is newer than both -> marking as pending."
  curl -sf -X PATCH \
    "$SUPABASE_URL/rest/v1/app_versions?app_id=eq.$APP_ID&platform=eq.$PLATFORM" \
    -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "{\"pending_version\": \"$VERSION\", \"pending_date\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
    | jq .
  echo "Done. app-version-promotion will flip this to live_version once the store confirms it (iOS: hourly poll; Android: 4h after this run)."
else
  echo "  $VERSION is not newer than the current live/pending version — nothing to do."
fi
