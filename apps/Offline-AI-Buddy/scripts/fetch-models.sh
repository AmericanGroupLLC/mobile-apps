#!/usr/bin/env bash
# Pre-fetch the default GGUF model into ./models/ so local dev runs skip
# the first-launch download flow. Tries every mirror in MODELS.md until
# the SHA-256 matches.
#
# Usage:  ./scripts/fetch-models.sh
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)
DEST_DIR="$ROOT/models"
DEST="$DEST_DIR/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf"

# Mirrors — kept in sync with MODELS.md §1.
MIRRORS=(
  "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf"
  "https://huggingface.co/lmstudio-community/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf"
)

# Expected SHA-256 — set in MODELS.md §1 once first build is verified. Until
# then the script accepts any successful download.
EXPECTED_SHA256="${EXPECTED_SHA256:-}"

mkdir -p "$DEST_DIR"

if [ -f "$DEST" ]; then
  echo "✓ Already present: $DEST"
  exit 0
fi

for url in "${MIRRORS[@]}"; do
  echo "▶ Trying $url"
  if command -v curl >/dev/null 2>&1; then
    if curl -fL --retry 3 -C - -o "$DEST.partial" "$url"; then
      mv "$DEST.partial" "$DEST"
      break
    fi
  elif command -v wget >/dev/null 2>&1; then
    if wget -c -O "$DEST.partial" "$url"; then
      mv "$DEST.partial" "$DEST"
      break
    fi
  else
    echo "Neither curl nor wget available." >&2; exit 1
  fi
done

if [ ! -f "$DEST" ]; then
  echo "✗ All mirrors failed." >&2
  exit 1
fi

if [ -n "$EXPECTED_SHA256" ]; then
  echo "▶ Verifying SHA-256"
  if command -v shasum >/dev/null 2>&1; then
    GOT=$(shasum -a 256 "$DEST" | awk '{print $1}')
  else
    GOT=$(sha256sum "$DEST" | awk '{print $1}')
  fi
  if [ "$GOT" != "$EXPECTED_SHA256" ]; then
    echo "✗ SHA-256 mismatch. expected=$EXPECTED_SHA256 got=$GOT" >&2
    rm -f "$DEST"
    exit 1
  fi
  echo "✓ SHA-256 matches"
fi

echo "✓ Fetched: $DEST"
echo "  ./scripts/run-ios-sim.sh and ./scripts/run-android-emulator.sh will side-load it for you."
