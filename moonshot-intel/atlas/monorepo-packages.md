# MoonshotAI/kimi-code Monorepo Package Map

Source: https://github.com/MoonshotAI/kimi-code (branch `main`)

## Package index

| Package | Path | Runtime role |
|---------|------|--------------|
| **acp-adapter** | `packages/acp-adapter` | ACP JSON-RPC for IDEs (Zed, JetBrains); capability matrix in llms-full |
| **agent-core** | `packages/agent-core` | Legacy agent engine |
| **agent-core-v2** | `packages/agent-core-v2` | v2 engine; `AgentSwarm`, tools, subagent timeout |
| **oauth** | `packages/oauth` | Managed platform OAuth, `/usages`, `/feedback`, token refresh |
| **node-sdk** | `packages/node-sdk` | HTTP client to Code API |
| **protocol** | `packages/protocol` | ACP daemon protocol TS (error codes 40110–40911); **not** billing protobuf |
| **kap-server** | `packages/kap-server` | Kimi ACP server / local daemon |
| **kaos** | `packages/kaos` | Internal utilities |
| **cli** | `packages/cli` | `kimi` binary, config.toml, providers |

## oauth — key files

| File | Purpose |
|------|---------|
| [`managed-usage.ts`](https://github.com/MoonshotAI/kimi-code/blob/main/packages/oauth/src/managed-usage.ts) | `GET /usages` parser; `boosterWallet`, `TIME_UNIT_*`, `FIXED_POINT_CENTS` |
| [`managed-feedback.ts`](https://github.com/MoonshotAI/kimi-code/blob/main/packages/oauth/src/managed-feedback.ts) | `POST /feedback` telemetry |
| `api-error.ts` | Shared error message extraction |

Managed platform ID: `managed:kimi-code`  
Default base URL: `https://api.kimi.com/coding/v1` (override via `KIMI_CODE_BASE_URL`)

## agent-core-v2 — features (from docs)

- Built-in tools: `Agent`, `AgentSwarm` (max 128 subagents), `Bash`, `Read`, `Edit`, …
- Env: `KIMI_CODE_AGENT_SWARM_MAX_CONCURRENCY`, `KIMI_SUBAGENT_TIMEOUT_MS` (default 2h)
- Slash: `/swarm`, `/usage`, `/status`
- Secondary model experiment: `KIMI_CODE_EXPERIMENTAL_SECONDARY_MODEL`

## acp-adapter

- Subcommand: `kimi acp`
- Protocol: `@agentclientprotocol/sdk@0.23.0`
- MCP transports forwarded: `http`, `stdio`, `sse` (not `acp` transport)
- Stable vs `unstable_*` method surfaces documented in llms-full

## protocol package — explicit non-scope

Grep confirms **no** `ClawExtension`, `membership_009`, or `.proto` billing definitions.

Billing protobuf `kimi.billing.v1.*` lives server-side; client sees only HTTP/JSON or gRPC error strings in docs.

## OpenClaw npm (external)

| Package | Repo path equivalent |
|---------|---------------------|
| `@openclaw/kimi-provider` | Coding endpoint wrapper (not in kimi-code monorepo) |
| `@openclaw/moonshot-provider` | Platform K3 wrapper |

## Install / distribution

Official CLI install (not `@kimi/code` npm):

```bash
curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
```

Legacy catch-all: `code.kimi.com/api/health` serves deprecated Python installer script.

## Plugin marketplace

Fetched catalog: [`marketplace.json`](marketplace.json) from `code.kimi.com/kimi-code/plugins/marketplace.json`

Official tier includes **Kimi Datasource** plugin; curated: Superpowers, Vercel Plugin.
