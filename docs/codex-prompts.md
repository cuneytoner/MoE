# Codex Prompts

## Project Rule

Always keep this rule in mind:

The codebase is source-only.

Runtime files must go to ~/MoE on each PC.

Never put logs, database data, model files, cache, virtual environments, node_modules, or generated runtime files inside codebase.

## Working Directory

Codex should work inside:

~/DiskD/Projects/MoE/codebase

## Runtime Directories

PC1 runtime:

~/MoE

PC2 runtime:

~/MoE

## Machine Context

PC1:

- IP: 192.168.50.1
- CPU: Ryzen 7 7700X3D
- GPU: RTX 5060 Ti
- RAM: 32 GB
- Role: source owner, main workstation, inference node, deployment controller

PC2:

- IP: 192.168.50.2
- CPU: Ryzen 3 3100
- GPU: GTX 1650
- RAM: 32 GB
- Role: memory services, database services, worker node

Network:

- PC1 and PC2 are connected over Cat5
- SSH user: cuneyt
- Passwordless SSH is expected

## Milestone 1 Prompt

We are rebuilding my MoE / AI-Brain-OS project from scratch.

Working directory:

~/DiskD/Projects/MoE/codebase

Rules:

- This is a source-only monorepo.
- Runtime will be deployed to ~/MoE on PC1 and PC2.
- Do not add runtime data, logs, database volumes, model files, or cache into codebase.
- Create or update only the folder skeleton, docs, Makefile, and validation scripts.
- Do not implement service business logic yet.

Create:

- apps/gateway-api
- apps/memory-api
- apps/embed-worker
- apps/dashboard
- packages/shared
- packages/schemas
- packages/clients
- infra/docker
- infra/postgres
- infra/qdrant
- infra/scripts
- deploy/pc1
- deploy/pc2
- docs
- scripts
- Makefile
- scripts/check-layout.sh

## Milestone 2 Prompt

Implement Docker foundation for the MoE / AI-Brain-OS project.

Rules:

- Keep codebase source-only.
- Runtime data must go under ~/MoE on each PC.
- Do not create database volumes inside codebase.
- Add Docker Compose configuration for PostgreSQL and Qdrant.
- Add environment examples.
- Add Makefile commands for docker-up, docker-down, docker-ps, and health.
- Add documentation explaining where runtime data is stored.

Do not implement application business logic yet.

## Milestone 3 Prompt

Implement the first Memory API skeleton.

Rules:

- Use FastAPI.
- Add /health endpoint.
- Add placeholder /memory/add endpoint.
- Add placeholder /memory/search endpoint.
- Do not connect to real database yet unless explicitly requested.
- Keep code clean and small.
- Add minimal tests if appropriate.
- Keep runtime state out of codebase.

## Milestone 5.1 Prompt Summary

Automate the current manual validation flow without creating runtime data inside the source repository.

Scope:

- Add `scripts/test-memory-api.sh`.
- Add `scripts/test-stack.sh`.
- Add `make test-memory`, `make test-stack`, and `make test`.
- Update milestone documentation to reflect completed milestones through Milestone 5.
- Mark Milestone 5.1 as in progress and Milestone 6 as planned.
- Keep embeddings, semantic search, Gateway API, and Dashboard out of scope.

## Milestone 6 Next Prompt Placeholder

Create the first embed-worker service skeleton.

Expected boundaries:

- Add a small service with `/health`.
- Add a local embedding interface placeholder.
- Do not download models.
- Do not implement heavy embedding inference.
- Prepare future BGE-M3 or sentence-transformers integration.

## Milestone 6 Prompt Summary

Create the Embed Worker skeleton with FastAPI, Uvicorn, Pydantic, and pydantic-settings.

Scope:

- Add `/health`.
- Add `/embed`.
- Use deterministic fake embeddings only.
- Document `EMBEDDING_MODEL_PATH=/home/cuneyt/MoE_Models_Backup/bge-m3`.
- Do not copy, mount, download, or load model files.
- Add Docker Compose service on port `8102`.
- Add `scripts/test-embed-worker.sh` and include it in stack tests.

## Milestone 7 Next Prompt Placeholder

Integrate Memory API with Embed Worker.

Expected boundaries:

- Add an Embed Worker client to Memory API.
- Request embeddings from Embed Worker when adding memory.
- Keep Qdrant writes small and explicit.
- Do not implement full semantic search until the next milestone.

## Milestone 7 Prompt Summary

Connect Memory API to the fake Embed Worker backend and Qdrant.

Scope:

- Add an Embed Worker client to Memory API.
- Call `/embed` during `POST /memory/add`.
- Ensure the Qdrant collection exists.
- Upsert fake vectors into Qdrant.
- Store `vector_id` in PostgreSQL.
- Keep `/memory/search` as a safe placeholder.
- Do not load BGE-M3 or implement real semantic ranking.

## Milestone 8 Next Prompt Placeholder

Prepare the real embedding backend.

Expected boundaries:

- Keep model files outside the codebase.
- Validate configured model paths.
- Preserve the fake backend as fallback.
- Do not download models.
- Do not introduce heavy inference behavior until explicitly requested.

## Milestone 8 Prompt Summary

Prepare Embed Worker backend selection for real embeddings without loading BGE-M3 yet.

Scope:

- Support `EMBEDDING_BACKEND=fake` and `EMBEDDING_BACKEND=bge-m3`.
- Keep fake backend fully functional.
- Add a safe BGE-M3 placeholder.
- Validate configured model path and report whether it exists in `/health`.
- Return HTTP 501 for `/embed` with `bge-m3`.
- Do not add heavy ML dependencies.
- Do not download, copy, or load model files.

## Milestone 9 Next Prompt Placeholder

Implement real BGE-M3 embedding runtime.

Expected boundaries:

- Load the existing local model from `/home/cuneyt/MoE_Models_Backup/bge-m3`.
- Keep model files outside the codebase.
- Add explicit fallback behavior if loading fails.
- Do not download models into the repository.
- Validate vector dimension before integrating with Memory API writes.

## Milestone 9 Prompt Summary

Implement the real BGE-M3 runtime in Embed Worker while keeping fake backend as the default.

Scope:

- Lazy-load the local model from `/home/cuneyt/MoE_Models_Backup/bge-m3`.
- Use local files only.
- Do not download models.
- Do not copy model files into the codebase.
- Cache the model after first load.
- Keep `make test` on the fake backend.
- Add optional `RUN_BGE_M3_TEST=1` validation.

## Milestone 9.1 Prompt Placeholder

Validate local embedding model integrity and runtime visibility before relying on real BGE-M3 embeddings.

Expected boundaries:

- Add a model validation script only.
- Detect Git LFS pointer files.
- Check required model files and approximate directory size.
- Verify Docker mount visibility for `/models/bge-m3`.
- Keep runtime validation optional and outside default `make test`.
- Do not download or copy model files.

## Milestone 9.1 Prompt Summary

Add model integrity and optional runtime validation around the working BGE-M3 backend.

Scope:

- Add `scripts/check-models.sh`.
- Detect Git LFS pointer files.
- Check required model files and approximate directory size.
- Fail if `pytorch_model.bin` looks suspiciously small.
- Add `scripts/test-bge-m3-runtime.sh`.
- Keep BGE-M3 runtime validation optional and outside default `make test`.
- Document the current dimension split: fake `384`, BGE-M3 `1024`.

## Milestone 10 Next Prompt Placeholder

Implement Memory Search with real embeddings.

Expected boundaries:

- Prevent `384` and `1024` dimension mismatch in Qdrant.
- Add collection validation or collection naming separation.
- Embed queries through Embed Worker.
- Query Qdrant and return PostgreSQL metadata.
- Keep the search behavior small and explainable.

## Milestone 10 Prompt Placeholder

Add Memory API search using real embeddings and Qdrant lookup.

Expected boundaries:

- Embed search queries through Embed Worker.
- Query Qdrant for nearest vectors.
- Return simple ranked memory candidates.
- Keep ranking logic understandable and easy to test.
- Avoid broad routing or UI work in this step.

## Milestone 10 Prompt Summary

Implement dimension-aware Memory API add/search with Qdrant.

Scope:

- Resolve Qdrant collection names from Embed Worker `backend` and `embedding_dim`.
- Use `moe_memories_fake_384` for fake vectors.
- Use `moe_memories_bge_m3_1024` for BGE-M3 vectors.
- Validate existing Qdrant collection vector size before reuse.
- Implement `/memory/search` by embedding the query and searching the matching collection.
- Store and return collection, backend, and dimension metadata.
- Keep fake as the default backend and keep BGE-M3 optional.
- Do not implement Gateway API or Dashboard.

## Milestone 11 Prompt Placeholder

Add a local model runtime and OpenAI-compatible serving layer.

Expected boundaries:

- Prepare llama.cpp or a similar local model server.
- Expose an OpenAI-compatible endpoint.
- Keep model files outside the codebase.
- Avoid bundling chat UI and gateway work into the same task.

## Milestone 11 Prompt Summary

Add host-based llama.cpp model runtime management.

Scope:

- Add source-only model and runtime config files.
- Manage `/home/cuneyt/Apps/llama.cpp/build/bin/llama-server` from host scripts.
- Start the default model on `0.0.0.0:8000`.
- Expose OpenAI-compatible base URL `http://localhost:8000/v1`.
- Keep GGUF model files in `/home/cuneyt/MoE_Models_Backup`.
- Store logs and pid files under `/home/cuneyt/MoE/runtime`.
- Add `make model-start`, `make model-stop`, `make model-status`, and `make model-health`.
- Do not implement Gateway API or Dashboard in this milestone.

## Milestone 11.1 Prompt Placeholder

Add backup, restore, and disaster recovery planning.

Expected boundaries:

- Document what to back up and what to exclude.
- Cover source, runtime data, Docker state, PostgreSQL, Qdrant, model backups, llama.cpp, environment templates, and docs.
- Keep pid files out of backups and make logs optional.
- Add model checksum manifest strategy.
- Add new PC restore and disaster recovery checklist.
- Do not implement actual backup scripts yet.

## Milestone 11.2 Prompt Placeholder

Add hardware role profiles and environment reassignment planning.

Expected boundaries:

- Add PC1, PC2, single-machine, and new-machine example/template profiles.
- Document role reassignment for model runtime, Memory API, PostgreSQL, Qdrant, Dashboard, Gateway, and research workers.
- Document IP, path, and default model selection updates.
- Keep real local profile files out of the repository.

## Milestone 12 Gateway API Placeholder

Add a central Gateway API after the model runtime is stable.

Expected boundaries:

- Route chat/model requests to the local OpenAI-compatible runtime.
- Expose model discovery and health aggregation.
- Keep Memory API and Embed Worker as separate internal services.
- Do not bundle Dashboard implementation into this milestone.

## Milestone 12 Prompt Summary

Add the first Gateway API service.

Scope:

- Create `apps/gateway-api` as a FastAPI service on port `8100`.
- Add `/gateway/health`, `/gateway/models`, `/gateway/chat`, and `/gateway/route`.
- Use Memory API, Embed Worker, and the host llama.cpp OpenAI-compatible runtime as dependencies.
- Use `host.docker.internal:8000/v1` from Docker and `localhost:8000/v1` for host docs.
- Keep `deepseek-coder-lite` as the current healthy default model.
- Keep `/gateway/chat` out of default tests because it requires the host model runtime.
- Do not implement advanced MoE routing or Dashboard.

## Milestone 13 Prompt Summary

Add optional memory-augmented Gateway chat.

Scope:

- Extend `/gateway/chat` with `use_memory` and `memory_limit`.
- Search Memory API when memory is requested.
- Inject concise memory context into the system prompt only when relevant results exist.
- Continue without memory when Memory API is unavailable.
- Return compact memory metadata in the Gateway chat response.
- Keep memory-chat tests optional because they require model runtime and Memory API.
- Do not implement Dashboard or advanced MoE routing.

## Milestone 14 Prompt Placeholder

Add simple Gateway router and intent-aware routing.

Expected boundaries:

- Extend `/gateway/route` beyond the current placeholder.
- Add simple intent classification for chat and memory-oriented requests.
- Keep model runtime, Memory API, and Embed Worker contracts stable.
- Do not implement Dashboard in this milestone.

## Milestone 14 Prompt Summary

Replace placeholder Gateway routing with deterministic intent-aware routing.

Scope:

- Add a small router service with keyword-based scoring.
- Detect `chat`, `code`, `memory`, `review`, and `ops` intents.
- Return confidence, matched keyword signals, reason, model target, and memory recommendation.
- Keep router deterministic with no LLM call.
- Keep default tests independent from model runtime.
- Do not implement Dashboard or advanced MoE routing.

## Milestone 15 Prompt Placeholder

Add router-aware chat or tool-aware routing.

Expected boundaries:

- Use `/gateway/route` decisions to shape chat behavior.
- Keep tool calls explicit and simple.
- Preserve existing Gateway chat and memory contracts.
- Do not implement advanced MoE routing or Dashboard.

## Milestone 15 Prompt Summary

Make Gateway chat router-aware.

Scope:

- Add `auto_route` to `/gateway/chat`, defaulting to true.
- Reuse the internal router service directly, without HTTP calls to `/gateway/route`.
- Include route metadata in chat responses.
- Auto-enable memory search for memory intent.
- Add concise intent-specific system prompt guidance.
- Keep actual llama.cpp model switching out of scope.
- Keep default tests independent from model runtime.

## Milestone 16 Prompt Placeholder

Add model mapping, runtime profiles, or simple tool-aware routing.

Expected boundaries:

- Use router intent metadata to choose advisory model/runtime profiles or tools.
- Keep hot switching explicit and observable.
- Preserve current Gateway fallback behavior.
- Do not implement advanced MoE routing or Dashboard.

## Milestone 16 Prompt Summary

Add explicit model mapping and runtime profile metadata.

Scope:

- Add `configs/model-routing.yaml`.
- Map Gateway route intents to advisory model targets.
- Return `model_target`, `model_target_runtime_id`, and mapping status from route/chat responses.
- Add `/gateway/model-routing`.
- Include model alignment metadata when the actual runtime model differs from the advisory target.
- Do not hot-switch llama.cpp models from Gateway.
- Keep default tests independent from model runtime.

## Milestone 17 Prompt Placeholder

Add runtime model switching or tool-aware routing.

Expected boundaries:

- Decide whether Gateway may request runtime model changes.
- Keep model switching explicit, observable, and reversible.
- Use intent metadata for simple tool-aware routing where appropriate.
- Do not implement advanced MoE routing or Dashboard.

## Milestone 17 Prompt Summary

Add safe runtime switch planning and host-side controls.

Scope:

- Add `scripts/model-runtime-switch.sh`.
- Validate model id, file existence, and GGUF magic before switching.
- Use existing host stop/start/health scripts.
- Add Gateway runtime status endpoint.
- Add Gateway switch-plan endpoint that returns manual commands only.
- Do not let Gateway execute host shell commands.
- Keep automatic switching deferred.

## Milestone 18 Prompt Summary

Add tool-aware routing metadata without automatic tool execution.

Scope:

- Add a Gateway tool planner service.
- Include `tool_plan` in `/gateway/route` and router-aware chat metadata.
- Add `/gateway/tools` with `auto_execution_enabled=false`.
- Keep shell, Docker, and runtime-switch actions advisory only.
- Do not implement Dashboard or advanced MoE routing.

## Milestone 19 Prompt Placeholder

Add controlled tool execution or Dashboard.

Expected boundaries:

- Keep tool execution gated, explicit, observable, and reversible.
- Do not let Gateway execute host shell commands without a deliberate control model.
- Preserve source-only repository and runtime data boundaries.
- Avoid advanced MoE routing until tool safety is proven.

## Milestone 23 Prompt Placeholder

Add an automation layer for local workflows.

Expected boundaries:

- Prepare n8n or a similar automation service.
- Connect it to local APIs with explicit credentials and URLs.
- Keep automation state outside the source repository.
- Avoid mixing this work with dashboard or homelab ops changes.

## Milestone 24 Prompt Placeholder

Add homelab operations support for the local AI stack.

Expected boundaries:

- Document and prepare Tailscale-style remote access.
- Add container management planning such as Portainer or Arcane.
- Keep security and operational visibility explicit.
- Avoid changing application business logic in this step.

## Safe Codex Task Boundary

Codex should work in small tasks.

Good task:

- Create the folder structure.
- Add one FastAPI health endpoint.
- Add one Docker Compose service.
- Add one Makefile command.
- Add one test file.

Bad task:

- Build the whole system at once.
- Rewrite all files without asking.
- Add runtime data into codebase.
- Download models into the repository.
- Create hidden caches inside the repository.

## Review Checklist

Before accepting Codex changes, check:

- git status
- make check-layout
- no .env committed
- no venv committed
- no node_modules committed
- no logs committed
- no data folder committed
- no models or checkpoints committed
- no runtime state inside codebase
