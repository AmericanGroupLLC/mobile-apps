#!/usr/bin/env bash
# Verify release.config.json is well-formed and references existing docs.
# Usage: scripts/verify-release-config.sh
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)
CFG="$ROOT/release.config.json"

ok()   { printf "  \033[1;32m✓\033[0m %s\n" "$1"; }
fail() { printf "  \033[1;31m✗\033[0m %s\n" "$1"; FAILED=1; }
warn() { printf "  \033[1;33m!\033[0m %s\n" "$1"; }

FAILED=0
[ -f "$CFG" ] || { fail "missing release.config.json at $CFG"; exit 1; }

if ! command -v jq >/dev/null 2>&1; then
  warn "jq not installed; install it for full schema validation"
  exit 0
fi

jq empty "$CFG" 2>/dev/null && ok "valid JSON" || fail "invalid JSON"

# Required keys
for key in schemaVersion appName appSlug displayName bundleId applicationId \
           electronAppId brandColor iconLetter platforms docs; do
  if jq -e ". | has(\"$key\")" "$CFG" >/dev/null; then
    ok "key '$key' present"
  else
    fail "missing required key '$key'"
  fi
done

# Brand colour is hex
BRAND=$(jq -r '.brandColor' "$CFG")
if [[ "$BRAND" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
  ok "brandColor format ok ($BRAND)"
else
  fail "brandColor must be #RRGGBB (got $BRAND)"
fi

# Bundle id format
BID=$(jq -r '.bundleId' "$CFG")
if [[ "$BID" =~ ^[a-zA-Z][a-zA-Z0-9.-]+(\.[a-zA-Z][a-zA-Z0-9.-]+)+$ ]]; then
  ok "bundleId format ok ($BID)"
else
  fail "bundleId must be reverse-DNS (got $BID)"
fi

# Docs exist
echo "▼ docs check"
MISSING=0
while IFS= read -r d; do
  if [ -f "$ROOT/$d" ]; then
    ok "doc: $d"
  else
    fail "doc missing: $d"
    MISSING=1
  fi
done < <(jq -r '.docs[]?' "$CFG")

# Marketing html exists
HTML=$(jq -r '.marketingHtml // "index.html"' "$CFG")
[ -f "$ROOT/$HTML" ] && ok "marketingHtml: $HTML" || fail "marketingHtml missing: $HTML"

# Video script exists (warn only — optional file)
VS=$(jq -r '.videoScript // "RELEASE-VIDEO-SCRIPT.md"' "$CFG")
[ -f "$ROOT/$VS" ] && ok "videoScript: $VS" || warn "videoScript missing: $VS"

# Desktop subdir exists if platforms.desktop=true
DESK=$(jq -r '.platforms.desktop // false' "$CFG")
if [ "$DESK" = "true" ]; then
  [ -d "$ROOT/desktop" ] && ok "desktop/ dir present" || fail "platforms.desktop=true but desktop/ dir missing"
fi

if [ "$FAILED" -eq 0 ]; then
  printf "\n\033[1;32m✓ release.config.json verified\033[0m\n"
else
  printf "\n\033[1;31m✗ verification FAILED\033[0m\n"
  exit 1
fi
