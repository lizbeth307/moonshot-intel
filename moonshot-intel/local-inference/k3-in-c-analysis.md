# Kimi K3 local inference: `kimi-k3-in-c` analysis

Research note on running the full Kimi K3 checkpoint without a GPU, and what that
implies for the Android agent-environment question.

- **Upstream:** <https://github.com/FareedKhan-dev/kimi-k3-in-c> (Apache-2.0, v1.0.0)
- **Reviewed at commit:** `117e9d2` ("docs: add CONTRIBUTORS.md")
- **Reproduced on:** 2026-09-04, Linux x86-64, GCC 13.3.0, 4 cores
- **Weights:** not included in that repo; `moonshotai/Kimi-K3` under Moonshot's own licence

## Verdict

The engine is real and its weightless claims reproduce exactly. Running K3 locally is
gated by **storage, not compute**: 1.56 TB of checkpoint plus a 109 GB packed trunk.

For Android that gate is decisive. The code would very likely build under Termux
(aarch64, NEON paths present), but no phone holds 1.7 TB, and the nearest measured ARM64
data point is 949 seconds per token. A local K3 agent on a handset is not viable. The
practical Android path is the hosted OpenAI-compatible API, which this repo already
documents.

## What the model actually is

Read from the checkpoint's own `config.json` by the engine, never hardcoded.

| Property | Value |
|---|---|
| Parameters | 2.78 T total, ~104 B active per token |
| Layers | 93 total: 69 KDA + 24 Gated MLA; layer 0 has a dense FFN |
| Hidden width | 7168 |
| Attention heads | 96 |
| Routed experts | 896 per layer, top-16 selected |
| Shared experts | 2, full width |
| Latent MoE width | 3584 |
| Expert intermediate | 3072 |
| Vocabulary | 163,840 |
| Activation | SiTU-GLU (β₁ = 4, β₂ = 25) |
| Expert weight format | native MXFP4, never dequantised |

Two attention mechanisms coexist. **Kimi Delta Attention** covers 69 layers as a linear
recurrence with a channel-wise forget gate, so its state does not grow with sequence
length. **Gated MLA** covers 24 layers, compressing keys and values into a low-rank
latent, and uses NoPE, meaning the 64 rope dimensions exist and are cached but never
rotated. The last two layers are both MLA, so the final layer always does global
attention.

**Attention Residuals** replace the single residual stream. Layers are partitioned into
blocks of 12, and at each boundary the running residual is snapshotted and cleared.

## Where the memory goes

| Component | Size | Residency |
|---|---:|---|
| Routed experts | 1.45 TB | never resident, streamed as MXFP4 |
| Dense trunk | 108.81 GB | resident or streamed, this is the dial |
| Embeddings, final norm, lm_head | 4.70 GB | always resident |
| Recurrent state, 93 layers | 626 MB | always resident |
| MLA KV cache | 2.37 MB per position | only with `--incremental` |

The resident floor is about 5.3 GB. Everything above it is a tuning choice.

## The four reductions

1. **Experts ship at half a byte.** MXFP4 with one shared 8-bit exponent per 32 elements,
   0.53125 bytes per weight. One expert is 33,030,144 parameters in 17,547,264 bytes.
   Dequantising would widen a 17.5 MB expert to 132 MB, and a token touches 1,472 of them,
   which is 194 GB per token of pure widening. The streaming design depends on not doing it.
2. **KDA removes quadratic KV growth** on 69 of 93 layers.
3. **MLA compresses 96 heads** into one latent on the remaining 24.
4. **Trunk streaming** turns the 108.81 GB dense trunk into an LRU-cached ring buffer, so
   memory becomes a speed dial rather than a hard floor.

## What I reproduced

Build, from a clean clone, with no checkpoint and no network:

```
make -j4      # 7 translation units, zero warnings at -Wall -Wextra -Wshadow
make test
```

The binary is 230,416 bytes, of which 207,513 is text. The dependencies are libm and
OpenMP.

Full test suite result:

```
GATE 1  teacher forcing : 32/32 positions match tf_pred
        generated span  : 20/20  <- must be exact
GATE 1b state reuse      : PASS  <- all logits bit-identical
GATE 2  greedy decode   : 20/20 generated tokens match full_ids
GATE 3  incremental    : 20/20 generated tokens match full_ids
VERDICT: ENGINE MATCHES THE REFERENCE EXACTLY
ALL WEIGHTLESS TESTS PASSED
```

The oracle runs a 13-layer model built with the same tensor graph as the released one,
checked against committed PyTorch reference fixtures. Tokenizer parity did not run here
because it needs `tiktoken.model` from the checkpoint; everything else did.

The published expert-cache measurement also replays from a committed trace:

```
python3 tools/sim_cache.py tests/fixtures/expert_trace.bin
```

| Cache | Slots | LRU hit | Belady | GB read/token | Sec/token (I/O only) |
|---:|---:|---:|---:|---:|---:|
| 8 GB | 455 | 36.24% | 39.42% | 16.47 | 13.35 |
| 32 GB | 1823 | 36.24% | 48.99% | 16.47 | 13.35 |
| 128 GB | 7294 | 49.19% | 84.59% | 13.12 | 10.64 |
| 192 GB | 10941 | 90.00% | 90.00% | 2.58 | 2.09 |
| 1450 GB | 82633 | 90.00% | 90.00% | 2.58 | 2.09 |

The trace holds 100,096 expert requests over about 68 tokens, touching 10,010 distinct
experts, which is 12.14% of the 82,432-expert pool. Reuse is 90.0%, and the 10,010
compulsory misses cap any policy at a 90% hit rate on this trace. Uncached, a token
would read 25.83 GB.

The shape worth noting: LRU is flat at 36.24% from 8 GB through 64 GB, then steps to 90%
at 192 GB. Holding every expert the trace touched needs 175.65 GB. Below that threshold,
adding memory to the expert cache buys nothing, which is why the presets spend it on the
trunk instead.

## Measured speed ladder

Upstream figures, one machine with 124 cores and fast NVMe.

| RAM | Preset | Time per token |
|---:|---|---:|
| 8 GB | laptop | 26.5 s |
| 32 GB | desktop | 24.2 s |
| 64 GB | — | 19.8 s |
| 128 GB+ | server | 5.6 s |

Output is byte-identical across every budget. Only the clock changes. Greedy decoding is
what guarantees that, and the test suite depends on the property.

## The ARM64 evidence

This is the part that bears on Android. The repo carries a four-run reproduction on an
NVIDIA Jetson Orin Nano Super: aarch64, six visible cores, 8 GB class, Ubuntu 22.04,
scalar and NEON C path with OpenMP, no CUDA.

| Run | Token | Layers | Expert drops | Peak RSS | Time |
|---:|---|---:|---:|---:|---:|
| 1 | ` Paris` | 93/93 | 0 | 2.76 GB | 948.5 s |
| 2 | ` Paris` | 93/93 | 0 | 2.76 GB | 949.8 s |
| 3 | ` Paris` | 93/93 | 0 | 2.76 GB | 950.7 s |
| 4 | ` Paris` | 93/93 | 0 | 2.76 GB | 948.7 s |

Mean 949.4 s per token, about 15 minutes 49 seconds. All four runs produced the same
float32 logit SHA-256, so agreement was not merely at argmax. Full precision, all 93
layers, official Top-16 routing, no dropped experts.

Each run read 108.8 GB of packed trunk from internal NVMe and 99.7 GB of routed experts
from an external rotating HDD, with `K3_NOPREFETCH=1` to avoid multi-stream seeks.

## Android feasibility

Android is aarch64 Linux, and the four porting requirements are the interesting ones.

**What works in principle.** NEON paths for the bf16 and MXFP4 matmuls exist and are
guarded by `__ARM_NEON && __aarch64__`. The Makefile and CMakeLists both handle the
`-mcpu` versus `-march` spelling for aarch64. Termux supplies Clang, GNU Make, OpenMP and
Python 3.9+. The tokenizer and config reader are portable C99 that build anywhere.

**What blocks it.**

1. **Storage, decisively.** The checkpoint is 1.56 TB and the packed trunk another 109 GB.
   Flagship phones ship 256 to 512 GB. USB-OTG storage is possible, but Android mounts
   external volumes through a FUSE emulation layer that does not honour `O_DIRECT`, which
   the trunk streamer uses to bypass the page cache. Losing `O_DIRECT` on a device with
   6 to 12 GB of RAM means page-cache thrash on every layer read.
2. **Speed.** The Jetson figure is 949 s per token on a six-core aarch64 part with NVMe
   for the trunk. A phone has slower sustained UFS random reads, fewer usable big cores,
   and thermal throttling that a Jetson in a fan-cooled enclosure does not face. Assume
   worse than 15 minutes per token.
3. **Process lifetime.** Android kills background processes aggressively. A single token
   at that rate outlives any ordinary foreground-service budget under Doze.

**Conclusion.** Local K3 on Android is a demonstration, not a deployment. The honest
version of the experiment is a one-token proof of life with the checkpoint on OTG storage,
and it would take longer than the Jetson's 15 minutes.

## What this means for the Android agent environment

Split the agent from the model, which is what the rest of this repo already documents.

- **Inference:** hosted `kimi-k3` over the OpenAI-compatible endpoint at
  `https://api.moonshot.ai/v1`, 1,048,576-token context, `$0.30` cached input, `$3.00`
  input, `$15.00` output per million tokens. K3 always reasons, with `reasoning_effort`
  at `low`, `high` or `max`, defaulting to `max`.
- **Agent loop on device:** Termux for a full Linux userland without root, plus
  `tool_choice` constraints and dynamic tool loading, which are the two new K3 API
  capabilities relevant to a large tool inventory on a constrained client.
- **Local model, if one is wanted at all:** a small model through llama.cpp or MediaPipe,
  used for routing and offline fallback, not as the K3 substitute.

Note the credential split documented in `../error-matrix.json`: Platform keys
(`api.moonshot.ai/v1`) and Kimi Code keys (`api.kimi.com/coding/v1`) are separate
universes, and a Code OAuth token is rejected outright by the Platform gate.

## Engine scope limits

Worth knowing before anyone plans on top of it.

- No chat template, so it produces base-model continuations rather than replies.
- Greedy decoding only, which is what keeps output identical across budgets.
- No chunked prefill. The ceiling is 32,768 tokens, and a 21,000-token prompt is one
  quadratic pass through the MLA layers.
- No vision. MoonViT-V2 is specified in `config.json` at 27 layers and roughly 0.4 B
  parameters, about 0.9 GB, with zero code in the engine.
- No SIMD in the KDA recurrence, which is the largest un-vectorised kernel off the I/O path.
- No quality benchmark. At the measured rates that would be days of compute, and it would
  measure Kimi K3 rather than the engine.

## Sources

- <https://github.com/FareedKhan-dev/kimi-k3-in-c>, README, `docs/ARCHITECTURE.md`,
  `docs/ROADMAP.md`, `docs/results/jetson-orin-nano-super/README.md`
- `docs/kimi-k3-tech-report.pdf`, vendored in that repo
- `../platform-docs/pricing-chat-k3.md` and `../platform-llms.txt` in this repo
- Local reproduction, 2026-09-04, x86-64, GCC 13.3.0
