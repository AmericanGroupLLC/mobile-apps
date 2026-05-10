#!/usr/bin/env bash
# Run every test suite locally. Skips iOS/Watch on non-macOS, skips Android
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
  green "▶ Android (core + app + wear unit tests)"
  (
    cd "$ROOT/android"
    if [ ! -x ./gradlew ]; then
      gradle wrapper --gradle-version 8.10
      chmod +x gradlew
    fi
    # NOTE: :core is JVM-only — `:core:test`, NOT `:core:testDebugUnitTest`.
    ./gradlew :core:test :app:testDebugUnitTest :wear:testDebugUnitTest
  ) || { red "✗ Android unit tests failed"; failures=$((failures+1)); }
else
  yellow "⚠ Skipping Android (gradle not installed)"
fi

# ──────────────────────── iOS / watchOS ────────────────────────
if [ "$(uname)" = "Darwin" ] && command -v xcodebuild >/dev/null 2>&1; then
  green "▶ DriftCore Swift Package tests"
  (
    cd "$ROOT/shared/DriftCore"
    xcodebuild test \
      -scheme DriftCore-Package \
      -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
      CODE_SIGNING_ALLOWED=NO | xcpretty --simple
  ) || { red "✗ DriftCore tests failed"; failures=$((failures+1)); }

  if command -v xcodegen >/dev/null 2>&1; then
    green "▶ iOS simulator build"
    (
      cd "$ROOT/ios" && xcodegen generate
      xcodebuild -project Drift.xcodeproj -scheme Drift \
        -sdk iphonesimulator -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
        CODE_SIGNING_ALLOWED=NO build | xcpretty --simple
    ) || { red "✗ iOS simulator build failed"; failures=$((failures+1)); }

    green "▶ watchOS simulator build"
    (
      cd "$ROOT/watchos" && xcodegen generate
      xcodebuild -project DriftWatch.xcodeproj -scheme DriftWatch \
        -sdk watchsimulator -configuration Debug \
        -destination 'platform=watchOS Simulator,name=Apple Watch Series 10 (46mm),OS=latest' \
        CODE_SIGNING_ALLOWED=NO build | xcpretty --simple
    ) || { red "✗ watchOS simulator build failed"; failures=$((failures+1)); }
  else
    yellow "⚠ Skipping iOS/watchOS sim build (xcodegen not installed: brew install xcodegen)"
  fi
else
  yellow "⚠ Skipping iOS/watchOS (not on macOS or xcodebuild missing)"
fi

# ──────────────────────── Marketing site (lint) ────────────
if command -v npx >/dev/null 2>&1; then
  green "▶ Marketing site lint (best-effort)"
  npx --yes htmlhint "$ROOT/index.html" || true
fi

echo
green "▶ Edge Function tests (Deno)"
if command -v deno >/dev/null 2>&1; then
  shopt -s nullglob
  tests=( "$ROOT"/backend/supabase/functions/*/_test.ts )
  if [ "${#tests[@]}" -gt 0 ]; then
    for t in "${tests[@]}"; do
      echo "=== $t ==="
      deno test --allow-env --allow-net --no-check "$t" \
        || { red "✗ Edge Function test failed: $t"; failures=$((failures+1)); }
    done
  else
    yellow "⚠ No Edge Function tests found yet"
  fi
else
  yellow "⚠ Skipping Edge Function tests (deno not installed)"
fi

echo
if [ "$failures" -eq 0 ]; then
  green "✓ All available suites passed"
else
  red "✗ $failures suite(s) failed"
  exit 1
fi
