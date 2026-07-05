# 08 Command Cheatsheet

Use this when you know what you need and just want the exact command.

## Most Common Daily Commands

### A. Start Of Day PC-2 Checks

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
curl -fsS http://127.0.0.1:8101/health | jq .
curl -fsS http://127.0.0.1:8102/health | jq .
curl -fsS http://127.0.0.1:6333/readyz
```

### B. Start Of Day PC-1 Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
docker ps
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

### C. Gateway Rebuild After Code Change

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

### D. Model Runtime Check

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-status
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

### E. Continue.dev Check

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gateway-auto","messages":[{"role":"user","content":"Reply with one short sentence."}]}' | jq .
```

Continue config should include:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

### F. Git Commit Check

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status
git diff --stat
find . -maxdepth 1 -type f -name '@*' -print
```

## PC-1 Checking PC-2 Commands

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
ssh cuneyt@192.168.50.2
```

Replace `cuneyt` only if the PC-2 Linux username is different.

## Gateway Runtime Profile Endpoints

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-preflight | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-run-catalog | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-compatibility-matrix | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-recommendation-summary | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-dashboard-summary | jq .
curl -fsS http://127.0.0.1:8100/gateway/runtime/profile-operator-checklist | jq .
```

## Git Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status
git diff --stat
find . -maxdepth 1 -type f -name '@*' -print
git add <files>
git commit -m "Describe the small milestone"
git push origin <branch>
```

## Dangerous Commands

Do not run these casually:

- `docker compose down -v`
- `docker system prune`
- `rm -rf`
- `kill -9`
- deleting model files
- deleting `~/MoE/runtime` data

Use them only when advanced, backed up, and sure of the target.
