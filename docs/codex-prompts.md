# Codex Prompts

## Codex New Chat Startup

Primary rules live in `AGENTS.md`. The reusable startup prompt is also documented in `docs/codex-startup-prompt.md`.

```text
I am working in ~/DiskD/Projects/MoE/codebase on the local MoE / AI-Brain-OS project. First read AGENTS.md and the relevant docs/milestones.md, docs/architecture.md, and docs/codex-prompts.md sections. Respect source-only repo rules: runtime data stays in ~/MoE/runtime, models stay in ~/MoE_Models_Backup, no real .env files, no model downloads, no commits unless explicitly asked. Keep changes milestone-scoped. After changes, show changed files and exact verification commands.
```

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

## Milestone 19 Prompt Summary

Add controlled read-only tool execution.

Scope:

- Add `/gateway/tools/execute`.
- Execute only allowlisted read-only internal HTTP/status checks.
- Reject shell, Docker, model chat, memory search, `none`, and runtime-switch advisory tools.
- Keep automatic execution disabled globally.
- Do not add workspace file reading or file writes.
- Preserve source-only repository and runtime data boundaries.
- Avoid advanced MoE routing until tool safety is proven.

## Milestone 20 Prompt Summary

Add local coding workspace integration.

Scope:

- Add read-only workspace context provider.
- Add workspace status, tree, file read, search, and context endpoints.
- Mount the source code into Gateway as `/workspace:ro`.
- Add read-only workspace tools.
- Keep file writes disabled.
- Do not execute shell commands from Gateway.
- Preserve source-only repository and runtime data boundaries.

## Milestone 21 Prompt Summary

Add Continue.dev / VS Code Gateway integration.

Scope:

- Add Gateway OpenAI-compatible `/v1/chat/completions` adapter.
- Point Continue.dev to Gateway or the model runtime.
- Add coding model profile templates.
- Document editor usage as a local coding assistant.
- Preserve Continue-style prior chat turns as Gateway conversation context.
- Keep streaming unsupported unless explicitly implemented later.
- Do not copy editor runtime state into the codebase.

## Milestone 22 Prompt Summary

Add a read-only repo-aware coding agent.

Scope:

- Add `/gateway/code/context` to search workspace files, include explicit paths, de-duplicate selected files, and build compact context.
- Add `/gateway/code/ask` to build repo context and call the existing router-aware Gateway chat flow.
- Return selected files, route metadata, memory metadata, model id, and truncation status.
- Add read-only tool catalog entries for `code_context` and `code_ask`.
- Keep default tests independent from model runtime.
- Do not write files.
- Do not apply patches.
- Do not execute shell commands.
- Do not switch model runtime from Gateway.


## Milestone 23 Prompt Summary

Add safe patch/diff suggestion workflow.

Scope:

- Add `/gateway/code/patch-plan` to build repo context and ask for a structured patch plan.
- Add `/gateway/code/diff-suggest` to build repo context and ask for a unified diff suggestion.
- Return selected files and route metadata.
- Add read-only tool catalog entries for `code_patch_plan` and `code_diff_suggest`.
- Set `apply_supported=false`.
- Keep default tests independent from model runtime.
- Generate suggestions only.
- Do not auto-apply changes.
- Do not write, edit, delete, move, rename, chmod, or apply patches from Gateway.
- Keep manual review explicit.

## Milestone 23.5 Prompt Summary

Add PC-2 worker node preparation.

Scope:

- Prepare PC-2 as a background worker node before Nightly Learning.
- Keep PC-1 as the interactive coding, model runtime, Dashboard, workspace, and media GPU node.
- Plan PC-2 roles for memory/vector services, learning jobs, research ingestion, reports, backups, maintenance, and telemetry.
- Add source-only PC-2 environment profile examples.
- Add source-only PC-2 deploy examples with Docker Compose profiles.
- Add optional read-only PC-2 connectivity and layout checks.
- Do not run heavy LLM inference on PC-2 by default.
- Keep PC-2 runtime data outside the codebase.
- Do not SSH into PC-2 unless explicitly asked to run the optional checks.
- Do not deploy, start, stop, or restart PC-2 services.
- Keep default tests independent from PC-2 availability.

## Milestone 24 Prompt Summary

Add the first Nightly Learning Worker skeleton.

Scope:

- Create `apps/nightly-learning-worker` as a FastAPI service on port `8200`.
- Add `/health`, `/nightly/run`, and `/nightly/latest`.
- Support `dry_run` only and reject other modes.
- Read bounded metadata from the configured read-only source root.
- Write JSON reports only under `NIGHTLY_REPORTS_DIR`.
- Keep `store_lessons=false` by default and make Memory API lesson storage optional.
- Do not modify source files, apply patches, execute shell commands, control Docker, control PC-2, or switch model runtime.
- Keep PC-2 deployment as an explicit future activation step behind the `learning` profile.

## Milestone 24.0.1 Prompt Summary

Prepare safe PC-2 activation for the Nightly Learning Worker.

Scope:

- Add explicit PC-1 helper scripts for source sync, PC-2 worker start, stop, health, and dry-run checks.
- Use `rsync` from PC-1 to `/home/cuneyt/MoE/codebase` on PC-2 without remote deletion.
- Exclude source-control metadata, caches, virtualenvs, build outputs, runtime data, models, data folders, checkpoints, and `custom_nodes`.
- Start only `nightly-learning-worker` through the PC-2 Docker Compose `learning` profile.
- Mount PC-2 source read-only at `/workspace`.
- Mount reports at `/home/cuneyt/MoE/runtime/reports/nightly`.
- Keep dry-run payload at `store_lessons=false` by default.
- Reference PC-1 Gateway and Memory API through `192.168.50.1`.
- Do not include PC-2 checks, sync, Docker, or worker availability in default `make test`.
- Do not start research ingestion, memory migration services, model runtime, Gateway, or Dashboard on PC-2.

## Milestone 24.1 Prompt Summary

Add the first Research Ingestion Worker skeleton.

Scope:

- Create `apps/research-ingestion-worker` as a FastAPI service on port `8210`.
- Add `/health`, `/research/run`, and `/research/latest`.
- Support `dry_run` only and reject other modes.
- Load approved sources from `configs/research-sources.example.yaml`.
- Process only `local_markdown` and `local_text` metadata inside `RESEARCH_SOURCE_ROOT`.
- Skip `url` sources with `remote fetch not implemented`.
- Reject paths outside the source root and ignore hidden/runtime/model/cache directories.
- Write JSON reports only under `RESEARCH_REPORTS_DIR`.
- Keep `store_findings=false` by default and make Memory API storage optional.
- Do not fetch arbitrary URLs, crawl the web, modify source files, apply patches, execute shell commands, control Docker, control PC-2, or switch model runtime.
- Keep PC-2 research activation behind explicit helper scripts and the Docker Compose `research` profile.

## Milestone 24.2 Prompt Summary

Add Feedback / Success Memory.

Scope:

- Create `apps/feedback-worker` as a FastAPI service on port `8220`.
- Add `/health`, `/feedback/event`, `/feedback/events`, `/feedback/report`, and `/feedback/latest-report`.
- Store events as JSONL under `FEEDBACK_EVENTS_FILE` inside `FEEDBACK_DATA_DIR`.
- Generate reports only under `FEEDBACK_REPORTS_DIR`.
- Support `dry_run` report mode only.
- Track task type, goal, route intent, model target, actual model, tools, selected files, tests run, outcome, failure reason, notes, and timestamp.
- Keep `store_lessons=false` by default and make Memory API storage optional.
- Do not modify source files, prompt templates, router config, model mappings, Docker, PC-2, or model runtime.
- Keep PC-2 feedback activation behind explicit helper scripts and the Docker Compose `feedback` profile.

## Milestone 24.3 Prompt Summary

Add Prompt and Routing Improvement Reports.

Scope:

- Extend `apps/feedback-worker` with `/improvement/report` and `/improvement/latest-report`.
- Read recent feedback events from runtime JSONL storage.
- Generate deterministic recommendations for router keywords, intent examples, model mapping alignment, prompt templates, tool planning, docs gaps, tests, and common failures.
- Write reports only under `IMPROVEMENT_REPORTS_DIR`.
- Return `apply_supported=false`.
- Support `dry_run` only and reject other modes.
- Keep `store_lessons=false` by default and make Memory API storage optional.
- Do not call model runtime, fetch internet data, modify source files, modify router config, modify prompt templates, modify model mappings, control Docker, control PC-2, or switch model runtime.
- Require human approval before any recommendation becomes a code or config change.

## Milestone 25 Prompt Summary

Add Media Lab Foundation.

Scope:

- Create dry-run-only `apps/media-api` on port `8300`.
- Create dry-run-only `apps/media-worker` on port `8310`.
- Store media jobs as JSON under `MEDIA_JOBS_DIR`.
- Store media dry-run reports under `MEDIA_REPORTS_DIR`.
- Keep media outputs under `/home/cuneyt/MoE/runtime/media`.
- Keep media models under `/home/cuneyt/MoE_Models_Backup`.
- Add placeholder media model and workflow config examples.
- Add optional Docker Compose `media` profile.
- Do not install ComfyUI or Blender.
- Do not download models.
- Do not call GPU generation, model runtime, ComfyUI, Blender, or arbitrary shell commands.
- Do not generate media into the codebase.

## Milestone 26.0 Prompt Summary

Prepare Image Generation Service.

Scope:

- Add image generation placeholders only.
- Add image model inventory check under `/home/cuneyt/MoE_Models_Backup`.
- Add image metadata validation for width, height, steps, seed, engine, and model id.
- Add image dry-run report fields with `generation_performed=false`.
- Keep real generation disabled.
- Do not install ComfyUI, Diffusers, Blender, or execute GPU jobs.
- Do not download or modify model files.

## Milestone 26.1 Prompt Summary

Prepare ComfyUI runtime and Flux Schnell activation plan.

Scope:

- Add optional user-run ComfyUI install/check/start/stop/health scripts.
- Install ComfyUI only under `/home/cuneyt/MoE/runtime/media-engines/comfyui`.
- Use the official ComfyUI repo: `https://github.com/comfy-org/comfyui`.
- Do not download models.
- Plan Flux Schnell components under `/home/cuneyt/MoE_Models_Backup`.
- Link ComfyUI models by symlink only, with dry-run default.
- Bind ComfyUI to `127.0.0.1:8188` by default.
- Keep real generation disabled until Milestone 26.2.

## Milestone 26.1-pre Prompt Summary

Prepare image engine decision and runtime probes.

Scope:

- Recommend ComfyUI as the primary future image engine.
- Defer Diffusers as an alternative for direct Python generation.
- Document planned ComfyUI runtime layout under `/home/cuneyt/MoE/runtime/media-engines/comfyui`.
- Keep model storage under `/home/cuneyt/MoE_Models_Backup`.
- Add read-only model component planning for Flux Schnell and SDXL.
- Add optional ComfyUI layout probe with `CREATE=1` directory creation limited to runtime.
- Document future safety gates: `MEDIA_REAL_GENERATION_ENABLED=false`, `MEDIA_IMAGE_ENGINE=disabled`, `MEDIA_COMFYUI_URL=http://127.0.0.1:8188`, and `MEDIA_ALLOW_GPU_JOBS=false`.
- Do not install ComfyUI, install Blender, download models, modify model files, create symlinks, run image generation, or execute GPU jobs.

## Milestone 26.2 Prompt Placeholder

Add first real image generation.

Expected boundaries:

- Require explicit real generation safety gates.
- Use ComfyUI as the selected image workflow engine.
- Validate Flux Schnell model components before accepting real jobs.
- Use queued jobs and asset tracking.
- Keep outputs under runtime media storage.

## Milestone 26.2 Prompt Summary

Add first guarded real image generation with ComfyUI and Flux Schnell.

Scope:

- Add Flux Schnell download plan/apply scripts that write only to `/home/cuneyt/MoE_Models_Backup`.
- Use `hf download`, not deprecated `huggingface-cli`, and document gated model approval.
- Add Flux model validation for main model, AE/VAE, `clip_l`, and `t5xxl`.
- Link ComfyUI models by symlink only.
- Add VRAM status and ComfyUI Flux smoke checks.
- Add first-image script that requires `APPLY=1`.
- Store generated images under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- Keep PC-2 as prompt/job helper only.
- Do not write generated outputs into the repository.

## Milestone 26.3 Prompt Summary

Add Media API to Prompt Interpreter to ComfyUI bridge.

Scope:

- Keep Media API dry-run jobs enabled by default.
- Reject real jobs unless `MEDIA_REAL_GENERATION_ENABLED=true`.
- Add Media Worker ComfyUI client for health, prompt submit, and output discovery.
- Surface image outputs under `/home/cuneyt/MoE/runtime/media/outputs/images/<job_id>`.
- Add helper scripts for dry-run, real-run, bridge tests, and latest images.
- Keep Prompt Interpreter as optional upstream input.
- Do not let Gateway trigger generation yet.

## Milestone 26.4 Prompt Placeholder

Add Gateway-to-Media guarded integration.

Expected boundaries:

- Gateway may plan or request media jobs only through explicit guarded endpoints.
- Real generation remains approval-gated.
- No arbitrary shell execution.
- Keep generated media under runtime media outputs.

## Milestone 26.4 Prompt Summary

Add guarded Gateway media integration.

Scope:

- Add `/gateway/media/health`, `/gateway/media/plan`, `/gateway/media/jobs/dry-run`, `/gateway/media/jobs/real`, and `/gateway/media/jobs/{job_id}`.
- Use PC-2 Prompt Interpreter when reachable.
- Fall back to local deterministic classification when Prompt Interpreter is unavailable.
- Create Media API dry-run jobs by default.
- Reject real generation unless `GATEWAY_MEDIA_REAL_ALLOWED=true` and `confirm_real_generation=true`.
- Keep Media API and Media Worker responsible for actual media job storage and processing.
- Do not let Gateway start or stop services, control PC-2, control Docker, start ComfyUI, or execute shell commands.

## Milestone 26.5 Prompt Placeholder

Add simple media dashboard/status UI.

Expected boundaries:

- Show media service health, Gateway media gates, latest jobs, and latest outputs.
- Keep generation controls explicit and guarded.
- Do not create runtime media inside the source repository.

## Milestone 26.5 Prompt Summary

Add a read-only Media Dashboard and runtime status UI.

Scope:

- Add `/gateway/media/dashboard`.
- Add source-only `apps/media-dashboard`.
- Show Gateway, Media API, Media Worker, Prompt Interpreter, Control API, and ComfyUI reachability.
- Show media gates, runtime mode hints, safe command text, and latest image output paths.
- Read latest image metadata from `/home/cuneyt/MoE/runtime/media/outputs` only.
- Do not start or stop services.
- Do not call Docker.
- Do not trigger real generation.
- Do not modify, delete, move, or copy generated media.

## Milestone 26.6 Prompt Placeholder

Add a guided image generation command pack.

Expected boundaries:

- Provide curated terminal command sequences for common image workflows.
- Keep every command explicit and user-run.
- Do not turn the dashboard or Gateway into a service control surface.
- Do not download, modify, or delete model files automatically.

## Milestone 26.6 Prompt Summary

Add a guided image generation lifecycle command pack.

Scope:

- Add `scripts/image/image-readiness.sh`.
- Add `scripts/image/image-dry-run.sh`.
- Add `scripts/image/image-mode-prepare.sh`.
- Add `scripts/image/image-real-run.sh`.
- Add `scripts/image/image-latest.sh`.
- Add `scripts/image/image-safe-shutdown.sh`.
- Add `scripts/image/image-full-cycle.sh`.
- Keep dry-run as the default flow.
- Require `APPLY=1` for real preparation, real generation, and safe shutdown.
- Require `CONFIRM_IMAGE_FULL_CYCLE=1` for full real cycle.
- Do not delete outputs, modify model files, create repo runtime artifacts, or accept arbitrary commands.

## Milestone 26.7 Prompt Placeholder

Add image prompt presets and history.

Expected boundaries:

- Store source-only preset templates.
- Store reviewed prompt history without generated media.
- Keep generated files under runtime media outputs.
- Keep real generation explicit and guarded.

## Milestone 26.8 Prompt Summary

Add a read-only Dashboard UI MVP.

Scope:

- Add `apps/dashboard-ui` with Vite, React, and TypeScript.
- Fetch `/gateway/media/dashboard`.
- Show service health, media health, real generation gates, latest image paths, safe command hints, mode hints, warnings, and PC-1/PC-2 role summary.
- Add Docker Compose dashboard profile and helper scripts.
- Do not start/stop backend services from the UI.
- Do not call Docker from the UI.
- Do not suspend machines from the UI.
- Do not trigger real generation.
- Do not serve generated image bytes in the MVP.

## Milestone 26.8.1 Prompt Summary

Upgrade the Dashboard UI with a Material UI / Minimal Dashboard inspired visual theme.

Scope:

- Add only necessary MUI dependencies: `@mui/material`, `@mui/icons-material`, `@emotion/react`, and `@emotion/styled`.
- Keep Vite, React, and TypeScript.
- Add a dashboard shell with top app bar, sidebar anchors, responsive cards, chips, alerts, lists, and copy-only command blocks.
- Preserve the existing `/gateway/media/dashboard` read-only data source.
- Do not vendor the external template or copy unrelated demo pages/assets.
- Do not add service control, Docker control, suspend controls, shell execution, or real generation triggers.

## Milestone 26.8.2 Prompt Summary

Add read-only Dashboard Runtime Cards.

Scope:

- Add `GET /gateway/runtime/dashboard`.
- Observe PC-1 GPU, llama-server, ComfyUI, PC-2 workers, latest media jobs, and image lifecycle state.
- Use fixed HTTP checks and fixed allowlisted GPU status probing only.
- Read media job JSON files from the runtime jobs directory without mutating them.
- Add Dashboard UI runtime cards for GPU, llama-server, ComfyUI, PC-2 workers, latest job, and image lifecycle.
- Missing ComfyUI, Control API, GPU, llama-server, and PC-2 workers should be warnings, not fatal errors.
- Do not start or stop services, call Docker from UI, SSH into PC-2, execute arbitrary shell, switch models, mutate runtime data, or trigger generation.

## Milestone 26.8.3 Prompt Summary

Add Dashboard System Resource Cards.

Scope:

- Extend `/gateway/runtime/dashboard` with `system.pc1`, `system.pc2`, and `system.docker`.
- Read PC-1 RAM, CPU load, uptime, and root disk usage from Linux read-only files and Python stdlib.
- Do not require `psutil`.
- Keep GPU unavailable non-fatal and report missing `nvidia-smi` as a clear container limitation.
- Keep PC-2 system and Docker summary as graceful unavailable observers unless safe read-only endpoints are added.
- Add Dashboard UI cards for PC1 System, PC2 System, and Docker Summary.
- Do not add dashboard controls, shell execution, Docker control, suspend, service start/stop, or generation triggers.

## Milestone 26.8.4 Prompt Summary

Add PC2 System Status Endpoint.

Scope:

- Add read-only `GET /system/status` to `apps/prompt-interpreter-worker`.
- Use stdlib and Linux read-only files only: `/proc/meminfo`, `/proc/loadavg`, `/proc/uptime`, `os.cpu_count()`, and `shutil.disk_usage("/")`.
- Make Gateway consume the fixed PC-2 Prompt Interpreter URL plus `/system/status`.
- Surface real PC-2 system metrics under `/gateway/runtime/dashboard` as `.system.pc2` when reachable.
- Keep PC-2 system unavailability as a warning.
- Do not use SSH, remote shell commands, Docker socket access, `nvidia-smi`, file mutation, service control, suspend, or generation triggers.

## Milestone 26.8.5 Prompt Summary

Add read-only Docker Summary Snapshot.

Scope:

- Add host-side `scripts/docker-summary-snapshot.sh`.
- Use Docker CLI only in that user-run host script.
- Inspect only fixed allowlisted container names.
- Write JSON to `/home/cuneyt/MoE/runtime/status/docker-summary.json`.
- Make Gateway read that fixed JSON file via `DOCKER_SUMMARY_SNAPSHOT_PATH`.
- Do not mount Docker socket into Gateway.
- Do not let Gateway call Docker, run shell commands, mutate containers, or inspect user-supplied container names.
- Add Dashboard UI Docker Summary counts from the snapshot.

## Milestone 26.9 Prompt Placeholder

Add dashboard guarded actions.

Expected boundaries:

- Actions must be explicit, allowlisted, observable, and gated.
- No arbitrary shell execution.
- No unguarded real generation.
- Keep destructive operations out of scope.

## Milestone 26.5.1 Prompt Summary

Add PC-1 / PC-2 sleep, wake, startup, and status command pack scripts.

Scope:

- Add fixed allowlisted scripts under `scripts/runtime`.
- Support PC-1 local flows, PC-2 local flows, and PC-1 orchestrating PC-2 over SSH.
- Require `APPLY=1` for suspend scripts.
- Support `DRY_RUN=1` for startup/prepare previews where useful.
- Keep real generation disabled by default.
- Do not start ComfyUI external bridge by default.
- Do not delete runtime data, generated media, Docker volumes, images, or model files.
- Do not accept arbitrary user-provided commands.

## Milestone 26.1.5 Prompt Summary

Add Control Plane Dashboard and Runtime Mode Manager.

Scope:

- Add `apps/control-api` on port `8400`.
- Add `configs/runtime-modes.example.yaml`.
- Expose `/health`, `/control/status`, `/control/modes`, `/control/mode/plan`, and `/control/mode/apply`.
- Keep status collection read-only.
- Define `coding`, `image`, `video`, `3d_suite`, and `media_off` modes.
- Document PC-1 as generation host and PC-2 as helper host.
- Keep mode application rejected by default.
- Do not execute arbitrary shell commands.
- Do not start generation or download models.
- Do not let Gateway control PC-2.

## Milestone 26.1.6 Prompt Placeholder

Add Prompt Interpreter Worker on PC-2.

Scope:

- Rule/template-based first version.
- No model required.
- Classify natural language prompts into image, video, 3D model, rigging, animation, 3D suite, or unknown.
- Produce structured dry-run job specs for media workflows.
- Do not execute generation jobs directly.
- Do not call llama-server, ComfyUI, Media API, or model runtime.

## Milestone 26.1.7 Prompt Placeholder

Add optional Mini Model Prompt Interpreter on PC-2.

Expected boundaries:

- Use a small local model only if rule/template interpretation is insufficient.
- Keep heavy generation on PC-1.
- Return structured job specs.
- Keep model files outside the codebase.

## Milestone 27 Prompt Placeholder

Add video generation service.

Expected boundaries:

- Support CogVideoX-style video and image-to-video workflows.
- Use queued jobs.
- Store outputs under runtime media storage.

## Milestone 28 Prompt Placeholder

Add 3D model generation pipeline.

Expected boundaries:

- Start with parametric Blender Python generation.
- Export `.blend`, `.glb`, and `.obj`.
- Support technical structures such as pergola.

## Milestone 29 Prompt Placeholder

Add rigging pipeline.

Expected boundaries:

- Add basic Blender rig and armature planning.
- Start with mechanical and object rigs before character rigs.
- Keep generated files under runtime media storage.

## Milestone 30 Prompt Placeholder

Add animation pipeline.

Expected boundaries:

- Convert text requests into keyframe plans.
- Support Blender camera and object animation.
- Render preview outputs under runtime media storage.

## Milestone 31 Prompt Placeholder

Add media workflow orchestrator.

Expected boundaries:

- Chain image, video, 3D, rig, and animation jobs.
- Add workflow status and asset tracking.
- Keep orchestration state outside the codebase.

## Future Automation Placeholder

Add an automation layer for local workflows.

Expected boundaries:

- Prepare n8n or a similar automation service.
- Connect it to local APIs with explicit credentials and URLs.
- Keep automation state outside the source repository.
- Avoid mixing this work with dashboard or homelab ops changes.

## Future Homelab Ops Placeholder

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

## Milestone 28.1 Gateway Chat Proxy

- Add a safe non-streaming `POST /gateway/chat` proxy for OpenAI-like chat messages.
- Forward to `LLAMA_SERVER_BASE_URL/v1/chat/completions`.
- Keep streaming, complex MoE routing, model switching, shell execution, Docker control, and runtime writes out of M28.1.
- Return `status: unavailable` when llama-server is unreachable.
- Validate with `make test-gateway-chat-proxy`.

## Milestone 28.2 Gateway Chat Advisory Router

- Add deterministic advisory router metadata to `POST /gateway/chat`.
- Support intents `fast_code`, `deep_code`, `review_debug`, `architecture`, and `general`.
- Return selected model id/path, active llama-server model, `active_model_matches`, confidence, mode, and reasons.
- Never start, stop, restart, switch, download, move, or delete models.
- Validate with `make test-gateway-chat-router`.

## Milestone 28.3 Continue Gateway Config

- Add Gateway OpenAI-compatible `GET /v1/models` and `POST /v1/chat/completions`.
- Reuse `/gateway/chat` validation, forwarding, and advisory router metadata.
- Add `docs/continue-gateway-config.md` with Continue.dev `apiBase: http://localhost:8100/v1`.
- Keep streaming unsupported and do not require a real API key.
- Do not start, stop, restart, switch, download, move, or delete models.
- Validate with `make test-openai-compatible-gateway`.

## Milestone 28.4 Gateway Memory Injection

- Add optional search-only memory injection for `/gateway/chat` and `/v1/chat/completions`.
- Support `memory="auto"` and `memory="off"` with `memory_limit` default `3`, max `8`.
- Search only the fixed configured `MEMORY_SEARCH_URL`; never accept memory URLs from user input.
- Inject bounded system context only when usable memory results exist.
- Return `/gateway/chat` memory metadata and OpenAI-compatible `x_gateway_memory`.
- Do not store new memory, log full prompts, expose raw memory metadata, control services, or switch models.
- Validate with `make test-gateway-memory-injection`.

## Milestone 28.5 Gateway Feedback Capture

- Add `POST /gateway/feedback` for allowlisted metadata-only feedback records.
- Add `GET /gateway/feedback/status` with aggregate count/latest timestamp only.
- Write append-only JSONL only under `/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl`.
- Validate rating, source, reason length, tag count/length, and request/response id lengths.
- Do not store full prompt text, full response text, secrets, runtime logs, or generated data in the repo.
- Do not execute shell commands, control Docker, switch models, or change OpenAI chat compatibility.
- Validate with `make test-gateway-feedback`.

## Milestone 28.6 Feedback Worker Bridge

- Extend `apps/feedback-worker` with `GET /feedback/status` and `POST /feedback/summarize`.
- Read Gateway feedback JSONL from `FEEDBACK_JSONL_PATH`, defaulting to `/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl`.
- Write the aggregate summary to `FEEDBACK_SUMMARY_PATH`, defaulting to `/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json`.
- Ignore malformed JSONL lines but count them in the summary.
- Include only aggregate metadata: generated timestamp, source path, record count, malformed count, rating/source/router intent/model counts, top tags, and latest timestamp.
- Do not include full reason text, raw prompt text, raw model response text, full feedback records, learning, training, fine-tuning, model switching, shell execution, Docker control, service control, or automatic memory/model mutation.
- If PC2 cannot directly see PC1 runtime feedback, document manual copy/sync of the JSONL file into PC2 runtime before summarizing.
- Validate with `make feedback-summary-local`, `make test-feedback-worker-bridge`, and existing feedback tests.

## Milestone 28.7 Feedback Sync PC1 to PC2

- Add explicit user-run sync tooling for Gateway feedback from PC1 runtime to PC2 worker runtime.
- Add `scripts/feedback-sync-status.sh`, `scripts/feedback-sync-to-pc2.sh`, and `scripts/test-feedback-sync.sh`.
- Make sync dry-run by default and require `APPLY=1` for SSH directory creation or `rsync` copy.
- Sync only `/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl` and optional `/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json`.
- Do not use deletion flags, copy model files, copy media outputs, copy repository files, or require always-on shared mounts.
- Do not train, fine-tune, mutate memory, modify prompts, change router config, control Docker, switch models, or control services.
- Keep status and tests independent from PC2 availability.
- Validate with `make feedback-sync-status`, `make feedback-sync-to-pc2`, `make test-feedback-sync`, and default source-only tests.

## Milestone 28.8 Reviewed Learning Loop Report

- Add `scripts/learning-loop-report-local.sh` and `scripts/test-learning-loop-report.sh`.
- Read `/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json`.
- Write `/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json`.
- Include aggregate observations and deterministic recommendations based only on rating, source, router intent, model, and tag counts.
- Set `apply_supported=false` and `human_review_required=true`.
- Do not include raw reason text, raw prompt text, raw model response text, or individual feedback records.
- Do not train, fine-tune, mutate memory, modify router config, modify prompt templates, call Memory API, call Gateway, call llama-server, control Docker, switch models, or control services.
- Validate with `make learning-loop-report-local`, `make test-learning-loop-report`, and default source-only tests.

## Milestone 28.9 Human-Approved Improvement Plan

- Add `scripts/improvement-plan-local.sh` and `scripts/test-improvement-plan.sh`.
- Read `/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json`.
- Write `/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json`.
- Include `plan_status=review_required`, `apply_supported=false`, `human_review_required=true`, proposed changes, validation plan, safety boundaries, and next steps.
- Generate patch-plan style recommendations from aggregate learning-loop observations and recommendations only.
- Do not include raw feedback reason text, raw prompt text, raw model response text, or individual feedback records.
- Do not apply changes, mutate memory, modify router config, modify prompt templates, call Memory API, call Gateway, call llama-server, train, fine-tune, download models, switch models, execute shell commands from apps, control Docker, or control services.
- Validate with `make improvement-plan-local`, `make test-improvement-plan`, and default source-only tests.

## Milestone 29.0 Reviewed Improvement Patch Planner

- Add `scripts/improvement-patch-plan-local.sh` and `scripts/test-improvement-patch-plan.sh`.
- Read `/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json`.
- Write `/home/cuneyt/MoE/runtime/reports/patch-plans/reviewed-improvement-patch-plan.json`.
- Include `patch_plan_status=review_required`, `apply_supported=false`, `human_review_required=true`, patch groups, validation plan, safety boundaries, review checklist, and next steps.
- Generate patch-plan style recommendations from `proposed_changes[]` only.
- Do not include raw feedback reason text, raw prompt text, raw model response text, or individual feedback records.
- Do not apply patches, edit target files, mutate memory, modify router config, modify prompt templates, call Memory API, call Gateway, call llama-server, train, fine-tune, download models, switch models, execute shell commands from apps, control Docker, or control services.
- Validate with `make improvement-patch-plan-local`, `make test-improvement-patch-plan`, and default source-only tests.

## Milestone 29.1 Human-Approved Router and Prompt Update Workflow

- Add `scripts/router-prompt-approval-local.sh` and `scripts/test-router-prompt-approval.sh`.
- Read `/home/cuneyt/MoE/runtime/reports/patch-plans/reviewed-improvement-patch-plan.json`.
- Write `/home/cuneyt/MoE/runtime/reports/approvals/router-prompt-update-approval-packet.json`.
- Include `approval_status=pending_human_review`, `apply_supported=false`, `human_review_required=true`, approval items, blocked items, validation plan, safety boundaries, reviewer checklist, and next steps.
- Allow approval items only for router, prompt, docs, tests, and model-routing categories.
- Block memory, ops, unknown, and high-risk items.
- Do not include raw feedback reason text, raw prompt text, raw model response text, or individual feedback records.
- Do not apply patches, edit target files, mutate memory, modify router config, modify prompt templates, call Memory API, call Gateway, call llama-server, train, fine-tune, download models, switch models, execute shell commands from apps, control Docker, or control services.
- Validate with `make router-prompt-approval-local`, `make test-router-prompt-approval`, and default source-only tests.

## Milestone 29.2 Feedback-to-Memory Candidate Review

- Add `scripts/feedback-memory-candidates-local.sh` and `scripts/test-feedback-memory-candidates.sh`.
- Read available aggregate runtime inputs: feedback summary, learning-loop report, human-approved improvement plan, and router/prompt approval packet.
- Write `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json`.
- Include `candidate_status=pending_human_review`, `memory_write_supported=false`, `human_review_required=true`, candidates, rejected or blocked candidates, validation plan, safety boundaries, reviewer checklist, and next steps.
- Generate deterministic memory candidates from aggregate report data only.
- Do not include raw feedback reason text, raw prompt text, raw model response text, individual feedback records, secrets, credentials, or sensitive data.
- Do not write to Memory API, call Memory API, apply generated candidates, mutate memory, modify router config, modify prompt templates, call Gateway, call llama-server, train, fine-tune, download models, switch models, execute shell commands from apps, control Docker, control services, or depend on PC2.
- Validate with `make feedback-memory-candidates-local`, `make test-feedback-memory-candidates`, and default source-only tests.

## Milestone 29.3 Human-Approved Memory Store Workflow

- Add `scripts/memory-store-plan-local.sh`, `scripts/memory-store-approved.sh`, and `scripts/test-memory-store-workflow.sh`.
- Read `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json`.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json`.
- Support optional approval file `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json`.
- Keep the store workflow dry-run by default; only `APPLY=1 make memory-store-approved` may call Memory API.
- Use Memory API `/memory/add` payload shape with `text`, `source`, and `metadata`.
- Store only sanitized approved candidate text. Never store blocked candidates, raw prompts, raw model responses, raw feedback reason bodies, individual feedback records, secrets, credentials, or sensitive data.
- Do not train, fine-tune, mutate router config, modify prompt templates, modify model mappings, switch models, execute shell commands from apps, control Docker, or control services.
- Validate with `make memory-store-plan-local`, `make memory-store-approved`, `make test-memory-store-workflow`, and default source-only tests.

## Milestone 29.4 Memory Store Audit and Candidate Dedup Review

- Add `scripts/memory-store-audit-local.sh` and `scripts/test-memory-store-audit.sh`.
- Read `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json`.
- Optionally read `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json`.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json`.
- Group duplicate candidates by normalized category and title.
- Include counts, duplicate groups, unique groups, approved/blocked/pending summaries, recommendations, validation plan, safety boundaries, reviewer checklist, and next steps.
- Keep `audit_status=review_required`, `memory_write_supported=false`, `apply_supported=false`, and `human_review_required=true`.
- Do not write to Memory API, call Memory API, call Gateway, call llama-server, auto-approve candidates, mutate memory, train, fine-tune, switch models, execute shell commands from apps, control Docker, or depend on PC2.
- Validate with `make memory-store-audit-local`, `make test-memory-store-audit`, `make test-memory-store-workflow`, and default source-only tests.

## Milestone 29.5 Human-Approved Memory Store Apply Log

- Update `scripts/memory-store-approved.sh` to append runtime apply-log JSONL entries around approved candidate store attempts.
- Add `scripts/memory-store-apply-log-status.sh` and `scripts/test-memory-store-apply-log.sh`.
- Write apply log entries to `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-log.jsonl`.
- Write latest summary to `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json`.
- Keep default mode dry-run. Do not log dry-runs unless `LOG_DRY_RUN=1`.
- Never run `APPLY=1` in tests. Only user-run `APPLY=1 make memory-store-approved` may call Memory API.
- Log safe metadata only: no raw prompts, raw model responses, proposed memory text, full API responses, secrets, credentials, or sensitive data.
- Validate with `make memory-store-approved`, `LOG_DRY_RUN=1 make memory-store-approved`, `make memory-store-apply-log-status`, `make test-memory-store-apply-log`, and default source-only tests.

## Milestone 29.6 Memory Candidate Approval File Helper

- Add `scripts/memory-candidate-approval-helper-local.sh`, `scripts/memory-candidate-list-local.sh`, and `scripts/test-memory-candidate-approval-helper.sh`.
- Read memory candidates, memory store plan, and memory store audit from runtime if present.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json`.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json`.
- Never create `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json`.
- Keep `auto_approval_supported=false`, `memory_write_supported=false`, and `human_review_required=true`.
- Do not call Memory API, Gateway, llama-server, Docker, or model runtimes.
- Do not approve candidates automatically, write memories, include raw prompts, include raw responses, include individual feedback records, train, fine-tune, switch models, or commit generated runtime reports.
- Validate with `make memory-candidate-approval-helper-local`, `make memory-candidate-list-local`, `make test-memory-candidate-approval-helper`, and default source-only tests.

## Milestone 29.7 Memory Approval Dry-Run End-to-End Flow

- Add `scripts/memory-approval-dry-run-e2e-local.sh`, `scripts/memory-approval-dry-run-e2e-status.sh`, and `scripts/test-memory-approval-dry-run-e2e.sh`.
- Orchestrate the safe local memory approval workflow: helper, candidate list, plan generation, `LOG_DRY_RUN=1 make memory-store-approved`, apply-log status, and audit.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json`.
- Reject runs where `APPLY=1` is present.
- Allow `USE_TEST_APPROVAL_FIXTURE=1` to create a temporary `test_fixture=true`, `dry_run_only=true` approval file under runtime; remove it by default.
- Never overwrite a non-test real approval file.
- Keep `dry_run_only=true`, `apply_used=false`, `memory_write_supported=false`, and `human_review_required=true`.
- Do not write to Memory API, call Gateway, call llama-server, auto-approve candidates, train, fine-tune, switch models, control Docker, or commit generated runtime reports.
- Validate with `make memory-approval-dry-run-e2e-local`, `USE_TEST_APPROVAL_FIXTURE=1 make memory-approval-dry-run-e2e-local`, `make memory-approval-dry-run-e2e-status`, `make test-memory-approval-dry-run-e2e`, and default source-only tests.

## Milestone 29.8 Memory Approval Dashboard Read-Only View

- Add `GET /gateway/memory-approval/dashboard`.
- Read fixed runtime JSON/JSONL reports only; do not accept arbitrary paths.
- Return report metadata, aggregate summary counts, compact candidate cards, duplicate groups, approval file status, apply-log status, E2E status, warnings, and safety boundaries.
- Keep `read_only=true`, `apply_supported=false`, `approval_supported=false`, `memory_write_supported=false`, and `human_review_required=true`.
- Add a Dashboard UI Memory Approval section using the endpoint.
- Do not add approve/apply/store buttons or write-oriented UI controls.
- Do not call Memory API, Gateway-to-Memory write routes, llama-server, Docker, scripts, model runtimes, or services.
- Do not auto-approve candidates, create approval files, write memories, train, fine-tune, switch models, or expose raw prompts/responses.
- Validate with `make test-memory-approval-dashboard`, M29 memory workflow tests, and default source-only tests.

## Milestone 29.9 Memory Approval Manual Store Runbook

- Add `docs/memory-approval-manual-store-runbook.md`, `scripts/memory-store-manual-preflight.sh`, and `scripts/test-memory-store-manual-preflight.sh`.
- Add `make memory-store-manual-preflight` and `make test-memory-store-manual-preflight`.
- Cross-reference the runbook from the M29 memory store workflow, audit, apply-log, helper, dry-run E2E, dashboard, architecture, README, and milestone docs.
- Keep the runbook dry-run-first and require manual review of approval file, plan, audit, dashboard, and apply-log status before any real write.
- Real writes remain manual only with `APPLY=1 make memory-store-approved`; tests never run `APPLY=1`.
- Do not call Memory API, run `APPLY=1`, approve candidates automatically, create runtime approval files, train, fine-tune, switch models, control Docker, or modify runtime files from tests.
- Validate with `make check-layout`, `make memory-store-manual-preflight`, `make test-memory-store-manual-preflight`, M29 memory approval tests, and default source-only tests.
