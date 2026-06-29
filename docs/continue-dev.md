# Continue.dev / VS Code Integration

Milestone 21 connects editor chat workflows to the local MoE stack.

The recommended path is to point Continue.dev at Gateway's OpenAI-compatible adapter:

```text
http://localhost:8100/v1
```

The fallback path is to point Continue.dev directly at the host llama.cpp runtime:

```text
http://localhost:8000/v1
```

## Recommended Gateway Path

Start Docker services:

```bash
make docker-up
```

Start or switch the host model runtime for coding:

```bash
make model-switch MODEL=qwen-coder-14b-fast
```

Use this Continue.dev config template:

```text
configs/continue/config-gateway.yaml.example
```

It defines:

- Provider: `openai`
- Model: `local-gateway`
- API base: `http://localhost:8100/v1`
- API key: `local`

Gateway receives Continue.dev chat requests at:

```text
POST /v1/chat/completions
```

Gateway converts the OpenAI-compatible request into the existing router-aware `/gateway/chat` flow. Runtime model switching remains manual.

## Direct Runtime Fallback

If Gateway is unavailable, Continue.dev can talk directly to llama.cpp:

```text
configs/continue/config-runtime-direct.yaml.example
```

Use Qwen 14B for the normal coding path:

```bash
make model-switch MODEL=qwen-coder-14b-fast
```

Use DeepSeek Coder Lite as the healthy fallback and ops-oriented model:

```bash
make model-switch MODEL=deepseek-coder-lite
```

Use Qwen 32B for heavier review or planning only:

```bash
make model-switch MODEL=qwen-coder-32b-main
```

## Known Limitations

- Gateway does not edit files.
- Workspace access is read-only.
- Gateway does not execute shell commands.
- Gateway does not switch the model runtime.
- Streaming is not supported by the Gateway OpenAI compatibility adapter yet.
- Continue.dev can use Gateway chat now; repo-aware coding agent behavior is a future milestone.

## Smoke Tests

Check Gateway workspace:

```bash
curl -fsS http://localhost:8100/gateway/workspace/status | jq
```

Check routing:

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"message":"fix this python traceback error","use_memory":false}' \
  http://localhost:8100/gateway/route | jq
```

Check Gateway OpenAI-compatible chat:

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{
    "model":"local-gateway",
    "messages":[
      {"role":"system","content":"You are a concise local coding assistant."},
      {"role":"user","content":"Return only the word OK."}
    ],
    "temperature":0.2,
    "max_tokens":16,
    "stream":false
  }' \
  http://localhost:8100/v1/chat/completions | jq
```

Optional Make target:

```bash
make test-continue-gateway
```

This optional test assumes Docker services and the host model runtime are already running.
