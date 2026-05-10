#!/usr/bin/env bash
# Boot an Android emulator, install the debug APK, and launch the app.
# Requires the Android SDK + a created AVD.
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)
AVD=${AVD_NAME:-"Pixel_6_API_34"}

green()  { printf "\033[1;32m%s\033[0m\n" "$1"; }

if [ -z "${ANDROID_HOME:-}" ]; then
  echo "Set ANDROID_HOME (Android SDK root)." >&2; exit 1
fi
EMULATOR="$ANDROID_HOME/emulator/emulator"
ADB="$ANDROID_HOME/platform-tools/adb"

if ! "$EMULATOR" -list-avds | grep -qx "$AVD"; then
  echo "AVD '$AVD' not found. Available:" >&2
  "$EMULATOR" -list-avds >&2
  echo "Create one in Android Studio → Device Manager." >&2
  exit 1
fi

green "▶ Building :app:assembleDebug"
(cd "$ROOT/android" && ./gradlew :app:assembleDebug)

green "▶ Booting AVD: $AVD"
"$EMULATOR" -avd "$AVD" -no-snapshot-save -no-boot-anim -netdelay none -netspeed full &
EMU_PID=$!
trap "kill $EMU_PID 2>/dev/null || true" EXIT

green "▶ Waiting for boot"
"$ADB" wait-for-device
until [ "$("$ADB" shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done

APK=$(find "$ROOT/android/app/build/outputs/apk/debug" -name '*.apk' | head -n1)
green "▶ Installing $APK"
"$ADB" install -r "$APK"

green "▶ Launching com.americangroupllc.buddyplay"
"$ADB" shell monkey -p com.americangroupllc.buddyplay -c android.intent.category.LAUNCHER 1

green "✓ Launched. Press Ctrl-C to stop the emulator."
wait $EMU_PID
