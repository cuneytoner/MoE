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

## Model IDs

- `qwen-coder-14b-fast`: fast coding assistant
- `qwen-coder-32b-main`: main coding brain
- `deepseek-coder-lite`: coding alternative
- `gemma-3-27b-general`: general reasoning
- `qwen-35b-a3b-reasoning`: reasoning / MoE candidate

## Client Integration

Tools that accept an OpenAI-compatible API base URL can point at:

`http://localhost:8000/v1`

This includes local clients such as Continue, Codex-compatible tooling, OpenWebUI, and AnythingLLM when configured for an OpenAI-compatible endpoint.

The Gateway API is not implemented in this milestone. Clients connect directly to the model runtime endpoint for now.
