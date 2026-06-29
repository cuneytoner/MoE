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

Status: IN PROGRESS

Goals:
- Point Continue.dev to Gateway or model runtime.
- Add coding model profiles.
- Add local prompt templates.
- Add docs for using the stack as a coding assistant.
- Add Gateway OpenAI-compatible chat adapter for Continue.dev.

## Milestone 22: Repo-Aware Coding Agent

Status: PLANNED

Goals:
- Combine workspace context, memory, router, and model runtime.
- Support code explanation, debugging, review, and implementation planning.
- Keep agent actions advisory until write safety is designed.

## Milestone 23: Safe Patch/Diff Workflow

Status: PLANNED

Goals:
- Generate patches only.
- Do not auto-apply changes.
- Add diff review workflow.

## Milestone 23.5: PC-2 Worker Node Preparation

Status: PLANNED

Goals:
- Prepare PC-2 as a background worker node before Nightly Learning.
- Assign PC-2 to memory/vector services, learning jobs, research ingestion, reports, and long-running background tasks.
- Keep PC-1 as the interactive coding, model runtime, Dashboard, and media GPU node.
- Do not run heavy LLM inference on PC-2 by default.
- Keep PC-2 runtime and data directories outside the codebase.
- Make PC-2 deployment reproducible through Docker Compose profiles and docs.

## Milestone 24: Nightly Learning Worker

Status: PLANNED

Goals:
- Add a scheduled read-only learning worker.
- Analyze recent git activity, tests, Gateway route decisions, Memory API records, and runtime/model health reports.
- Produce nightly reports under `/home/cuneyt/MoE/runtime/reports/nightly`.
- Store useful lessons into Memory API.
- Never modify code automatically.
- Never execute shell commands automatically.
- Never restart Docker or model runtime.
- Keep reports safe, observable, and manually reviewable.

## Milestone 24.1: Research Ingestion Worker

Status: PLANNED

Goals:
- Add optional research, news, and document ingestion.
- Support user-approved sources only.
- Summarize findings.
- Store useful findings in Memory API.
- Keep all outputs under runtime data.
- Make no automatic code changes.

## Milestone 24.2: Feedback / Success Memory

Status: PLANNED

Goals:
- Track which tasks succeeded or failed.
- Store routing decisions, selected model target, actual model used, tests run, and final status.
- Use this history to improve future routing and prompts.
- Keep feedback memory transparent and inspectable.

## Milestone 24.3: Prompt & Routing Improvement Reports

Status: PLANNED

Goals:
- Generate recommendations for router keywords, model mapping, prompt templates, test improvements, and docs gaps.
- Output reports only.
- Require human approval before changing code or config.

## Milestone 25: Media Lab Foundation

Status: PLANNED

Goals:
- Define `media-api` / `media-worker` architecture.
- Define runtime output directories under `/home/cuneyt/MoE/runtime/media`.
- Define model paths under `/home/cuneyt/MoE_Models_Backup`.
- Keep generated media out of the codebase.

## Milestone 26: Image Generation Service

Status: PLANNED

Goals:
- Integrate ComfyUI or an image worker.
- Support Flux-style image generation.
- Add job, status, and assets model.

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
