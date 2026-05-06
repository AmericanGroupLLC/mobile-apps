#!/usr/bin/env bash
# Update the version string in every manifest. Use before tagging a release.
# Usage:  ./scripts/bump-version.sh 1.2.0
set -euo pipefail
NEW="${1:?Pass a semver like 1.2.0}"

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)

# Cross-platform sed wrapper — macOS BSD sed needs an empty -i argument.
sedi() {
  if [ "$(uname)" = "Darwin" ]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# 1. Android phone
sedi -E "s/(versionName\s*=\s*)\"[0-9.]+\"/\1\"$NEW\"/" "$ROOT/android/app/build.gradle.kts"

# 2. iOS
plutil -replace CFBundleShortVersionString -string "$NEW" "$ROOT/ios/BuddyPlay/Resources/Info.plist" 2>/dev/null \
  || sedi -E "s|<string>[0-9.]+</string>(\s*<key>CFBundleVersion)|<string>$NEW</string>\1|" \
       "$ROOT/ios/BuddyPlay/Resources/Info.plist" 2>/dev/null \
  || true

echo "✓ Bumped to $NEW everywhere."
echo "  git diff to review, then:"
echo "    git commit -am 'chore(release): v$NEW'"
echo "    git tag v$NEW && git push origin main v$NEW"
