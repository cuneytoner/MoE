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

Status: IN PROGRESS

Goals:
- Add host-managed llama.cpp serving scripts.
- Expose an OpenAI-compatible local endpoint at `http://localhost:8000/v1`.
- Track model runtime configuration in source-only YAML files.
- Store logs and pid files under `/home/cuneyt/MoE/runtime`.
- Keep model files outside the codebase.

## Milestone 12: Gateway API

Status: PLANNED

Goals:
- Add a central API entrypoint for local AI services.
- Route requests to memory, embedding, and model runtime layers.
- Expose health, model discovery, and future chat endpoints.
- Keep the interface compatible with local tool and client integrations.

## Milestone 13: Dashboard

Status: PLANNED

Goals:
- Add a management dashboard for service and machine status.
- Show Docker service health and runtime summaries.
- Surface memory, embedding, and model runtime health.
- Keep the dashboard operational rather than decorative.

## Milestone 14: Document RAG Ingestion

Status: PLANNED

Goals:
- Add document ingestion and chunking flow.
- Embed chunks and store vectors in Qdrant.
- Track document metadata and ingestion state.
- Prepare safe local RAG workflows.

## Milestone 15: Local Chat UI Integration

Status: PLANNED

Goals:
- Integrate a local chat UI layer such as OpenWebUI or AnythingLLM.
- Connect the UI to the local OpenAI-compatible endpoint.
- Keep memory and RAG hooks explicit.
- Avoid copying external UI runtime state into the codebase.

## Milestone 16: Coding Agent Integration

Status: PLANNED

Goals:
- Integrate local coding agents and editor workflows.
- Support Codex, Continue, and related local agent tooling.
- Route coding-context requests into the local AI stack safely.
- Keep source/runtime separation strict for agent workflows.

## Milestone 17: Automation Layer

Status: PLANNED

Goals:
- Add an automation layer such as n8n.
- Connect memory, model runtime, and future gateway endpoints into workflows.
- Support repeatable local task automation.
- Keep automation state out of the source repository.

## Milestone 18: Homelab Ops

Status: PLANNED

Goals:
- Add homelab operations support such as Tailscale and always-on access patterns.
- Add container management visibility with tools such as Portainer or Arcane.
- Prepare safe remote monitoring and maintenance.
- Keep operational access explicit and documented.
