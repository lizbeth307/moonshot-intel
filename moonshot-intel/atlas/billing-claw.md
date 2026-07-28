# Billing, Quota, and Claw Stack

## Three billing systems

| System | Trigger | Unit | CLI surface |
|--------|---------|------|-------------|
| **Membership** | Postgres `membership_009` | Plan tier (Moderato, Allegretto, Vivace, …) | 402 on inference |
| **Usage quota** | Redis + `/usages` | Rolling windows + weekly cap | `/usage`, `/status` |
| **Fuel pack** | `boosterWallet` type `BOOSTER` | Prepaid extra usage | Shown in `/usage` |

## Membership tier hints (from error-reference)

Errors reference upgrade URLs with plan names:

| Error | Required tier (docs) |
|-------|----------------------|
| No K3 access | **Moderato** or above |
| K3 1M context blocked | Higher tier (256K-only on lower plan) |
| `kimi-for-coding-highspeed` | **Allegretto** or above |
| Usage limit exhausted | 403 — wait for billing cycle refresh |

Upgrade link pattern: `https://www.kimi.com/membership/pricing?from=server_*`

## Claw / OpenClaw integration

### Two OpenClaw provider packages

| Package | Base URL | Auth | Default model |
|---------|----------|------|---------------|
| `@openclaw/kimi-provider` | `https://api.kimi.com/coding/` | Coding Plan API key (`KIMI_API_KEY`) | `kimi-for-coding` |
| `@openclaw/moonshot-provider` | `https://api.moonshot.ai/v1` | Platform API key | `moonshot/kimi-k3` |

Coding provider details (npm `@openclaw/kimi-provider@2026.7.1`):

- API: `anthropic-messages`
- User-Agent: `claude-code/0.1.0`
- Legacy model IDs: `kimi-code`, `k2p5` → normalized to `kimi-for-coding`
- Context: 262144 tokens; max output 32768

### ClawExtension billing

- Protobuf: `kimi.billing.v1.ClawExtension.bot_id`
- Valid values: UUID v4 only (`openclaw-local` fails validation)
- Attached server-side when Claw clients send requests
- Env hint: `KIMI_CLAW_ID` (docs leak)

**Claw is not a separate public host** — billing rides on Code API gateway.

## Quota endpoint

```
GET https://api.kimi.com/coding/v1/usages
Authorization: Bearer <oauth_or_coding_key>
```

Without feature permission: **403** protobuf `permission_denied`.  
With membership: **200** + JSON per [`protobuf.md`](protobuf.md).

## Platform API billing (separate)

```
GET https://api.moonshot.ai/v1/users/me/balance
Authorization: Bearer <platform_api_key>
```

Pay-as-you-go; no Swarm/Claw. K3 pricing: see [`../platform-docs/pricing-chat-k3.md`](../platform-docs/pricing-chat-k3.md).

## Feedback endpoint (telemetry)

From `managed-feedback.ts`:

```
POST {baseUrl}/feedback
Body: { session_id, model, ... } with kimi-code- version prefix
```

Exists alongside chat; membership context required for full acceptance.
