# Vivace / Membership Capabilities Playbook

**Trigger:** active Kimi Membership or Vivace subscription.  
**Probe script:** [`../post-access-probe.ps1`](../post-access-probe.ps1)

## Expected runtime (fill after access)

| Check | Expected | Actual | Date |
|-------|----------|--------|------|
| `GET /models` | HTTP 200 + model list | _pending_ | |
| `GET /usages` | HTTP 200 + quota JSON | _pending_ | |
| `POST /chat/completions` (K3) | HTTP 200 | _pending_ | |
| `kimi -p "ping"` | Model response | _pending_ | |
| CLI `/usage` | Weekly + fuel pack | _pending_ | |
| CLI `/status` | Plan + booster balance | _pending_ | |

## Quota JSON fields (from `managed-usage.ts`)

When `/usages` returns 200, record:

```json
{
  "usage": { "used": "", "limit": "", "resetTime": "" },
  "limits": [{ "window": { "duration": 0, "timeUnit": "" }, "detail": {} }],
  "boosterWallet": { "type": "BOOSTER" }
}
```

Save raw response to `atlas/vivace-usages-sample.json` after first successful probe.

## AgentSwarm verification

1. Enable experimental flag if needed: `KIMI_CODE_EXPERIMENTAL_FLAG=1` for `kimi -p`
2. Run `/swarm` or invoke `AgentSwarm` tool with ≥2 items
3. Optional cap: `KIMI_CODE_AGENT_SWARM_MAX_CONCURRENCY=<n>`
4. Confirm max 128 subagents documented in llms-full

## kimi web debug endpoints

```bash
kimi web --no-open --port 59999 --debug-endpoints
```

Inventory:

- `GET /openapi.json` — local REST spec
- `GET /asyncapi.json` — WebSocket spec
- `/api/v1/debug/*` — debug routes (off by default)

## Claw path (if membership includes)

1. OpenClaw with `@openclaw/kimi-provider` + Coding Plan key from https://www.kimi.com/code/en
2. Verify `bot_id` UUID v4 auto-injection (no manual `openclaw-local`)
3. Monitor for `ClawExtension` errors in error-reference taxonomy

## Models to test

| Alias | Backend | Context |
|-------|---------|---------|
| `kimi-code/k3` | k3 | 1M |
| `kimi-code/k3-256k` | k3-256k | 256K |
| `kimi-code/kimi-for-coding` | kimi-for-coding | K2.7 Code |
| `kimi-code/kimi-for-coding-highspeed` | kimi-for-coding-highspeed | HighSpeed |

## Membership tier errors (reference)

See [`error-catalog.json`](error-catalog.json) sections: `no-k3-access`, `no-1m-access`, `unable-to-verify-membership`.
