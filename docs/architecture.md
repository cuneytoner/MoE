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

apps/nightly-learning-worker:

Read-only background worker skeleton for Milestone 24. It exposes FastAPI on port `8200`, checks bounded project metadata from the read-only source mount, optionally probes Gateway and Memory API health, and writes JSON reports only under `/home/cuneyt/MoE/runtime/reports/nightly`. It can optionally send distilled lessons to Memory API when explicitly requested. PC-2 activation is manual through source-only helper scripts and Docker Compose `learning` profile commands. It does not modify source files, apply patches, execute shell commands, control Docker from Gateway, control PC-2 from Gateway, or switch model runtime.

apps/research-ingestion-worker:

Read-only approved-source ingestion skeleton for Milestone 24.1. It exposes FastAPI on port `8210`, reads approved source definitions from `configs/research-sources.example.yaml`, processes only local markdown/text metadata from the read-only source mount, skips URL sources because remote fetch is disabled, and writes JSON reports only under `/home/cuneyt/MoE/runtime/reports/research`. Optional Memory API storage is explicit and off by default.

apps/feedback-worker:

Runtime-only feedback and success memory skeleton for Milestone 24.2. It exposes FastAPI on port `8220`, appends task outcome events to `/home/cuneyt/MoE/runtime/feedback/events.jsonl`, and writes feedback reports under `/home/cuneyt/MoE/runtime/reports/feedback`. Milestone 24.3 extends it with advisory prompt and routing improvement reports under `/home/cuneyt/MoE/runtime/reports/improvements`. It summarizes outcomes by task type, route intent, model target, and failure reason. It does not modify source, prompts, router config, model mappings, Docker, PC-2, or model runtime.

apps/media-api and apps/media-worker:

Dry-run-only Media Lab foundation for Milestone 25. Media API exposes job creation and dry-run processing on port `8300`; Media Worker exposes dry-run worker processing on port `8310`. Jobs and media reports are JSON files under `/home/cuneyt/MoE/runtime/media` and `/home/cuneyt/MoE/runtime/reports/media`. The foundation does not install or call ComfyUI, Blender, GPU jobs, model runtime, or media generation backends.

Milestone 26.0 adds image generation preparation only: image job metadata validation, placeholder model/workflow configs, image model inventory checks, and dry-run image report fields. Milestone 26.1-pre selects ComfyUI as the recommended future image engine, adds runtime layout and model download planning probes, and keeps real generation disabled. Milestone 26.1 adds optional user-run scripts to install, check, start, stop, and health-check a local ComfyUI runtime under `/home/cuneyt/MoE/runtime/media-engines/comfyui`, plus symlink-only Flux Schnell model planning. Model storage remains `/home/cuneyt/MoE_Models_Backup`; real generation is deferred to Milestone 26.2.

Milestone 26.3 connects Media API to Media Worker to ComfyUI for gated real image generation. Media API remains the job entry point, Media Worker owns ComfyUI submission and output discovery, and generated images are surfaced under `/home/cuneyt/MoE/runtime/media/outputs/images/<job_id>`. Real generation is disabled by default and requires explicit environment gates.

Milestone 26.4 adds a Gateway Media Adapter. Gateway can plan media prompts, optionally use the PC-2 Prompt Interpreter when reachable, create Media API dry-run jobs, and read Media API job status. Real jobs remain rejected by default and require `GATEWAY_MEDIA_REAL_ALLOWED=true`, `MEDIA_REAL_GENERATION_ENABLED=true` on the media services, and `confirm_real_generation=true` in the request. Gateway still does not start or stop services, control PC-2, execute shell commands, control Docker, or start ComfyUI.

Milestone 26.5 adds a simple read-only Media Dashboard / Status UI. Gateway exposes `/gateway/media/dashboard`, which aggregates service reachability, media safety gates, runtime mode hints, safe command text, and latest runtime image output paths. The optional `apps/media-dashboard` frontend displays that model only. It does not start services, stop services, call Docker, trigger real generation, or modify runtime media.

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

Future media services should keep generated assets under `/home/cuneyt/MoE/runtime/media`, keep media models under `/home/cuneyt/MoE_Models_Backup`, and keep source-only service code in this repository. PC-1 is the future GPU media generation host by default; PC-2 remains a worker/report node and is not the default media GPU node. The planned sequence is foundation, image generation, video generation, 3D generation, rigging, animation, then workflow orchestration.

apps/dashboard:

Management and monitoring UI. It will show service health, machine status, GPU status, model endpoints, and memory system status.

apps/dashboard-ui:

Read-only Dashboard UI MVP for Milestone 26.8. It displays Gateway media dashboard data, service reachability, generation gates, latest runtime image paths, safe command hints, mode hints, and PC-1/PC-2 roles. Milestone 26.8.1 upgrades the visual layer with Material UI components and a Minimal Dashboard inspired shell. It does not start or stop services, call Docker, suspend machines, execute shell commands, or trigger real generation.

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
