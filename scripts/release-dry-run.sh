#!/usr/bin/env bash
# Locally build every release artefact without pushing anything. Mirrors what
# release.yml does on a tag push. Useful to catch issues before tagging.
# Usage:  ./scripts/release-dry-run.sh v1.2.0
set -euo pipefail
TAG="${1:?Pass a tag like v1.2.0}"

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)
STAGE="$ROOT/distribution/staging-$TAG"
mkdir -p "$STAGE"

green()  { printf "\033[1;32m%s\033[0m\n" "$1"; }

# Android phone APK + AAB
if [ -d "$ROOT/android" ]; then
  green "▶ Android build"
  (
    cd "$ROOT/android"
    [ -x ./gradlew ] || { gradle wrapper --gradle-version 8.10; chmod +x gradlew; }
    ./gradlew :app:assembleRelease :app:bundleRelease
  )
  cp "$ROOT/android/app/build/outputs/apk/release/app-release.apk"      "$STAGE/BuddyPlay-$TAG.apk" || true
  cp "$ROOT/android/app/build/outputs/bundle/release/app-release.aab"   "$STAGE/BuddyPlay-$TAG.aab" || true
fi

# Marketing zip
green "▶ Marketing site zip"
zip -j "$STAGE/buddyplay-web-$TAG.zip" \
  "$ROOT/index.html" "$ROOT/styles.css" "$ROOT/script.js" \
  "$ROOT/robots.txt" "$ROOT/sitemap.xml" >/dev/null

# iOS xcarchive (only on macOS + xcodegen)
if [ "$(uname)" = "Darwin" ] && command -v xcodegen >/dev/null 2>&1; then
  green "▶ iOS unsigned archive"
  (cd "$ROOT/ios" && xcodegen generate)
  xcodebuild -project "$ROOT/ios/BuddyPlay.xcodeproj" \
    -scheme BuddyPlay -configuration Release -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -archivePath "$ROOT/ios/build/BuddyPlay.xcarchive" \
    CODE_SIGNING_ALLOWED=NO archive | xcpretty --simple || true
  if [ -d "$ROOT/ios/build/BuddyPlay.xcarchive" ]; then
    (cd "$ROOT/ios/build" && zip -qr "$STAGE/BuddyPlay-$TAG-iOS.xcarchive.zip" BuddyPlay.xcarchive)
  fi
fi

green "▶ Done. Artefacts in: $STAGE"
ls -la "$STAGE"

# === added-by-productionize-plan: extended dry-run checks ===
green() { printf "\033[1;32m%s\033[0m\n" "$1"; }
warn()  { printf "\033[1;33m%s\033[0m\n" "$1"; }

# 1. release.config.json validity
green "▶ Validate release.config.json"
if [ -f "$ROOT/release.config.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    jq empty "$ROOT/release.config.json" || { echo "::error::release.config.json invalid"; exit 1; }
    APPNAME=$(jq -r '.appName' "$ROOT/release.config.json")
    BRAND=$(jq -r '.brandColor' "$ROOT/release.config.json")
    echo "  appName=$APPNAME  brandColor=$BRAND"
  else
    warn "  jq not installed — skipping JSON schema check"
  fi
else
  echo "::error::release.config.json missing"; exit 1
fi

# 2. Desktop electron-builder dir-pack
if [ -d "$ROOT/desktop" ]; then
  green "▶ Desktop dry-build (electron-builder --linux --dir)"
  if command -v node >/dev/null 2>&1; then
    NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
    if [ "$NODE_MAJOR" -lt 18 ]; then
      warn "  node $(node -v) is too old for Electron 33 — skipping (need >= 18)"
    else
      (
        cd "$ROOT/desktop"
        if [ ! -d node_modules ]; then npm install --no-audit --no-fund; fi
        npx electron-builder --linux --dir || warn "  electron-builder failed (non-fatal in dry-run)"
      )
    fi
  else
    warn "  node not installed — skipping desktop dry-build"
  fi
fi

# 3. PDF release book — pandoc syntax check on each listed doc
if [ -f "$ROOT/release.config.json" ] && command -v jq >/dev/null 2>&1; then
  green "▶ Validate docs list referenced by release.config.json.docs"
  MISSING=0
  while IFS= read -r d; do
    if [ ! -f "$ROOT/$d" ]; then
      echo "  ✗ missing: $d"; MISSING=1
    fi
  done < <(jq -r '.docs[]?' "$ROOT/release.config.json")
  [ "$MISSING" -eq 0 ] && echo "  all docs present" || warn "  some docs missing"

  if command -v pandoc >/dev/null 2>&1; then
    green "▶ pandoc syntax check (markdown only, no PDF render)"
    while IFS= read -r d; do
      [ -f "$ROOT/$d" ] || continue
      pandoc "$ROOT/$d" -t plain -o /dev/null \
        || warn "  pandoc parse warnings for $d"
    done < <(jq -r '.docs[]?' "$ROOT/release.config.json")
  else
    warn "  pandoc not installed — skipping syntax check"
  fi
fi

# 4. RELEASE-VIDEO-SCRIPT.md parse check
if [ -f "$ROOT/RELEASE-VIDEO-SCRIPT.md" ]; then
  green "▶ Parse RELEASE-VIDEO-SCRIPT.md"
  PARSER="$HOME/AmericanGroupLLC/AmericanGroupLLC/scripts/parse-video-script.js"
  if [ -f "$PARSER" ] && command -v node >/dev/null 2>&1; then
    NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
    if [ "$NODE_MAJOR" -lt 12 ]; then
      warn "  node too old to run parser"
    else
      SCENE_COUNT=$(node "$PARSER" "$ROOT/RELEASE-VIDEO-SCRIPT.md" \
                       --app-name TEST --version vTEST | jq 'length' 2>/dev/null \
                    || echo "?")
      echo "  parsed $SCENE_COUNT scene(s)"
    fi
  else
    warn "  parser or node missing — skipping"
  fi
fi

# 5. actionlint on workflows (best effort)
if command -v actionlint >/dev/null 2>&1; then
  green "▶ actionlint workflows"
  actionlint -color "$ROOT/.github/workflows/"*.yml || warn "  actionlint reported issues"
else
  warn "  actionlint not installed — skipping (https://github.com/rhysd/actionlint)"
fi

green "▶ Extended checks complete"
