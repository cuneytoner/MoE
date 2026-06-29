# Model Runtime

Milestone 11 adds a host-based llama.cpp runtime layer for OpenAI-compatible serving.

The runtime is managed by source-controlled scripts, but the server process, logs, pid files, and model files stay outside the codebase.

## Runtime Shape

- Server: `/home/cuneyt/Apps/llama.cpp/build/bin/llama-server`
- Model backup path: `/home/cuneyt/MoE_Models_Backup`
- Default host: `0.0.0.0`
- Default port: `8000`
- OpenAI-compatible base URL: `http://localhost:8000/v1`
- Logs: `/home/cuneyt/MoE/runtime/logs/llama-server.log`
- Pid file: `/home/cuneyt/MoE/runtime/pids/llama-server.pid`

Model files are referenced from `configs/models.yaml`. They are never copied into this repository.

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

- `qwen-coder-14b-fast`: fast coding assistant
- `qwen-coder-32b-main`: main coding brain
- `deepseek-coder-lite`: coding alternative
- `gemma-3-27b-general`: general reasoning
- `qwen-35b-a3b-reasoning`: reasoning / MoE candidate

Current Gateway advisory targets:

- `chat`, `code`, `memory`: `qwen-coder-14b-fast`
- `review`: `qwen-coder-32b-main`
- `ops`: `deepseek-coder-lite`

Gateway-driven hot switching between these models is a future milestone. Start or switch the desired model manually with the host runtime scripts.

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
