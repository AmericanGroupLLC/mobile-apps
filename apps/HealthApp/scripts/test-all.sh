#!/usr/bin/env bash
# Run every test suite locally. Skips iOS/Watch on non-macOS.
# Usage:  ./scripts/test-all.sh
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)

green()  { printf "\033[1;32m%s\033[0m\n" "$1"; }
yellow() { printf "\033[1;33m%s\033[0m\n" "$1"; }
red()    { printf "\033[1;31m%s\033[0m\n" "$1"; }

failures=0

# ──────────────────────── Backend ────────────────────────
green "▶ Backend (Jest + smoke)"
(
  cd "$ROOT/server"
  if [ ! -f .env ]; then
    cp .env.example .env
    if [ "$(uname)" = "Darwin" ]; then
      sed -i '' "s|JWT_SECRET=.*|JWT_SECRET=test-secret-12345678901234567890|" .env
      sed -i '' "s|DB_PATH=.*|DB_PATH=$(mktemp -t myhealth.XXXX).db|" .env
    else
      sed -i "s|JWT_SECRET=.*|JWT_SECRET=test-secret-12345678901234567890|" .env
      sed -i "s|DB_PATH=.*|DB_PATH=$(mktemp -t myhealth.XXXXXX --suffix=.db)|" .env
    fi
  fi
  npm ci --no-audit --no-fund
  # Care+ v1: runs both the original api.test.js and the new careplus.test.js
  # (vendor / insurance / fhir-401 / doctors-validation / audit-log smoke).
  npm test
  node server.js & SERVER_PID=$!
  sleep 3
  set +e
  node smoke.js
  RC=$?
  set -e
  kill "$SERVER_PID" 2>/dev/null || true
  exit $RC
) || { red "✗ Backend tests failed"; failures=$((failures+1)); }

# ──────────────────────── Android ────────────────────────
if command -v gradle >/dev/null 2>&1 || [ -x "$ROOT/android/gradlew" ]; then
  green "▶ Android (core + app unit tests)"
  (
    cd "$ROOT/android"
    if [ ! -x ./gradlew ]; then
      gradle wrapper --gradle-version 8.10
      chmod +x gradlew
    fi
    ./gradlew :core:testDebugUnitTest :app:testDebugUnitTest
  ) || { red "✗ Android unit tests failed"; failures=$((failures+1)); }
else
  yellow "⚠ Skipping Android (gradle not installed)"
fi

# ──────────────────────── iOS / watchOS ────────────────────────
if [ "$(uname)" = "Darwin" ] && command -v xcodebuild >/dev/null 2>&1; then
  green "▶ Swift Package tests"
  (cd "$ROOT/shared/FitFusionCore" && swift test --parallel) \
    || { red "✗ Swift Package tests failed"; failures=$((failures+1)); }

  if command -v xcodegen >/dev/null 2>&1; then
    green "▶ iOS simulator build"
    (
      cd "$ROOT/ios" && xcodegen generate
      xcodebuild -project FitFusion.xcodeproj -scheme FitFusion \
        -sdk iphonesimulator -configuration Debug \
        -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
        CODE_SIGNING_ALLOWED=NO build
    ) || { red "✗ iOS simulator build failed"; failures=$((failures+1)); }
  else
    yellow "⚠ Skipping iOS sim build (xcodegen not installed: brew install xcodegen)"
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
if [ "$failures" -eq 0 ]; then
  green "✓ All available suites passed"
else
  red "✗ $failures suite(s) failed"
  exit 1
fi
