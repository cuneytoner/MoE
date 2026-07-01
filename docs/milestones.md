# MoE / AI-Brain-OS Milestones

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
- Expose Gateway switch-plan endpoint that returns manual commands only.
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

Status: IN PROGRESS

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

## Milestone 27: Video Generation Service

Status: PLANNED

Goals:
- Support CogVideoX-style video and image-to-video workflows.
- Use queued jobs.
- Store outputs under the runtime media directory.

## Milestone 28: 3D Model Generation Pipeline

Status: PLANNED

Goals:
- Start with parametric Blender Python generation.
- Export `.blend`, `.glb`, and `.obj`.
- Support technical structures such as pergola.

## Milestone 29: Rigging Pipeline

Status: PLANNED

Goals:
- Add basic Blender rig and armature pipeline.
- Start with mechanical and object rigs before character rigs.

## Milestone 30: Animation Pipeline

Status: PLANNED

Goals:
- Convert text requests into keyframe plans.
- Support Blender camera and object animation.
- Render preview outputs.

## Milestone 31: Media Workflow Orchestrator

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
