# Deepening Pass B — New Findings (2026-07-28)

Runtime and source recon beyond Phase 1–8 atlas. No membership bypass attempted.

## 1. Device OAuth flow (confirmed live)

`POST https://auth.kimi.com/api/oauth/device_authorization` with `client_id=17e5f671-d194-4dfb-9706-5516cb48c098&scope=kimi-code` returns **200**:

```json
{
  "device_code": "...",
  "user_code": "XXXX-XXXX",
  "verification_uri": "https://www.kimi.com/code/authorize_device",
  "verification_uri_complete": "https://www.kimi.com/code/authorize_device?user_code=...",
  "expires_in": 1800,
  "interval": 5
}
```

Polling: `POST /api/oauth/token` with `grant_type=device_code`. Source: `packages/oauth/src/oauth.ts`.

**New surface:** official headless/CI login path without browser redirect — user approves at `kimi.com/code/authorize_device`.

## 2. Code API dual protocol routing

From `managed-kimi-code.ts`, `/models` entries may declare:

| Field | Values | Effect |
|-------|--------|--------|
| `protocol` | `kimi` (default) or `anthropic` | Routes anthropic models to Messages API |
| `think_efforts` | `{ support, valid_efforts, default_effort }` | Thinking effort levels per model |
| `supports_thinking_type` | `only` / `no` / `both` | Overrides legacy `supports_reasoning` |

When `protocol === 'anthropic'`, CLI sets `betaApi: true` → **`/v1/messages?beta=true`** on the Code gateway (same membership gate).

OpenClaw `@openclaw/kimi-provider` uses anthropic-messages on `api.kimi.com/coding/` — aligns with this path.

## 3. Feedback pipeline (three endpoints)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/feedback` | POST | Submit feedback JSON; returns `feedback_id` |
| `/feedback/upload_url` | POST | Multipart presigned URLs for log/codebase attachments |
| `/feedback/upload_complete` | POST | Complete multipart upload with etags |

Source: `managed-feedback.ts`, `managed-feedback-upload.ts`. Requires membership context for full acceptance (same gateway).

## 4. Device identity headers (OAuth)

Every OAuth request carries `X-Msh-*` headers from `identity.ts`:

| Header | Example / role |
|--------|----------------|
| `X-Msh-Platform` | `kimi_code_cli` |
| `X-Msh-Version` | CLI version |
| `X-Msh-Device-Id` | UUID in `~/.kimi-code/device_id` |
| `X-Msh-Device-Name` | hostname |
| `X-Msh-Device-Model` | OS arch/type |
| `X-Msh-Os-Version` | OS release |

JWT `device_id` claim binds token to this machine id.

## 5. Goal mode — now GA + internal state machine

Changelog (llms-full): **goals, background questions, sub-skill discovery no longer require experimental opt-in.**

Internal design doc `GOAL.md` (monorepo) defines state machine:

| State | Behavior |
|-------|----------|
| `active` | Auto-continues turns until complete/blocked/paused |
| `paused` | User or error halt; resumable |
| `blocked` | Needs input or budget hit; resumable |
| `complete` | Transient; cleared after summary |

**`kimi -p` exit codes for goals:**

| Code | Meaning |
|------|---------|
| 0 | Goal complete |
| 3 | Goal blocked |
| 6 | Goal paused |

Queue storage: `upcoming-goals.json` (TUI-only until promoted).

## 6. Platform API — full surface (not on Code API)

From live `platform.kimi.ai/docs/llms.txt` + openapi (10 paths):

| Path | Capability |
|------|------------|
| `/v1/chat/completions` | K3, K2.7 Code, K2.6 inference |
| `/v1/models` | Model list with capabilities |
| `/v1/users/me/balance` | Prepaid + voucher balances |
| `/v1/batches` | Async batch jobs (JSONL, max 100MB) |
| `/v1/files` | Upload for extract/image/video |
| `/v1/tokenizers/estimate-token-count` | Pre-flight token estimate |

**Regional endpoint:** `api-sg.moonshot.ai` resolves and returns **401** without key (Singapore mirror).

**Rate limit tiers** (from `docs/pricing/limits.md`):

| Tier | Cumulative recharge | Concurrency | RPM | TPM |
|------|---------------------|-------------|-----|-----|
| Tier0 | $1 | 1 | 3 | 500K |
| Tier1 | $10 | 50 | 200 | 2M |
| Tier2 | $20 | 100 | 500 | 3M |
| Tier3 | $100 | 200 | 5K | 3M |
| Tier4 | $1,000 | 400 | 5K | 4M |
| Tier5 | $3,000 | 1,000 | 10K | 5M |

Minimum **$1 recharge** to start; **$5 cumulative → $5 voucher**.

## 7. Platform model lineup (new docs)

| Model ID | Context | Notes |
|----------|---------|-------|
| `kimi-k3` | 1M | Flagship; Platform + Code (membership) |
| `kimi-k2.7-code` | 256K | Coding model; thinking-only |
| `kimi-k2.7-code-highspeed` | 256K | ~180–260 tok/s; resource-limited |
| `kimi-k2.6` | 256K | Prior gen |
| `kimi-k2.5` | 256K | Legacy |

K2.7 Code on Platform = pay-as-you-go alternative to Code membership for **inference-only** coding.

## 8. OpenClaw moonshot-provider (npm 2026.7.1)

Beyond prior kimi-provider intel:

- Provider id: `moonshot`; aliases `moonshotai`, `moonshot-ai`
- Special stream hooks for `kimi-k2.7-code` thinking
- Registers **media understanding** + **Kimi web search** providers
- Uses OpenAI-compatible replay policy with tool-call ID sanitization

## 9. BoosterWallet parser (source detail)

From `managed-usage.ts`:

- `FIXED_POINT_CENTS = 1_000_000` for money fields
- `boosterWallet.type` must be **`BOOSTER`** to parse as fuel pack
- Window units: `TIME_UNIT_MINUTE|HOUR|DAY|WEEK`
- CLI label: **Extra Usage** in `/usage` and `/status`

## 10. Infra updates

| Host | Status (2026-07-28) |
|------|---------------------|
| `chat.msh.team` | 503 |
| `vapay.kimi.com` | 404 (CRT-listed payment subdomain) |
| `test-platform.moonshot.ai` | NXDOMAIN |
| `api-sg.moonshot.ai` | 401 (live) |

Pricing Wayback (`membership-pricing-20260727`): SPA meta mentions **Swarm + Goal** marketing; no extractable dollar tiers in static HTML (client-rendered).

## 11. Experimental flags still relevant

| Env | Scope |
|-----|-------|
| `KIMI_CODE_EXPERIMENTAL_FLAG=1` | Master switch for `kimi -p` v2: `--agent`, SYSTEM.md, secondary model |
| `KIMI_CODE_EXPERIMENTAL_SECONDARY_MODEL=1` | Secondary model for subagents under `kimi web` |
| `KIMI_CODE_EXPERIMENTAL_SUB_SKILL=1` | `/sub-skill.review`, `/sub-skill.consolidate` bundles |

Goals themselves are **no longer** behind `KIMI_CODE_EXPERIMENTAL_GOAL_COMMAND` per latest changelog.

## References

- Device OAuth: `packages/oauth/src/oauth.ts`, `constants.ts`
- Model protocol: `packages/oauth/src/managed-kimi-code.ts`
- Goal design: `GOAL.md` in kimi-code monorepo
- Platform limits: `platform-docs/docs-pricing-limits.md`
- K2.7 Code: `platform-docs/docs-guide-kimi-k2-7-code-quickstart.md`
