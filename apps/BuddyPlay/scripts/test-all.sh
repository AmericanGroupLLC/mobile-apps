#!/usr/bin/env bash
# Run every test suite locally. Skips iOS on non-macOS, skips Android
# when Gradle isn't installed.
# Usage:  ./scripts/test-all.sh
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)

green()  { printf "\033[1;32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[1;33m%s\033[0m\n" "$1"; }
red()    { printf "\033[1;31m%s\033[0m\n" "$1"; }

failures=0

# ──────────────────────── Android ────────────────────────
if command -v gradle >/dev/null 2>&1 || [ -x "$ROOT/android/gradlew" ]; then
  green "▶ Android (core + app unit tests)"
  (
    cd "$ROOT/android"
    if [ ! -x ./gradlew ]; then
      gradle wrapper --gradle-version 8.10
      chmod +x gradlew
    fi
    # NOTE: :core is JVM-only — `:core:test`, NOT `:core:testDebugUnitTest`.
    ./gradlew :core:test :app:testDebugUnitTest
  ) || { red "✗ Android unit tests failed"; failures=$((failures+1)); }
else
  yellow "⚠ Skipping Android (gradle not installed)"
fi

# ──────────────────────── iOS ────────────────────────
if [ "$(uname)" = "Darwin" ] && command -v xcodebuild >/dev/null 2>&1; then
  green "▶ BuddyCore Swift Package tests"
  (
    cd "$ROOT/shared/BuddyCore"
    xcodebuild test \
      -scheme BuddyCore-Package \
      -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
      CODE_SIGNING_ALLOWED=NO | xcpretty --simple
  ) || { red "✗ BuddyCore tests failed"; failures=$((failures+1)); }

  if command -v xcodegen >/dev/null 2>&1; then
    green "▶ iOS simulator build"
    (
      cd "$ROOT/ios" && xcodegen generate
      xcodebuild -project BuddyPlay.xcodeproj -scheme BuddyPlay \
        -sdk iphonesimulator -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
        CODE_SIGNING_ALLOWED=NO build | xcpretty --simple
    ) || { red "✗ iOS simulator build failed"; failures=$((failures+1)); }
  else
    yellow "⚠ Skipping iOS sim build (xcodegen not installed: brew install xcodegen)"
  fi
else
  yellow "⚠ Skipping iOS (not on macOS or xcodebuild missing)"
fi

# ──────────────────────── Marketing site (lint) ────────────
if command -v npx >/dev/null 2>&1; then
  green "▶ Marketing site lint (best-effort)"
  npx --yes htmlhint "$ROOT/index.html" || true
fi

echo
if [ "$failures" -eq 0 ]; then
  green "✓ All available suites passed"
else
  red "✗ $failures suite(s) failed"
  exit 1
fi
