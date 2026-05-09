# vendor/llama.cpp

This directory hosts the [llama.cpp](https://github.com/ggerganov/llama.cpp)
git submodule. It's pinned to a specific commit so neither the iOS Swift
target nor the Android NDK build silently breaks when upstream changes
its API surface.

To populate it after cloning the repo:

```sh
git submodule update --init --recursive
```

The pinned commit hash is documented in `MODELS.md` §2 and only bumped
in a stand-alone, review-only commit (see `RELEASING.md` §8).

This file is the only thing that lives in `vendor/llama.cpp/` until the
submodule is initialized.
