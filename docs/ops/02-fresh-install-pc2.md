# 02 Fresh Install PC-2

PC-2 is the worker/support machine at `192.168.50.2`. It runs or supports Memory API, Embed Worker, Postgres, Qdrant, and background workers when enabled.

## 1. Confirm PC-2 Network Address

### Run on PC-2

```bash
ip -4 addr
hostname -I
```

Expected wired IP:

```text
192.168.50.2
```

If the IP is different, fix networking before continuing or adjust the docs for the real address.

## 2. Test PC-2 From PC-1

Replace `cuneyt` only if the Linux username on PC-2 is different.

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
ssh cuneyt@192.168.50.2
```

Expected good signs:

- Ping receives replies.
- SSH opens a PC-2 shell.

## 3. Clone The Repo On PC-2

### Run on PC-2

```bash
mkdir -p ~/DiskD/Projects/MoE
cd ~/DiskD/Projects/MoE
git clone https://github.com/cuneytoner/MoE.git codebase
cd ~/DiskD/Projects/MoE/codebase
git status --short
```

Expected good sign: `git status --short` is empty on a clean clone.

## 4. Verify Docker On PC-2

### Run on PC-2

```bash
docker --version
docker compose version
```

Expected good sign: both commands print version numbers.

## 5. Start Worker/Support Services On PC-2

The repo includes `deploy/pc2/docker-compose.worker.example.yml` for PC-2 worker services, but memory/database support services are currently defined in `infra/docker/docker-compose.yml`.

Current repo uses `infra/docker/docker-compose.yml`. For PC-2 worker-only mode, start only the needed services manually after reviewing compose service names.

For Memory API, Embed Worker, Postgres, and Qdrant support on PC-2, the exact current service names are `memory-api`, `embed-worker`, `postgres`, and `qdrant`.

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
make runtime-prepare
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build memory-api embed-worker postgres qdrant
docker ps
```

Expected good signs:

- `docker ps` shows containers named like `moe-memory-api`, `moe-embed-worker`, `moe-postgres`, and `moe-qdrant`.
- No container is restarting repeatedly.

## 6. Check PC-2 Health From PC-2

### Run on PC-2

```bash
curl -fsS http://127.0.0.1:8101/health | jq .
curl -fsS http://127.0.0.1:8102/health | jq .
curl -fsS http://127.0.0.1:6333/readyz
```

Expected good signs:

- Memory API and Embed Worker return JSON.
- Qdrant ready check returns success text.

## 7. Check PC-2 Health From PC-1

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-1 can reach PC-2 services over the wired link.

## PC-2 Should Not Run

PC-2 should not run Continue.dev, switch PC-1 models, or store model files inside the source repo.
