# Card — QUICKSTART

The fastest path to a running build on each platform. For deeper architecture
context see [`DESIGN.md`](DESIGN.md). For the manual test checklist see
[`TESTING.md`](TESTING.md).

---

## 0. Common setup

```bash
git clone git@github.com:AmericanGroupLLC/Card.git
cd Card
```

That's it for cloning. Each platform is self-contained underneath the relevant
top-level directory (`ios/`, `watchos/`, `android/`).

---

## 1. iPhone (macOS, requires Xcode 16)

```bash
brew install xcodegen
cd ios
xcodegen generate          # produces Card.xcodeproj
open Card.xcodeproj
```

Then in Xcode pick the **Card** scheme + an iPhone 15 simulator and hit ▶.

Or in one shot from the repo root:

```bash
./scripts/run-ios-sim.sh   # builds + boots iPhone 15 sim + launches Card
```

The Share Extension target (`CardShareExtension`) is generated alongside.
To smoke-test sharing, add the simulator to your Mac, open Notes,
select some text, tap Share → **Card – Save**.

---

## 2. Apple Watch (macOS, requires Xcode 16)

```bash
brew install xcodegen
cd watchos
xcodegen generate          # produces CardWatch.xcodeproj
open CardWatch.xcodeproj
```

Choose the **CardWatch** scheme + an Apple Watch Series 10 (46mm) simulator
and hit ▶. To exercise the Quick-capture complication, add it to the watch
face from the simulator's complication picker.

---

## 3. Android phone

```bash
# requires Android Studio Hedgehog+ (AGP 8.5.0) and JDK 17
cd android
gradle wrapper --gradle-version 8.10   # one-time bootstrap
./gradlew :app:assembleDebug
./gradlew :core:test :app:testDebugUnitTest
```

To run on an emulator:

```bash
export ANDROID_HOME=~/Library/Android/sdk    # or wherever your SDK lives
export AVD_NAME=Pixel_6_API_34
./scripts/run-android-emulator.sh
```

To exercise the Quick Settings tile: open Quick Settings, hit the pencil
(edit) icon, drag the **Card** tile into the active row, then tap it.

---

## 4. Wear OS

```bash
cd android
./gradlew :wear:assembleDebug
./gradlew :wear:testDebugUnitTest
```

Run on a Wear emulator:

```bash
export ANDROID_HOME=~/Library/Android/sdk
export WEAR_AVD_NAME=Wear_Round_API_33
./scripts/run-wear-emulator.sh
```

To exercise the Wear tile: long-press the watch face → "Add tiles" → pick
the Card tile.

---

## 5. Run everything in one shot

```bash
./scripts/test-all.sh
```

Skips iOS/watchOS on non-macOS hosts and skips Android when Gradle isn't
installed — runs whatever is available.

---

## 6. Release dry-run

Before tagging, sanity-check the binaries that the release workflow would
produce:

```bash
./scripts/bump-version.sh 0.1.0
./scripts/release-dry-run.sh v0.1.0
ls distribution/staging-v0.1.0/
```

See [`RELEASING.md`](RELEASING.md) for the full tag → release flow.
