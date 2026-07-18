# MoE / AI-Brain-OS Architecture

## Goal

A local multi-PC AI system for coding, memory, routing, monitoring, and future agent workflows.

The system is designed around a strict separation between source code and runtime state.

Source code lives only in:

/home/cuneyt/DiskD/Projects/MoE/codebase

Runtime environments live in:

/home/cuneyt/MoE

## PC1

Role:

- Main workstation
- Source code owner
- Codex and Continue workspace
- Strong GPU inference node
- Deployment controller
- Dashboard access point
- Gateway API
- Model runtime
- Workspace context
- Media Lab GPU workloads

Specs:

- Ryzen 7 7700X3D
- RTX 5060 Ti
- 32 GB RAM
- IP: 192.168.50.1

Paths:

- Source: /home/cuneyt/DiskD/Projects/MoE/codebase
- Runtime: /home/cuneyt/MoE

## PC2

Role:

- Runtime worker node
- Memory services
- Database services
- Future worker and fallback services
- PostgreSQL/Qdrant optional migration target
- Nightly Learning Worker
- Research Ingestion Worker
- Report generation
- Backup and maintenance jobs
- Telemetry source

Specs:

- Ryzen 3 3100
- GTX 1650
- 32 GB RAM
- IP: 192.168.50.2

Path:

- Runtime: /home/cuneyt/MoE

## Network

PC1 and PC2 are connected over Cat5 direct network.

SSH:

- User: cuneyt
- Passwordless SSH is expected from PC1 to PC2.

## High-Level Components

apps/gateway-api:

Central API and router entrypoint. It exposes Gateway health, model discovery, runtime status, safe runtime switch plans, chat proxying to the local OpenAI-compatible runtime, optional memory-augmented chat through Memory API search, deterministic intent-aware route decisions, router-aware chat prompt shaping, advisory model mapping metadata, advisory tool planning metadata, and controlled read-only tool execution for internal HTTP checks.

The Gateway routing flow is:

- classify intent with the deterministic router
- map intent to an advisory model target
- attach an advisory tool plan
- execute only already-supported safe paths such as model chat and optional memory search
- execute allowlisted read-only internal status tools when explicitly requested

The controlled tool execution layer has hard safety gates:

- tools must be explicitly marked `executable: true`
- tools must be explicitly marked `read_only: true`
- shell command suggestions are never executed by Gateway
- Docker checks are advisory and are not run by Gateway
- runtime switch plans remain manual and are not executed by Gateway

Future broader tool execution must remain gated, explicit, observable, and reversible.

apps/memory-api:

Memory storage and search API. It will store memory metadata in PostgreSQL and vector embeddings in Qdrant.

apps/embed-worker:

Embedding generation worker. It will create vectors from text using local embedding models.

The embedding layer now has two planning concerns:

- runtime backend support for local models such as BGE-M3
- model integrity validation so local mounts and files are trustworthy before other layers depend on them

Host model runtime:

Host-managed llama.cpp serving layer for local GGUF chat and coding models. It exposes an OpenAI-compatible endpoint at `http://localhost:8000/v1`, with model files loaded from `/home/cuneyt/MoE_Models_Backup` and runtime logs/pids stored under `/home/cuneyt/MoE/runtime`.

Milestone 28.1 adds a minimal Gateway chat proxy at `/gateway/chat`. It accepts OpenAI-like non-streaming chat messages, forwards them to `LLAMA_SERVER_BASE_URL/v1/chat/completions`, returns a compact Gateway response, and reports graceful `status: unavailable` responses when llama-server is down. It does not require an API key, stream responses, execute shell commands, control Docker, read workspace files, switch models, or start services. Richer routing is reserved for Milestone 28.2.

Milestone 28.2 adds deterministic advisory model routing metadata to the same endpoint. Gateway classifies chat requests into `fast_code`, `deep_code`, `review_debug`, `architecture`, or `general`, selects an advisory model id/path, compares it with the active llama-server model from `/v1/models` when available, and returns mismatch information without failing. The router never switches models or controls services.

Milestone 28.3 adds OpenAI-compatible Gateway routes at `/v1/models` and `/v1/chat/completions` so Continue.dev can point to `http://localhost:8100/v1`. These routes proxy the local llama-server runtime, reuse Gateway chat validation and advisory router metadata, and initially keep streaming unsupported.

Milestone 29.11 hardens Continue compatibility for `/v1/chat/completions`. Gateway accepts Continue/OpenAI stream and tool payload fields, wraps `stream: true` responses as minimal OpenAI-compatible SSE chunks after one internal non-streaming model call, returns `x_gateway_compat`, and ignores `tools` / `tool_choice` safely. This is compatibility streaming, not true token-by-token runtime streaming. It still does not execute tools from Continue/OpenAI payloads, execute shell commands, control Docker, switch models, write files, or call Memory API write routes.

Milestone 29.12 hardens Gateway-Auto runtime routing metadata while keeping routing advisory-only. `x_gateway_router` reports `routing_mode=advisory_only`, switch support/attempt flags set to false, active runtime mismatch level/reason, `effective_runtime_model`, `continue_safe=true`, and safe next steps. Gateway reports mismatches clearly but never switches models automatically; any real switching would require a separate guarded milestone.

Milestone 29.13 hardens `/gateway/runtime/switch-plan` as a planning-only guardrail. The endpoint returns `status=plan_only`, explicit false apply/auto-execution/switch flags, safety guardrails, preflight checks, and natural-language next steps without executable command fields. Gateway still does not start, stop, restart, or switch runtime models automatically.

Milestone 29.14 links runtime switch plans to `docs/gateway-runtime-switch-runbook.md`. These runbook references are documentation only; Gateway still does not switch models, and future real guarded switching remains separate future work.

Milestone 29.15 adds a read-only runtime profile preflight. Gateway checks model routing mappings, configured runtime model ids, local file existence for path-like model ids, and active runtime metadata without switching models or downloading missing files.

Milestone 29.16 adds a documentation-only runtime profile run catalog. Gateway exposes configured model paths and run settings for human review, but it does not execute host scripts, switch models, control Docker, or mutate runtime state.

Milestone 29.17 adds a read-only runtime profile compatibility matrix for static PC-1 hardware assumptions. The matrix is advisory only; Gateway does not inspect live GPU state, execute scripts, switch models, or mutate runtime state.

Milestone 29.18 adds a read-only runtime profile recommendation summary. Gateway combines existing preflight, catalog, and matrix data into default/review/fallback recommendations for human review without executing scripts, switching models, or inspecting live GPU state.

Milestone 29.19 surfaces runtime profile recommendations in dashboard/read-only form. Gateway adds a compact profile summary endpoint and embeds the same summary in `/gateway/runtime/dashboard`; the Dashboard UI displays it as a visibility-only card with no action buttons.

Milestone 29.20 adds a read-only runtime profile operator checklist export. Gateway returns manual review checklist items for human operators without executing scripts, switching models, writing files, or mutating runtime state.

Milestone 28.4 adds optional search-only memory injection to `/gateway/chat` and `/v1/chat/completions`. Gateway extracts the latest user message, calls the fixed configured `MEMORY_SEARCH_URL`, injects a bounded system context only when usable results exist, and returns memory metadata without storing new memory or exposing raw memory records in response metadata. Chat remains available when memory search is unavailable.

Milestone 28.5 adds `POST /gateway/feedback` and `GET /gateway/feedback/status` for metadata-only feedback capture. Gateway appends allowlisted rating metadata to `/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl`, keeps full prompts and responses out of the record schema, and exposes only aggregate status for reads.

Milestone 28.6 adds a Feedback Worker Bridge that reads the Gateway feedback JSONL path from `FEEDBACK_JSONL_PATH` and writes aggregate-only summaries to `FEEDBACK_SUMMARY_PATH`, defaulting to `/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json`. It counts ratings, sources, router intents, models, tags, malformed lines, and latest timestamps without including full reason text, raw prompts, raw responses, or full feedback records. If PC2 cannot see PC1's runtime path directly, the expected strategy is a manual copy or sync of the JSONL file into PC2 runtime before summarization.

Milestone 28.7 adds explicit user-run feedback sync tooling from PC1 to PC2. `make feedback-sync-to-pc2` is dry-run by default and `APPLY=1 make feedback-sync-to-pc2` copies only `gateway-feedback.jsonl` plus `reports/feedback-summary.json` when present. It does not use deletion flags, copy repo/model/media files, require shared mounts, train, mutate memory, modify prompts, or change router config.

Milestone 28.8 adds a reviewed learning loop report generated from `/home/cuneyt/MoE/runtime/feedback/reports/feedback-summary.json`. The report is written to `/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json` and contains aggregate observations and deterministic recommendations only, with `apply_supported=false` and `human_review_required=true`. It does not train, fine-tune, mutate memory, call Memory API, call Gateway, call llama-server, modify router config, or update prompts.

Milestone 28.9 adds a human-approved improvement plan generated from the reviewed learning-loop report. The plan is written to `/home/cuneyt/MoE/runtime/reports/improvement-plans/human-approved-improvement-plan.json` and contains proposed changes, validation commands, safety boundaries, and next steps with `plan_status=review_required`, `apply_supported=false`, and `human_review_required=true`. It does not apply changes, mutate memory, modify router config, update prompts, call Memory API, call Gateway, call llama-server, train, switch models, control Docker, or control services.

Milestone 29.0 adds a reviewed improvement patch planner generated from the human-approved improvement plan. The patch plan is written to `/home/cuneyt/MoE/runtime/reports/patch-plans/reviewed-improvement-patch-plan.json` and contains patch groups, proposed patch strategies, validation commands, safety boundaries, review checklist, and next steps with `patch_plan_status=review_required`, `apply_supported=false`, and `human_review_required=true`. It does not apply patches, edit target files, mutate memory, modify router config, update prompts, call Memory API, call Gateway, call llama-server, train, switch models, control Docker, or control services.

Milestone 29.1 adds a human-approved router and prompt update workflow generated from the reviewed patch plan. The approval packet is written to `/home/cuneyt/MoE/runtime/reports/approvals/router-prompt-update-approval-packet.json` and contains approval items, blocked items, validation commands, safety boundaries, reviewer checklist, and next steps with `approval_status=pending_human_review`, `apply_supported=false`, and `human_review_required=true`. It does not apply patches, edit files, mutate memory, modify router config, update prompts, call services, train, switch models, control Docker, or control services.

Milestone 29.2 adds a feedback-to-memory candidate review generated from aggregate feedback and reviewed learning reports. The candidate report is written to `/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json` and contains input availability, human-reviewable candidates, rejected or blocked candidates, validation commands, safety boundaries, reviewer checklist, and next steps with `candidate_status=pending_human_review`, `memory_write_supported=false`, and `human_review_required=true`. It does not write to Memory API, call Memory API, store raw prompts or model responses, include individual feedback records, train, mutate memory, modify router config, update prompts, call services, switch models, control Docker, or depend on PC2.

Milestone 29.3 adds a human-approved memory store workflow. `make memory-store-plan-local` reads the memory candidate review and optional approved-candidate ids, then writes `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json` with `plan_status=pending_human_approval`, `memory_write_supported=false`, `apply_supported=false`, and `human_review_required=true`. `make memory-store-approved` is dry-run by default and only calls Memory API `/memory/add` when a user explicitly runs it with `APPLY=1`. It stores only sanitized approved candidate text and never stores raw prompts, raw responses, raw feedback bodies, or blocked candidates.

Milestone 29.4 adds a memory store audit and candidate dedup review. `make memory-store-audit-local` reads the memory store plan, optionally enriches candidates from the feedback memory candidate report, groups candidates by normalized category/title, and writes `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json` with review-only recommendations. It never calls Memory API, Gateway, llama-server, Docker, PC2, or auto-approves candidates.

Milestone 29.5 adds append-only apply logging around `make memory-store-approved`. Dry-run mode does not log unless `LOG_DRY_RUN=1`; `APPLY=1` appends one JSONL entry per approved candidate attempt and writes `/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json`. Logs include safe metadata only and exclude raw prompts, raw responses, proposed memory text, and full API response bodies.

Milestone 29.6 adds a helper-only approval review step. `make memory-candidate-approval-helper-local` reads memory candidates, the store plan, and the audit report if present, then writes `/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json` and `/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json`. It never creates the real approval file, auto-approves candidates, calls Memory API, or writes memories.

Milestone 29.7 adds a dry-run-only end-to-end memory approval validation flow. `make memory-approval-dry-run-e2e-local` orchestrates the helper, list, plan, approved-store dry-run, apply-log status, and audit steps, then writes `/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json`. `USE_TEST_APPROVAL_FIXTURE=1` may create a temporary test approval file, but the script removes it by default and refuses to overwrite a non-test approval file. It never runs `APPLY=1` or writes to Memory API.

Milestone 29.8 adds read-only Gateway and Dashboard visibility for memory approval. `GET /gateway/memory-approval/dashboard` reads fixed runtime reports only and returns compact summaries, candidate cards, duplicate groups, approval file presence, apply-log counts, E2E status, warnings, and safety boundaries. The endpoint does not accept paths, execute scripts, call Memory API, call llama-server, control Docker, approve candidates, create files, or write memories. The Dashboard UI renders this data in a Memory Approval section with no action buttons.

Milestone 29.9 adds a manual memory approval store runbook and `make memory-store-manual-preflight`. The preflight checks source/runtime readiness before a human-operated real write, while real Memory API writes remain manual only through `APPLY=1 make memory-store-approved`; tests never run `APPLY=1`.

Milestone 29.10 adds a read-only real apply guardrail review through `make memory-store-real-apply-guardrail`, integrated before the `APPLY=1` Memory API write loop in `make memory-store-approved`. It does not call Memory API, Gateway, or llama-server, and it rejects test fixtures, `dry_run_only=true` approval files, missing approvals, and raw prompt/response markers before writes. Batch apply with more than one approved candidate warns unless `ALLOW_BATCH_MEMORY_APPLY=1` is set; that flag only silences the warning and does not bypass FAIL checks.

apps/nightly-learning-worker:

Read-only background worker skeleton for Milestone 24. It exposes FastAPI on port `8200`, checks bounded project metadata from the read-only source mount, optionally probes Gateway and Memory API health, and writes JSON reports only under `/home/cuneyt/MoE/runtime/reports/nightly`. It can optionally send distilled lessons to Memory API when explicitly requested. PC-2 activation is manual through source-only helper scripts and Docker Compose `learning` profile commands. It does not modify source files, apply patches, execute shell commands, control Docker from Gateway, control PC-2 from Gateway, or switch model runtime.

apps/research-ingestion-worker:

Read-only approved-source ingestion skeleton for Milestone 24.1. It exposes FastAPI on port `8210`, reads approved source definitions from `configs/research-sources.example.yaml`, processes only local markdown/text metadata from the read-only source mount, skips URL sources because remote fetch is disabled, and writes JSON reports only under `/home/cuneyt/MoE/runtime/reports/research`. Optional Memory API storage is explicit and off by default.

apps/feedback-worker:

Runtime-only feedback and success memory skeleton for Milestone 24.2. It exposes FastAPI on port `8220`, appends task outcome events to `/home/cuneyt/MoE/runtime/feedback/events.jsonl`, and writes feedback reports under `/home/cuneyt/MoE/runtime/reports/feedback`. Milestone 24.3 extends it with advisory prompt and routing improvement reports under `/home/cuneyt/MoE/runtime/reports/improvements`. It summarizes outcomes by task type, route intent, model target, and failure reason. It does not modify source, prompts, router config, model mappings, Docker, PC-2, or model runtime.
Milestone 28.6 also exposes `/feedback/status` and `/feedback/summarize` for aggregate Gateway feedback summaries. These bridge endpoints remain read-only toward the feedback source and write only the configured runtime summary JSON.

apps/media-api and apps/media-worker:

Dry-run-only Media Lab foundation for Milestone 25. Media API exposes job creation and dry-run processing on port `8300`; Media Worker exposes dry-run worker processing on port `8310`. Jobs and media reports are JSON files under `/home/cuneyt/MoE/runtime/media` and `/home/cuneyt/MoE/runtime/reports/media`. The foundation does not install or call ComfyUI, Blender, GPU jobs, model runtime, or media generation backends.

Milestone 26.0 adds image generation preparation only: image job metadata validation, placeholder model/workflow configs, image model inventory checks, and dry-run image report fields. Milestone 26.1-pre selects ComfyUI as the recommended future image engine, adds runtime layout and model download planning probes, and keeps real generation disabled. Milestone 26.1 adds optional user-run scripts to install, check, start, stop, and health-check a local ComfyUI runtime under `/home/cuneyt/MoE/runtime/media-engines/comfyui`, plus symlink-only Flux Schnell model planning. Model storage remains `/home/cuneyt/MoE_Models_Backup`; real generation is deferred to Milestone 26.2.

Milestone 26.3 connects Media API to Media Worker to ComfyUI for gated real image generation. Media API remains the job entry point, Media Worker owns ComfyUI submission and output discovery, and generated images are surfaced under `/home/cuneyt/MoE/runtime/media/outputs/images/<job_id>`. Real generation is disabled by default and requires explicit environment gates.

Milestone 26.4 adds a Gateway Media Adapter. Gateway can plan media prompts, optionally use the PC-2 Prompt Interpreter when reachable, create Media API dry-run jobs, and read Media API job status. Real jobs remain rejected by default and require `GATEWAY_MEDIA_REAL_ALLOWED=true`, `MEDIA_REAL_GENERATION_ENABLED=true` on the media services, and `confirm_real_generation=true` in the request. Gateway still does not start or stop services, control PC-2, execute shell commands, control Docker, or start ComfyUI.

Milestone 26.5 adds a simple read-only Media Dashboard / Status UI. Gateway exposes `/gateway/media/dashboard`, which aggregates service reachability, media safety gates, runtime mode hints, safe command text, and latest runtime image output paths. The optional `apps/media-dashboard` frontend displays that model only. It does not start services, stop services, call Docker, trigger real generation, or modify runtime media.

Milestone 26.8.2 adds a read-only Gateway Runtime Dashboard adapter at `/gateway/runtime/dashboard`. It observes PC-1 runtime status, fixed HTTP health checks, optional fixed `nvidia-smi` GPU status, PC-2 worker HTTP health, latest media job JSON summaries from the runtime jobs directory, and image lifecycle hints. It does not start or stop services, call Docker, SSH into PC-2, mutate runtime files, switch models, or trigger generation.

Milestone 26.8.3 extends the runtime dashboard with source-safe system resource observations. Gateway reads PC-1 RAM, CPU load, uptime, and root disk usage through Linux read-only files and Python stdlib calls. PC-2 system and Docker summary are explicit unavailable observers until a safe HTTP endpoint or read-only socket observer is introduced. No UI action can execute shell commands or control Docker.

Milestone 26.8.4 adds `GET /system/status` to the PC-2 Prompt Interpreter Worker. Gateway observes it through the fixed PC-2 HTTP URL and surfaces the response under `.system.pc2`. The app does not SSH to PC-2, run remote shell commands, inspect Docker, call `nvidia-smi`, or mutate files.

Milestone 26.8.5 adds a read-only Docker Summary Snapshot. A host-side script may inspect a fixed allowlist of container names with the Docker CLI and writes `/home/cuneyt/MoE/runtime/status/docker-summary.json`. Gateway reads that JSON file through a read-only runtime status mount. Gateway does not mount `docker.sock`, call Docker, execute shell commands, or control containers.

apps/control-api:

Control Plane API for Milestone 26.1.5. It exposes read-only runtime status, configured runtime modes, and dry-run mode plans on port `8400`. The Control Plane is the planned system coordination surface; Gateway remains a chat/routing/workspace API and must not become the system start/stop controller. PC-1 is the generation host for heavy GPU work, `llama-server`, ComfyUI, and future video/3D engines. PC-2 is the helper host for prompt interpretation, queue metadata, feedback, reports, and future optional mini-model interpretation.

apps/prompt-interpreter-worker:

Rule/template-based PC-2 helper worker for Milestone 26.1.6. It exposes FastAPI on port `8230`, classifies natural language media prompts into image, video, 3D model, rigging, animation, 3D suite, or unknown intents, and returns structured dry-run media job specs. It does not call models, llama-server, ComfyUI, Media API, generation engines, shell commands, or PC-1 controls.

Backup and environment planning:

Backup planning covers source, runtime, PostgreSQL, Qdrant, model backups, llama.cpp, and docs without copying runtime data into the codebase. Environment profile templates describe how PC1, PC2, single-machine, and future machines can own roles without rewriting the project.

Future local AI stack layers expected around it:

- advanced model routing through future Gateway work
- document RAG ingestion and vector workflows
- local coding workspace integration
- Continue.dev and VS Code Gateway integration
- repo-aware coding agent workflows
- safe patch-only edit planning
- PC-2 worker node activation
- nightly learning and self-improvement reports
- media lab services for image, video, 3D, rigging, animation, and workflow orchestration
- local chat UI integration
- automation layer such as n8n
- homelab operations and container management

Workspace context provider:

The stack becomes practically useful for local code development after Milestone 20 and Milestone 21. The workspace context provider mounts source code into Gateway as `/workspace:ro` and exposes read-only status, tree, file read, search, and context bundle endpoints.

Repo-aware coding agent:

Milestone 22 adds a read-only coding agent layer inside Gateway. It classifies coding tasks through the existing router, searches workspace files, selects relevant safe files, builds a compact repository context bundle, and can call the existing router-aware Gateway chat flow. It returns selected file references, route metadata, memory metadata, and model information when runtime-backed asking succeeds. It does not write files, apply patches, execute shell commands, control Docker, or switch host model runtime.

Safe patch/diff workflow:

Milestone 23 adds a suggestion-only patch layer after the repo-aware coding agent. Gateway can build repo context, ask the model for a patch plan, or ask for a unified diff suggestion. It returns summaries, affected files, steps, risks, tests, selected file references, route metadata, explanations, and `apply_supported: false`. Gateway still does not write files, apply patches, execute shell commands, control Docker, or switch model runtime.

Coding flow:

- user task
- Continue.dev or VS Code sends chat to Gateway's OpenAI-compatible adapter
- Gateway route decision
- optional repo-aware workspace search or context bundle
- optional patch plan or diff suggestion for human review
- optional memory search
- model chat through the host OpenAI-compatible runtime

File writes and patch application remain disabled until the safe write/edit plan milestone.

PC-2 worker node roadmap:

Milestone 23.5 prepares PC-2 as a background worker node before Nightly Learning begins. PC-1 remains the interactive coding, model runtime, Dashboard, workspace context, and media GPU node. PC-2 is planned for memory/vector services, Nightly Learning, research ingestion, reports, backups, maintenance, and telemetry. PC-2 should not run heavy LLM inference by default.

PC-2 worker node preparation:

PC-2 joins the architecture at Milestone 23.5 as a prepared but not-yet-activated worker node. The canonical recommended PC-2 source checkout path is `/home/cuneyt/MoE/codebase`; runtime data stays under `/home/cuneyt/MoE/runtime`. Optional validation scripts can inspect connectivity and expected paths over passwordless SSH, but they are not part of default tests and do not modify PC-2. PC-2 becomes active for scheduled background work in Milestone 24.

Nightly learning roadmap:

Nightly learning begins at Milestone 24. It is read-only and report-first: inspect bounded project metadata and configured service health, then write reports under `/home/cuneyt/MoE/runtime/reports/nightly` and optionally store useful lessons through Memory API. Milestone 24.0.1 prepares explicit PC-2 activation commands for the Nightly Learning Worker. Automatic self-modification is out of scope until a later approval-gated milestone.

Research ingestion roadmap:

Research ingestion begins at Milestone 24.1 with approved local markdown/text sources only. It produces reports under `/home/cuneyt/MoE/runtime/reports/research` and may later feed reviewed findings into Memory API. Remote URL fetching, broad crawling, and automatic source discovery are out of scope until a future approval-gated milestone.

Feedback / success memory roadmap:

Feedback memory begins at Milestone 24.2 with runtime-only JSONL event storage and report generation. It tracks task outcomes, tests run, route intent, model target, actual model, selected files, and notes. Future integration may move this to PostgreSQL or Memory API, but automatic router, prompt, config, and model mapping changes remain out of scope.

Prompt and routing improvement reports:

Milestone 24.3 uses feedback events to generate deterministic recommendations for router keywords, intent examples, model mapping alignment, prompt templates, docs gaps, test coverage, and common failure patterns. Reports are advisory, have `apply_supported=false`, and require human review before any source or config change.

Media lab roadmap:

Future media services should keep generated assets under `/home/cuneyt/MoE/runtime/media`, keep media models under `/home/cuneyt/MoE_Models_Backup`, and keep source-only service code in this repository. PC-1 is the future GPU media generation host by default; PC-2 remains a worker/report node and is not the default media GPU node. M35 closed the generic 3D / Blender parametric pipeline foundation. M36 starts the Animation Pipeline with source-only planning for deterministic timeline/keyframe contracts, runtime output boundaries under `/home/cuneyt/MoE/runtime/media/animation`, and future guarded animation/preview generation. M36.1 adds the canonical schema at `configs/animation/animation-plan.schema.json`; M36.2 adds source-only structural and timeline/keyframe semantic validation; M36.3 adds Blender-independent deterministic timeline/keyframe planning. M36.4 adds source-only camera orbit planning with right-handed `+Z` up coordinates, XY orbit positions, look-at Euler rotations, static lens metadata, and canonical M36.2/M36.3 plan reuse. M36.5 adds source-only object `transform_between` planning for location, Euler rotation degree-to-radian conversion, scale, and optional visibility tracks, again reusing M36.2/M36.3. M36.6 plans the Blender animation adapter operation envelope, target resolution, operation ordering, interpolation mapping, and guarded execution requirements. M36.7 implements the source-only adapter at `apps/media-worker/app/blender_animation_adapter.py`; normal use remains plan-only, while execution requires both `REAL_ANIMATION_GENERATION=1` and `--execute-animation`, imports `bpy` only inside the guarded execution function, and still avoids rendering, `.blend` saves, Gateway endpoints, Dashboard features, and Docker changes. M36.8 adds `apps/media-worker/app/animation_metadata_sidecar.py` for deterministic metadata sidecar planning and explicit `/tmp` atomic writes only. M36.9 adds `apps/media-worker/app/animation_metadata_validator.py` and `configs/animation/animation-metadata.schema.json` for read-only standalone and provenance validation without runtime scanning, metadata repair, rendering, Gateway, Dashboard, or Docker changes. M36.10 adds source-only preview render safety planning with `configs/animation/preview-render-request.schema.json`; it defines sampled PNG frames, fixed runtime preview roots, explicit camera resolution, frame/resolution/output limits, staging, atomic publish, timeout, and render settings restore boundaries. M36.11 adds `apps/media-worker/app/animation_preview_renderer.py`, which is plan-only by default and can guarded-render sampled PNG frames only with both animation and preview environment guards plus both CLI flags.

apps/dashboard:

Management and monitoring UI. It will show service health, machine status, GPU status, model endpoints, and memory system status.

apps/dashboard-ui:

Read-only Dashboard UI MVP for Milestone 26.8. It displays Gateway media dashboard data, service reachability, generation gates, latest runtime image paths, safe command hints, mode hints, and PC-1/PC-2 roles. Milestone 26.8.1 upgrades the visual layer with Material UI components and a Minimal Dashboard inspired shell. Milestone 26.8.2 adds runtime cards for GPU, llama-server, ComfyUI, PC-2 workers, latest media job, and image lifecycle state. Milestone 26.8.3 adds PC-1 system, PC-2 system placeholder, and Docker summary placeholder cards. Milestone 26.8.4 fills the PC2 System card from a read-only PC-2 HTTP endpoint when reachable. Milestone 26.8.5 fills Docker Summary from a host-written runtime snapshot when available. It does not start or stop services, call Docker, suspend machines, execute shell commands, or trigger real generation.

apps/media-dashboard:

Source-only static Media Lab status UI for Milestone 26.5. It reads Gateway's dashboard model and displays service health, gates, mode hints, safe command text, and latest runtime image paths. It is a viewer only.

packages/shared:

Shared utilities used across services.

packages/schemas:

Shared API and data schemas.

packages/clients:

Internal service clients for gateway, memory, embedding, and dashboard communication.

infra/docker:

Docker and Compose-related infrastructure files.

infra/postgres:

PostgreSQL initialization and migration-related files.

infra/qdrant:

Qdrant configuration and collection setup files.

infra/scripts:

Infrastructure helper scripts.

deploy/pc1:

PC1-specific deployment configuration.

deploy/pc2:

PC2-specific deployment configuration.

scripts:

Local helper scripts used from the codebase.

## Runtime Principle

The repository is not the runtime environment.

The codebase should remain clean, portable, and source-only.

Runtime state belongs under:

/home/cuneyt/MoE

This includes:

- database data
- logs
- Docker volumes
- model caches
- temporary files
- generated runtime configuration
