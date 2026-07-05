# 10 Runtime Profile Guide

M29.15 through M29.20 added read-only runtime profile endpoints for human review. They do not switch models.

These endpoints run through Gateway on PC-1. They do not use PC-2 directly unless Gateway config points to PC-2 services.

## Check Runtime Profile Endpoints

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-preflight | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-run-catalog | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-compatibility-matrix | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-recommendation-summary | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-dashboard-summary | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-operator-checklist | jq .
```

Expected good signs:

- Each endpoint returns JSON.
- The response says `read_only: true`.
- The response says `runtime_switch_supported: false`.

## What Each Endpoint Means

| Endpoint | Purpose |
| --- | --- |
| `/gateway/runtime/profile-preflight` | Checks configured runtime profiles and active runtime state. |
| `/gateway/runtime/profile-run-catalog` | Shows documentation-only run settings for profiles. |
| `/gateway/runtime/profile-compatibility-matrix` | Estimates compatibility for the documented PC-1 class machine. |
| `/gateway/runtime/profile-recommendation-summary` | Summarizes default, review, and fallback profile choices. |
| `/gateway/runtime/profile-dashboard-summary` | Exposes compact read-only summary for dashboard surfaces. |
| `/gateway/runtime/profile-operator-checklist` | Exports a manual operator checklist for profile decisions. |

## Safety Contract

These endpoints do not:

- Switch models.
- Start llama-server.
- Stop llama-server.
- Run shell commands.
- Call Docker.
- Write runtime files.
- Inspect live GPU state unless a future milestone adds that.

Use the output for human review before manual runtime changes.
