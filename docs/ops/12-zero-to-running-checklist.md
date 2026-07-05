# 12 Zero To Running Checklist

Use this as a compact checklist. Run rows in order.

| Order | Machine | Directory | Command | Expected good sign | If failed, read |
| --- | --- | --- | --- | --- | --- |
| 1 | PC-2 | any | `ip -4 addr` | PC-2 shows `192.168.50.2` | [07 Troubleshooting](07-troubleshooting.md#pc-1-cannot-ping-pc-2) |
| 2 | PC-1 checking PC-2 | any | `ping -c 3 192.168.50.2` | Replies from PC-2, `0%` loss | [07 Troubleshooting](07-troubleshooting.md#pc-1-cannot-ping-pc-2) |
| 3 | PC-2 | `~/DiskD/Projects/MoE/codebase` | `docker ps` | Expected PC-2 containers are running | [02 Fresh Install PC-2](02-fresh-install-pc2.md) |
| 4 | PC-1 checking PC-2 | any | `curl -fsS http://192.168.50.2:8101/health \| jq .` | Memory API returns JSON | [07 Troubleshooting](07-troubleshooting.md#pc-2-memory-unreachable-from-pc-1) |
| 5 | PC-1 checking PC-2 | any | `curl -fsS http://192.168.50.2:8102/health \| jq .` | Embed Worker returns JSON | [02 Fresh Install PC-2](02-fresh-install-pc2.md) |
| 6 | PC-1 checking PC-2 | any | `curl -fsS http://192.168.50.2:6333/readyz` | Qdrant returns ready response | [02 Fresh Install PC-2](02-fresh-install-pc2.md) |
| 7 | PC-1 | `~/DiskD/Projects/MoE/codebase` | `git status --short` | Empty or recognized changes only | [09 Git Workflow](09-git-workflow.md) |
| 8 | PC-1 | `~/DiskD/Projects/MoE/codebase` | `docker ps` | `moe-gateway-api` is running | [07 Troubleshooting](07-troubleshooting.md#gateway-unavailable) |
| 9 | PC-1 | `~/DiskD/Projects/MoE/codebase` | `curl -fsS http://127.0.0.1:8100/gateway/health \| jq .` | Gateway health returns JSON | [07 Troubleshooting](07-troubleshooting.md#gateway-unavailable) |
| 10 | PC-1 | `~/DiskD/Projects/MoE/codebase` | `curl -fsS http://127.0.0.1:8000/v1/models \| jq .` | llama-server returns model list | [07 Troubleshooting](07-troubleshooting.md#llama-server-unavailable) |
| 11 | PC-1 | `~/DiskD/Projects/MoE/codebase` | `curl -fsS http://127.0.0.1:8100/v1/models \| jq .` | Gateway OpenAI models return JSON | [07 Troubleshooting](07-troubleshooting.md#v1models-not-responding) |
| 12 | PC-1 | Continue config | `apiBase: http://localhost:8100/v1` and `model: gateway-auto` | Continue points to Gateway-Auto | [07 Troubleshooting](07-troubleshooting.md#continue-returns-only-ok-or-no-answer) |

If you are unsure where to run a command, stop and check [13-service-location-reference.md](13-service-location-reference.md).
