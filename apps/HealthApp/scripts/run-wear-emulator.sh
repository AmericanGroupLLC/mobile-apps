#!/usr/bin/env bash
# Boot a Wear OS emulator, install the debug APK, and launch.
set -euo pipefail
HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)
AVD=${WEAR_AVD_NAME:-"Wear_Round_API_33"}

green()  { printf "\033[1;32m%s\033[0m\n" "$1"; }

[ -n "${ANDROID_HOME:-}" ] || { echo "Set ANDROID_HOME"; exit 1; }
EMULATOR="$ANDROID_HOME/emulator/emulator"
ADB="$ANDROID_HOME/platform-tools/adb"

green "▶ Building :wear:assembleDebug"
(cd "$ROOT/android" && ./gradlew :wear:assembleDebug)

green "▶ Booting Wear AVD: $AVD"
"$EMULATOR" -avd "$AVD" -no-snapshot-save -no-boot-anim &
EMU_PID=$!
trap "kill $EMU_PID 2>/dev/null || true" EXIT

"$ADB" wait-for-device
until [ "$("$ADB" shell getprop sys.boot_completed | tr -d '\r')" = "1" ]; do sleep 2; done

APK=$(find "$ROOT/android/wear/build/outputs/apk/debug" -name '*.apk' | head -n1)
green "▶ Installing $APK"
"$ADB" install -r "$APK"

green "▶ Launching com.myhealth.wear"
"$ADB" shell monkey -p com.myhealth.wear -c android.intent.category.LAUNCHER 1

green "✓ Wear emulator running. Ctrl-C to stop."
wait $EMU_PID
