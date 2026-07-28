# Global Analysis: How Kimi K3 Differs From Other Models

Compiled 2026-07-28 from Moonshot README/blog, Platform docs, and local product intel (`atlas/`).  
Benchmarks cited are **Moonshot’s published table** (max effort) unless noted — treat as vendor-reported, harness-dependent.

---

## 1. One-sentence positioning

**Kimi K3** is the first **open ~3T-class** multimodal MoE built for **long-horizon agents** (1M context, hybrid KDA+MLA, AttnRes), competitive with frontier closed models on coding/agentic suites, while still trailing **Claude Fable 5** and **GPT-5.6 Sol** overall — and uniquely paired with Moonshot’s own **Kimi Code** harness (Swarm/Goal).

---

## 2. Comparison axes

| Axis | What matters for “difference” |
|------|-------------------------------|
| **Weights** | Open vs closed |
| **Scale / sparsity** | Total vs activated params, expert count |
| **Attention** | Full softmax vs hybrid linear + latent |
| **Context** | Native 1M + agentic training vs marketing window |
| **Post-training** | Agentic/coding RL, thinking contract |
| **Product harness** | First-party agent CLI vs generic chat API |
| **API contract** | Always-think, preserved reasoning history |
| **Economics** | Cache-hit pricing, subscription vs pay-go |

---

## 3. Scoreboard vs named peers (vendor table, selected)

Legend: **K3** = Kimi K3 (max). Peers: Fable 5, GPT-5.6 Sol, Opus 4.8, GPT-5.5, GLM-5.2.

### Where K3 is near or above the pack

| Domain | Signal |
|--------|--------|
| **Long SWE / marathon** | SWE-Marathon **42.0** (best in table; Fable 35, Sol 39) |
| **Browse / search agents** | BrowseComp **91.2** (above Fable 88, Sol 90.4); DeepSearchQA F1 **95.0** |
| **MCP / tools** | MCPMark-Verified **94.5** (above Fable 87.4, Sol 92.9) |
| **Terminal agents** | Terminal-Bench 2.1 **88.3** ≈ Fable 88.0 / Sol 88.8 |
| **ProgramBench** | **77.8** ≈ Sol 77.6, above Fable 76.8 |
| **Doc / office vision** | OmniDocBench **91.1**; SpreadsheetBench 2 **34.8** ≈ Fable |
| **Finance/legal slices** | Harvey Lab-AA **94.6**; CorpFin competitive |

### Where K3 trails the top closed models

| Domain | K3 | Leader in table | Gap meaning |
|--------|-----|-----------------|-------------|
| DeepSWE | 67.5 | Sol 73.0 / Fable 70.0 | Pure SWE agent still behind |
| FrontierSWE | 81.2 | Fable 86.6 | Hard frontier SWE |
| HLE-Full | 43.5/56.0 | Fable 53.3/63.0 | Hard human-level exams |
| CritPt | 23.4 | Sol 32.3 | Critique / hard reasoning |
| OfficeQA Pro | 63.3 | Fable 69.9 | Heavy office agent |
| OSWorld 2.0 | 58.3 | Fable 66.1 | Computer-use agent |
| GDPval Elo | 1686 | Fable 1747 | Broad knowledge-work Elo |
| ZeroBench | 23/41 | Fable 23/46 | Hard vision |

**Pattern:** K3 is **frontier-adjacent on agentic coding + browsing/tools**, weaker on the hardest closed-model reasoning/SWE peaks and some computer-use/office suites. Moonshot’s own framing matches this.

### Vs open / semi-open peers in the same table

Against **GLM-5.2**, K3 wins almost across the board (coding, agentic, many vision rows). That puts K3 in a different tier from “strong open MoE chat models” — closer to closed frontier on agent workloads.

*(DeepSeek / Qwen / Llama not in this Moonshot table; architectural comparison below.)*

---

## 4. Architecture differences

| | **Kimi K3** | Typical frontier closed (Claude/GPT) | Typical open MoE (DeepSeek/Qwen-MoE class) | Dense open (Llama-class) |
|--|-------------|--------------------------------------|---------------------------------------------|---------------------------|
| Weights | **Open** | Closed | Often open | Open |
| Size class | **2.8T / 104B act** | Undisclosed / various | ~100B–600B+ MoE | 70B–400B dense |
| Experts | **896 → 16** (+2 shared) | Unknown / different | Fewer experts, less extreme sparsity | N/A |
| Attention | **Hybrid 69 KDA + 24 Gated MLA** | Usually full attention variants | Mostly standard / MLA families | Full attention |
| Depth trick | **AttnRes** (attend over residual blocks) | Standard residuals | Standard residuals | Standard |
| Context | **1,048,576 native** | Long (varies; often <1M or managed) | Often 128K–256K | Often 128K |
| Multimodal | **Native** MoonViT-V2 | Native | Varies (often separate VL) | Often separate |
| Deploy quant | **MXFP4/MXFP8 QAT from SFT** | Vendor serving | Post-train quant common | Post-train quant |
| Scaling claim | **~2.5× efficiency vs K2** | N/A | Generation-over-generation | — |

### What is *unique* to K3 (not just “bigger MoE”)

1. **KDA as majority attention** — built for million-token agents, not bolted-on long context.
2. **AttnRes** — information flow across **depth**, not only sequence.
3. **Stable LatentMoE at 16/896** — extreme sparsity with Quantile Balancing (trainability at 3T-class).
4. **Open weights at this scale** — Moonshot claims first open 3T-class model.
5. **QAT MXFP4** as shipping format — self-host path is first-class (vLLM/SGLang recipes).

### Vs Kimi’s own line

| | K2 / earlier | **K2.7 Code** | **K3** |
|--|--------------|---------------|--------|
| Role | Prior flagship | Coding specialist | New flagship agent |
| Context (product) | Shorter | **256K** | **1M** |
| Thinking | Varies | **Thinking-only** | Always think; effort low/high/max |
| Product | General | Coding inference + HighSpeed | Long-horizon + knowledge work |
| Efficiency | Baseline | Faster decode (HS ~180–260 tok/s) | 2.5× scaling efficiency vs K2 (train) |

K2.7 Code ≠ “small K3”: it is a **coding SKU** (256K, speed variants). K3 is the **1M agentic flagship**.

---

## 5. Behavior / API contract differences

| Contract | K3 | Many other models |
|----------|----|--------------------|
| Thinking | **Always on**; returns `reasoning_content` | Optional `/think` or hidden CoT |
| Effort | `reasoning_effort`: low / high / **max (default)** | Often one mode or separate “o1-class” SKU |
| Multi-turn | **Must** echo full assistant msg including reasoning + tool_calls | Often only `content` required |
| Harness sensitivity | Unstable if thinking history dropped or mid-session model switch | Usually more tolerant |
| Default posture | Long-horizon / proactive (Moonshot: “excessive proactiveness”) | Often more conservative chat defaults |
| Tooling extras | Dynamic tool loading, tool_choice constraints (Platform docs) | Varies by vendor |

**Practical difference:** K3 is closer to an **agent runtime contract** than a chat completion contract. Wrong harness → looks like a “worse model.”

---

## 6. Product stack difference (from our intel)

Most models ship “weights + API.” Moonshot ships **three universes**; K3 sits in all, but **full power is Code**:

| Capability | K3 via Platform API | K3 via Kimi Code / Vivace | Typical competitor |
|------------|---------------------|---------------------------|--------------------|
| Chat / tools / 1M | Yes (pay-go) | Yes | Yes |
| AgentSwarm / Goal | **No** | **Yes** (CLI-local) | Rarely first-party |
| Dual protocol (OpenAI + Anthropic Messages) | Yes | Yes | Usually one dialect |
| Open weights self-host | Yes | N/A | Rare at this tier |
| Cache-hit economics | **$0.30 vs $3.00** input | Membership + quota + fuel | Flat or weaker cache story |

This is a major differentiator vs “just another frontier API”: **K3 + Kimi Code** is co-designed (blog evaluates under Kimi Code / Claude Code / Codex).

---

## 7. Economics difference

| | K3 Platform | Typical closed frontier API | Self-host K3 |
|--|-------------|----------------------------|--------------|
| Unlock | ≥ **$1** top-up | Subscription / prepaid | CapEx + power |
| Input | $0.30 cache / $3.00 miss | Often flatter | Electricity + GPUs |
| Output | **$15 / 1M** | High on reasoning models | Fixed infra |
| Coding workloads | Blog: **>90% cache hit** claim via Mooncake | Depends | Your cache design |
| Rate limits | Tiered by cumulative recharge | Org tiers | Hardware |

Vs Cursor Ultra (~$200): different product class (IDE orchestration vs Moonshot agent stack). See `decision-matrix.md`.

---

## 8. Failure modes unique or emphasized for K3

From Moonshot Limitations + our runtime map:

1. **Thinking-history breakage** — quality collapses if harness strips `reasoning_content`.
2. **Over-agency** — may act without enough confirmation on ambiguous tasks.
3. **Harness lock-in effect** — best with Kimi Code; mid-session switch from another model warned against.
4. **Membership / balance gates** — Code 402, Platform prepaid; open weights don’t unlock their cloud for free (`auth-vs-architecture-verdict.md`).
5. **Still behind Fable/Sol** on several hard suites — not “best overall,” “best open + strong agentic.”

---

## 9. Decision matrix: when K3 vs alternatives

| If you need… | Prefer |
|--------------|--------|
| Open weights at frontier scale + self-host | **K3** |
| Max closed SWE / hard exams | **Claude Fable 5** or **GPT-5.6 Sol** |
| First-party Swarm/Goal/Code CLI co-design | **K3 + Vivace/Kimi Code** |
| Cheap/fast coding decode 256K | **K2.7 Code HighSpeed** (Platform/Code) |
| IDE tab-complete multi-model | **Cursor** (not a K3 substitute) |
| Pay-go K3 without agent stack | **Platform `kimi-k3`** |
| Classic open MoE without 1M agent stack | DeepSeek/Qwen-class (different product bet) |

---

## 10. Synthesis: the real deltas

```
Other models often optimize:  chat quality · closed serving · optional tools
Kimi K3 optimizes:            open 3T MoE · 1M hybrid attention · agent RL · Code harness
```

**Five global differences:**

1. **Open at closed-frontier scale** — rare combination.  
2. **Hybrid long-context architecture (KDA+MLA+AttnRes)** — not just a bigger window flag.  
3. **Agent-first post-training + always-think API** — different contract than chat LLMs.  
4. **First-party agent product (Code/Swarm/Goal)** — model and harness sold as one thesis.  
5. **Honest ceiling** — Moonshot places it **below Fable 5 / GPT-5.6 Sol**, above most other evaluated peers — especially vs GLM-class open competitors.

---

## References

- https://github.com/MoonshotAI/Kimi-K3 (README benchmarks)  
- https://www.kimi.com/blog/kimi-k3  
- https://platform.kimi.ai/docs/guide/kimi-k3-quickstart  
- Local: `k3-architecture-analysis.md`, `architecture.md`, `decision-matrix.md`, `billing-claw.md`
