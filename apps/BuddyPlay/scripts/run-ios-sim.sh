#!/usr/bin/env bash
# Boot iPhone 15 simulator, install BuddyPlay.app, launch it, and exit.
# macOS-only.
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)
DEVICE=${SIM_DEVICE:-"iPhone 15"}

green()  { printf "\033[1;32m%s\033[0m\n" "$1"; }

if [ "$(uname)" != "Darwin" ]; then
  echo "macOS required" >&2; exit 1
fi
command -v xcodegen >/dev/null || { echo "Install xcodegen: brew install xcodegen" >&2; exit 1; }

green "▶ Generating Xcode project"
(cd "$ROOT/ios" && xcodegen generate)

green "▶ Booting simulator: $DEVICE"
SIM_UDID=$(xcrun simctl list devices available | grep "$DEVICE" | head -n1 | grep -oE '[0-9A-F-]{36}')
if [ -z "$SIM_UDID" ]; then
  echo "No simulator found for '$DEVICE'. Available:" >&2
  xcrun simctl list devices available | head -n40 >&2
  exit 1
fi
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
open -a Simulator

green "▶ Building BuddyPlay.app for simulator"
xcodebuild -project "$ROOT/ios/BuddyPlay.xcodeproj" \
  -scheme BuddyPlay \
  -sdk iphonesimulator \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  CODE_SIGNING_ALLOWED=NO \
  -derivedDataPath "$ROOT/build/derivedData" \
  build

APP=$(find "$ROOT/build/derivedData/Build/Products/Debug-iphonesimulator" -maxdepth 1 -name '*.app' | head -n1)
if [ -z "$APP" ]; then echo "Built .app not found" >&2; exit 1; fi

green "▶ Installing $APP"
xcrun simctl install "$SIM_UDID" "$APP"

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP/Info.plist")
green "▶ Launching $BUNDLE_ID"
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"

green "✓ Running. Open Simulator.app to interact."
