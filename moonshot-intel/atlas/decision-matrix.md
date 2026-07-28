# Decision Matrix: Vivace vs Platform API vs Cursor Ultra

For a developer wanting **full Kimi K3 + Swarm + Claw** vs **inference-only** vs **IDE assistant**.

## Summary

| | **Vivace / Membership** (~$199/mo) | **Platform API** (pay-as-you-go) | **Cursor Ultra** (~$200/mo) |
|--|-----------------------------------|----------------------------------|----------------------------|
| **K3 inference** | Yes (Code API) | Yes (`kimi-k3`) | Via Cursor models (not native Kimi stack) |
| **K3 1M context** | Yes (tier-dependent) | Yes | N/A |
| **AgentSwarm** | Yes (CLI `/swarm`) | No | No |
| **Kimi Code CLI** | Full OAuth stack | Partial (Platform key via `/login`) | No |
| **OpenClaw Claw** | Yes (Coding key + membership) | Platform path only (K3, no Claw billing stack) | No |
| **ACP / Zed** | Yes (`kimi acp`) | No | Cursor-native |
| **Billing** | Subscription + quota + fuel pack | Prepaid balance (tiered RPM/TPM) | Cursor subscription |
| **Auth** | OAuth / Coding Plan key | Platform API key | Cursor account |

## When to choose Vivace

- You want **Moonshot's agent stack**: Swarm, Claw, Code CLI, K3 1M, local `kimi web`
- You accept **subscription** and membership tier rules (Moderato/Allegretto for model features)
- Cursor is **not** a substitute for this stack

## When to choose Platform API

- You need **K3 API only** (scripts, OpenClaw with `@openclaw/moonshot-provider`, Codex/Claude Code guides)
- Pay-as-you-go fits sporadic usage (~$0.30–$15 / 1M tokens per [`pricing-chat-k3.md`](../platform-docs/pricing-chat-k3.md))
- **K2.7 Code** available on Platform without Vivace (`kimi-k2.7-code`, highspeed variant)
- Minimum $1 recharge; rate limits scale with cumulative spend (Tier0: 3 RPM → Tier5: 10K RPM)
- Setup: `platform.kimi.ai` key → `kimi /login` → Kimi Platform **or** direct `api.moonshot.ai/v1`

## When Cursor Ultra still makes sense

- Primary workflow is **Cursor IDE** with multi-model tab completion
- You do **not** need Kimi-specific Swarm/Claw/Code CLI
- Complement (not replace): Platform key for Kimi K3 in external tools while keeping Cursor for editing

## Current user state (2026-07-28)

| Item | Status |
|------|--------|
| OAuth fix | **OK** (`FIX_OK_MEMBERSHIP_BLOCKED`) |
| Membership | **Not active** → 402 |
| Platform key | **Not configured** |
| Recommended next step | Wait for Vivace **or** add Platform key for partial K3 |

## Legal paths only

No bypass of membership gate documented in [`architecture.md`](architecture.md). All inference paths require subscription, Platform balance, or consumer web session.

## References

- Architecture: [`architecture.md`](architecture.md)
- Billing: [`billing-claw.md`](billing-claw.md)
- Platform playbook: [`../platform-probe.ps1`](../platform-probe.ps1)
- Vivace playbook: [`vivace-capabilities.md`](vivace-capabilities.md)
