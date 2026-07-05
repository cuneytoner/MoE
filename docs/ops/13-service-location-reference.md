# 13 Service Location Reference

If you are unsure where to run a command, stop here and check the table.

## Quick Answers

- Gateway runs on PC-1 at `192.168.50.1`, port `8100`.
- llama-server runs on PC-1 at `192.168.50.1`, port `8000`.
- Memory API usually runs on PC-2 at `192.168.50.2`, port `8101`, or in the local PC-1 Docker stack for single-machine mode.
- Embed Worker usually runs on PC-2 at `192.168.50.2`, port `8102`, or in the local PC-1 Docker stack for single-machine mode.
- Postgres usually runs on PC-2 or the local Docker stack, port `5432`.
- Qdrant usually runs on PC-2 or the local Docker stack, ports `6333` and `6334`.
- Continue should run on PC-1.
- Models should live on PC-1 under `~/MoE_Models_Backup/`.
- Git commands for normal operator work usually run on PC-1 in `~/DiskD/Projects/MoE/codebase`.

## Service Table

| Service | Machine | IP/Host | Port | Start method | Health check | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Continue.dev | PC-1 | `localhost` | n/a | editor config | Check config uses `apiBase: http://localhost:8100/v1` | Uses `model: gateway-auto` |
| Gateway API | PC-1 | `127.0.0.1` or `192.168.50.1` | `8100` | Docker service `gateway-api` | `curl -fsS http://127.0.0.1:8100/gateway/health \| jq .` | Does not switch models |
| llama-server | PC-1 | `127.0.0.1` or `192.168.50.1` | `8000` | host script `make model-start MODEL=qwen-coder-14b-fast` | `curl -fsS http://127.0.0.1:8000/v1/models \| jq .` | Model files live under `~/MoE_Models_Backup/` |
| Memory API | PC-2 or local stack | `192.168.50.2` or `127.0.0.1` | `8101` | Docker service `memory-api` | `curl -fsS http://192.168.50.2:8101/health \| jq .` | PC-1 can check PC-2 over wired link |
| Embed Worker | PC-2 or local stack | `192.168.50.2` or `127.0.0.1` | `8102` | Docker service `embed-worker` | `curl -fsS http://192.168.50.2:8102/health \| jq .` | Embedding service |
| Postgres | PC-2 or local stack | `192.168.50.2` or `127.0.0.1` | `5432` | Docker service `postgres` | `docker ps` on host machine | Preserve volumes |
| Qdrant | PC-2 or local stack | `192.168.50.2` or `127.0.0.1` | `6333/6334` | Docker service `qdrant` | `curl -fsS http://192.168.50.2:6333/readyz` | Preserve volumes |
| Runtime profile endpoints | PC-1 Gateway | `127.0.0.1` | `8100` | manual only, read-only API | `curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-recommendation-summary \| jq .` | Advisory only |
| Git workflow | PC-1 | local filesystem | n/a | manual only | `git status --short` | Usually in `~/DiskD/Projects/MoE/codebase` |

Start method meanings:

- Docker service: controlled by Docker Compose after human review.
- Host script: a local operator script run manually by a human.
- Editor config: configured inside Continue.dev.
- Manual only: no automatic service execution.
