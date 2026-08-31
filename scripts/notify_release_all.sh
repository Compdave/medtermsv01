#!/usr/bin/env bash
#
# scripts/notify_release_all.sh
#
# Convenience wrapper around notify_release_version.sh. Marks the same
# version as pending_version for every app in this Supabase project
# (medterms, teasquiz) on both platforms (ios, android) in one call.
#
# Same rules as the underlying script apply per (app_id, platform):
# nothing happens unless the given version is higher than both the current
# live_version and any existing pending_version, and the hourly
# app-version-promotion job still gates pending -> live on store confirmation.
#
# Requires the Supabase SERVICE_ROLE key in the environment:
#   export SUPABASE_SERVICE_ROLE_KEY=...
#
# Usage:
#   ./scripts/notify_release_all.sh <version>
#
# Example:
#   ./scripts/notify_release_all.sh 2.23.91

set -euo pipefail

VERSION="${1:-}"

if [[ -z "$VERSION" ]]; then
  echo "Usage: $0 <version>   (e.g. $0 2.23.91)" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFY="$SCRIPT_DIR/notify_release_version.sh"

APP_IDS=(com.reichardreviews.medterms com.reichardreviews.teassci26)
PLATFORMS=(ios android)

fail=0
for app_id in "${APP_IDS[@]}"; do
  for platform in "${PLATFORMS[@]}"; do
    echo "=== $app_id / $platform -> $VERSION ==="
    if ! "$NOTIFY" "$app_id" "$platform" "$VERSION"; then
      echo "!! failed: $app_id / $platform" >&2
      fail=1
    fi
    echo
  done
done

if [[ "$fail" -ne 0 ]]; then
  echo "One or more updates failed — see output above." >&2
fi
exit "$fail"
