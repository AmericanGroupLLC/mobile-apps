# App Icon + Accent Color

XcodeGen reads `Assets.xcassets` automatically when the catalog sits next to
`Info.plist` inside the source folder of the target. Both the iOS and watchOS
targets in this repo already do that.

## Drop in a real icon (one-time, ~5 minutes)

1. Generate a 1024×1024 PNG (transparent background OK for watchOS, opaque for iOS).
   Easy free tools: `https://www.appicon.co`, `https://icon.kitchen`, or any image editor.
2. Save it as `AppIcon.png` and drop it into:
   - iOS:    `ios/FitFusion/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
   - Watch:  `watch/HealthAppWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
3. Re-run `xcodegen generate` and rebuild.

## Until then

The empty `Contents.json` files committed in this repo are valid Xcode 15 single-size
asset catalogs (the new "Single Size" / 1024 idiom). Xcode will warn at build time
that the icon image is missing, but the app **will still build and run** — it just
shows a generic Springboard placeholder.

## Accent color

`AccentColor.colorset/Contents.json` is set to MyHealth orange-pink
`#F9496F`. Change the RGB hex values there to re-tint every `Color.accentColor`
usage in the app.
