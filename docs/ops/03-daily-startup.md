# 03 Daily Startup

Use this checklist when both PCs have just powered on.

Order:

1. PC-2 startup first if memory/database services are needed.
2. PC-1 startup second.
3. Verify Continue.
4. Troubleshoot only after a read-only check fails.

## A. PC-2 Startup First

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
docker ps
curl -fsS http://127.0.0.1:8101/health | jq .
curl -fsS http://127.0.0.1:8102/health | jq .
curl -fsS http://127.0.0.1:6333/readyz
```

Expected good signs:

- `git status --short` is empty or only shows changes you recognize.
- `docker ps` shows the expected support containers.
- Memory API and Embed Worker return JSON.
- Qdrant ready check returns success text.

If services are not running and you intentionally want PC-2 support services up:

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d memory-api embed-worker postgres qdrant
docker ps
```

## B. PC-1 Checks PC-2

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-1 can reach PC-2 at `192.168.50.2`.

## C. PC-1 Startup Second

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
docker ps
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
make model-status
make model-start MODEL=qwen-coder-14b-fast
make model-health
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good signs:

- Gateway health returns JSON.
- `/v1/models` returns a model list.
- `make model-health` succeeds.

If Gateway is not running and you intentionally want the PC-1 stack up:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make runtime-prepare
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api memory-api embed-worker postgres qdrant
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

## D. Verify Continue

Continue runs on PC-1. It should point to:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

Expected good sign: Continue can answer through Gateway-Auto.

## E. If Something Fails

Open [07-troubleshooting.md](07-troubleshooting.md). Do not restart everything blindly. First find which check failed: PC-2 network, PC-2 service, PC-1 Gateway, PC-1 llama-server, or Continue config.
