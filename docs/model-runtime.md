# Model Runtime

Milestone 11 adds a host-based llama.cpp runtime layer for OpenAI-compatible serving.

The runtime is managed by source-controlled scripts, but the server process, logs, pid files, and model files stay outside the codebase.

## Runtime Shape

- Server: `/home/cuneyt/Apps/llama.cpp/build/bin/llama-server`
- Model backup path: `/home/cuneyt/MoE_Models_Backup`
- Model archive path: `/media/cuneyt/Disk2TB/model_backup/MoE_Models_Archive`
- Default host: `0.0.0.0`
- Default port: `8000`
- OpenAI-compatible base URL: `http://localhost:8000/v1`
- Logs: `/home/cuneyt/MoE/runtime/logs/llama-server.log`
- Pid file: `/home/cuneyt/MoE/runtime/pids/llama-server.pid`

Model files are referenced from `configs/models.yaml`. The source-only registry example lives at `configs/model-registry.example.yaml`. They are never copied into this repository.

`make check-models` only fails for active required models and active required media assets. Archived models are documented in `configs/models.yaml` under `archived_models` with `archive_path`, but they are not required to exist under `/home/cuneyt/MoE_Models_Backup`.

See `docs/models.md` for the model registry and inventory workflow.

Runtime defaults live in `configs/runtime.yaml`. Environment variables in `.env.example` document the common overrides.

Advisory Gateway model routing lives in `configs/model-routing.yaml`. It maps intents such as `code`, `review`, and `ops` to model target names and runtime model ids. Gateway reports these mappings, but it does not hot-switch llama.cpp models yet.

## Commands

Prepare runtime folders:

```bash
make runtime-prepare
```

Start the default model:

```bash
make model-start
```

Start a specific model:

```bash
make model-start MODEL=qwen-coder-14b-fast
```

Stop the runtime:

```bash
make model-stop
```

Show pid, endpoint, and model status:

```bash
make model-status
```

Check the OpenAI-compatible `/v1/models` endpoint:

```bash
make model-health
```

Run the Gateway chat proxy smoke test:

```bash
make test-openai-compatible-gateway
make test-gateway-chat-proxy
```

Switch the host runtime manually:

```bash
make model-switch MODEL=qwen-coder-14b-fast
make model-switch MODEL=deepseek-coder-lite
make model-switch MODEL=qwen-coder-32b-main
```

`model-runtime-switch.sh` validates the selected model id, verifies the model file exists, checks the GGUF magic bytes, stops the current host `llama-server`, starts the selected model, then waits for `/v1/models` health. If health fails, it prints runtime status and the last 120 runtime log lines.

Gateway never executes this script and never runs host shell commands from inside the container. Gateway only reports switch plans and manual commands.

## Runtime Readiness

Large GGUF models can take several seconds to load after the `llama-server` process starts. A pid file only means the host process exists; the runtime is not ready for clients until the OpenAI-compatible endpoint answers `/v1/models` with valid JSON.

`make model-health` waits for `/v1/models` for up to 60 seconds by default. Override the wait when testing slower models:

```bash
MODEL_RUNTIME_HEALTH_TIMEOUT=120 make model-health
```

`make model-switch MODEL=...` uses the same health retry after starting the selected model. If readiness fails, it prints status details and the last 120 runtime log lines.

`make model-status` reports pid state, endpoint readiness, the selected model when metadata is available, and the runtime log path. If the pid exists but `/v1/models` is not reachable yet, status reports `process exists but endpoint unavailable`.

Troubleshooting commands:

```bash
ps -fp $(cat ~/MoE/runtime/pids/llama-server.pid)
```

```bash
ss -ltnp | grep ':8000'
```

```bash
curl http://localhost:8000/v1/models
```

## Model IDs

Active required GGUF runtime models:

- `qwen-coder-14b-fast`: fast coding assistant
- `qwen-coder-32b-main`: main coding brain
- `deepseek-coder-lite`: coding alternative

Active required embedding and media assets:

- `bge-m3`: embedding model directory under `/home/cuneyt/MoE_Models_Backup/bge-m3`
- `flux-schnell-main`: `/home/cuneyt/MoE_Models_Backup/flux/flux1-schnell.safetensors`
- `flux-schnell-clip-l`: `/home/cuneyt/MoE_Models_Backup/clip/clip_l.safetensors`
- `flux-schnell-t5xxl`: `/home/cuneyt/MoE_Models_Backup/clip/t5xxl_fp8_e4m3fn.safetensors`
- `flux-schnell-ae`: `/home/cuneyt/MoE_Models_Backup/vae/ae.safetensors`

Archived optional models:

- `gemma-3-27b-general`
- `qwen-35b-a3b-reasoning`
- `qwen-coder-32b-q4-k-m-duplicate`
- `deepseek-coder-lite-q8-archive`
- `cogvideox-5b-i2v-gguf`
- `cogvideox-5b-i2v-safetensors`
- archived checkpoint duplicates

Archived entries live under `/media/cuneyt/Disk2TB/model_backup/MoE_Models_Archive` and are not required by default checks.

Current Gateway advisory targets:

- `chat`, `code`, `memory`: `qwen-coder-14b-fast`
- `review`: `qwen-coder-32b-main`
- `ops`: `deepseek-coder-lite`

Gateway-driven hot switching between these models is a future milestone. Start or switch the desired model manually with the host runtime scripts.

The M28.1 Gateway chat proxy uses `LLAMA_SERVER_BASE_URL` with default `http://host.docker.internal:8000` and forwards to `/v1/chat/completions`. It supports non-streaming requests only and returns a graceful unavailable response when llama-server cannot be reached.

M28.2 adds advisory model routing metadata to `/gateway/chat`. The router may recommend `qwen-coder-14b-fast`, `qwen-coder-32b-main`, or `deepseek-coder-lite`, but it never starts, stops, restarts, or switches the active `llama-server` model. `active_model_matches=false` is expected when the advisory model differs from the currently loaded runtime model.

M29.12 keeps Gateway-Auto advisory-only while making mismatch metadata clearer for Continue/OpenAI clients. Gateway reports `active_model_mismatch_level`, `active_model_mismatch_reason`, `effective_runtime_model`, and safe `next_steps`; it does not switch models automatically. Future real runtime switching would require a separate guarded milestone.

M29.13 hardens `/gateway/runtime/switch-plan` as a planning-only guardrail. The endpoint returns safety guardrails, human preflight checks, and natural-language next steps, not executable command fields. Gateway still never switches runtime models automatically; real runtime switching would require a later guarded milestone and human operation.

M29.14 links runtime switch planning to `docs/gateway-runtime-switch-runbook.md`. The runbook reference is documentation only; Gateway still does not switch models, and future guarded switching remains separate future work.

M29.15 adds `GET /gateway/runtime/profile-preflight` and the read-only `runtime_profile_preflight` tool. The preflight checks mapping readiness and local model file presence only; it does not switch models or download missing files. Missing model files are warnings that require review.

M29.16 adds `GET /gateway/runtime/profile-run-catalog` and the read-only `runtime_profile_run_catalog` tool. The catalog exposes runtime profile settings for human review only; it does not execute scripts or switch models. Host runtime scripts remain manual/operator controlled.

M29.17 adds `GET /gateway/runtime/profile-compatibility-matrix` and the read-only `runtime_profile_compatibility_matrix` tool. The matrix is advisory only and uses static PC-1 hardware assumptions; it does not inspect live GPU state, execute scripts, or switch models.

M28.3 exposes Gateway OpenAI-compatible routes at `http://localhost:8100/v1`. Continue.dev should use `apiBase: http://localhost:8100/v1` for normal use. Direct `http://localhost:8000/v1` llama-server access is a troubleshooting fallback only.

M28.4 adds optional Gateway memory injection before forwarding chat to llama-server. `memory="auto"` searches the fixed configured `MEMORY_SEARCH_URL` and injects bounded local memory context only when usable results exist. `memory="off"` disables search. Memory search failures are non-fatal and return metadata while chat continues when llama-server is reachable.

M28.5 adds metadata-only Gateway feedback capture under `/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl`. It stores ratings, tags, ids, router intent, and model metadata, but not full prompts or full responses.

## Registry And Inventory

Validate the source-controlled registry against local active model paths:

```bash
make model-registry-check
```

Generate a read-only inventory report from the active and archive roots:

```bash
make model-inventory
```

The inventory report is generated at `/home/cuneyt/MoE/runtime/reports/models/model-inventory.json`. It is runtime output and must not be copied into this repository.

For safer manual switches, prefer:

```bash
make model-switch MODEL=qwen-coder-14b-fast
```

Current validation notes:

- `deepseek-coder-lite` has been confirmed as a healthy runtime model.
- `qwen-coder-14b-fast` has been freshly replaced and validated. llama.cpp loaded it successfully, `/v1/models` worked, and `/v1/chat/completions` returned `OK`.
- Earlier invalid or truncated Qwen 14B downloads were replaced. Keep using GGUF magic checks before trusting new model files.

Qwen 14B validation metadata:

- `n_params`: `14770033664`
- `size`: `8113872896`
- `n_ctx_train`: `32768`
- `n_embd`: `5120`

## GGUF Troubleshooting

Valid GGUF model files must start with the magic bytes `GGUF`.

If llama.cpp reports:

`invalid magic characters: 'Entr', expected 'GGUF'`

the file is probably not a model file. A common cause is saving a non-GGUF HTTP response or error page with a `.gguf` extension.

Quick checks:

```bash
head -c 4 /home/cuneyt/MoE_Models_Backup/MODEL.gguf
```

```bash
xxd -l 32 /home/cuneyt/MoE_Models_Backup/MODEL.gguf
```

Expected first four bytes:

```text
GGUF
```

Quarantine invalid model files outside the codebase instead of deleting them immediately. Keep model files under `/home/cuneyt/MoE_Models_Backup`, not in this repository.

## Client Integration

Tools that accept an OpenAI-compatible API base URL can point at:

`http://localhost:8000/v1`

This includes local clients such as Continue, Codex-compatible tooling, OpenWebUI, and AnythingLLM when configured for an OpenAI-compatible endpoint.

Gateway API can also proxy chat requests to the model runtime while reporting advisory model mapping metadata.
