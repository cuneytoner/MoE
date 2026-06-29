# Gateway API

Milestone 12 adds `gateway-api` as the single API entry point for local AI stack clients.

This is the first simple gateway. It supports optional memory-augmented chat, but it does not implement the advanced MoE router and does not include Dashboard work.

Gateway can report tool-aware routing metadata and execute a small allowlist of read-only internal HTTP checks. It does not execute shell commands, Docker commands, or host model runtime switches.

## Service

- Name: `gateway-api`
- Port: `8100`
- Health endpoint: `GET /gateway/health`
- Host URL: `http://localhost:8100`

## Dependencies

Inside Docker Compose:

- Memory API: `http://memory-api:8101`
- Embed Worker: `http://embed-worker:8102`
- Model runtime: `http://host.docker.internal:8000/v1`

The model runtime runs on the host through llama.cpp, not in Docker. Compose uses:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

Host examples and clients can use:

`http://localhost:8000/v1`

Current healthy runtime models:

- `qwen-coder-14b-fast`: default advisory target
- `deepseek-coder-lite`: healthy fallback and ops target

## Start

Start Docker services:

```bash
make docker-up
```

Containers may report `health: starting` for a few seconds after a fresh build. The Gateway test script waits up to 30 seconds for `/gateway/health` before failing.

Start the host model runtime when chat/model calls are needed:

```bash
make model-start MODEL=deepseek-coder-lite
```

## Endpoints

### GET /gateway/health

Checks Memory API, Embed Worker, and model runtime best-effort. The Gateway service returns `status: ok` even when the model runtime is not running, with `model_runtime` marked unavailable.

### GET /gateway/models

Proxies the OpenAI-compatible model runtime `/models` endpoint.

```bash
curl -fsS http://localhost:8100/gateway/models | jq
```

If the model runtime is unavailable, this returns a controlled `503` with a clear detail message.

### POST /v1/chat/completions

OpenAI-compatible chat adapter for Continue.dev and similar local clients.

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

Gateway converts the request into the existing router-aware `/gateway/chat` flow:

- last `user` message becomes the Gateway `message`
- `system` messages are combined into the Gateway `system` prompt
- `model: local-gateway` lets Gateway use the currently loaded runtime model
- non-`local-gateway` model values are passed through to the model runtime

Streaming is not supported yet. Requests with `stream: true` return HTTP 400 with a clear JSON error.

This adapter does not edit files, execute shell commands, or switch the model runtime.

### GET /gateway/model-routing

Returns the loaded advisory model routing config:

```bash
curl -fsS http://localhost:8100/gateway/model-routing | jq
```

The config comes from `configs/model-routing.yaml`. It maps router intents to advisory model targets and runtime model ids. It does not restart or hot-switch llama.cpp.

### GET /gateway/tools

Returns the advisory tool catalog:

```bash
curl -fsS http://localhost:8100/gateway/tools | jq
```

Example response:

```json
{
  "status": "ok",
  "tools": {
    "model_chat": {
      "description": "Send a chat completion request to the OpenAI-compatible model runtime.",
      "auto_execution_supported": false,
      "executable": false,
      "read_only": false
    },
    "memory_search": {
      "description": "Search local Memory API for relevant stored context.",
      "auto_execution_supported": false,
      "executable": false,
      "read_only": false
    },
    "gateway_health_check": {
      "description": "Read Gateway dependency health using internal HTTP clients.",
      "auto_execution_supported": false,
      "executable": true,
      "read_only": true
    },
    "memory_deep_health_check": {
      "description": "Read Memory API /health/deep status.",
      "auto_execution_supported": false,
      "executable": true,
      "read_only": true
    },
    "code_context": {
      "description": "Build read-only repo-aware coding context from selected workspace files.",
      "auto_execution_supported": false,
      "executable": true,
      "read_only": true
    },
    "code_ask": {
      "description": "Ask the repo-aware coding assistant using read-only workspace context.",
      "auto_execution_supported": false,
      "executable": true,
      "read_only": true,
      "requires_runtime": true
    },
    "code_patch_plan": {
      "description": "Generate a human-reviewable patch plan without applying changes.",
      "auto_execution_supported": false,
      "executable": true,
      "read_only": true,
      "requires_runtime": true,
      "apply_supported": false
    },
    "code_diff_suggest": {
      "description": "Generate a unified diff suggestion without applying changes.",
      "auto_execution_supported": false,
      "executable": true,
      "read_only": true,
      "requires_runtime": true,
      "apply_supported": false
    },
    "runtime_switch_plan": {
      "description": "Return an advisory manual runtime switch command without executing it.",
      "auto_execution_supported": false,
      "executable": false,
      "read_only": false
    },
    "docker_status_check": {
      "description": "Suggest Docker status checks for the user to run manually.",
      "auto_execution_supported": false,
      "executable": false,
      "read_only": false
    },
    "shell_command_suggestion": {
      "description": "Suggest shell commands for the user to inspect before running.",
      "auto_execution_supported": false,
      "executable": false,
      "read_only": false
    }
  },
  "auto_execution_enabled": false,
  "read_only_execution_enabled": true
}
```

`auto_execution_enabled` is always `false`. `read_only_execution_enabled` means Gateway may execute only tools marked with both `executable: true` and `read_only: true`.

### POST /gateway/tools/execute

Executes a controlled read-only tool from the allowlist.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"tool":"runtime_status_check","arguments":{}}' \
  http://localhost:8100/gateway/tools/execute | jq
```

Executable read-only tools:

- `gateway_health_check`
- `memory_health_check`
- `memory_deep_health_check`
- `embed_worker_health_check`
- `runtime_status_check`
- `model_routing_read`
- `tools_read`

Success response:

```json
{
  "status": "ok",
  "tool": "runtime_status_check",
  "read_only": true,
  "result": {
    "runtime_available": false,
    "model_runtime_url": "http://localhost:8000/v1",
    "loaded_models": [],
    "current_model": null
  }
}
```

Advisory tools are rejected:

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"tool":"shell_command_suggestion","arguments":{}}' \
  http://localhost:8100/gateway/tools/execute | jq
```

```json
{
  "status": "rejected",
  "tool": "shell_command_suggestion",
  "reason": "Tool is advisory only and cannot be executed by Gateway"
}
```

Rejected tools include `shell_command_suggestion`, `docker_status_check`, `runtime_switch_plan`, `model_chat`, `memory_search`, and `none`. Gateway still does not execute shell commands, Docker actions, file writes, model chat, memory search, or runtime switches through this endpoint.

Unknown tools return an error response:

```json
{
  "status": "error",
  "tool": "unknown_tool",
  "reason": "Unknown tool"
}
```

Read-only workspace tools are also available:

- `workspace_status`
- `workspace_tree`
- `workspace_file_read`
- `workspace_search`
- `workspace_context`
- `code_context`
- `code_ask`
- `code_patch_plan`
- `code_diff_suggest`

These tools use the same safety checks as the workspace endpoints below.

### GET /gateway/workspace/status

Returns read-only workspace provider status. Inside Docker, the source code is mounted into Gateway as `/workspace:ro`.

```bash
curl -fsS http://localhost:8100/gateway/workspace/status | jq
```

Example:

```json
{
  "status": "ok",
  "workspace_enabled": true,
  "workspace_root": "/workspace",
  "read_only": true,
  "max_file_bytes": 200000,
  "max_tree_items": 500
}
```

### GET /gateway/workspace/tree

Returns a bounded read-only file tree with workspace-relative paths.

```bash
curl -fsS "http://localhost:8100/gateway/workspace/tree?path=docs&max_items=50" | jq
```

### GET /gateway/workspace/file

Reads one allowed text file.

```bash
curl -fsS "http://localhost:8100/gateway/workspace/file?path=docs/gateway-api.md" | jq
```

Rejected paths return JSON with `status: rejected`, for example when the path escapes `/workspace`, is ignored, is too large, is binary, or has a disallowed extension.

### POST /gateway/workspace/search

Searches allowed text files using pure Python. Gateway does not call shell `grep`.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"query":"gateway","path":"docs","max_results":20}' \
  http://localhost:8100/gateway/workspace/search | jq
```

### POST /gateway/workspace/context

Builds a compact context bundle from selected safe files. This endpoint does not call a model and does not edit files.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"task":"explain gateway routing","paths":["apps/gateway-api/app/main.py","docs/gateway-api.md"],"max_chars":12000}' \
  http://localhost:8100/gateway/workspace/context | jq
```

Workspace safety rules:

- Gateway never writes, edits, deletes, moves, renames, or chmods workspace files.
- Gateway does not execute shell commands for workspace inspection.
- All paths are resolved under `/workspace` and returned as workspace-relative paths.
- Ignored directories include `.git`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`, `node_modules`, `dist`, `build`, `.venv`, `venv`, `models`, `runtime`, `data`, `checkpoints`, and `custom_nodes`.
- Binary files and files larger than `WORKSPACE_MAX_FILE_BYTES` are rejected.

### POST /gateway/code/context

Builds read-only repo-aware coding context. It searches workspace files when `query` is provided, includes explicit `paths`, de-duplicates selected files, applies the same workspace safety rules as `/gateway/workspace/*`, and returns a compact context bundle. It does not call the model runtime and never writes files.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"task":"explain how gateway routing works","query":"gateway routing","paths":[],"max_files":8,"max_chars":20000}' \
  http://localhost:8100/gateway/code/context | jq
```

Example response shape:

```json
{
  "status": "ok",
  "task": "explain how gateway routing works",
  "query": "gateway routing",
  "selected_files": [
    {
      "path": "apps/gateway-api/app/main.py",
      "reason": "Matched query 'gateway routing' at line 1"
    }
  ],
  "context": "Task: explain how gateway routing works\n\n--- apps/gateway-api/app/main.py ---\n...",
  "truncated": false
}
```

Path traversal, ignored directories, binary files, oversized files, and unsupported extensions are safely skipped by the underlying workspace context builder.

### POST /gateway/code/ask

Builds repo context with the same logic as `/gateway/code/context`, then calls the existing router-aware Gateway chat flow with a repo-aware system prompt. It returns the model answer, selected files, route metadata, memory metadata, loaded model id, and truncation status.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"task":"explain how gateway routing works","query":"gateway routing","paths":[],"max_files":8,"max_context_chars":20000,"temperature":0.1,"max_tokens":512,"use_memory":false,"auto_route":true}' \
  http://localhost:8100/gateway/code/ask | jq
```

If the model runtime is unavailable, Gateway returns a controlled JSON response with `status: unavailable` and a reason instead of a server error.

Read-only limitations:

- Gateway does not edit files.
- Gateway does not apply patches.
- Gateway does not execute shell commands.
- Gateway does not switch the model runtime.
- Suggested changes must be descriptive or patch-style suggestions only.

### POST /gateway/code/patch-plan

Builds repo context, asks the model for a human-reviewable patch plan, and returns structured planning fields. It does not write files and does not apply patches.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"task":"Add validation for missing query in workspace search","query":"workspace search","paths":["apps/gateway-api/app/main.py","apps/gateway-api/app/services/workspace.py"],"max_files":8,"max_context_chars":20000,"temperature":0.1,"max_tokens":768}' \
  http://localhost:8100/gateway/code/patch-plan | jq
```

Response fields include `summary`, `affected_files`, `proposed_steps`, `risks`, `tests_to_run`, `selected_files`, and `route`.

If the model runtime is unavailable, Gateway returns `status: unavailable` with selected files and a reason.

### POST /gateway/code/diff-suggest

Builds repo context and asks the model for a unified diff suggestion only. The response always includes `apply_supported: false`. Gateway never applies the diff.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"task":"Add validation for missing query in workspace search","query":"workspace search","paths":["apps/gateway-api/app/main.py","apps/gateway-api/app/services/workspace.py"],"max_files":8,"max_context_chars":20000,"temperature":0.1,"max_tokens":1200}' \
  http://localhost:8100/gateway/code/diff-suggest | jq
```

Response fields include `diff`, `explanation`, `apply_supported: false`, `selected_files`, and `route`.

The user must review any suggested diff and apply it manually outside Gateway. Future patch application, if added, must be approval-gated and implemented in a later milestone.

### GET /gateway/runtime/status

Reports whether the host OpenAI-compatible model runtime is reachable and which model id is currently loaded:

```bash
curl -fsS http://localhost:8100/gateway/runtime/status | jq
```

If the runtime is unavailable, Gateway still returns `status: ok` with `runtime_available: false`.

### POST /gateway/runtime/switch-plan

Returns a safe manual switch plan. Gateway does not execute host commands.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"message":"review this architecture for risks"}' \
  http://localhost:8100/gateway/runtime/switch-plan | jq
```

Example response fields:

```json
{
  "status": "ok",
  "intent": "review",
  "target": "qwen-coder-32b-main",
  "target_runtime_id": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-32B-Instruct-IQ4_XS.gguf",
  "current_runtime_model": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
  "switch_required": true,
  "manual_command": "make model-switch MODEL=qwen-coder-32b-main",
  "reason": "Target model differs from current runtime model"
}
```

Automatic switching is intentionally deferred. Run the returned command manually from the host when you want to switch models.

### POST /gateway/chat

Calls the OpenAI-compatible model runtime `/chat/completions` endpoint.

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"message":"hello","temperature":0.2,"max_tokens":128}' \
  http://localhost:8100/gateway/chat | jq
```

Memory-augmented chat can be enabled per request:

```bash
curl -fsS -H "Content-Type: application/json" -X POST \
  -d '{"message":"What is my current local AI runtime model?","use_memory":true,"memory_limit":5,"temperature":0.2,"max_tokens":128}' \
  http://localhost:8100/gateway/chat | jq
```

When `use_memory` is true, Gateway searches Memory API with the chat message and `memory_limit`. If results are found, Gateway injects a concise system message:

`Use the following local memory only if relevant. If it is not relevant, ignore it.`

The injected context includes only compact memory text, source, and score when available. Gateway does not return the full raw memory payload by default.

If Memory API is unavailable or search fails, Gateway continues chat without memory and returns memory metadata with `status: unavailable`. If memory search succeeds but returns no results, the status is `empty`.

Router-aware chat is enabled by default with `auto_route: true`. Gateway calls the internal deterministic router directly and includes route metadata in the chat response:

```json
{
  "route": {
    "intent": "code",
    "confidence": 0.82,
    "model_target": "qwen-coder-14b-fast",
    "model_target_runtime_id": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
    "model_mapping_status": "mapped",
    "use_memory_recommended": false,
    "reason": "Matched coding/debugging terms",
    "signals": {
      "matched_keywords": ["traceback", "error"],
      "message_length": 31
    },
    "tool_plan": {
      "recommended_tools": ["model_chat"],
      "requires_runtime": true,
      "requires_memory": false,
      "safe_to_auto_run": true,
      "reason": "Coding requests can use the model runtime directly."
    }
  }
}
```

If `auto_route` is false, Gateway skips router-derived system prompt additions and preserves the older chat behavior as much as possible. Explicit `use_memory: true` still works.

When the router intent is `memory`, Gateway automatically enables memory search unless `use_memory` was already true. Other intents do not auto-enable memory yet.

Gateway adds one concise intent-specific system hint when `auto_route` is enabled:

- `chat`: answer naturally and concisely
- `code`: prefer precise, actionable coding help
- `memory`: use local memory only when relevant
- `review`: look for correctness, risks, missing cases, and improvements
- `ops`: prefer terminal-safe commands, verification, and rollback notes

`model_target` is advisory for now. Gateway does not hot-switch llama.cpp models in this milestone. If `model` is provided in the request, that model is sent to the OpenAI-compatible runtime. Otherwise Gateway keeps the current behavior: first model from `/models` when available, then `DEFAULT_MODEL`.

If the advisory target differs from the actual model used, the chat response includes `model_alignment`:

```json
{
  "model_alignment": {
    "target": "qwen-coder-32b-main",
    "target_runtime_id": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-32B-Instruct-IQ4_XS.gguf",
    "actual": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
    "matched": false,
    "reason": "Gateway does not switch runtime models yet"
  }
}
```

This endpoint is optional in default tests because it requires the host model runtime to be running and loaded.

### POST /gateway/route

Returns a deterministic intent-aware route decision. This router does not call an LLM; it uses readable keyword matching and simple confidence scoring.

```json
{
  "status": "ok",
  "intent": "code",
  "confidence": 0.82,
  "model_target": "qwen-coder-14b-fast",
  "model_target_runtime_id": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
  "model_mapping_status": "mapped",
  "use_memory_recommended": false,
  "memory_enabled": false,
  "reason": "Matched coding/debugging terms",
  "signals": {
    "matched_keywords": ["traceback", "error"],
    "message_length": 31
  },
  "tool_plan": {
    "recommended_tools": ["model_chat"],
    "requires_runtime": true,
    "requires_memory": false,
    "safe_to_auto_run": true,
    "reason": "Coding requests can use the model runtime directly."
  }
}
```

Supported intents:

- `chat`: general conversation fallback
- `code`: coding, debugging, implementation, refactors, tests
- `memory`: recall, remember, previous context, memory search
- `review`: code review, architecture, security, performance analysis
- `ops`: Docker, Linux, deployment, runtime, servers, network, logs

Current advisory model targets:

- `chat`: `qwen-coder-14b-fast`
- `code`: `qwen-coder-14b-fast`
- `memory`: `qwen-coder-14b-fast`
- `review`: `qwen-coder-32b-main`
- `ops`: `deepseek-coder-lite`

Tool plans are advisory:

- `chat`: `model_chat`
- `code`: `model_chat`
- `memory`: `memory_search`, `model_chat`
- `review`: `runtime_switch_plan`, `model_chat`
- `ops`: `docker_status_check`, `shell_command_suggestion`, `model_chat`

For `review`, a heavier model may be recommended, but runtime switching remains manual. For `ops`, shell and Docker actions are suggestions only.

Future milestones can add controlled tool execution, but this milestone only reports the plan.

Advanced MoE routing is intentionally left for a future milestone.

## Tests

Default Gateway tests:

```bash
make test-gateway
```

Optional runtime-dependent chat test:

```bash
make model-start MODEL=deepseek-coder-lite
make test-gateway-chat
```

Optional memory-augmented chat test:

```bash
make model-start MODEL=deepseek-coder-lite
make test-gateway-chat-memory
```

Optional router-aware chat test:

```bash
make model-start MODEL=qwen-coder-14b-fast
make test-gateway-chat-router
```

Optional Continue.dev Gateway compatibility test:

```bash
make model-start MODEL=qwen-coder-14b-fast
make test-continue-gateway
```

Default `make test` does not require the host model runtime to be running.
