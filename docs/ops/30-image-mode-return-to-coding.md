# 30 Image Mode Return To Coding

Use this checklist after image mode to return PC-1 to normal coding mode.

## Goal

- Verify image/media services are understood.
- Start llama-server manually if needed.
- Verify Gateway and Continue.
- Verify PC-2 support services if used.
- Confirm generated media/model files are not staged in Git.

## Step 1: Check Repo And Docker State

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
find . -maxdepth 1 -type f -name '@*' -print
docker ps
```

Expected good signs:

- Git status has no generated images, model files, checkpoints, or secrets.
- No stray `@*` pasted-output files are present.
- Docker state is visible.

## Step 2: Start Or Verify llama-server

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-status
make model-start MODEL=qwen-coder-14b-fast
make model-health
```

Expected good sign: model health succeeds.

## Step 3: Verify Gateway

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good signs:

- Gateway health returns JSON.
- Gateway `/v1/models` returns JSON.

## Step 4: Verify Continue

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gateway-auto","messages":[{"role":"user","content":"Reply with OK."}]}' | jq .
```

Expected good sign: Gateway returns an assistant response.

## Step 5: Verify Memory Services If PC-2 Is Used

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-2 network and support services respond.

## Step 6: Confirm Nothing Unsafe Is Staged

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
```

Expected good sign: no generated images, model files, large checkpoints, real `.env` files, or runtime outputs are staged.

## Do Not Commit

- generated images.
- generated videos.
- model files.
- `.safetensors` files.
- checkpoints.
- runtime logs/reports unless intentionally reviewed.
- real `.env` files.

## If Coding Mode Still Fails

Read:

- [07-troubleshooting.md](07-troubleshooting.md)
- [13-service-location-reference.md](13-service-location-reference.md)
- [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md)
