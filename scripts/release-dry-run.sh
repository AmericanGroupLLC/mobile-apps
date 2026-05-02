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

# Android phone APK + AAB + Wear APK
if [ -d "$ROOT/android" ]; then
  green "▶ Android build"
  (
    cd "$ROOT/android"
    [ -x ./gradlew ] || { gradle wrapper --gradle-version 8.10; chmod +x gradlew; }
    ./gradlew :app:assembleRelease :app:bundleRelease :wear:assembleRelease
  )
  cp "$ROOT/android/app/build/outputs/apk/release/app-release.apk"      "$STAGE/MyHealth-$TAG.apk"      || true
  cp "$ROOT/android/app/build/outputs/bundle/release/app-release.aab"   "$STAGE/MyHealth-$TAG.aab"      || true
  cp "$ROOT/android/wear/build/outputs/apk/release/wear-release.apk"    "$STAGE/MyHealth-Wear-$TAG.apk" || true
fi

# Server tarball
if [ -d "$ROOT/server" ]; then
  green "▶ Server tarball"
  (cd "$ROOT/server" && npm ci --omit=dev --no-audit --no-fund)
  tar --exclude='node_modules/.cache' \
      -czf "$STAGE/myhealth-server-$TAG.tgz" -C "$ROOT/server" .
fi

# Marketing zip
green "▶ Marketing site zip"
zip -j "$STAGE/myhealth-web-$TAG.zip" \
  "$ROOT/index.html" "$ROOT/styles.css" "$ROOT/script.js" >/dev/null

# iOS xcarchive (only on macOS + xcodegen)
if [ "$(uname)" = "Darwin" ] && command -v xcodegen >/dev/null 2>&1; then
  green "▶ iOS unsigned archive"
  (cd "$ROOT/ios" && xcodegen generate)
  xcodebuild -project "$ROOT/ios/FitFusion.xcodeproj" \
    -scheme FitFusion -configuration Release -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -archivePath "$ROOT/ios/build/MyHealth.xcarchive" \
    CODE_SIGNING_ALLOWED=NO archive | xcpretty --simple || true
  if [ -d "$ROOT/ios/build/MyHealth.xcarchive" ]; then
    (cd "$ROOT/ios/build" && zip -qr "$STAGE/MyHealth-$TAG-iOS.xcarchive.zip" MyHealth.xcarchive)
  fi
fi

green "▶ Done. Artefacts in: $STAGE"
ls -la "$STAGE"
