# 17 Mode Startup Recipes

These recipes are copy/paste friendly. They do not add automation; a human operator decides what to run.

## A. Coding Mode Startup

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
curl -fsS http://127.0.0.1:8101/health | jq .
curl -fsS http://127.0.0.1:8102/health | jq .
curl -fsS http://127.0.0.1:6333/readyz
```

Expected good sign: PC-2 support services respond locally.

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-1 can reach PC-2 support services.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
make model-status
make model-start MODEL=qwen-coder-14b-fast
make model-health
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good sign: Gateway, llama-server, and Gateway OpenAI model listing all return good responses.

Continue.dev should use:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

## B. Image Mode Startup Preparation

Image generation may need PC-1 GPU VRAM. llama-server also uses VRAM, so it may need to be stopped manually before real image work. Do not auto-stop anything.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
docker ps
make check-media-layout
make check-image-models
make check-comfyui-layout
make comfyui-vram-status
make image-readiness
```

Expected good sign: the operator can see GPU state, whether llama-server is running, Docker state, media layout readiness, image model candidates, ComfyUI layout, and guided image readiness.

Related docs:

- [18 Image Mode Entry Checklist](18-image-mode-entry-checklist.md)
- [guided-image-generation.md](../guided-image-generation.md)
- [image-generation.md](../image-generation.md)
- [media-lab.md](../media-lab.md)

## C. Return From Image Mode To Coding Mode

If ComfyUI or image services were started manually, verify they are stopped if you need the GPU back for coding.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
docker ps
nvidia-smi
pgrep -af 'llama-server.*--port 8000' || true
make model-start MODEL=qwen-coder-14b-fast
make model-health
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
```

Expected good sign: llama-server is running again, model health succeeds, `/v1/models` returns JSON, and Gateway health returns JSON.

## D. Backup Mode

Backups are manual. Do not prune volumes.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
test -d /media/cuneyt/Backup/MoE-Drill
```

Expected good sign: repo status is understood and the backup root exists.

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
ssh cuneyt@192.168.50.2
```

Expected good sign: PC-1 can reach PC-2 over SSH. Replace `cuneyt` only if the PC-2 username is different.

Then read and follow [14-backup-restore-drill.md](14-backup-restore-drill.md).
