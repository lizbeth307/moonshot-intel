# Protobuf and Error Envelope Reference

## 403 `/usages` — `common.error.v1.ErrorDetail`

Runtime response (OAuth, no membership feature permission):

```json
{
  "code": "permission_denied",
  "details": [{
    "type": "common.error.v1.ErrorDetail",
    "value": "<base64 protobuf>"
  }]
}
```

Decoded payload (from runtime base64 decode):

| Field | Value |
|-------|-------|
| Locale | `en-US` |
| Message | `You do not have permission to use this feature. Please subscribe to access.` |

**Conclusion:** 403 uses gRPC-style `ErrorDetail` protobuf with localized message. Separate from 402 OpenAI-style membership error on `/models`.

## 402 — OpenAI-compatible envelope

```json
{
  "error": {
    "message": "We're unable to verify your membership benefits at this time. Please ensure your membership is active.",
    "type": "invalid_request_error"
  }
}
```

HTTP **402** on membership gate; includes `X-Trace-Id`.

## Billing — `kimi.billing.v1.ClawExtension`

From [error-reference](https://www.kimi.com/code/docs/en/kimi-code/error-reference.html) (archived in `wayback/error-ref-20260727.html`):

```
invalid_argument: field kimi.billing.v1.ClawExtension.bot_id: value "openclaw-local" (id_kind=uuid_v4): value does not match id_kinds: [uuid_v4]
```

| Field | Constraint |
|-------|------------|
| `bot_id` | Must be valid UUID v4 |
| Injection | Auto-attached by client software (OpenClaw plugin), not user-set |

**Not found in:** `@openclaw/kimi-provider` npm bundle (server-side extension only).

## Usage API JSON schema (from `managed-usage.ts`)

Expected **200** response from `GET /usages`:

```json
{
  "usage": {
    "used": "40",
    "limit": "1000",
    "resetTime": "2026-08-03T05:20:51Z"
  },
  "limits": [{
    "window": { "duration": 300, "timeUnit": "TIME_UNIT_MINUTE" },
    "detail": { "used": "1", "limit": "100", "resetTime": "..." }
  }],
  "boosterWallet": {
    "type": "BOOSTER"
  }
}
```

Constants from source:

- `FIXED_POINT_CENTS = 1_000_000` (money fields)
- `TIME_UNIT_*` proto enums (minute, hour, etc.)
- CLI `/usage` and `/status` display **Extra Usage (fuel pack)** from `boosterWallet`

## Platform dual error taxonomy

On `api.moonshot.ai/v1`:

| Path | Error style |
|------|-------------|
| `/v1/models` (no key) | OpenAI `invalid_authentication_error` |
| Wrong method/path | Chinese `url.not_found` code:5 |

## gRPC status → HTTP mapping (docs leak)

| gRPC | Typical HTTP | Meaning |
|------|--------------|---------|
| `invalid_argument` | 400 | Bad request / ClawExtension validation |
| `unauthenticated` | 401 | Auth failure |
| `permission_denied` | 403 | Feature / quota permission |
| `failed_precondition` | 402/403 | Membership / plan |
| `unavailable` | 503 | Backend down |
| `internal` | 500 | Postgres/Redis failures |
| `canceled` | — | Client disconnect |

Full catalog: [`error-catalog.json`](error-catalog.json) (33 sections from error-reference).
