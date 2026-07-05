# 16 Startup Service Matrix

Use this when you know the mode you want, but not which services should be running.

PC-1 is `192.168.50.1`. PC-2 is `192.168.50.2`.

| Mode | PC-1 services | PC-2 services | Start order | Verify commands | Notes / warnings |
| --- | --- | --- | --- | --- | --- |
| Coding mode | Gateway `:8100`, llama-server `:8000`, Continue.dev | Memory API `:8101`, Embed Worker `:8102`, Postgres `:5432`, Qdrant `:6333/:6334` if memory is needed | PC-2 first, then PC-1 Gateway, then PC-1 llama-server, then Continue | PC-1 checks PC-2 health, then PC-1 checks Gateway and models | Normal daily mode. Gateway-Auto points Continue to `http://localhost:8100/v1`. |
| Review/debug mode | Gateway `:8100`, optional llama-server `:8000` | Optional support services depending on bug | Start only the service being debugged plus dependencies | PC-1 checks Gateway logs and route health; PC-2 checks support service health | Rebuild only the changed container. Do not restart everything blindly. |
| Memory/database mode | Gateway optional, llama-server optional | Memory API, Embed Worker, Postgres, Qdrant | PC-2 database/vector services first, then Memory API and Embed Worker | PC-1 checks `192.168.50.2:8101`, `8102`, and `6333` | Use this when validating memory, embeddings, or storage. |
| Image generation mode | Image/ComfyUI readiness tools, optional media services; llama-server may need to be stopped manually for VRAM | Usually optional unless media pipeline needs storage/services | PC-1 GPU/VRAM checks first, then manually decide whether to stop llama-server, then image readiness checks | PC-1 checks `nvidia-smi`, llama-server process, Docker, and model files | Do not auto-stop llama-server. No real generation in this checklist. |
| Video/3D/media mode placeholder | Future media services and GPU tools | Optional worker/storage services | Future milestone | Use image/media docs and readiness checks only | Placeholder until media runbooks mature. |
| Backup mode | Source repo, model backup folder, runtime folder; services may stay running for file backup | PC-2 repo and optional database/vector services | Verify backup target, then PC-1 backup, then PC-2 SSH backup, then DB dump if needed | Use [14 Backup Restore Drill](14-backup-restore-drill.md) | Do not prune volumes. Do not restore over live repo. |
| Restore/new-machine mode | Fresh repo, restored configs, restored models, rebuilt Docker, manual llama-server | Fresh repo, restored configs/data, rebuilt support services | Repo first, configs/secrets, models, Docker, DB/vector data, llama-server, Gateway, Continue | Use [15 Disaster Recovery Card](15-disaster-recovery-card.md) | Restore into test folders first when possible. |
| Troubleshooting mode | Only services needed for the failing symptom | Only services needed for the failing symptom | Identify failed check, inspect one layer, then act | Use [07 Troubleshooting](07-troubleshooting.md) | Do not restart all services until you know which layer failed. |

## Coding Mode Checks

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-2 network, Memory API, Embed Worker, and Qdrant respond.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good sign: Gateway and both model endpoints return JSON.

## Memory/Database Mode Checks

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
curl -fsS http://127.0.0.1:8101/health | jq .
curl -fsS http://127.0.0.1:8102/health | jq .
curl -fsS http://127.0.0.1:6333/readyz
```

Expected good sign: PC-2 support containers are running and local health checks pass.

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-1 can reach PC-2 support services over the wired link.

## Image Generation Mode Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
docker ps
make image-readiness
```

Expected good sign: GPU status is visible, the operator knows whether llama-server is running, Docker state is known, and image readiness prints its guided checks.

## Backup Mode Checks

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
test -d /media/cuneyt/Backup/MoE-Drill
```

Expected good sign: repo status is understood and the backup root exists before running the drill.

Read [14-backup-restore-drill.md](14-backup-restore-drill.md) before running backup commands.
