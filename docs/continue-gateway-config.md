# Continue.dev Gateway Config

M28.3 lets Continue.dev talk to Gateway through an OpenAI-compatible base URL:

```text
http://localhost:8100/v1
```

Gateway forwards non-streaming chat requests to the active local llama-server and adds advisory router metadata in `x_gateway_router`. It does not require a real API key, switch models, execute shell commands, control Docker, or read/write files.

## Recommended Config

Use this as the main Continue `config.yaml` shape:

```yaml
name: Main Config
version: 1.0.0
schema: v1
models:
  - name: Gateway-Qwen
    provider: openai
    model: gateway-auto
    apiBase: http://localhost:8100/v1
    apiKey: local
    temperature: 0.2
    contextLength: 16384
defaultModel: Gateway-Qwen
```

`model: gateway-auto` is advisory. Gateway does not treat it as a model path and does not switch the running llama-server model.

## Troubleshooting Fallback

If Gateway is unavailable, Continue can temporarily talk directly to llama-server:

```yaml
models:
  - name: Direct-Llama
    provider: openai
    model: local-runtime
    apiBase: http://localhost:8000/v1
    apiKey: local
```

Prefer Gateway for normal use so requests pass through the same advisory router and compatibility layer.

## Smoke Test

```bash
make test-openai-compatible-gateway
```
