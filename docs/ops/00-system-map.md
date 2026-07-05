# 00 System Map

MoE / AI-Brain-OS is a local two-machine-friendly setup. PC-1 is the operator machine. PC-2 is the worker/support machine.

## Machines

| Machine | IP | Role | Runs |
| --- | --- | --- | --- |
| PC-1 | `192.168.50.1` | Operator/inference | Continue, Gateway `:8100`, llama-server `:8000` |
| PC-2 | `192.168.50.2` | Worker/support | Memory API `:8101`, Embed Worker `:8102`, Postgres `:5432`, Qdrant `:6333/:6334` |

## Service Ports

| Port | Service | Usual machine | Purpose |
| --- | --- | --- | --- |
| 8000 | llama-server | PC-1 | OpenAI-compatible local model runtime |
| 8100 | Gateway API | PC-1 | Continue and local Gateway entry point |
| 8101 | Memory API | PC-2 or local Docker stack | Memory add/search service |
| 8102 | Embed Worker | PC-2 or local Docker stack | Embedding service |
| 5432 | Postgres | PC-2 or local Docker stack | Relational data store |
| 6333 | Qdrant HTTP | PC-2 or local Docker stack | Vector database HTTP API |
| 6334 | Qdrant gRPC | PC-2 or local Docker stack | Vector database gRPC |

## A. Local PC-1 Flow

```text
Continue on PC-1
  -> http://localhost:8100/v1
  -> Gateway on PC-1
  -> http://127.0.0.1:8000/v1
  -> llama-server on PC-1
```

Continue should use:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

## B. PC-1 Checking PC-2

```text
PC-1 -> http://192.168.50.2:8101/health -> PC-2 Memory API
PC-1 -> http://192.168.50.2:8102/health -> PC-2 Embed Worker
PC-1 -> http://192.168.50.2:6333/readyz -> PC-2 Qdrant
```

## Safety Contract

Gateway runs on PC-1. It does not start, stop, restart, or switch models automatically. Runtime profile endpoints are read-only and advisory.
