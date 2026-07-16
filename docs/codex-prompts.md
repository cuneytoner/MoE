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

## Current Media Milestone Status

- M31.5 Generated Image Output Handling / Git Safety DONE
- M31.6 ComfyUI Workflow Inventory DONE
- M31.7 Gateway Real Image Run Drill DONE
- M31.8 Prompt Variants / Batch Image Plan DONE
- M31.9 Media Dashboard Output Review DONE
- M32.0 Controlled Prompt Variant Generation DONE
- M32.1 Media Dashboard UI Output Cards PLANNED
- M32.2 Prompt Variant Result Review DONE
- M32.3 Prompt Quality Improvement Plan DONE
- M32.4 Improved Prompt Controlled Run Result Review DONE
- M32.5 Pergola Project-Specific Prompt Pack DONE
- M32.6 Technical Detail Image Run Result Review DONE
- M32.7 Pergola Image Selection / Reference Board DONE
- M32.8 Real Pergola Technical Drawing Prompt Pack DONE
- M32.9 Pergola Usta Package Plan PLANNED
- M33.0 Technical Drawing Controlled Run DONE
- M33.1 Technical Drawing Controlled Run Result Review DONE
- M33.2 Simplified Technical Drawing Controlled Run Result Review DONE
- M33.3 Geometry-only CAD-style Drawing Run DONE
- M33.4 Deterministic Pergola Drawing Plan DONE
- M33.5 SVG Drawing Tool Skeleton DONE
- M33.6 Side Elevation + Top Plan SVG DONE
- M33.7 Beam-post + Roof Sheet SVG Details PLANNED
- M33.8 PDF Export Plan PLANNED
- M34.0 Generic Image + Architecture Drawing Roadmap DONE
- M34.1 Generic Prompt Pack Structure DONE
- M34.2 Generic Drawing Engine Skeleton DONE
- M34.3 Media Dashboard Output Cards Plan DONE
- M34.4 Prompt Metadata Capture Plan DONE
- M34.5 Output Cards API Implementation DONE
- M34.6 Dashboard Output Cards UI DONE
- M34.7 Metadata Sidecar Implementation DONE
- M34.7.1 Drawing Runtime Volumes Fix DONE
- M34.8 Reference Board Selection Plan DONE
- M34.9 Output Card Preview Serving Plan DONE
- M34.10 Image Generation Metadata Sidecars DONE
- M34.11 Reference Board API Implementation DONE
- M34.12 Reference Board UI Implementation DONE
- M34.12.1 Reference Board UI CORS + Unique Card Keys Fix DONE
- M34.13 Output Preview API Implementation DONE
- M34.14 Dashboard Preview UI Implementation DONE
- M34.15 Output Card Metadata Detail Drawer DONE
- M34.16 Reference Board Safe Runtime Store DONE
- M34.17 Reference Board Item Selection API DONE
- M34.18 Reference Board Output Card Integration BACKLOG
- M34.19 Reference Board Detail View DONE
- M34.20 Reference Board Export Plan DONE
- M34.21 Reference Board Selected Reason Edit DONE
- M34.22 Reference Board Compare View BACKLOG
- M34.23 Reference Board JSON Export Implementation DONE
- M34.24 Reference Board Markdown Export Implementation DONE
- M34.25 Reference Board Export UI DONE
- M34.26 Reference Board Export Download Plan DONE
- M34.27 Reference Board Markdown Download Implementation DONE
- M34.28 Reference Board JSON Download Implementation DONE
- M34.29 Reference Board Download UI DONE
- M34.30 Reference Board Export Regression Review DONE
- M34.31 Reference Board Export Polish DONE
- M34.32 Reference Board Workflow Summary DONE
- M34.33 Reference Board Hardening Plan DONE
- M34.34 Reference Board Error Handling Polish DONE
- M34.35 Reference Board Validation Limits DONE
- M34.36 Reference Board Malformed Store Regression DONE
- M34.37 Reference Board Store Repair Plan DONE
- M34.38 Reference Board Store Backup Plan DONE
- M34.39 Reference Board Store Repair CLI Plan DONE
- M34.40 Reference Board Store Validate CLI Implementation DONE
- M34.41 Reference Board Store Backup CLI Implementation DONE
- M34.42 Reference Board Store Repair CLI Implementation DONE
- M34.43 Reference Board Store Repair Regression DONE
- M34.44 Reference Board Duplicate Item Repair Plan DONE
- M34.45 Reference Board Stale Item Handling Plan DONE
- M34.46 Reference Board Duplicate Item Repair Implementation DONE
- M34.47 Reference Board Duplicate Item Repair Regression DONE
- M34.48 Reference Board Stale Item Marking Implementation DONE
- M34.49 Reference Board Stale Item Regression DONE
- M34.50 Reference Board Repair CLI Operator Runbook DONE
- M34.51 Reference Board Repair CLI Summary Review DONE
- M34.52 Reference Board Export Stale/Duplicate Status Polish DONE
- M34.53 Reference Board Backup Retention Plan DONE
- M34.54 Reference Board Export Review UI Polish DONE
- M35.0 Reference Board Phase Closure and M35 Roadmap DONE
- M35.1 3D / Blender Parametric Pipeline Foundation DONE
- M35.2 Generic Parametric Blender Prototype Plan DONE
- M35.3 Blender Runtime Output Safety Plan DONE
- M35.4 Generic Parametric Blender Script Skeleton DONE
- M35.5 Generic 3D Parameter Config Draft DONE
- M35.6 First Dry-Run Blender Script Review DONE
- M35.7 Guarded First Blender Generation Drill Plan DONE
- M35.8 3D Metadata Sidecar Plan PLANNED

Pergola is now a case study/prototype. Generic media and drawing roadmap begins at M34.

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
- Add Gateway switch-plan endpoint that returns manual planning metadata only.
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

## Milestone 30.0 Prompt: Operator Runbook Pack

Implement the M30.0 Operator Runbook Pack as documentation-only source changes.

Expected boundaries:

- Add `docs/ops/` with beginner-friendly runbooks for system map, fresh install, daily startup, daily shutdown, backup, restore, troubleshooting, command cheatsheet, Git workflow, and runtime profile review.
- Explain PC-1 and PC-2 roles, service ports, Gateway, Continue, llama-server, Memory API, Embed Worker, Postgres, Qdrant, and Docker services.
- Keep commands terminal-first and clearly separate read-only checks from manual start, stop, rebuild, backup, and restore actions.
- Do not add runtime behavior, automatic switching, shell execution, Docker control, Memory API writes, model downloads, or runtime file creation.
- Update layout validation, milestone docs, and docs index references.

M30.0 follow-up hardening:

- Improve the runbooks for true beginner use with exact PC-1 and PC-2 labels, direct-link IPs `192.168.50.1` and `192.168.50.2`, exact repo/model/runtime paths, expected good signs, and PC-1-to-PC-2 health checks.
- Keep all improvements documentation-only.

## Milestone 30.1 Prompt: Operator Runbook Walkthrough QA

Improve the M30.0 Operator Runbook Pack with scenario-based beginner walkthroughs.

Expected boundaries:

- Add `docs/ops/11-first-day-walkthrough.md`, `docs/ops/12-zero-to-running-checklist.md`, and `docs/ops/13-service-location-reference.md`.
- Include exact PC-1 and PC-2 command labels, direct-link IPs, directories, expected good signs, and fallback links.
- Improve troubleshooting to include symptom, likely cause, first check, fallback action, and related doc links.
- Keep changes documentation-only. Do not alter Gateway runtime behavior, application code, Docker Compose behavior, or service execution features.

## Milestone 30.2 Prompt: Backup / Restore Drill Documentation

Add beginner-friendly backup and restore drill documentation for the two-PC MoE system.

Expected boundaries:

- Add `docs/ops/14-backup-restore-drill.md` with a concrete drill using `/media/cuneyt/Backup/MoE-Drill`.
- Add `docs/ops/15-disaster-recovery-card.md` as a one-page emergency card.
- Use exact PC-1, PC-2, PC-1-to-PC-2, and Postgres-container command labels.
- Restore only into a temporary `restore-test` folder. Never restore over live source.
- Warn about `--delete`, large model files, secrets, backups not belonging in Git, and avoiding Docker volume prune.
- Keep changes documentation-only. Do not alter runtime behavior, app code, Docker Compose behavior, or service execution features.

## Milestone 30.3 Prompt: PC-1 / PC-2 Startup Service Matrix

Add beginner-friendly operational documentation that explains exactly which services should run on PC-1 and PC-2 for each daily mode.

Expected boundaries:

- Add `docs/ops/16-startup-service-matrix.md`, `docs/ops/17-mode-startup-recipes.md`, and `docs/ops/18-image-mode-entry-checklist.md`.
- Cover coding, review/debug, memory/database, image generation, media placeholder, backup, restore, and troubleshooting modes.
- Include exact PC-1, PC-2, and PC-1-to-PC-2 command labels, IPs, checks, expected good signs, and warnings.
- Keep image mode readiness-only. Do not add real image generation, automatic model switching, automatic llama-server stop/start, or service execution features.

## Milestone 30.4 Prompt: Media / Image Runtime Readiness Map

Create a beginner-friendly readiness map for future image/media processing.

Expected boundaries:

- Add `docs/ops/19-media-readiness-map.md`, `docs/ops/20-image-mode-safety-rules.md`, and `docs/ops/21-image-pipeline-entry-plan.md`.
- Map PC-1 media/GPU role, PC-2 support role, GPU/VRAM readiness, existing image/media scripts and docs, model folders, model checks, service checks, and safe readiness flow.
- Keep image generation future work. Do not add real generation commands, automatic llama-server stop/start, automatic model switching, app code, Docker Compose behavior, or service execution features.

## Milestone 31.0 Prompt: Image Processing Pipeline Runbook

Create the first beginner-friendly image processing pipeline runbook.

Expected boundaries:

- Add `docs/ops/22-image-processing-pipeline-runbook.md`, `docs/ops/23-image-model-inventory-guide.md`, and `docs/ops/24-image-first-dry-run-plan.md`.
- Explain pipeline overview, PC-1/PC-2 roles, required folders, required model files, required services, VRAM safety, readiness checks, and dry-run planning.
- Do not include real image generation commands yet.
- Keep changes documentation-only. Do not alter runtime behavior, app code, Docker Compose behavior, service execution features, automatic model switching, or automatic image generation.

## Milestone 31.1 Prompt: ComfyUI / Flux Startup Checklist

Create a beginner-friendly startup checklist for ComfyUI / Flux image runtime readiness.

Expected boundaries:

- Add `docs/ops/25-comfyui-flux-startup-checklist.md`, `docs/ops/26-comfyui-flux-blockers.md`, and `docs/ops/27-comfyui-flux-startup-evidence-template.md`.
- Include exact PC-1 readiness checks for repo status, GPU, llama-server, Docker, scripts/docs, model files, and model folder sizes.
- Keep startup operator-reviewed and explicit.
- Avoid real image generation commands, automatic model switching, automatic llama-server stop/start, app code changes, Docker Compose changes, or service execution features.

## Milestone 31.2 Prompt: Image Mode VRAM Safety / LLM Stop Plan

Create beginner-friendly documentation for VRAM safety when moving between coding mode and image mode.

Expected boundaries:

- Add `docs/ops/28-image-mode-vram-safety.md`, `docs/ops/29-manual-llm-stop-start-plan.md`, and `docs/ops/30-image-mode-return-to-coding.md`.
- Explain when and how a human operator safely handles llama-server before image/media work.
- Keep all stop/start actions explicit and operator-reviewed.
- Do not add runtime behavior, app code, Docker Compose changes, automatic model switching, automatic image generation, or real generation commands.

## Milestone 31.3 Prompt: First Image Dry Run Evidence Review

Create a beginner-friendly dry-run evidence review workflow before first real image generation.

Expected boundaries:

- Add `docs/ops/31-first-image-dry-run-evidence-review.md`, `docs/ops/32-first-image-dry-run-evidence-template.md`, and `docs/ops/33-first-image-dry-run-review-checklist.md`.
- Define evidence collection for repo state, GPU/VRAM, llama-server, Docker/media containers, scripts, docs, model inventory, Gateway/media endpoints, and PC-2 support services.
- Keep review documentation-only. Do not alter runtime behavior, app code, Docker Compose behavior, service execution features, automatic model switching, or automatic image generation.
- Do not include real image generation commands.

## Milestone 31.3.1 Prompt: Image Mode Safety Alignment

Align existing image-mode scripts and docs with operator safety rules before M31.4.

Expected boundaries:

- Update `scripts/image/image-mode-prepare.sh` so `STOP_LLM=1` uses `make model-stop`, `make model-status`, and a `pgrep` verification check instead of direct `pkill`.
- Update dry-run script text and existing image-mode docs to match the guarded Makefile-controlled stop path.
- Add `docs/ops/34-image-existing-script-map.md`.
- Do not run real generation. Do not use `APPLY=1` in tests. Do not add Gateway shell execution, automatic model switching, or automatic image generation.

## Milestone 31.4 Prompt: First Real Image Generation Drill

Add first real image generation drill.

Expected boundaries:

- Add `docs/ops/35-first-real-image-generation-drill.md`, `docs/ops/36-first-real-image-generation-evidence-template.md`, and `docs/ops/37-generated-image-git-safety.md`.
- Document the guarded first real image generation sequence after evidence review.
- Keep real generation explicit, guarded, and operator-approved.
- Preserve return-to-coding and VRAM safety checks.

## Milestone 31.5 Prompt: Generated Image Output Handling / Git Safety

Add generated image output handling / Git safety documentation.

Status: DONE

Expected boundaries:

- Document generated image output locations and Git safety checks.
- Keep generated media out of source control.
- Preserve runtime/source separation for image outputs.
- Add beginner-friendly output inspection, archive, metadata-recording, and cleanup policy docs.

## Milestone 31.6 Prompt Placeholder

Add ComfyUI workflow inventory.

Status: DONE

Expected boundaries:

- Inventory ComfyUI workflows, required model files, inputs, outputs, and safety gates.
- Keep real workflow execution explicit and operator-approved.
- Do not add automatic image generation or Gateway shell execution.
- Add beginner-friendly Flux Schnell parameter guidance and a manual workflow change log template.

## Milestone 31.7 Prompt Placeholder

Add Gateway real image run drill.

Status: DONE

Expected boundaries:

- Document a Gateway-facing real image run drill after ComfyUI workflow inventory.
- Keep real generation explicit and operator-approved.
- Do not add Gateway shell execution, Docker control, automatic model switching, or automatic generation.
- Add evidence and troubleshooting templates for the guarded Gateway/media image path.

## Milestone 31.8 Prompt Placeholder

Add prompt variants / batch image plan.

Status: DONE

Expected boundaries:

- Plan safe prompt variant and batch image experiments after the Gateway real image run drill.
- Keep batch generation operator-reviewed and explicitly gated.
- Do not add automatic image generation, Gateway shell execution, Docker control, or model switching.
- Add prompt variant planning, small batch safety, image comparison notes, and output naming policy docs.

## Milestone 31.9 Prompt Placeholder

Add media dashboard output review.

Status: DONE

Expected boundaries:

- Review how generated image outputs are surfaced in the media dashboard.
- Keep dashboard output review read-only.
- Do not add automatic generation, Gateway shell execution, Docker control, model switching, or generated media commits.
- Document `latest_images` fields and add a dashboard output review template.

## Milestone 32.0 Prompt Placeholder

Add controlled prompt variant generation.

Status: DONE

Expected boundaries:

- Implement controlled prompt variant generation only after M31.8 planning and M31.9 dashboard review.
- Keep generation explicitly operator-approved and guarded.
- Do not add uncontrolled batch execution, Gateway shell execution, Docker control, model switching, or generated media commits.
- Add a dry-run helper plan, run templates, session evidence template, and stop conditions.

## Milestone 32.1 Prompt Placeholder

Add media dashboard UI output cards.

Status: PLANNED

Expected boundaries:

- Plan dashboard UI output cards for generated media review.
- Keep dashboard output cards read-only.
- Do not add dashboard write actions, automatic generation, Gateway shell execution, Docker control, model switching, or generated media commits.

## Milestone 32.2 Prompt Placeholder

Add prompt variant result review.

Status: DONE

Expected boundaries:

- Review controlled prompt variant results after operator-run generation.
- Keep review documentation and dashboard references read-only.
- Do not add dashboard write actions, automatic generation, Gateway shell execution, Docker control, model switching, or generated media commits.
- Record the first controlled 3-variant result set and fix Git binary safety checks to be extension-anchored.

## Milestone 32.3 Prompt Placeholder

Add prompt quality improvement plan.

Status: DONE

Expected boundaries:

- Plan prompt quality improvements from reviewed controlled variant results.
- Keep improvement planning documentation-only until a separate guarded generation milestone.
- Do not add automatic generation, Gateway shell execution, Docker control, model switching, or generated media commits.
- Add next pergola prompt set, negative prompt notes, and prompt quality review template.

## Milestone 32.4 Prompt Placeholder

Add improved prompt controlled run result review.

Status: DONE

Expected boundaries:

- Review the manually executed improved prompt controlled run.
- Record result notes, VRAM observations, dashboard visibility, shutdown, and coding restore.
- Do not add automatic generation, Gateway shell execution, Docker control, model switching, or generated media commits.

## Milestone 32.5 Prompt Placeholder

Add pergola project-specific prompt pack.

Status: PLANNED

Expected boundaries:

- Build a project-specific pergola prompt pack after improved prompt review.
- Keep prompt pack documentation-only until a separate guarded generation milestone.
- Do not add automatic generation, Gateway shell execution, Docker control, model switching, or generated media commits.

## Milestone 32.6 Prompt Placeholder

Add technical detail image run.

Status: PLANNED

Expected boundaries:

- Run the next technical/detail prompt set through the guarded operator-controlled path.
- Keep generation one variant at a time.
- Do not add automatic generation, Gateway shell execution, Docker control, model switching, or generated media commits.

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

## Milestone 29.10 Memory Store Real Apply Guardrail Review

- Add `scripts/memory-store-real-apply-guardrail.sh` and `scripts/test-memory-store-real-apply-guardrail.sh`.
- Add `make memory-store-real-apply-guardrail` and `make test-memory-store-real-apply-guardrail`.
- Integrate the guardrail before the `APPLY=1` Memory API write loop in `scripts/memory-store-approved.sh`.
- Keep the guardrail read-only: no Memory API calls, Gateway calls, llama-server calls, runtime writes, approval-file mutation, or `APPLY=1` execution.
- Reject missing or invalid `memory-store-plan.json`, missing or invalid `approved-memory-candidates.json`, test fixtures, `dry_run_only=true`, missing approved candidates, missing `human_review_required=true`, and raw prompt/response field markers.
- Warn on batch apply with more than one approved candidate unless `ALLOW_BATCH_MEMORY_APPLY=1` is set; this only silences the warning and does not bypass FAIL checks.
- Real writes remain manual and explicit with `APPLY=1 make memory-store-approved`; tests never run `APPLY=1`.
- Validate with `make check-layout`, `make memory-store-real-apply-guardrail`, `make test-memory-store-real-apply-guardrail`, M29 memory approval tests, and default source-only tests.

## Milestone 29.11 Gateway Continue Compatibility Hardening

- Update `/v1/chat/completions` to tolerate Continue/OpenAI extra fields: `stream`, `tools`, `tool_choice`, `parallel_tool_calls`, `response_format`, `stop`, penalties, `top_p`, `n`, and `user`.
- Support `stream=true` with a minimal OpenAI-compatible SSE wrapper over the existing non-streaming internal model call and return `x_gateway_compat.stream_requested=true` and `x_gateway_compat.stream_wrapped=true`.
- Keep SSE support as compatibility streaming, not true token-by-token runtime streaming.
- Accept `tools` and `tool_choice` fields but ignore them safely; never execute tools from Continue/OpenAI tool payloads.
- Return OpenAI-style JSON error bodies for rejected or failed `/v1/chat/completions` requests.
- Keep Gateway-Auto configs pointed at `http://localhost:8100/v1`.
- Do not execute shell commands, control Docker, switch models, write files, call Memory API write routes, train, fine-tune, or mutate runtime state.
- Validate with `make test-openai-compatible-gateway`, `make test-continue-gateway`, Gateway API tests, and default source-only tests.

## Milestone 29.12 Gateway-Auto Runtime Routing Hardening

- Harden Gateway-Auto runtime routing metadata for Continue/OpenAI-compatible clients without adding automatic switching.
- Keep existing router fields and add `routing_mode=advisory_only`, `runtime_switch_supported=false`, `runtime_switch_attempted=false`, `active_model_mismatch_level`, `active_model_mismatch_reason`, `effective_runtime_model`, `continue_safe=true`, and safe `next_steps`.
- If a selected model target is missing from mapping, report `model_mapping_status`, use fallback safely when available, and do not fail chat only because advisory mapping fell back.
- Do not start, stop, restart, or switch llama-server, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.
- Validate with `make test-gateway-chat-router`, `make test-openai-compatible-gateway`, `make test-continue-gateway`, Gateway API tests, and default source-only tests.

## Milestone 29.13 Gateway Runtime Switch Plan Guardrail

- Harden `/gateway/runtime/switch-plan` as a planning-only endpoint.
- Return `status=plan_only`, `apply_supported=false`, `auto_execution_supported=false`, `runtime_switch_supported=false`, `runtime_switch_attempted=false`, `requires_human_operator=true`, target/current model metadata, `risk_level`, guardrails, preflight checks, and natural-language next steps.
- Do not return executable command fields or command-like strings from the switch-plan response.
- Keep `runtime_switch_plan` non-executable in the tool catalog and verify `/gateway/tools/execute` still rejects it.
- If target or intent mapping is unknown, use fallback safely when available and include `model_mapping_status` plus a safe warning.
- Do not start, stop, restart, or switch llama-server, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.
- Validate with Gateway API tests and default source-only tests.

## Milestone 29.14 Gateway Runtime Runbook Integration

- Link `/gateway/runtime/switch-plan` to `docs/gateway-runtime-switch-runbook.md`.
- Return `runbook`, `runbook_status=manual_only`, `runbook_required=true`, verification steps, and natural-language rollback guidance.
- Keep runbook references safe documentation only.
- Do not start, stop, restart, or switch llama-server, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.
- Keep future real guarded switching separate from this milestone.

## Milestone 29.15 Runtime Profile Preflight

- Add read-only `GET /gateway/runtime/profile-preflight`.
- Add read-only `runtime_profile_preflight` tool execution.
- Check configured model routing targets, `runtime_model_id` values, local file existence for path-like ids, and active runtime metadata.
- Report missing model files as warnings or `review_required`; do not download or repair them automatically.
- Do not start, stop, restart, or switch llama-server, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.

## Milestone 29.16 Runtime Profile Run Command Catalog

- Add documentation-only `GET /gateway/runtime/profile-run-catalog`.
- Add read-only `runtime_profile_run_catalog` tool execution.
- Derive safe catalog metadata from model routing, model, and runtime configs where possible.
- Expose run settings for human review without executable instructions.
- Keep host scripts manual/operator controlled.
- Do not start, stop, restart, or switch llama-server, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.

## Milestone 29.17 Runtime Profile Compatibility Matrix

- Add read-only `GET /gateway/runtime/profile-compatibility-matrix`.
- Add read-only `runtime_profile_compatibility_matrix` tool execution.
- Use the runtime profile run catalog and static PC-1 hardware assumptions.
- Report advisory compatibility, risk level, estimated VRAM pressure, notes, and warnings.
- Do not inspect live GPU state, execute scripts, switch models, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.

## Milestone 29.18 Runtime Profile Recommendation Summary

- Add read-only `GET /gateway/runtime/profile-recommendation-summary`.
- Add read-only `runtime_profile_recommendation_summary` tool execution.
- Combine existing profile preflight, run catalog, and compatibility matrix data into advisory default/review/fallback recommendations.
- Keep recommendations for human review only.
- Do not inspect live GPU state, execute scripts, switch models, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.

## Milestone 29.19 Gateway Runtime Profile Dashboard Summary

- Surface runtime profile recommendations in dashboard/read-only form.
- Add compact `GET /gateway/runtime/profile-dashboard-summary` and embed `runtime_profile_summary` in `/gateway/runtime/dashboard`.
- Add a read-only Dashboard UI card with default, review, fallback, compatibility, risk, and warning summary.
- Do not add action buttons.
- Do not inspect live GPU state, execute scripts, switch models, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.

## Milestone 29.20 Runtime Profile Operator Checklist Export

- Add read-only `GET /gateway/runtime/profile-operator-checklist`.
- Add read-only `runtime_profile_operator_checklist` tool execution.
- Export manual operator checklist items for runtime profile decisions.
- Keep checklist export documentation-only and manual-review-only.
- Do not inspect live GPU state, execute scripts, switch models, call shell, control Docker, write files, call Memory API write routes, train, or fine-tune.
