# 07 Troubleshooting

Every case below says where to run the command. Start with "Run this first." Do not restart everything blindly.

## PC-1 Cannot Ping PC-2

Symptom: PC-1 cannot reach `192.168.50.2`.

Likely cause: wrong wired IP, cable/network issue, or PC-2 is offline.

Run this first:

### Run on PC-1

```bash
ip -4 addr
ping -c 3 192.168.50.2
```

If that fails:

### Run on PC-2

```bash
ip -4 addr
ping -c 3 192.168.50.1
```

Related doc: [13-service-location-reference.md](13-service-location-reference.md).

## Gateway 404 After Code Change

Symptom: a newly added Gateway route returns `404`.

Likely cause: the `gateway-api` Docker container is still running old code.

Run this first:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

If that fails: inspect Gateway logs.

### Run on PC-1

```bash
docker compose --env-file .env.example -f infra/docker/docker-compose.yml logs gateway-api --tail=80
```

Related doc: [08-command-cheatsheet.md](08-command-cheatsheet.md).

## Gateway Unavailable

Symptom: `http://127.0.0.1:8100/gateway/health` does not return JSON.

Likely cause: Gateway container is stopped, unhealthy, or old.

Run this first:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

If that fails:

### Run on PC-1

```bash
docker compose --env-file .env.example -f infra/docker/docker-compose.yml logs gateway-api --tail=80
```

Related doc: [03-daily-startup.md](03-daily-startup.md).

## llama-server Unavailable

Symptom: `http://127.0.0.1:8000/v1/models` does not return a model list.

Likely cause: host llama-server is not running or the model file is missing.

Run this first:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-status
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

If that fails and you intentionally want the model runtime up:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-start MODEL=qwen-coder-14b-fast
make model-health
```

Related doc: [13-service-location-reference.md](13-service-location-reference.md).

## PC-2 Memory Unreachable From PC-1

Symptom: PC-1 cannot reach `http://192.168.50.2:8101/health`.

Likely cause: PC-2 Memory API is stopped, PC-2 network is wrong, or the service is bound incorrectly.

Run this first:

### Run on PC-1

```bash
curl -v http://192.168.50.2:8101/health
```

If that fails:

### Run on PC-2

```bash
docker ps
curl -v http://127.0.0.1:8101/health
```

Related doc: [02-fresh-install-pc2.md](02-fresh-install-pc2.md).

## `/v1/models` Not Responding

Symptom: Continue or Gateway cannot list models.

Likely cause: llama-server on `8000` is down, or Gateway on `8100` is down.

Run this first:

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

If that fails: fix the first failed endpoint. Port `8000` is llama-server. Port `8100` is Gateway.

Related doc: [11-first-day-walkthrough.md](11-first-day-walkthrough.md).

## Continue Returns Only OK Or No Answer

Symptom: Continue sends requests but does not show a useful assistant response.

Likely cause: Continue points at the wrong base URL, Gateway cannot reach llama-server, or streaming compatibility is not being exercised through Gateway.

Run this first:

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gateway-auto","messages":[{"role":"user","content":"Reply with one short sentence."}]}' | jq .
```

If that fails: confirm Continue config uses:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

Related doc: [11-first-day-walkthrough.md](11-first-day-walkthrough.md).

## Model Missing

Symptom: model start fails or llama-server reports no usable model.

Likely cause: model files are missing from `~/MoE_Models_Backup/`.

Run this first:

### Run on PC-1

```bash
ls -lh ~/MoE_Models_Backup/
cd ~/DiskD/Projects/MoE/codebase
make check-models
```

If that fails: restore model files outside the repo. Do not commit model files.

Related doc: [06-restore-new-machine.md](06-restore-new-machine.md).

## Unhealthy Container

Symptom: Docker shows a container as unhealthy or restarting.

Likely cause: service config, dependency, or old image problem.

Run this first:

### Run on the machine where the container is running

```bash
docker ps
docker compose --env-file .env.example -f infra/docker/docker-compose.yml logs --tail=80
```

If that fails: rebuild only the affected service after reviewing logs.

Related doc: [08-command-cheatsheet.md](08-command-cheatsheet.md).

## Port Conflict

Symptom: a service cannot bind to its port.

Likely cause: another process is already using the port.

Run this first:

### Run on the machine with the conflict

```bash
ss -ltnp | grep ':8100' || true
ss -ltnp | grep ':8000' || true
```

If that fails: identify the owner before stopping anything. Do not kill unknown processes.

Related doc: [13-service-location-reference.md](13-service-location-reference.md).

## Tests Fail Because Container Has Old Code

Symptom: source tests expect a route or response, but the live container behaves like old code.

Likely cause: Gateway container has not been rebuilt.

Run this first:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api
```

If that fails: inspect Gateway logs before changing code.

Related doc: [08-command-cheatsheet.md](08-command-cheatsheet.md).

## Dangerous Or Advanced

Symptom: you are tempted to delete volumes, prune Docker, or kill processes.

Likely cause: frustration, not a confirmed diagnosis. Back up and verify first.

Run this first:

### Run on the affected machine

```bash
docker ps
git status --short
```

If that fails: stop and ask for help. Commands that stop containers, delete Docker volumes, prune Docker state, or kill processes are manual/advanced.

Related doc: [05-backup.md](05-backup.md).
