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
- Optional named profiles for Qwen 14B fast, DeepSeek Lite fallback, and Qwen 32B review

Gateway receives Continue.dev chat requests at:

```text
POST /v1/chat/completions
```

Gateway converts the OpenAI-compatible request into the existing router-aware `/gateway/chat` flow. It keeps system messages and prior user/assistant turns as conversation context, then sends the latest user turn through the Gateway chat path. Runtime model switching remains manual.

M29.11 normalizes Continue stream/tool payloads for compatibility. Continue can point Gateway-Auto style configs at:

```text
http://localhost:8100/v1
```

Gateway accepts `stream: true` and returns a minimal OpenAI-compatible SSE wrapper for Continue, while still using one internal non-streaming model call. This is compatibility streaming, not true token-by-token runtime streaming. It accepts `tools` and `tool_choice` fields but ignores them safely; it does not execute tools from Continue/OpenAI tool payloads.

Use the default `MoE Gateway` profile for normal editor chat. Use a model-specific Gateway profile only after manually switching the host runtime to that model:

```bash
make model-switch MODEL=qwen-coder-14b-fast
```

Gateway reports model alignment metadata, but it does not switch the runtime automatically.

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
- `stream: true` uses a minimal SSE wrapper over the non-streaming Gateway model call.
- Continue/OpenAI tool payloads are accepted for compatibility but never executed.
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
