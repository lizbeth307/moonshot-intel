# Investigation: Can K3 Architecture Bugs Enable Use Without Auth?

**Question:** Чи можливий баг в архітектурі моделі (MoE/KDA/AttnRes), який дозволяє користуватись K3 без authentication?  
**Method:** Layer separation + fresh unauth probes + public hosting check (2026-07-28).  
**Scope:** Recon only — no exploit development.

## Hypothesis under test

H1: A property or defect in the **neural architecture** creates an unauthenticated path to hosted Moonshot inference.

## Layer model

| Layer | What lives here | Example “bugs” | Can grant no-auth hosted use? |
|-------|-----------------|----------------|-------------------------------|
| L0 Neural architecture | KDA, AttnRes, LatentMoE, SiTU | Expert imbalance, numerical instability, wrong routing | **No** — runs only after job is accepted |
| L1 Serving / inference engine | vLLM/SGLang, Mooncake, KV/prefix cache | Cache mix-up, OOM, wrong tenant isolation | Infra issue; still needs a request that passed AuthN |
| L2 API gateway | Cloudflare, AuthN, AuthZ | Missing auth on route, misconfig | **Only this layer** could expose no-auth API |
| L3 Product billing | membership_009, balance | Wrong plan check | Auth already happened |

Architecture (L0) never sees the request until L2+L3 accept it.

## Fresh unauth probes (this session)

| Target | No credentials | Result |
|--------|----------------|--------|
| `GET api.kimi.com/coding/v1/models` | none | **401** Invalid Authentication |
| `GET api.moonshot.ai/v1/models` | none | **401** Incorrect API key |
| `GET api-sg.moonshot.ai/v1/models` | none | **401** |
| `GET api.moonshot.cn/v1/models` | none | **401** |
| `GET www.kimi.com/api/user` | none | **401** |
| HF router `moonshotai/Kimi-K3` chat | none | **401** |
| OpenRouter `moonshotai/kimi-k3` | none | **401** No cookie auth |

No public hosted completion returned 200 without credentials.

Prior intel (error-matrix): OAuth without membership → **402**; fake keys → **401**; no free/trial DNS hosts (NXDOMAIN).

## Architecture properties checked against H1

| Property | What it does | Auth implication |
|----------|--------------|------------------|
| Sparse MoE 16/896 | Activates subset of experts per token | Cost/quality only |
| KDA / AttnRes | Long-context / depth efficiency | Serving complexity; not an open door |
| MXFP4/MXFP8 QAT | Smaller deploy footprint | Easier **self-host**, still your hardware |
| Prefix / Mooncake cache | Cheap repeated context | Needs authenticated traffic to populate |
| Open weights (HF ungated) | Downloadable checkpoints | Intentional; **not** a hosted no-auth API |

Open weights + `gated: False` on Hugging Face means you can **run your own** stack (vLLM/SGLang recipes). That bypasses *Moonshot’s* auth by design — you become the host. It is not a bug in KDA/MoE that opens `api.kimi.com`.

## What would falsify the verdict

Evidence of a **gateway** path that returns model completions with no credential (misconfigured route, forgotten debug endpoint, public anonymous playground API). Architecture papers and weight files alone cannot falsify AuthZ on Cloudflare-fronted APIs.

None found in this or prior sweeps.

## Verdict

**H1 is not supported.**

1. Neural-architecture bugs do not create unauthenticated access to Moonshot-hosted K3.  
2. All probed hosted inference surfaces require AuthN (and Code also AuthZ/membership).  
3. The only auth-free path to “use the model” is **self-host open weights** (or other providers’ paid keys) — product design, not an architecture exploit.

## Legal next steps if the goal is “use K3”

| Path | Auth to Moonshot? |
|------|-------------------|
| Vivace / Coding membership | Yes (OAuth + plan) |
| Platform API (≥ $1 top-up) | Yes (API key) |
| Consumer kimi.com | Browser session |
| Self-host HF `moonshotai/Kimi-K3` | No Moonshot auth; your infra/cost |
| OpenRouter / HF Inference Providers | Their keys/billing, not zero-auth |

## References

- Probes this session + `error-matrix.json`  
- `atlas/k3-architecture-analysis.md`  
- https://huggingface.co/moonshotai/Kimi-K3  
- https://github.com/MoonshotAI/Kimi-K3  
