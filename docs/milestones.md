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

Status: IN PROGRESS

Goals:
- Add real BGE-M3 runtime loading.
- Keep model files outside the codebase.
- Add safe startup and fallback behavior.
- Avoid downloading models into the repository.
- Validate embedding dimension compatibility.

## Milestone 10: Memory Search with Real Embeddings

Status: PLANNED

Goals:
- Embed search queries through Embed Worker.
- Query Qdrant for candidate memories.
- Return simple ranked memory search results.
- Keep ranking behavior understandable and testable.
- Do not implement Gateway API or Dashboard yet.
