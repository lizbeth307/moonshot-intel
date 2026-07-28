# Kimi K3 Architecture ↔ Product Stack Analysis

Links the **model architecture** (2.8T MoE) to **runtime findings** in this repo, then maps analogies to other systems.

## 1. Model card (from MoonshotAI/Kimi-K3 + tech blog)

| Property | Value |
|----------|-------|
| Class | Open-weight native multimodal MoE |
| Total / activated params | **2.8T** / **104B** |
| Layers | 93 (1 dense + MoE stack) |
| Attention mix | **69 KDA** + **24 Gated MLA** |
| Experts | **896** routed, **16** active/token, **2** shared |
| Latent MoE dim | 3584 (experts at 3072) |
| Hidden / heads | 7168 / 96 |
| Context | **1,048,576** tokens |
| Vision | MoonViT-V2 (401M) |
| Activation | SiTU-GLU |
| Quant | MXFP4 weights / MXFP8 activations (QAT) |
| Positioning | Trails Claude Fable 5 & GPT-5.6 Sol; beats most other evaluated models |

### Architectural pillars

1. **Kimi Delta Attention (KDA)** — linear/selective attention for long sequences (not uniform O(n²) accumulation).
2. **Attention Residuals (AttnRes)** — selective retrieval across **depth** (which earlier layers to read), not just across tokens.
3. **Stable LatentMoE** — extreme sparsity (16/896 ≈ 1.8%); Quantile Balancing for load; latent projection before expert compute.
4. **Hybrid stack** — KDA (efficient long-range) interleaved with Gated MLA (global token interaction every ~4th attention layer).
5. **Agentic post-training** — RL across general / agentic / coding; multiple reasoning-effort levels; million-token agentic RL with persistent rollout/sandbox.

---

## 2. How product findings map onto model design

The product stack is not accidental — it **externalizes** what K3 was trained to do.

| Model design intent | Product / runtime finding | Evidence |
|---------------------|---------------------------|----------|
| Long-horizon coding (24h+ sessions, repos, terminals) | **Kimi Code CLI** + Agent tools + Goal mode GA | `GOAL.md` state machine; `/goal` exit codes 0/3/6; llms-full goals guide |
| Million-token context | Code models `k3` (1M) vs `k3-256k`; Platform `kimi-k3` 1M; membership tier gate for 1M | config.toml; error-reference “only 256K on lower plan” |
| Always-on reasoning | Platform: `reasoning_effort` low/high/max, **default max**; `supports_thinking_type: only` on K2.7 Code | pricing-chat-k3.md; managed-kimi-code.ts |
| Multi-agent / parallel work | **AgentSwarm** (max 128) client-side; no REST `/swarm` | error-matrix agentswarm_cli_only; NXDOMAIN swarm.kimi.com |
| Tool orchestration | Code API `/search`, `/fetch`; MCP; skills; OpenClaw | architecture.md; marketplace.json |
| Vision-in-the-loop | Platform Files API (image/video); OpenClaw media understanding | platform-api-inventory; moonshot-provider |
| Cache-friendly long coding | Platform pricing **$0.30 cache hit** vs **$3.00 miss** (10×); blog claims >90% cache hit via Mooncake | pricing-chat-k3.md; kimi.com/blog/kimi-k3 |
| Extreme sparsity / cost at scale | Dual product: **subscription Code** (quota+fuel) vs **pay-go Platform**; fuel pack `boosterWallet` | billing-claw.md |
| Harness sensitivity | Docs warn: K3 needs preserved thinking history; recommend **Kimi Code** harness | blog Limitations §1 |
| Agentic “excessive proactiveness” | Goal/Swarm product surfaces; permission modes manual/auto/yolo | vivace-capabilities; slash commands |

### Dual-gate AuthZ mirrors dual training surfaces

```
Model:  general RL  |  agentic RL  |  coding RL
Product: Consumer   |  Code+Vivace |  Platform API (inference)
```

- **402 membership** = “you bought the agent product that matches agentic/coding RL harness”
- **Platform key** = “you buy raw inference” (same weights path, no Swarm/Goal orchestration)
- JWT without plan = identity only — entitlement is **server-side** (`membership_009`), like router gating experts at inference time

### Dual protocol (kimi vs anthropic) mirrors harness diversity

Benchmarks in the K3 blog explicitly evaluate under **Kimi Code, Claude Code, or Codex** harnesses. Runtime finding: Code `/models` may declare `protocol: anthropic` → `/v1/messages?beta=true`. OpenClaw kimi-provider uses anthropic-messages. **Product speaks multiple agent dialects because the model was evaluated that way.**

---

## 3. What it resembles (architecture analogies)

### A. Model level — closest cousins

| System | Similarity | Difference |
|--------|------------|------------|
| **DeepSeek-V3 / R1 family** | Huge sparse MoE, open weights, coding/reasoning push | K3 adds hybrid **KDA+MLA**, AttnRes, native multimodal, 1M ctx as first-class |
| **Mixtral / Qwen-MoE line** | MoE sparsity for cost | K3 is ~3T-class with LatentMoE + QAT MXFP4; far larger expert pool (896) |
| **Claude / GPT frontier** | Agentic coding + long context product framing | K3 is **open weights**; still trails Fable 5 / GPT-5.6 Sol per Moonshot’s own table |
| **Gemini long-context** | Million-token marketing | K3 pairs 1M with **agentic RL + Code harness**, not only RAG chat |

**One-line model analogy:** *DeepSeek-scale sparse MoE + Claude-style agentic coding product, with Moonshot-specific KDA/AttnRes for 1M agents.*

### B. Product / platform level — what the stack looks like

| Analogy | Why it fits | Where it breaks |
|---------|-------------|-----------------|
| **Claude Code / Anthropic** | Terminal agent, tools, subscription, Messages API compatibility path | Moonshot also sells raw OpenAI-compatible Platform API + open model weights |
| **OpenAI Codex + ChatGPT Plus split** | Separate “agent coding product” vs “API inference” | Moonshot’s split is sharper: Code membership 402 vs Platform balance; Swarm is CLI-only |
| **GitHub Copilot + Azure OpenAI** | Same model family, different SKUs (IDE vs API) | Copilot doesn’t expose AgentSwarm/Goal as first-class CLI product |
| **Kubernetes control plane + kubelet** | Orchestration (CLI: Swarm/Goal) is **local**; workers (API inference) are remote | Inference is remote MoE cluster; orchestration state is client-side |
| **MoE routing ↔ product routing** | Token → 16/896 experts; user → Code vs Platform vs Consumer | Product routers are billing gates (402/403), not neural routers |

### C. Structural rhyme: sparsity at every layer

Moonshot repeats the same pattern at three scales:

```
Model:   2.8T total → activate 104B (16/896 experts)
Serving: Mooncake disagg + prefix cache → $0.30 vs $3.00
Product: Full agent stack (Vivace) vs inference-only (Platform) vs chat (Consumer)
```

**Sparsity = activate only what you need.** That is the unifying design thesis.

---

## 4. Implications for our intel (decision-relevant)

1. **K3 without Kimi Code harness is underutilized.** Blog: thinking-history sensitivity; recommend Kimi Code. Platform key alone = model access; Vivace = harness the model was optimized for (Swarm, Goal, tools, preserved thinking).

2. **1M context is a first-class product gate**, not just a model feature. Runtime: separate `k3` vs `k3-256k` aliases; membership errors for 1M on lower tiers. Matches AttnRes/KDA investment — they monetize the capability they built.

3. **Swarm is the productization of multi-agent RL evals.** Blog case: “20+ concurrent subagents” on GWTC-5. Our finding: AgentSwarm max 128, CLI-only, env concurrency cap. Server has no `/swarm` host because orchestration was designed as **harness-side**.

4. **Cache pricing is architecture-aware.** KDA challenges conventional prefix cache; they contributed vLLM KDA cache. Platform’s 10× cache-hit discount and “>90% hit in coding” claim are **serving-stack** consequences of the attention design.

5. **Cursor is a different species.** Cursor = IDE orchestration over mixed models. Kimi Code = Moonshot’s own harness co-designed with K3 agentic RL. Replacing Vivace with Cursor Ultra loses the harness K3 was tuned for.

---

## 5. Compact picture

```
┌─────────────────────────────────────────────────────────┐
│  Kimi K3 model                                          │
│  2.8T MoE · KDA+MLA · AttnRes · 1M ctx · MoonViT       │
│  Trained for: long-horizon coding + agentic + reasoning │
└──────────────────────────┬──────────────────────────────┘
                           │ served via
     ┌─────────────────────┼─────────────────────┐
     ▼                     ▼                     ▼
 Consumer chat      Kimi Code (Vivace)     Platform API
 cookies            OAuth + membership     prepaid key
                    + CLI Swarm/Goal       chat/batch/files
                    + Claw billing         no agent harness
```

**Verdict:** K3 is a frontier sparse MoE built for **agentic million-token work**; the product stack we mapped (dual AuthZ, CLI Swarm, Goal GA, Platform split, cache pricing) is the **commercial harness** around that architecture — closest product analogue is **Claude Code + API split**, closest model analogue is **DeepSeek-scale MoE with Claude-like agent ambitions**.

## References

- https://www.kimi.com/blog/kimi-k3
- https://github.com/MoonshotAI/Kimi-K3
- arXiv:2607.24653
- Local: `architecture.md`, `billing-claw.md`, `findings-deepening-b.md`, `decision-matrix.md`
