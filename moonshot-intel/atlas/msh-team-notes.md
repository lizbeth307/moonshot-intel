# msh.team Infrastructure Notes

## Host comparison

| Host | IP / edge | Reachability | Role |
|------|-----------|--------------|------|
| `api.msh.team` | **172.24.64.47** (RFC1918) | Unreachable from public internet | Internal moderation (`/v1/moderations`), VPC-only |
| `chat.msh.team` | **103.143.17.156** (volcddos.com) | Public; observed **503** nginx | Consumer/chat edge (not Code API) |
| `code.msh.team` | — | NXDOMAIN | — |
| `platform.msh.team` | — | NXDOMAIN | — |

## chat.msh.team anomaly (intel-hunt-6/7/8)

Historical probe found:

- CNAME → volcddos.com → same IP as `code.kimi.com`
- Path `/api` returned **200** with EchoMind Stoplight OpenAPI (39 paths)
- Documented server URL pointed to `https://qianxun-dev.rcrai.com/api` — **misplaced third-party dev spec**, not Kimi Code gateway

Current state (2026-07-28): root and `/v1/models` return **503 Service Temporarily Unavailable**.

**Conclusion:** Public msh.team edge exists but is not a bypass path to Kimi Code inference.

## volcddos edge cluster (103.143.17.156)

Shared by:

- `code.kimi.com`
- `open.kimi.com` (404 at root — reserved)
- `chat.msh.team` (503)

Direct IP requests with `Host:` header → **302** nginx redirect (no API bypass).

## Internal references in docs

From error-reference:

```
image_url: Post "https://api.msh.team/v1/moderations": context deadline exceeded
```

Moderation failures surface as HTTP 500 to clients; illegal content → Chinese `非法输入`.

## DNS / TLS discovery

See [`infra-dns.json`](infra-dns.json) for:

- Resolved `*.kimi.com` hosts
- NXDOMAIN list for inference-related subdomains
- CRT.sh certificate transparency samples for `kimi.com`, `msh.team`, `moonshot.ai`

## Trace IDs

Code API 402/403 responses include `X-Trace-Id` (Cloudflare edge). Useful for Moonshot support tickets; not exposed via foreign Cloudflare zone MCP.
