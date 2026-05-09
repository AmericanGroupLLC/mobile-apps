# MODELS.md

The GGUF model catalogue for Offline AI Buddy v1.

## §1 — Default bundled model (v1.0)

| Field | Value |
|---|---|
| Family | Qwen2.5 |
| Parameters | 1.5B |
| Quantisation | Q4_K_M |
| File | `Qwen2.5-1.5B-Instruct-Q4_K_M.gguf` |
| Approximate size | 1,073,741,824 bytes (~1.0 GB) |
| Context window | 4096 tokens |
| Languages | English, Hindi, Mandarin, French, Spanish (officially), 25+ others (best-effort). |
| License | Apache 2.0 |
| Hugging Face mirror (primary) | `https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf` |
| Alternative mirror 1 | `https://huggingface.co/lmstudio-community/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-Q4_K_M.gguf` |
| Alternative mirror 2 | `<set when CDN provisioned>` |
| SHA-256 | `<set in v1.0 release commit once first build downloaded; ModelDownloader rejects mismatch>` |

`ModelDownloader` tries the mirrors in order until one returns a file
whose SHA-256 matches.

## §2 — llama.cpp submodule pin

| Field | Value |
|---|---|
| Submodule path | `vendor/llama.cpp` |
| Origin | `https://github.com/ggerganov/llama.cpp` |
| Pinned commit | `<set on first integration; bumped via separate review-only commit>` |
| Rationale | Pinned because llama.cpp's API surface (and especially its tokenizer + sampler) changes month-to-month; an unpinned submodule will silently break the build. |

To bump: see `RELEASING.md §8`.

## §3 — Hardware floor

| Tier | Phone | tokens/sec | Notes |
|---|---|---|---|
| Recommended | iPhone 14 / Pixel 7 or newer | 12–15 t/s | Comfortable conversation pace. |
| Minimum | iPhone 12 / Pixel 6 | 5–9 t/s | Slow but usable. Consent screen warns on first launch. |
| Below floor | iPhone 11 / Pixel 5 and older | < 4 t/s | Refused on first launch with "Your device may struggle with this model" + refund deep link to App Store / Play. |

`ConsentScreen` reads `ProcessInfo.physicalMemory` (iOS) /
`ActivityManager.MemoryInfo.totalMem` (Android). If `< 3.5 GB`, the
sub-floor warning is shown.

## §4 — Supported quants (informational; v1 ships only Q4_K_M)

| Quant | Approx size | Quality | When to use |
|---|---|---|---|
| Q3_K_M | ~700 MB | -1 BLEU vs Q4 | Sub-3GB-RAM phones (v1.1 fallback). |
| **Q4_K_M (default)** | **~1 GB** | **baseline** | **Default for v1.** |
| Q5_K_M | ~1.4 GB | +0.5 BLEU | Power users (v1.1 opt-in). |
| Q8_0 | ~2 GB | +1 BLEU | Reference, not shipped. |

## §5 — Translation quality

Some lower-resource pairs (zh→hi, fr→hi) score below the rest. The
50-sentence-per-pair golden suite is a regression alarm. When the BLEU
score drops below threshold:

1. UI surfaces a **"Beta translation"** banner above the result.
2. A 1-tap **"Open in Google Translate"** deep-link is offered as a
   comfort fallback (this is just `https://translate.google.com/?sl=...&tl=...&text=...`,
   which the user opens in their browser — no SDK in our app).

## §6 — v1.1 swap path (model marketplace)

A `ModelManifest` enumeration + on-disk `models/<name>.gguf` layout is
already in `BuddyAICore.ModelStore`. v1.1 plan:

1. Settings → Models screen lists the catalog.
2. Each entry shows size + quality tier + download-not-installed state.
3. `LlamaRunner.activeModel = manifest` reload swaps the runner without
   a process restart.
4. App Store / Play Store review notes will need to mention each model
   the catalog ships.

Out of scope for v1.

## §7 — Why not Apple Foundation Models / Gemini Nano?

- **Apple Foundation Models** (iOS 18+) are iOS-only and require
  iPhone 15 Pro+. Cuts off the Pixel 7 / iPhone 13 user base.
- **Gemini Nano** is Android-only and requires Pixel 8 Pro / Galaxy S24
  hardware. Same problem.
- Single quantised LLM via llama.cpp is the **only** path that runs on
  every iPhone 12+ and Android API 26+ in the wild today.

When Apple / Google ship cross-platform consumer-ready stacks, v2 may
attach them as additional `LlamaRunner`-equivalents alongside llama.cpp.
