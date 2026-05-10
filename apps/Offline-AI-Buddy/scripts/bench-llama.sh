#!/usr/bin/env bash
# Quick host-machine tokens/sec benchmark using the llama.cpp `main`
# binary. Useful when sweeping new model candidates. Builds llama.cpp
# from the submodule if it isn't already built.
#
# Usage:  ./scripts/bench-llama.sh [path/to/model.gguf]
set -euo pipefail

HERE=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)
ROOT=$(cd "$HERE/.." && pwd)
MODEL="${1:-$ROOT/models/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf}"

if [ ! -f "$MODEL" ]; then
  echo "Model not found: $MODEL" >&2
  echo "Run ./scripts/fetch-models.sh first." >&2
  exit 1
fi

LLAMA_DIR="$ROOT/vendor/llama.cpp"
if [ ! -d "$LLAMA_DIR" ]; then
  echo "vendor/llama.cpp submodule missing." >&2
  echo "Run: git submodule update --init --recursive" >&2
  exit 1
fi

BUILD_DIR="$LLAMA_DIR/build"
if [ ! -x "$BUILD_DIR/bin/llama-bench" ] && [ ! -x "$BUILD_DIR/bin/main" ]; then
  echo "▶ Building llama.cpp (first run can take a few minutes)"
  cmake -S "$LLAMA_DIR" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release -DLLAMA_BUILD_TESTS=OFF
  cmake --build "$BUILD_DIR" -j --target llama-bench main
fi

if [ -x "$BUILD_DIR/bin/llama-bench" ]; then
  "$BUILD_DIR/bin/llama-bench" -m "$MODEL" -p 32 -n 64 -t 4
else
  "$BUILD_DIR/bin/main" -m "$MODEL" -p "Hello, world." -n 64 -t 4 --no-display-prompt
fi
