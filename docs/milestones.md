# MoE / AI-Brain-OS Milestones

Current active phase:
- M30 Ops resilience is active.
- Latest completed: M34.49 Reference Board Stale Item Regression.
- Next planned: M34.50 Reference Board Repair CLI Operator Runbook.
- Future phases: M31 Homelab Ops, M32+ Media expansion.

Pergola is now a case study/prototype. Generic media and drawing roadmap begins at M34.

Current media milestone status:
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
- M34.18 Reference Board Output Card Integration PLANNED
- M34.19 Reference Board Detail View DONE
- M34.20 Reference Board Export Plan DONE
- M34.21 Reference Board Selected Reason Edit DONE
- M34.22 Reference Board Compare View PLANNED
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
- M34.50 Reference Board Repair CLI Operator Runbook PLANNED
- M34.51 Reference Board Repair CLI Summary Review PLANNED

## Milestone 0: Clean Codebase

Status: DONE

Goals:
- Create clean source-only codebase.
- Reset GitHub `main` to the clean codebase.
- Keep runtime data separate from source code.

## Milestone 1: Monorepo Skeleton

Status: DONE

Goals:
- Create monorepo structure.
- Define apps, packages, infra, deploy, docs, and scripts areas.
- Add source/runtime separation rules.
- Add layout validation.

## Milestone 2: Docker Foundation

Status: DONE

Goals:
- Add Docker Compose foundation.
- Add PostgreSQL service.
- Add Qdrant service.
- Use runtime bind mounts under `~/MoE/runtime`.
- Add Docker health and runtime preparation commands.

## Milestone 3: Memory API Skeleton

Status: DONE

Goals:
- Add FastAPI Memory API service.
- Add `/health`.
- Add `/memory/add`.
- Add `/memory/search`.
- Keep behavior placeholder-only.

## Milestone 3.1: Qdrant Healthcheck Fix

Status: DONE

Goals:
- Remove fragile Qdrant in-container healthcheck.
- Check Qdrant externally with `make health`.
- Avoid false unhealthy status when the Qdrant image lacks probe tools.

## Milestone 4: Memory API Infrastructure Clients

Status: DONE

Goals:
- Add environment-driven Memory API config.
- Add PostgreSQL client placeholder.
- Add Qdrant client placeholder.
- Add `/health/deep`.

## Milestone 5: Memory Storage Foundation

Status: DONE

Goals:
- Add PostgreSQL `memories` table.
- Store raw memory text, source, and metadata in PostgreSQL.
- Add Qdrant collection configuration placeholder.
- Keep embeddings and vector search intentionally unimplemented.

## Milestone 5.1: Test Automation and Documentation Sync

Status: DONE

Goals:
- Automate stack tests.
- Automate Memory API tests.
- Update milestone docs.
- Prepare safe checkpoint before embeddings.

## Milestone 6: Embedding Worker Skeleton

Status: DONE

Goals:
- Create embed-worker service skeleton.
- Add `/health` endpoint.
- Add local embedding interface placeholder.
- Do not download models yet.
- Do not implement heavy embedding inference yet.
- Prepare future BGE-M3 or sentence-transformers integration.

## Milestone 7: Memory API + Embed Worker Integration

Status: DONE

Goals:
- Connect Memory API to Embed Worker for embedding requests.
- Keep embedding generation behind a small client interface.
- Store generated vector ids alongside memory rows.
- Prepare Qdrant vector insertion without implementing semantic search yet.

## Milestone 8: Real Embedding Backend Preparation

Status: DONE

Goals:
- Prepare configuration for a real local embedding backend.
- Keep model files outside the codebase.
- Add safe model path validation.
- Do not download models into the repository.
- Keep fallback fake embedding support.

## Milestone 9: Real BGE-M3 Embedding Runtime

Status: DONE

Goals:
- Add real BGE-M3 runtime loading.
- Keep model files outside the codebase.
- Add safe startup and fallback behavior.
- Avoid downloading models into the repository.
- Validate embedding dimension compatibility.

## Milestone 9.1: Model Integrity and Runtime Validation

Status: DONE

Goals:
- Add script to validate local model paths.
- Detect Git LFS pointer files.
- Check model directory size.
- Check required model files exist.
- Check Docker mount visibility.
- Add optional BGE-M3 runtime test.
- Keep BGE-M3 test optional and not part of default `make test` yet.

## Milestone 10: Memory Search with Dimension-Aware Qdrant Collections

Status: DONE

Goals:
- Select Qdrant collections from active embedding backend and vector dimension.
- Keep fake `384` vectors and BGE-M3 `1024` vectors in separate collections.
- Validate collection dimensions before write and search.
- Implement `/memory/search` using Embed Worker query embeddings and Qdrant.
- Return collection, backend, dimension, score, and payload metadata with search results.

## Milestone 11: Model Runtime / OpenAI-Compatible Serving

Status: DONE

Goals:
- Add host-managed llama.cpp serving scripts.
- Expose an OpenAI-compatible local endpoint at `http://localhost:8000/v1`.
- Track model runtime configuration in source-only YAML files.
- Store logs and pid files under `/home/cuneyt/MoE/runtime`.
- Keep model files outside the codebase.

## Milestone 11.1: Backup / Restore / Disaster Recovery

Status: PLANNED

Goals:
- Define backup strategy for source, runtime, Docker state, PostgreSQL, Qdrant, models, llama.cpp, environment templates, and docs.
- Keep source, runtime data, and model files in their assigned locations.
- Exclude pid files from backups and make logs optional.
- Add checksum manifest strategy for model files.
- Add restore process for a new PC.
- Add disaster recovery checklist.

## Milestone 11.2: Hardware Role Profiles / Environment Reassignment

Status: PLANNED

Goals:
- Add environment role profile plan for PC1, PC2, single-machine, and new-machine setups.
- Allow future hardware changes without rewriting the project.
- Document role reassignment for model runtime, Memory API, PostgreSQL, Qdrant, Dashboard, Gateway, and research workers.
- Document how to update IPs, paths, and model defaults.
- Document current PC1 and PC2 ownership assumptions.

## Milestone 12: Gateway API

Status: DONE

Goals:
- Add a central API entrypoint for local AI services.
- Expose Gateway health and dependency status.
- Proxy model discovery and chat requests to the host OpenAI-compatible runtime.
- Add a first simple route decision endpoint.
- Keep advanced MoE routing and Dashboard work out of scope.

## Milestone 13: Memory-Augmented Gateway Chat

Status: DONE

Goals:
- Add optional memory search to `/gateway/chat`.
- Inject concise local memory context only when requested.
- Continue chat without memory if Memory API search is unavailable.
- Return memory metadata without exposing large raw memory payloads.
- Keep advanced MoE routing and Dashboard work out of scope.

## Milestone 14: Simple Router / Intent-Aware Routing

Status: DONE

Goals:
- Replace placeholder Gateway route decisions with deterministic intent-aware routing.
- Detect chat, code, memory, review, and ops intents with readable keyword scoring.
- Return confidence, reason, matched keyword signals, and memory recommendation.
- Keep advanced MoE routing optional and incremental.
- Preserve the current model runtime and memory API contracts.

## Milestone 15: Router-Aware Gateway Chat

Status: DONE

Goals:
- Use deterministic route decisions to influence Gateway chat behavior.
- Add route metadata to `/gateway/chat` responses.
- Auto-enable memory search for memory intent.
- Add concise intent-specific system prompt guidance.
- Keep actual model hot-switching out of scope.
- Preserve default tests without requiring model runtime.

## Milestone 16: Model Mapping / Runtime Profiles or Tool-Aware Routing

Status: DONE

Goals:
- Add explicit model routing config for Gateway intents.
- Return advisory model target and runtime id metadata from route and chat endpoints.
- Report actual model alignment without switching the runtime model.
- Keep model switching explicit and observable.
- Preserve current fallback behavior for default tests.
- Avoid advanced MoE routing until simpler routing is stable.

## Milestone 17: Runtime Model Switch Plan and Safe Runtime Controls

Status: DONE

Goals:
- Add host-side safe model runtime switch script.
- Expose Gateway runtime status.
- Expose Gateway switch-plan endpoint that returns manual planning metadata only.
- Keep Gateway from executing host shell commands.
- Keep automatic runtime switching deferred.

## Milestone 18: Tool-Aware Routing Plan

Status: DONE

Goals:
- Add tool-aware routing metadata using existing intent and model metadata.
- Report recommended tools without executing shell, Docker, or runtime-switch actions.
- Keep Gateway behavior backward compatible.
- Avoid advanced MoE routing until safe controls are proven.

## Milestone 19: Controlled Read-Only Tool Execution

Status: DONE

Goals:
- Add explicit read-only Gateway tool execution for safe internal HTTP checks.
- Keep shell commands, Docker actions, and runtime switches advisory only.
- Keep automatic execution disabled globally.
- Keep workspace file reading and file writes out of scope.
- Preserve default tests without requiring model runtime.

## Milestone 20: Local Coding Workspace Integration

Status: DONE

Goals:
- Add read-only workspace context provider.
- Add repo file tree endpoint.
- Add safe file search endpoint.
- Add code task prompt templates.
- Keep file writes disabled.

## Milestone 21: Continue.dev / VS Code Gateway Integration

Status: DONE

Goals:
- Point Continue.dev to Gateway or model runtime.
- Add coding model profiles.
- Add local prompt templates.
- Add docs for using the stack as a coding assistant.
- Add Gateway OpenAI-compatible chat adapter for Continue.dev.

## Milestone 22: Repo-Aware Coding Agent

Status: DONE

Goals:
- Combine workspace context, memory, router, and model runtime.
- Support code explanation, debugging, review, and implementation planning.
- Keep agent actions advisory until write safety is designed.
- Add read-only `/gateway/code/context` and `/gateway/code/ask` endpoints.
- Add read-only `code_context` and `code_ask` tool entries.
- Preserve default tests without requiring model runtime.

## Milestone 23: Safe Patch/Diff Workflow

Status: DONE

Goals:
- Generate patches only.
- Do not auto-apply changes.
- Add diff review workflow.
- Add `/gateway/code/patch-plan` for human-reviewable patch planning.
- Add `/gateway/code/diff-suggest` for unified diff suggestions.
- Keep `apply_supported=false`.
- Preserve default tests without requiring model runtime.

## Milestone 23.5: PC-2 Worker Node Preparation

Status: DONE

Goals:
- Prepare PC-2 as a background worker node before Nightly Learning.
- Assign PC-2 to memory/vector services, learning jobs, research ingestion, reports, and long-running background tasks.
- Keep PC-1 as the interactive coding, model runtime, Dashboard, and media GPU node.
- Do not run heavy LLM inference on PC-2 by default.
- Keep PC-2 runtime and data directories outside the codebase.
- Make PC-2 deployment reproducible through Docker Compose profiles and docs.
- Add source-only PC-2 worker profile examples and deploy templates.
- Add optional read-only PC-2 connectivity and layout validation scripts.
- Keep default tests independent from PC-2 availability.

## Milestone 24: Nightly Learning Worker

Status: DONE

Goals:
- Add a separate read-only Nightly Learning Worker service skeleton.
- Support `dry_run` report generation through FastAPI on port `8200`.
- Inspect only bounded source metadata and configured service health.
- Produce nightly reports under `/home/cuneyt/MoE/runtime/reports/nightly`.
- Optionally store useful lessons into Memory API when explicitly requested.
- Never modify code automatically.
- Never execute shell commands automatically.
- Never restart Docker or model runtime.
- Keep reports safe, observable, and manually reviewable.

Current scope:
- Add `/health`, `/nightly/run`, and `/nightly/latest`.
- Keep PC-2 deployment as a source-only example behind the `learning` profile.
- Keep default tests independent from PC-2, Docker, model runtime, and live service availability.

## Milestone 24.0.1: PC-2 Nightly Worker Activation

Status: DONE

Goals:
- Prepare explicit PC-2 activation flow for the Nightly Learning Worker.
- Add source sync helper from PC-1 to PC-2 that excludes runtime, model, cache, and build artifacts.
- Add optional PC-2 start, stop, health, and dry-run helper scripts.
- Start only `nightly-learning-worker` through the Docker Compose `learning` profile.
- Keep `store_lessons=false` for the default dry-run command.
- Keep default tests independent from PC-2, Docker, model runtime, and live service availability.
- Do not start research ingestion, memory migration services, model runtime, Gateway, or Dashboard on PC-2.

## Milestone 24.1: Research Ingestion Worker

Status: DONE

Goals:
- Add the first Research Ingestion Worker skeleton.
- Support approved source definitions from `configs/research-sources.example.yaml`.
- Process local markdown/text metadata only.
- Skip URL sources because remote fetch is not implemented.
- Write research reports under `/home/cuneyt/MoE/runtime/reports/research`.
- Optionally store distilled findings in Memory API when explicitly requested.
- Keep all outputs under runtime data.
- Make no automatic code changes.
- Keep default tests independent from PC-2, internet, Docker, model runtime, and live service availability.

## Milestone 24.2: Feedback / Success Memory

Status: DONE

Goals:
- Add the first Feedback Worker skeleton.
- Store task outcome events as runtime-only JSONL under `/home/cuneyt/MoE/runtime/feedback`.
- Generate feedback reports under `/home/cuneyt/MoE/runtime/reports/feedback`.
- Track task type, goal, route intent, model target, actual model, tools, selected files, tests run, outcome, failure reason, notes, and timestamp.
- Optionally store distilled lessons in Memory API when explicitly requested.
- Keep feedback memory transparent and inspectable.
- Do not automatically modify source, router config, prompt templates, model mappings, Docker, or model runtime.
- Keep default tests independent from PC-2, internet, Docker, model runtime, and live service availability.

## Milestone 24.3: Prompt & Routing Improvement Reports

Status: DONE

Goals:
- Generate deterministic recommendations from feedback events.
- Cover router keywords, intent examples, model mapping alignment, prompt templates, tool planning, docs gaps, test coverage, and common failure patterns.
- Write improvement reports under `/home/cuneyt/MoE/runtime/reports/improvements`.
- Keep `apply_supported=false`.
- Do not automatically modify source, router config, prompt templates, model mappings, Docker, PC-2, or model runtime.
- Require human approval before changing code or config.

## Milestone 25: Media Lab Foundation

Status: DONE

Goals:
- Add dry-run-only `media-api` and `media-worker` skeletons.
- Define runtime job, output, and report directories under `/home/cuneyt/MoE/runtime/media` and `/home/cuneyt/MoE/runtime/reports/media`.
- Define placeholder media model paths under `/home/cuneyt/MoE_Models_Backup`.
- Add dry-run workflow config examples.
- Add optional Docker `media` profile.
- Keep generated media out of the codebase.
- Do not install ComfyUI or Blender.
- Do not implement actual image, video, 3D, rigging, or animation generation yet.

## Milestone 26.0: Image Generation Service Preparation

Status: DONE

Goals:
- Add image generation configuration placeholders.
- Add image model inventory checks that inspect `/home/cuneyt/MoE_Models_Backup` without modifying files.
- Add image-specific dry-run job metadata validation.
- Add image dry-run report fields.
- Keep real image generation disabled by default.
- Do not install ComfyUI, Diffusers, Blender, or execute GPU jobs.

## Milestone 26.1-pre: Image Engine Decision and Runtime Probe

Status: DONE

Goals:
- Recommend ComfyUI as the primary future image engine and defer Diffusers.
- Document planned ComfyUI runtime layout under `/home/cuneyt/MoE/runtime/media-engines/comfyui`.
- Keep media outputs under `/home/cuneyt/MoE/runtime/media`.
- Keep media models under `/home/cuneyt/MoE_Models_Backup`.
- Add read-only image model download planning report format.
- Add optional ComfyUI layout probe that exits successfully when directories are missing.
- Add optional runtime directory creation mode limited to the planned runtime path.
- Keep real generation, model downloads, ComfyUI installation, symlink creation, and GPU jobs disabled.

## Milestone 26.1: Real Image Generation Service

Status: DONE

Goals:
- Add optional user-run ComfyUI runtime installation under `/home/cuneyt/MoE/runtime/media-engines/comfyui`.
- Add ComfyUI runtime check, up, down, and health scripts.
- Add Flux Schnell model acquisition planning without downloads.
- Add symlink-only ComfyUI model linking with dry-run default.
- Keep source-only repo separation.
- Keep real image generation disabled.
- Do not run actual image generation or GPU jobs.

## Milestone 26.1.5: Control Plane Dashboard and Runtime Mode Manager

Status: DONE

Goals:
- Add `control-api` on port `8400`.
- Expose read-only runtime status for known services.
- Define safe runtime modes: `coding`, `image`, `video`, `3d_suite`, and `media_off`.
- Return dry-run mode plans with host roles, prompt interpreter state, start/stop lists, and VRAM recommendations.
- Keep `/control/mode/apply` rejected by default.
- Document PC-1 as generation host and PC-2 as helper host.
- Keep Gateway from becoming the system control surface.
- Do not implement arbitrary shell execution, automatic self-modification, model downloads, or real media generation.

## Milestone 26.1.6: Prompt Interpreter Worker

Status: DONE

Goals:
- Add a PC-2 prompt interpreter worker.
- Start with rule/template-based interpretation.
- Produce structured media job specs.
- Require no local model.
- Keep output dry-run only.
- Do not call llama-server, ComfyUI, Media API, or generation engines.

## Milestone 26.1.7: Mini Model Prompt Interpreter on PC-2

Status: PLANNED

Goals:
- Evaluate a small local model for prompt interpretation only if needed.
- Keep output structured and reviewable.
- Keep heavy generation on PC-1.

## Milestone 26.2: First Real Image Generation

Status: DONE

Goals:
- Add explicit Flux Schnell model download plan/apply scripts.
- Add checksum/size validation helpers.
- Link models into ComfyUI by symlink only.
- Add guarded ComfyUI Flux smoke and first-image scripts.
- Enable first real generation only through explicit user-run `APPLY=1`.
- Validate ComfyUI health, selected Flux model, text encoders, and VAE/AE.
- Support queued image jobs and asset tracking.
- Store generated images under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- Keep Gateway from controlling PC-2 or executing arbitrary shell commands.

## Milestone 26.3: Media API to Prompt Interpreter to ComfyUI Bridge

Status: DONE

Goals:
- Connect Media API image jobs to Media Worker processing.
- Keep dry-run as the default safe path.
- Gate real image generation behind `MEDIA_REAL_GENERATION_ENABLED=true`.
- Submit Flux Schnell workflows to ComfyUI from Media Worker.
- Surface generated outputs under `/home/cuneyt/MoE/runtime/media/outputs/images/<job_id>`.
- Keep Prompt Interpreter as an optional upstream job-spec helper.
- Do not let Gateway trigger generation.

## Milestone 26.4: Gateway-to-Media Guarded Integration

Status: DONE

Goals:
- Add explicit Gateway-to-Media planning/dispatch integration.
- Keep generation approval-gated and observable.
- Preserve PC-1 generation host and PC-2 helper roles.

Current scope:
- Add Gateway media health, plan, dry-run job, guarded real job, and job status endpoints.
- Use PC-2 Prompt Interpreter when reachable, with local fallback classification.
- Keep Gateway from starting or stopping services, controlling PC-2, controlling Docker, or starting ComfyUI.
- Keep real generation rejected by default.

## Milestone 26.5: Simple Media Dashboard / Status UI

Status: DONE

Goals:
- Add a lightweight media status/dashboard surface.
- Show Gateway media safety gates, dry-run jobs, and latest media outputs.
- Keep real generation controls explicit and guarded.

Current scope:
- Add read-only `/gateway/media/dashboard`.
- Add a source-only `apps/media-dashboard` UI.
- Show service reachability, media gates, mode hints, safe command text, and latest image output paths.
- Do not start/stop services, call Docker, trigger real generation, or modify runtime media.

## Milestone 26.5.1: PC1 / PC2 Sleep Wake Startup Command Pack

Status: DONE

Goals:
- Add fixed, user-run PC-1, PC-2, and cluster command scripts for sleep preparation, guarded suspend, startup, and status.
- Keep suspend behind `APPLY=1`.
- Keep real generation disabled by default.
- Avoid destructive Docker, runtime, model, and media operations.

## Milestone 26.6: Guided Image Generation Command Pack

Status: DONE

Goals:
- Add reviewed command packs for common image-generation flows.
- Keep commands explicit and user-run.
- Preserve source/runtime/model separation.

Current scope:
- Add guided image readiness, dry-run, image-mode prepare, real-run, latest output, safe shutdown, and full-cycle scripts.
- Keep real generation behind `APPLY=1`.
- Keep ComfyUI bridge mode explicit.
- Keep generated media under runtime output paths.

## Milestone 26.7: Image Prompt Presets and History

Status: SKIPPED / LATER

Goals:
- Add source-only image prompt preset templates.
- Track reviewed prompt history without copying generated media into the repository.
- Keep real generation explicit and guarded.

## Milestone 26.8: Dashboard UI MVP

Status: DONE

Goals:
- Add a read-only browser Dashboard UI.
- Show system and media health, real generation gates, latest generated image paths, safe command hints, and PC-1/PC-2 roles.
- Keep dashboard actions out of scope.

## Milestone 26.8.1: Dashboard Material Kit Theme Integration

Status: DONE

Goals:
- Upgrade `apps/dashboard-ui` to a Material UI / Minimal Dashboard inspired visual theme.
- Add top app bar, left navigation rail, responsive dashboard cards, chips, alerts, lists, command code blocks, and warnings.
- Preserve read-only behavior and the single Gateway dashboard data source.
- Do not vendor the external template, copy unrelated demo pages, or add large assets.

## Milestone 26.8.2: Dashboard Runtime Cards

Status: DONE

Goals:
- Add read-only runtime status cards to the Dashboard UI.
- Add `/gateway/runtime/dashboard` for PC-1 runtime, GPU, llama-server, ComfyUI, PC-2 worker, media job, and image lifecycle observations.
- Keep missing runtime services as warnings.
- Keep the UI read-only and keep actions out of scope.

## Milestone 26.8.3: Dashboard System Resource Cards

Status: DONE

Goals:
- Add PC-1 RAM, CPU load, disk, and uptime cards to the Dashboard UI.
- Extend `/gateway/runtime/dashboard` with read-only system data from procfs and Python stdlib.
- Keep PC-2 system and Docker summary as graceful unavailable observers unless safe endpoints are added.
- Keep GPU, Docker, ComfyUI, Control API, and PC-2 unavailability non-fatal.
- Preserve read-only dashboard boundaries.

## Milestone 26.8.4: PC2 System Status Endpoint

Status: DONE

Goals:
- Add read-only `GET /system/status` to the PC-2 Prompt Interpreter Worker.
- Use Linux procfs and Python stdlib only for PC-2 RAM, CPU load, disk, and uptime.
- Make Gateway consume the fixed PC-2 HTTP endpoint for `.system.pc2`.
- Keep unavailable PC-2 system status non-fatal.
- Avoid SSH, remote shell commands, Docker socket access, `nvidia-smi`, and file mutation.

## Milestone 26.8.5: Read-only Docker Summary Snapshot

Status: DONE

Goals:
- Add a host-side `docker-summary-snapshot` script for fixed allowlisted container status.
- Write snapshot JSON under `/home/cuneyt/MoE/runtime/status/docker-summary.json`.
- Make Gateway read the fixed snapshot file instead of Docker or `docker.sock`.
- Show Docker Summary counts in the Dashboard UI when a snapshot is available.
- Keep missing or invalid snapshots as warnings.
- Preserve read-only Dashboard and Gateway boundaries.

## Milestone 26.9: Dashboard Guarded Actions

Status: PLANNED

Goals:
- Explore explicit, allowlisted, observable dashboard actions.
- Keep service control and real generation guarded.
- Avoid arbitrary shell execution.

## Milestone 27.0: Model Registry and Inventory

Status: DONE

Goals:
- Keep active required coder, embedding, and Flux assets under `/home/cuneyt/MoE_Models_Backup`.
- Document archived inactive models under `/media/cuneyt/Disk2TB/model_backup/MoE_Models_Archive`.
- Ensure `make check-models` fails only for active required models and active required media assets.
- Add source-only model registry and read-only inventory tooling.
- Write generated inventory reports only under `/home/cuneyt/MoE/runtime/reports/models`.

## Milestone 28.1: Gateway Chat Proxy

Status: DONE

Goals:
- Add safe non-streaming `POST /gateway/chat` proxying to llama-server.
- Use `LLAMA_SERVER_BASE_URL` with default `http://host.docker.internal:8000`.
- Return graceful unavailable responses when llama-server is down.
- Keep streaming and richer routing deferred to Milestone 28.2.
- Preserve no shell execution, no Docker control, no model movement, and no runtime switching.

## Milestone 28.2: Gateway Chat Advisory Router

Status: DONE

Goals:
- Add deterministic advisory router metadata to `POST /gateway/chat`.
- Classify chat requests into `fast_code`, `deep_code`, `review_debug`, `architecture`, or `general`.
- Recommend model ids and paths without switching the active llama-server model.
- Report active model and `active_model_matches` when `/v1/models` is reachable.
- Support `routing="off"` for disabled router metadata.
- Preserve no shell execution, no Docker control, no service control, and no model movement.

## Milestone 28.3: Continue.dev Gateway Config and OpenAI-Compatible Gateway Routes

Status: DONE

Goals:
- Add Gateway `GET /v1/models` and `POST /v1/chat/completions`.
- Reuse Gateway chat proxy validation, forwarding, and advisory router metadata.
- Add Continue.dev config guidance for `apiBase: http://localhost:8100/v1`.
- Keep direct llama-server `http://localhost:8000/v1` config as troubleshooting fallback only.
- Keep streaming unsupported, no API key required, no model switching, no shell execution, and no Docker control.

## Milestone 28.4: Gateway Memory Injection

Status: DONE

Goals:
- Add optional search-only memory injection to `/gateway/chat` and `/v1/chat/completions`.
- Support `memory="auto"` and `memory="off"` with bounded `memory_limit`.
- Search the fixed configured `MEMORY_SEARCH_URL` using the latest user message.
- Inject concise bounded system context only when usable memory results exist.
- Return memory metadata in `/gateway/chat` and `x_gateway_memory` for OpenAI-compatible responses.
- Keep memory service failures non-fatal and do not store new memories.
- Preserve no shell execution, no Docker control, no model switching, and no full prompt logging.

## Milestone 28.5: Gateway Feedback Capture

Status: DONE

Goals:
- Add `POST /gateway/feedback` for metadata-only feedback capture.
- Add `GET /gateway/feedback/status` with aggregate status only.
- Store append-only JSONL under `/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl`.
- Validate source, rating, reason length, tag count/length, and id lengths.
- Do not store full prompts or full responses by default.
- Keep feedback capture free of shell execution, Docker control, model switching, and repo runtime writes.

## Milestone 28.6: Feedback Worker Bridge

Status: DONE

Goals:
- Add a safe Feedback Worker Bridge for reading Gateway feedback JSONL.
- Add read-only feedback status and summary behavior.
- Generate aggregate feedback summaries under `/home/cuneyt/MoE/runtime/feedback/reports`.
- Add local feedback summary fallback tooling.
- Keep Gateway feedback append-only.
- Do not store raw prompts or raw model responses in summaries.
- Do not implement training, model switching, Docker control, service control, or shell execution.

## Milestone 28.7: Feedback Sync PC1 to PC2

Status: DONE

Goals:
- Add explicit user-run sync strategy for Gateway feedback from PC1 runtime to PC2 worker runtime.
- Prefer manual `make` target and rsync-style flow first.
- Keep sync observable and non-destructive.
- Do not require always-on shared mounts.
- Do not automatically train, mutate memory, modify prompts, or change router config.
- Keep default tests independent from PC2 availability.

## Milestone 28.8: Reviewed Learning Loop Report

Status: DONE

Goals:
- Add a local reviewed learning loop report generator.
- Read aggregate feedback summaries from `/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json`.
- Write human-reviewable reports under `/home/cuneyt/MoE/runtime/reports/learning-loop`.
- Generate deterministic observations and recommendations from aggregate counts only.
- Set `apply_supported=false` and `human_review_required=true`.
- Do not include raw prompts, raw model responses, or individual feedback records.
- Do not train, fine-tune, mutate memory, modify router config, modify prompts, call Memory API, call Gateway, call llama-server, control Docker, or control services.

## Milestone 28.9: Human-Approved Improvement Plan

Status: DONE

Goals:
- Convert reviewed learning-loop reports into human-reviewable improvement plans.
- Propose router keyword updates, prompt template improvements, docs updates, and test coverage improvements.
- Generate patch-plan style recommendations only.
- Keep `apply_supported=false` by default.
- Require explicit human approval before any code, config, prompt, router, or documentation change.
- Do not automatically modify memory, prompts, router config, model mappings, Docker, services, or model runtime.
- Do not train, fine-tune, download models, switch models, execute shell commands, or control Docker.

## Milestone 29.0: Reviewed Improvement Patch Planner

Status: DONE

Goals:
- Convert human-approved improvement plans into patch-plan style recommendations.
- Generate proposed changes for docs, tests, router keywords, and prompt templates.
- Keep `apply_supported=false` by default.
- Require explicit human approval before any file changes.
- Do not automatically mutate memory, prompts, router config, model mappings, Docker, services, or runtime state.
- Do not train, fine-tune, download models, switch models, execute shell commands, or control Docker.

## Milestone 29.1: Human-Approved Router and Prompt Update Workflow

Status: DONE

Goals:
- Add a local approval packet generator for reviewed router, prompt, docs, tests, and model-routing update candidates.
- Read the reviewed improvement patch plan from `/home/cuneyt/MoE/runtime/reports/patch-plans/reviewed-improvement-patch-plan.json`.
- Write a pending human-review approval packet under `/home/cuneyt/MoE/runtime/reports/approvals`.
- Keep `apply_supported=false` and `human_review_required=true`.
- Separate allowed approval items from blocked memory, ops, unknown, and high-risk items.
- Require explicit human approval before any code, config, prompt, router, documentation, memory, Docker, service, or runtime change.
- Do not automatically edit files, mutate memory, modify router config, update prompts, train, fine-tune, switch models, execute shell commands from apps, control Docker, or control services.

## Milestone 29.2: Feedback-to-Memory Candidate Review

Status: DONE

Goals:
- Add a local feedback-to-memory candidate review generator.
- Read available aggregate feedback, learning-loop, improvement plan, and router/prompt approval runtime reports.
- Write human-reviewable memory candidates under `/home/cuneyt/MoE/runtime/reports/memory-candidates`.
- Keep `candidate_status=pending_human_review`, `memory_write_supported=false`, and `human_review_required=true`.
- Handle missing inputs gracefully with input availability metadata.
- Avoid raw prompts, raw model responses, raw feedback reason bodies, individual feedback records, secrets, credentials, and sensitive data.
- Do not call Memory API, write memory entries, train, fine-tune, mutate memory, modify router config, modify prompt templates, call Gateway, call llama-server, switch models, execute shell commands from apps, control Docker, or depend on PC2.

## Milestone 29.3: Human-Approved Memory Store Workflow

Status: DONE

Goals:
- Add a local memory store plan generator for feedback memory candidates.
- Read `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json`.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json`.
- Support optional human approval file `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json`.
- Keep default mode dry-run and require `APPLY=1` before any Memory API write.
- Store only sanitized approved candidate memory text through `/memory/add`.
- Keep `memory_write_supported=false`, `apply_supported=false`, and `human_review_required=true` in the plan.
- Do not store raw prompts, raw responses, raw feedback reason bodies, individual feedback records, secrets, credentials, or sensitive data.
- Do not automatically train, fine-tune, mutate router config, modify prompts, modify model mappings, switch models, execute shell commands from apps, control Docker, or control services.

## Milestone 29.4: Memory Store Audit and Candidate Dedup Review

Status: DONE

Goals:
- Add a local audit generator for memory store plans.
- Read `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json`.
- Optionally read `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json`.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json`.
- Detect duplicate or near-duplicate candidate groups by normalized category and title.
- Recommend review actions only; never approve, reject, merge, or apply changes automatically.
- Keep `audit_status=review_required`, `memory_write_supported=false`, `apply_supported=false`, and `human_review_required=true`.
- Do not write to Memory API, call Memory API, call Gateway, call llama-server, train, mutate memory, modify router config, modify prompts, switch models, execute shell commands from apps, control Docker, or depend on PC2.

## Milestone 29.5: Human-Approved Memory Store Apply Log

Status: DONE

Goals:
- Add append-only apply logging around approved memory store attempts.
- Keep default mode dry-run and do not log dry-runs unless `LOG_DRY_RUN=1`.
- Append one JSONL entry per approved candidate attempt when `APPLY=1`.
- Write latest summary to `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json`.
- Add `make memory-store-apply-log-status`.
- Keep tests dry-run only and never run `APPLY=1`.
- Do not include raw prompts, raw responses, proposed memory text, full API response bodies, secrets, credentials, or sensitive data.
- Do not train, fine-tune, switch models, mutate router config, modify prompts, control Docker, or control services.

## Milestone 29.6: Memory Candidate Approval File Helper

Status: DONE

Goals:
- Generate a human-editable approval file template from reviewed memory candidates and audit recommendations.
- Keep approval output under `/home/cuneyt/MoE/runtime/reports/memory-store`.
- Require human edits before any candidate is considered approved.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json`.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json`.
- Never create `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json`.
- Add `make memory-candidate-approval-helper-local`, `make memory-candidate-list-local`, and `make test-memory-candidate-approval-helper`.
- Do not call Memory API, Gateway, llama-server, auto-approve candidates, write memories, train, fine-tune, switch models, mutate router config, modify prompts, control Docker, or control services.

## Milestone 29.7: Memory Approval Dry-Run End-to-End Flow

Status: DONE

Goals:
- Add a guided validation flow from candidate review to helper report, manual approval file, plan regeneration, dry-run store, audit, and apply-log status.
- Keep the default path dry-run only.
- Require explicit human-created approval files and explicit `APPLY=1` before any Memory API writes.
- Write `/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json`.
- Add `make memory-approval-dry-run-e2e-local`, `make memory-approval-dry-run-e2e-status`, and `make test-memory-approval-dry-run-e2e`.
- Support `USE_TEST_APPROVAL_FIXTURE=1` for a temporary dry-run-only test approval file, removed by default.
- Never run `APPLY=1`, write to Memory API, auto-approve candidates, call Gateway, call llama-server, train, fine-tune, switch models, mutate router config, modify prompts, control Docker, or control services.

## Milestone 29.8: Memory Approval Dashboard Read-Only View

Status: DONE

Goals:
- Add a read-only dashboard view for memory candidates, helper report, audit summary, dry-run E2E report, and apply-log status.
- Keep the dashboard read-only with no approval, apply, Memory API write, service control, shell execution, Docker control, model switching, training, or fine-tuning actions.
- Continue keeping generated reports under `/home/cuneyt/MoE/runtime`.
- Add `GET /gateway/memory-approval/dashboard`.
- Add Dashboard UI Memory Approval section with compact counts, candidates, duplicate groups, warnings, approval file status, apply-log status, and E2E status.
- Add `make test-memory-approval-dashboard`.
- Do not accept arbitrary paths, execute scripts, call Memory API, call llama-server, auto-approve candidates, create approval files, or write memories.

## Milestone 29.9: Memory Approval Manual Store Runbook

Status: DONE

Goals:
- Add a human-run manual store runbook for the approved memory workflow.
- Keep the runbook dry-run-first and explicit about `APPLY=1` risk.
- Require human-created approval files, plan inspection, dashboard review, apply-log review, and post-run verification.
- Add `make memory-store-manual-preflight` and `make test-memory-store-manual-preflight`.
- Keep tests dry-run-only and never run `APPLY=1`.
- Do not add automated approval, Memory API write tests, service control, shell execution from apps, Docker control, model switching, training, or fine-tuning.

## Milestone 29.10: Memory Store Real Apply Guardrail Review

Status: DONE

Goals:
- Review the human-operated real apply guardrails before any future refinement of the approved memory store path.
- Add a read-only `make memory-store-real-apply-guardrail` check before the `APPLY=1` write path.
- Keep real writes manual only through explicit user-run `APPLY=1 make memory-store-approved`.
- Do not run `APPLY=1` automatically from tests, preflight, dashboard, apps, or scheduled workflows.
- Reject test fixtures, `dry_run_only=true` approval files, missing approved candidates, and raw prompt/response markers before Memory API writes.
- Warn on batch apply with more than one approved candidate unless `ALLOW_BATCH_MEMORY_APPLY=1` is set; this flag only silences the batch warning and does not bypass FAIL checks.
- Do not add automated approval, Memory API write tests, service control, shell execution from apps, Docker control, model switching, training, or fine-tuning.

## Milestone 29.11: Gateway Continue Compatibility Hardening

Status: DONE

Goals:
- Harden Gateway compatibility for Continue and OpenAI-compatible clients.
- Normalize stream and tool payload handling without enabling unsupported write actions.
- Return consistent JSON error bodies for Continue-facing Gateway failures.
- Accept `stream`, `tools`, `tool_choice`, `parallel_tool_calls`, `response_format`, `stop`, penalties, `top_p`, `n`, and `user` in `/v1/chat/completions`.
- Support `stream=true` with a minimal OpenAI-compatible SSE wrapper over the existing non-streaming internal model call and return `x_gateway_compat`.
- Keep SSE support as compatibility streaming, not true token-by-token runtime streaming.
- Ignore Continue/OpenAI tool payloads safely; never execute tools from these payloads.
- Keep Gateway from writing files, executing shell commands, switching models, calling Memory API write routes, controlling Docker, or mutating runtime state automatically.

## Milestone 29.12: Gateway-Auto Runtime Routing Hardening

Status: DONE

Goals:
- Harden `gateway-auto` runtime routing behavior for Continue and OpenAI-compatible clients.
- Keep runtime routing advisory unless a future reviewed milestone explicitly adds guarded switching.
- Improve model alignment metadata and mismatch handling for active llama-server models.
- Add advisory-only switch support/attempt flags, mismatch level/reason fields, `effective_runtime_model`, `continue_safe`, and safe next steps to Gateway router metadata.
- Keep fallback mapping safe when a selected model target is missing from model routing config.
- Do not switch models, execute shell commands, control Docker, write files, call Memory API write routes, train, or fine-tune automatically.

## Milestone 29.13: Gateway Runtime Switch Plan Guardrail

Status: DONE

Goals:
- Plan guardrails for any future Gateway runtime switch flow without adding automatic switching.
- Keep runtime switch output advisory and human-reviewed unless a later guarded milestone explicitly changes behavior.
- Return `status=plan_only`, explicit false apply/auto-execution/switch flags, guardrails, preflight checks, and natural-language next steps.
- Do not return executable command fields from `/gateway/runtime/switch-plan`.
- Do not switch models, start or stop services, execute shell commands, control Docker, write files, call Memory API write routes, train, or fine-tune automatically.

## Milestone 29.14: Gateway Runtime Runbook Integration

Status: DONE

Goals:
- Integrate Gateway runtime switch planning with documentation and runbook references only.
- Keep runbook integration informational and human-operated.
- Do not add automatic model switching, service control, shell execution, Docker control, file writes, Memory API write calls, training, or fine-tuning.

## Milestone 29.15: Runtime Profile Preflight

Status: DONE

Goals:
- Validate runtime profile readiness without switching models.
- Keep checks source/runtime-read-only unless a future guarded milestone explicitly changes behavior.
- Do not start, stop, restart, or switch model runtimes automatically.
- Report missing model files as warnings and review-required status instead of downloading or fixing them automatically.

## Milestone 29.16: Runtime Profile Run Command Catalog

Status: DONE

Goals:
- Catalog documented runtime profile run instructions for human operators.
- Keep the catalog documentation-only and non-executable.
- Do not start, stop, restart, or switch model runtimes automatically.

## Milestone 29.17: Runtime Profile Compatibility Matrix

Status: DONE

Goals:
- Validate runtime profile compatibility metadata in a read-only way.
- Keep compatibility checks documentation/validation only.
- Do not start, stop, restart, or switch model runtimes automatically.
- Use static PC-1 hardware assumptions unless a future telemetry milestone explicitly changes behavior.

## Milestone 29.18: Runtime Profile Recommendation Summary

Status: DONE

Goals:
- Summarize runtime profile recommendations in a read-only advisory way.
- Keep recommendations documentation-only unless a future guarded milestone explicitly changes behavior.
- Do not start, stop, restart, or switch model runtimes automatically.

## Milestone 29.19: Gateway Runtime Profile Dashboard Summary

Status: DONE

Goals:
- Expose runtime profile recommendation summary in dashboard/read-only UI only.
- Keep dashboard integration read-only and advisory.
- Do not start, stop, restart, or switch model runtimes automatically.

## Milestone 29.20: Runtime Profile Operator Checklist Export

Status: DONE

Goals:
- Export runtime profile operator checklist content for human review.
- Keep export documentation-only and non-executable.
- Do not start, stop, restart, or switch model runtimes automatically.

## Milestone 29.21: Runtime Profile Decision Audit Snapshot

Status: PLANNED

Goals:
- Provide a read-only runtime profile decision audit snapshot.
- Do not write runtime files unless a later milestone explicitly adds a guarded approval flow.
- Do not start, stop, restart, or switch model runtimes automatically.

## Milestone 30.0: Operator Runbook Pack

Status: DONE

Goals:
- Add beginner-friendly operator runbooks under `docs/ops/`.
- Explain PC-1 and PC-2 roles, service ports, Docker services, llama-server, Gateway, Memory API, Embed Worker, Postgres, Qdrant, and Continue.
- Document fresh install, daily startup, daily shutdown, backup, restore, troubleshooting, command cheatsheet, Git workflow, and runtime profile guide.
- Keep the pack documentation-only and source-only.
- Emphasize verify-first operation and manual-only runtime actions.

## Milestone 30.1: Operator Runbook Walkthrough QA

Status: DONE

Goals:
- Add scenario-based first-day operator walkthrough docs under `docs/ops/`.
- Add a compact zero-to-running checklist with exact machine, directory, command, expected good sign, and fallback doc links.
- Add service location reference so beginners know which machine owns Gateway, llama-server, Memory API, Embed Worker, Postgres, Qdrant, Continue, models, and Git commands.
- Improve troubleshooting into symptom, likely cause, first check, fallback action, and related doc format.
- Keep the milestone documentation-only with no runtime behavior changes.

## Milestone 30.2: Backup / Restore Drill Documentation

Status: DONE

Goals:
- Add a beginner-friendly backup/restore drill under `docs/ops/14-backup-restore-drill.md`.
- Prove backups can be copied, inspected, restored into a temporary test folder, and compared without deleting or overwriting live source.
- Add a one-page emergency card under `docs/ops/15-disaster-recovery-card.md`.
- Keep the milestone documentation-only with no runtime behavior, app code, or Docker Compose changes.

## Milestone 30.3: PC-1 / PC-2 Startup Service Matrix

Status: DONE

Goals:
- Add startup service matrix documentation for coding, review/debug, memory/database, image generation, media placeholder, backup, restore, and troubleshooting modes.
- Add copy/paste friendly mode startup recipes.
- Add image mode entry checklist for readiness-only transition from coding mode to future media work.
- Keep the milestone documentation-only with no runtime behavior, app code, Docker Compose, automatic model switching, or automatic image generation changes.

## Milestone 30.4: Media / Image Runtime Readiness Map

Status: DONE

Goals:
- Add media/image readiness map documentation for PC-1 GPU/media work.
- Add image mode safety rules before real image generation.
- Add image pipeline entry plan for M31.0.
- Keep the milestone documentation-only with no runtime behavior, app code, Docker Compose, automatic model switching, or automatic image generation changes.

## Milestone 30.5: Hardware Role Profiles / Environment Reassignment

Status: PLANNED

Goals:
- Add environment role profile plan for PC1, PC2, single-machine, and new-machine setups.
- Allow future hardware changes without rewriting the project.
- Document role reassignment for model runtime, Memory API, PostgreSQL, Qdrant, Dashboard, Gateway, workers, and media services.
- Document how to update IPs, paths, and model defaults.
- Document current PC1 and PC2 ownership assumptions.

## Milestone 31.0: Image Processing Pipeline Runbook

Status: DONE

Goals:
- Add beginner-friendly image processing pipeline runbook.
- Add image model inventory guide.
- Add first dry-run planning guide without real generation commands.
- Keep real generation explicit and reserved for M31.1 or later.
- Preserve coding-mode recovery steps and GPU/VRAM safety notes.

## Milestone 31.1: ComfyUI / Flux Startup Checklist

Status: DONE

Goals:
- Add exact ComfyUI / Flux startup readiness checklist.
- Add plain-language blocker guide.
- Add copy/paste evidence template for operator review before real image generation.
- Keep startup operator-reviewed and explicit with no real generation commands.

## Milestone 31.2: Image Mode VRAM Safety / LLM Stop Plan

Status: DONE

Goals:
- Add image mode VRAM safety guide.
- Add manual llama-server stop/start plan for image mode transitions.
- Add return-to-coding checklist after image mode.
- Keep all stop/start actions explicit and operator-reviewed.
- Do not add automatic model switching or automatic image generation.

## Milestone 31.3: First Image Dry Run Evidence Review

Status: DONE

Goals:
- Add first-image dry-run evidence collection guide.
- Add first-image dry-run evidence template.
- Add first-image dry-run review checklist for human/Codex review before M31.4.
- Keep review documentation-only with no real generation commands.

## Milestone 31.3.1: Image Mode Safety Alignment

Status: DONE

Goals:
- Align image-mode scripts with operator safety rules.
- Replace direct `pkill` stop behavior in image mode preparation with `make model-stop` and `make model-status`.
- Add existing image/media script map before M31.4.
- Keep Gateway out of shell execution and automatic llama-server control.

## Milestone 31.4: First Real Image Generation Drill

Status: DONE

Goals:
- Add the first controlled real image generation drill runbook.
- Add post-drill evidence template.
- Add generated image Git safety guidance.
- Keep real generation explicit, guarded, and operator-approved.
- Preserve return-to-coding and VRAM safety checks.

## Milestone 31.5: Generated Image Output Handling / Git Safety

Status: DONE

Goals:
- Document generated image output locations and Git safety checks.
- Keep generated media out of source control.
- Preserve runtime/source separation for image outputs.
- Add beginner-friendly output inspection, archive, metadata-recording, and cleanup policy docs.

## Milestone 31.6: ComfyUI Workflow Inventory

Status: DONE

Goals:
- Inventory existing ComfyUI workflows.
- Document workflow inputs, outputs, models, and safety gates.
- Keep workflow execution explicit and operator-approved.
- Add beginner-friendly Flux Schnell parameter guidance and a manual workflow change log template.

## Milestone 31.7: Gateway Real Image Run Drill

Status: DONE

Goals:
- Add a Gateway-facing real image run drill after workflow inventory review.
- Keep real generation explicitly operator-approved.
- Preserve Gateway safety boundaries: no shell execution, no Docker control, no automatic model switching, and no automatic generation.
- Add evidence and troubleshooting templates for the guarded Gateway/media image path.

## Milestone 31.8: Prompt Variants / Batch Image Plan

Status: DONE

Goals:
- Plan safe prompt variant and batch image experiments after the Gateway real image run drill.
- Keep batch generation operator-reviewed and explicitly gated.
- Preserve generated output, model, and Git safety boundaries.
- Add prompt variant planning, small batch safety, image comparison notes, and output naming policy docs.

## Milestone 31.9: Media Dashboard Output Review

Status: DONE

Goals:
- Review how generated image outputs are surfaced in the media dashboard.
- Keep dashboard output review read-only.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.
- Document `latest_images` fields and add a dashboard output review template.

## Milestone 32.0: Controlled Prompt Variant Generation

Status: DONE

Goals:
- Add controlled prompt variant generation after planning and dashboard output review.
- Keep generation explicitly operator-approved and guarded.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.
- Add a dry-run helper plan, run templates, session evidence template, and stop conditions.

## Milestone 32.1: Media Dashboard UI Output Cards

Status: PLANNED

Goals:
- Plan dashboard UI output cards for generated media review.
- Keep dashboard output cards read-only.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 32.2: Prompt Variant Result Review

Status: DONE

Goals:
- Review controlled prompt variant results after operator-run generation.
- Keep review documentation and dashboard references read-only.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.
- Record the first controlled 3-variant result set and fix Git binary safety checks to be extension-anchored.

## Milestone 32.3: Prompt Quality Improvement Plan

Status: DONE

Goals:
- Plan prompt quality improvements from reviewed controlled variant results.
- Keep improvement planning documentation-only until a separate guarded generation milestone.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.
- Add next pergola prompt set, negative prompt notes, and prompt quality review template.

## Milestone 32.4: Improved Prompt Controlled Run Result Review

Status: DONE

Goals:
- Review the manually executed improved prompt controlled run.
- Record result notes, VRAM observations, dashboard visibility, shutdown, and coding restore.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 32.5: Pergola Project-Specific Prompt Pack

Status: DONE

Goals:
- Build a project-specific pergola prompt pack after improved prompt review.
- Keep prompt pack documentation-only until a separate guarded generation milestone.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 32.6: Technical Detail Image Run Result Review

Status: DONE

Goals:
- Review the manually executed project-specific pergola image run.
- Record project overview, rain protection, and technical close-up outputs.
- Capture lessons for image selection and future technical drawing prompts.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 32.7: Pergola Image Selection / Reference Board

Status: DONE

Goals:
- Review generated pergola images and select reference candidates.
- Keep selected evidence as notes and external paths, not committed binaries.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 32.8: Real Pergola Technical Drawing Prompt Pack

Status: DONE

Goals:
- Prepare prompts for more drawing-like pergola technical references.
- Keep generated-image references separate from validated engineering drawings.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 32.9: Pergola Usta Package Plan

Status: PLANNED

Goals:
- Prepare a carpenter/usta-friendly package using measurements, materials, and selected visual references.
- Keep AI-generated images as visual intent only, not build plans.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 32.10: Video Generation Service

Status: PLANNED

Goals:
- Support CogVideoX-style video and image-to-video workflows.
- Use queued jobs.
- Store outputs under the runtime media directory.

## Milestone 33.0: Technical Drawing Controlled Run

Status: DONE

Goals:
- Run selected technical drawing prompts through the guarded operator-controlled path.
- Review drawing-like outputs as visual communication only.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.1: Technical Drawing Controlled Run Result Review

Status: DONE

Goals:
- Review the manually executed first technical drawing controlled run.
- Record drawing-like outputs, limitations, and prompt lessons.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.2: Simplified Technical Drawing Controlled Run Result Review

Status: DONE

Goals:
- Review the manually executed simplified technical drawing controlled run.
- Record side elevation, top plan, and beam-post schematic outputs.
- Capture the geometry-only CAD-style prompt strategy.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.3: Geometry-only CAD-style Drawing Run

Status: DONE

Goals:
- Run geometry-only CAD-style drawing prompts through the guarded operator-controlled path.
- Avoid labels, dimensions, perspective, 3D, shading, and texture during generation.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.4: Deterministic Pergola Drawing Plan

Status: DONE

Goals:
- Review geometry-only CAD-style image results.
- Decide to move measured technical drawings to deterministic code-generated SVG/DXF-style geometry.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.5: SVG Drawing Tool Skeleton

Status: DONE

Goals:
- Create the first source-only SVG drawing generator skeleton.
- Default generated drawing outputs to runtime.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.6: Side Elevation + Top Plan SVG

Status: DONE

Goals:
- Generate deterministic side elevation and top plan SVG drawings.
- Use millimeter-based geometry and reviewed labels.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.7: Beam-post + Roof Sheet SVG Details

Status: PLANNED

Goals:
- Generate deterministic beam-post and roof sheet SVG detail drawings.
- Keep structural details marked as placeholders pending manual review.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.8: PDF Export Plan

Status: PLANNED

Goals:
- Plan SVG-to-PDF export for reviewed deterministic pergola drawings.
- Keep generated PDF outputs under runtime by default.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 33.9: 3D Model Generation Pipeline

Status: PLANNED

Goals:
- Start with parametric Blender Python generation.
- Export `.blend`, `.glb`, and `.obj`.
- Support technical structures such as pergola.

## Milestone 34.0: Generic Image + Architecture Drawing Roadmap

Status: DONE

Goals:
- Reframe pergola as the first media/drawing case study.
- Define generic image, architecture concept, deterministic drawing, dashboard, and reference-board tracks.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.1: Generic Prompt Pack Structure

Status: DONE

Goals:
- Define reusable generic prompt pack folders and templates.
- Support architecture, product, outdoor, technical reference, and marketing visual categories.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.2: Generic Drawing Engine Skeleton

Status: DONE

Goals:
- Plan or create the first generic drawing-engine structure.
- Create reusable SVG primitive helpers without moving the pergola prototype.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.3: Media Dashboard Output Cards Plan

Status: DONE

Goals:
- Plan dashboard output cards for generated images, prompts, metadata, paths, and reference-board selection.
- Keep dashboard behavior read-only unless explicitly changed.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.4: Prompt Metadata Capture Plan

Status: DONE

Goals:
- Plan safe prompt and output metadata capture.
- Define runtime sidecar metadata strategy for images and drawings.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.5: Output Cards API Implementation

Status: DONE

Goals:
- Implement a read-only output cards API for allowlisted runtime folders.
- Do not trigger generation or expose arbitrary filesystem browsing.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.6: Dashboard Output Cards UI

Status: DONE

Goals:
- Implement read-only dashboard output cards.
- Avoid destructive actions, generation buttons, and shell controls.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.7: Metadata Sidecar Implementation

Status: DONE

Goals:
- Implement runtime sidecar metadata writing for deterministic SVG drawing outputs.
- Do not store secrets, API keys, or arbitrary shell history.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.7.1: Drawing Runtime Volumes Fix

Status: DONE

Goals:
- Mount deterministic drawing runtime folders read-only into Gateway.
- Let output cards discover `drawing_svg` cards and metadata sidecars inside the container.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.8: Reference Board Selection Plan

Status: DONE

Goals:
- Plan safe reference-board selection on top of output cards.
- Keep selection metadata read-only until a later explicit implementation milestone.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.9: Output Card Preview Serving Plan

Status: DONE

Goals:
- Plan safe preview serving for output cards.
- Avoid arbitrary filesystem browsing and runtime mutation.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.10: Image Generation Metadata Sidecars

Status: DONE

Goals:
- Plan and implement image generation metadata sidecars after drawing sidecars are stable.
- Do not alter generation safety gates.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.11: Reference Board API Implementation

Status: DONE

Goals:
- Implement safe reference-board JSON API under runtime.
- Validate selected assets against output cards.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.12: Reference Board UI Implementation

Status: DONE

Goals:
- Implement dashboard reference-board selection UI.
- Avoid generation buttons, arbitrary file pickers, shell actions, and asset mutation.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.12.1: Reference Board UI CORS + Unique Card Keys Fix

Status: DONE

Goals:
- Fix dashboard reference-board CORS behavior and duplicate card key warnings.
- Keep reference-board UI behavior safe and board-id based.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.13: Output Preview API Implementation

Status: DONE

Goals:
- Implement safe card-id based output preview serving.
- Keep SVG preview unavailable and avoid arbitrary path access.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.14: Dashboard Preview UI Implementation

Status: DONE

Goals:
- Show image previews through the safe output preview API.
- Keep drawing/SVG cards on placeholder UI.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.15: Output Card Metadata Detail Drawer

Status: DONE

Goals:
- Add dashboard metadata detail review for output cards.
- Keep metadata viewing read-only and card-id based.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.16: Reference Board Safe Runtime Store

Status: DONE

Goals:
- Store reference board review metadata under runtime.
- Keep source assets in their original runtime locations.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.17: Reference Board Item Selection API

Status: DONE

Goals:
- Add safe API support for adding output card references to boards.
- Use stable ids and avoid arbitrary filesystem input.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.18: Reference Board Output Card Integration

Status: PLANNED

Goals:
- Plan deeper output-card integration for reference board workflows.
- Keep selection/review behavior separate from asset mutation.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.19: Reference Board Detail View

Status: DONE

Goals:
- Improve dashboard reference board detail review.
- Keep board item inspection read-only except explicit review metadata edits.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.20: Reference Board Export Plan

Status: DONE

Goals:
- Plan JSON and Markdown reference board review exports.
- Keep exports response-only and avoid runtime export files.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.21: Reference Board Selected Reason Edit

Status: DONE

Goals:
- Support editing selected reasons and tags for board items.
- Keep edits limited to reference board review metadata.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.22: Reference Board Compare View

Status: PLANNED

Goals:
- Plan a future compare view for selected board items.
- Keep comparison read-only and avoid asset mutation.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.23: Reference Board JSON Export Implementation

Status: DONE

Goals:
- Implement JSON reference board review export.
- Keep export response-only and avoid source asset copying.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.24: Reference Board Markdown Export Implementation

Status: DONE

Goals:
- Implement Markdown reference board review export.
- Keep export response-only and avoid runtime export files.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.25: Reference Board Export UI

Status: DONE

Goals:
- Add dashboard UI for read-only JSON and Markdown export panels.
- Keep export actions separate from download, approve, delete, move, and generate actions.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.26: Reference Board Export Download Plan

Status: DONE

Goals:
- Plan safe JSON and Markdown download endpoints.
- Keep downloads response-only and avoid source asset bundles.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.27: Reference Board Markdown Download Implementation

Status: DONE

Goals:
- Implement Markdown attachment download for reference board review.
- Keep download content safe and response-only.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.28: Reference Board JSON Download Implementation

Status: DONE

Goals:
- Implement JSON attachment download for reference board review.
- Keep download content safe and response-only.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.29: Reference Board Download UI

Status: DONE

Goals:
- Add dashboard download controls for reference board review artifacts.
- Avoid approve, delete, move, rename, generate, ZIP, or PDF actions.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.30: Reference Board Export Regression Review

Status: DONE

Goals:
- Add regression review coverage for reference board export and download behavior.
- Verify safe response-only exports and no runtime export files.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.31: Reference Board Export Polish

Status: DONE

Goals:
- Polish dashboard export/download grouping and copy feedback.
- Keep export UI read-only and avoid destructive actions.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.32: Reference Board Workflow Summary

Status: DONE

Goals:
- Summarize the reference board workflow and operator review path.
- Keep source/runtime/model boundaries explicit.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.33: Reference Board Hardening Plan

Status: DONE

Goals:
- Plan reference board validation, runtime-store, export/download, and dashboard hardening.
- Keep hardening changes milestone-scoped and safety-first.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.34: Reference Board Error Handling Polish

Status: DONE

Goals:
- Standardize safe Gateway and dashboard reference board error behavior.
- Avoid tracebacks, host path leaks, and raw internal exceptions.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.35: Reference Board Validation Limits

Status: DONE

Goals:
- Add explicit validation limits for board ids, titles, descriptions, reasons, and tags.
- Keep invalid payload errors controlled and operator-readable.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.36: Reference Board Malformed Store Regression

Status: DONE

Goals:
- Add regression coverage for malformed runtime board JSON files.
- Verify controlled errors and cleanup of the temporary malformed test file.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.37: Reference Board Store Repair Plan

Status: DONE

Goals:
- Plan safe operator repair workflows for reference board runtime store issues.
- Keep repair planning separate from source asset mutation and generation.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.38: Reference Board Store Backup Plan

Status: DONE

Goals:
- Plan safe backup behavior for reference board JSON files before repair tooling.
- Keep backup scope limited to board review metadata.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.39: Reference Board Store Repair CLI Plan

Status: DONE

Goals:
- Plan the future validate, backup, and repair CLI contract.
- Keep dry-run defaults, APPLY gates, backup requirements, and reporting explicit.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.40: Reference Board Store Validate CLI Implementation

Status: DONE

Goals:
- Implement read-only validation for reference board runtime JSON files.
- Write a local validation report without modifying board files or source assets.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.41: Reference Board Store Backup CLI Implementation

Status: DONE

Goals:
- Implement safe single-board backup for reference board runtime JSON files.
- Require a safe board id and avoid source asset or metadata sidecar copying.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.42: Reference Board Store Repair CLI Implementation

Status: DONE

Goals:
- Implement guarded `repair-schema` mode with dry-run default.
- Require `APPLY=1` and an existing backup before modifying a board file.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.43: Reference Board Store Repair Regression

Status: DONE

Goals:
- Add regression coverage for validate, backup, and guarded repair-schema flows.
- Keep repair regression scoped to safe runtime test fixtures.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.44: Reference Board Duplicate Item Repair Plan

Status: DONE

Goals:
- Plan duplicate item repair behavior before implementing deletion or mutation.
- Keep item deletion and stale item handling out of scope until explicitly approved.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.45: Reference Board Stale Item Handling Plan

Status: DONE

Goals:
- Plan stale item handling before implementing mutation.
- Keep stale item deletion and source asset recreation out of scope until explicitly approved.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.46: Reference Board Duplicate Item Repair Implementation

Status: DONE

Goals:
- Implement duplicate item repair only after preserve-first behavior and conflict handling are reviewed.
- Keep source assets, metadata sidecars, output cards, and generation out of scope.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.47: Reference Board Duplicate Item Repair Regression

Status: DONE

Goals:
- Add regression coverage for duplicate item detection, dry-run reporting, backup gating, and `APPLY=1` removal.
- Keep regression fixtures scoped to controlled runtime test boards.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.48: Reference Board Stale Item Marking Implementation

Status: DONE

Goals:
- Implement guarded `mark-stale-items` repair mode with dry-run default.
- Keep stale item deletion, source asset recreation, and metadata invention out of scope.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.49: Reference Board Stale Item Regression

Status: DONE

Goals:
- Add regression coverage for stale item marking behavior.
- Keep stale item regression scoped to controlled runtime test fixtures.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.50: Reference Board Repair CLI Operator Runbook

Status: PLANNED

Goals:
- Document the operator sequence for validate, backup, dry-run repair, apply, and post-repair validation.
- Keep repair operations board-scoped and explicit.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 34.51: Reference Board Repair CLI Summary Review

Status: PLANNED

Goals:
- Summarize validate, backup, schema repair, duplicate repair, and stale marking coverage.
- Identify remaining operator hardening gaps after repair regressions.
- Preserve generated output, model, Git, Gateway, and Docker safety boundaries.

## Milestone 35.0: Rigging Pipeline

Status: PLANNED

Goals:
- Add basic Blender rig and armature pipeline.
- Start with mechanical and object rigs before character rigs.

## Milestone 36.0: Animation Pipeline

Status: PLANNED

Goals:
- Convert text requests into keyframe plans.
- Support Blender camera and object animation.
- Render preview outputs.

## Milestone 37.0: Media Workflow Orchestrator

Status: PLANNED

Goals:
- Chain image, video, 3D, rig, and animation jobs.
- Add workflow status and asset tracking.
- Keep generated assets under runtime media storage.

## Future Homelab Ops

Status: PLANNED

Goals:
- Add homelab operations support such as Tailscale and always-on access patterns.
- Add container management visibility with tools such as Portainer or Arcane.
- Prepare safe remote monitoring and maintenance.
- Keep operational access explicit and documented.
