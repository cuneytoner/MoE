# 29 Manual LLM Stop Start Plan

This is a manual-only plan for stopping llama-server before image mode and starting it again when returning to coding mode.

Gateway does not do this for you.

## When To Stop llama-server

Stop llama-server only when:

- you intentionally leave coding mode,
- image/media work needs PC-1 VRAM,
- current coding work is saved,
- and you are ready to start it manually again later.

## When NOT To Stop llama-server

Do not stop llama-server when:

- Continue/Gateway-Auto is actively needed for coding,
- you are only reading docs or running readiness checks,
- you are unsure which process is using VRAM,
- or you do not know how to restart the model runtime.

## Before Stopping

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-status
curl -fsS http://127.0.0.1:8000/v1/models | jq . || true
```

Expected good signs:

- You know whether llama-server is running.
- If it is running, `/v1/models` returns JSON.

## Stop llama-server Manually

This is an operator-run manual action.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-stop
make model-status
pgrep -af 'llama-server.*--port 8000' || true
nvidia-smi
```

Expected good signs:

- `make model-stop` completes.
- `pgrep` no longer shows llama-server on port `8000`.
- `nvidia-smi` shows VRAM freed if llama-server was using GPU memory.

## Verify It Stopped

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8000/v1/models | jq . || true
```

Expected good sign: this no longer returns a model list if llama-server is stopped.

## Image-mode Scripts Use make model-stop

`scripts/image/image-mode-prepare.sh` with `STOP_LLM=1` uses `make model-stop`, then `make model-status`, then a `pgrep` verification check.

Gateway still does not stop llama-server. The operator must explicitly run the guarded path with `APPLY=1 STOP_LLM=1`.

`pkill` is not the normal path.

## Enter Image Mode

After stopping llama-server manually, continue with readiness docs:

- [25-comfyui-flux-startup-checklist.md](25-comfyui-flux-startup-checklist.md)
- [26-comfyui-flux-blockers.md](26-comfyui-flux-blockers.md)
- [27-comfyui-flux-startup-evidence-template.md](27-comfyui-flux-startup-evidence-template.md)

This page still does not include real image generation commands.

## Return To Coding Mode

Use [30-image-mode-return-to-coding.md](30-image-mode-return-to-coding.md) after image/media work.

## Start llama-server Manually

This is an operator-run manual action after image mode.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make model-start MODEL=qwen-coder-14b-fast
make model-health
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good signs:

- `make model-health` succeeds.
- llama-server `/v1/models` returns JSON.
- Gateway `/v1/models` returns JSON.

## Verify Gateway And Continue Again

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gateway-auto","messages":[{"role":"user","content":"Reply with OK."}]}' | jq .
```

Expected good sign: JSON includes an assistant message with `OK` or a short response.

## Troubleshooting

- If `make model-stop` does not stop llama-server, inspect before doing anything stronger.
- If `make model-start` fails, check model files under `~/MoE_Models_Backup/`.
- If Gateway works but Continue does not, verify Continue uses `http://localhost:8100/v1` and `gateway-auto`.

Warnings:

- Do not use `pkill` as the default.
- Do not kill unknown processes.
- Do not delete runtime files.
- Do not remove Docker volumes.
- Gateway does not stop/start llama-server for you.
