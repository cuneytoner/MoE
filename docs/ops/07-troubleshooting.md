# 07 Troubleshooting

Every command below says where to run it. Start with read-only checks. Change one thing at a time.

## PC-1 Cannot Ping PC-2

### Run on PC-1

```bash
ip -4 addr
ping -c 3 192.168.50.2
```

### Run on PC-2

```bash
ip -4 addr
ping -c 3 192.168.50.1
```

Expected good signs:

- PC-1 has `192.168.50.1` on the wired link.
- PC-2 has `192.168.50.2` on the wired link.
- Ping works in both directions.

## Gateway 404 After Code Change

The Gateway container may be running old code.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

Expected good sign: Gateway health returns JSON.

## Gateway Unavailable

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
docker compose --env-file .env.example -f infra/docker/docker-compose.yml logs gateway-api --tail=80
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

Expected good sign: `moe-gateway-api` is running and health returns JSON.

## llama-server Unavailable

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-status
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

If it is not running and you intentionally want it up:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-start MODEL=qwen-coder-14b-fast
make model-health
```

Expected good sign: `/v1/models` returns a model list.

## PC-2 Memory Unreachable From PC-1

### Run on PC-1

```bash
curl -v http://192.168.50.2:8101/health
```

### Run on PC-2

```bash
docker ps
curl -v http://127.0.0.1:8101/health
```

Expected good signs:

- PC-2 shows `moe-memory-api` running.
- Local PC-2 health works.
- PC-1 can reach `192.168.50.2:8101`.

## `/v1/models` Not Responding

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good signs:

- Port `8000` returns llama-server model data.
- Port `8100` returns Gateway model data.

## Continue Returns Only OK Or No Answer

Check Continue config:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

Then test Gateway chat directly.

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gateway-auto","messages":[{"role":"user","content":"Reply with one short sentence."}]}' | jq .
```

Expected good sign: JSON includes `choices[0].message.content`.

## Model Missing

### Run on PC-1

```bash
ls -lh ~/MoE_Models_Backup/
cd ~/DiskD/Projects/MoE/codebase
make check-models
```

Restore model files outside the repo. Do not commit model files.

## Unhealthy Container

### Run on the machine where the container is running

```bash
docker ps
docker compose --env-file .env.example -f infra/docker/docker-compose.yml logs --tail=80
```

## Port Conflict

### Run on the machine with the conflict

```bash
ss -ltnp | grep ':8100' || true
ss -ltnp | grep ':8000' || true
```

Do not kill unknown processes without understanding what owns them.

## Tests Fail Because Container Has Old Code

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api
make test-gateway
```

## Dangerous Or Advanced

Commands that stop containers, delete Docker volumes, prune Docker state, or kill processes are manual/advanced. Back up first and verify the target before running them.
