# 01 Fresh Install PC-1

PC-1 is the main workstation/operator machine at `192.168.50.1`. It runs Continue.dev, Gateway API, llama-server, and local operator commands.

## 1. Create Folders

### Run on PC-1

```bash
mkdir -p ~/DiskD/Projects/MoE
mkdir -p ~/MoE_Models_Backup
mkdir -p ~/Apps
```

Expected good sign: the commands finish without output.

## 2. Clone The Repo

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE
git clone https://github.com/cuneytoner/MoE.git codebase
cd ~/DiskD/Projects/MoE/codebase
```

Expected good sign: `codebase` exists and contains `Makefile`, `docs/`, `apps/`, and `infra/`.

## 3. Verify Paths

### Run on PC-1

```bash
pwd
git status --short
ls -lh ~/MoE_Models_Backup/
```

Expected good signs:

- `pwd` prints `/home/cuneyt/DiskD/Projects/MoE/codebase`.
- `git status --short` is empty on a clean clone.
- The model backup folder exists. Model files may need to be restored there before model runtime works.

## 4. Verify Docker

### Run on PC-1

```bash
docker --version
docker compose version
```

Expected good sign: both commands print version numbers.

## 5. Start Gateway Stack On PC-1

The current Compose services are `gateway-api`, `memory-api`, `embed-worker`, `postgres`, and `qdrant`.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make runtime-prepare
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api memory-api embed-worker postgres qdrant
docker ps
```

Expected good signs:

- `docker ps` shows containers named like `moe-gateway-api`, `moe-memory-api`, `moe-embed-worker`, `moe-postgres`, and `moe-qdrant`.
- No container is restarting repeatedly.

## 6. Start llama-server On PC-1

The documented llama.cpp server path is:

```text
~/Apps/llama.cpp/build/bin/llama-server
```

Use the host script through Make:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-start MODEL=qwen-coder-14b-fast
make model-health
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

Expected good signs:

- `make model-health` succeeds.
- `/v1/models` returns JSON with a model list.

## 7. Check Gateway

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good signs:

- Gateway health returns JSON.
- Gateway `/v1/models` returns a model list.

## 8. Check PC-2 From PC-1

Skip this if you are installing PC-1 only.

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good signs:

- Ping receives replies.
- Memory API and Embed Worker return JSON.
- Qdrant ready check returns success text.

## 9. Configure Continue.dev On PC-1

Use Gateway, not direct llama-server.

```yaml
name: Main Config
version: 1.0.0
schema: v1
models:
  - name: Gateway-Auto
    provider: openai
    model: gateway-auto
    apiBase: http://localhost:8100/v1
    apiKey: local
    temperature: 0.2
    contextLength: 8192
defaultModel: Gateway-Auto
```

Expected good sign: Continue can answer through `Gateway-Auto`.

## Do Not Run On PC-1

Do not put model files in the repo. Do not create real `.env` files unless you intentionally manage local secrets. Do not expect Gateway to switch models automatically.
