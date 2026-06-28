# MoE / AI-Brain-OS Milestones

## Milestone 0: Clean Codebase

Status: DONE

Goals:
- Move old project into legacy backup.
- Create clean source-only repository under `~/DiskD/Projects/MoE/codebase`.
- Push clean `main` branch to GitHub.
- Keep runtime separate from source code.

## Milestone 1: Monorepo Skeleton

Status: IN PROGRESS

Goals:
- Create clean monorepo structure.
- Define apps, packages, infra, deploy, docs, and scripts areas.
- Add source/runtime separation rules.
- Add basic layout validation script.

## Milestone 2: Docker Foundation

Goals:
- Add Docker Compose foundation.
- Add Postgres service.
- Add Qdrant service.
- Add shared network and volume rules.
- Ensure runtime data lives under `~/MoE`, not inside codebase.

## Milestone 3: Memory API

Goals:
- Build FastAPI memory service.
- Add `/health`.
- Add `/memory/add`.
- Add `/memory/search`.
- Store metadata in Postgres.
- Store vectors in Qdrant.

## Milestone 4: Embed Worker

Goals:
- Add embedding worker service.
- Support local embedding model.
- Prepare BGE-M3 or sentence-transformers backend.
- Add queue-ready structure.

## Milestone 5: Gateway API

Goals:
- Build central FastAPI gateway.
- Add `/health`.
- Add `/models`.
- Add `/route`.
- Add `/chat`.
- Prepare OpenAI-compatible routing later.

## Milestone 6: MoE Router v1

Goals:
- Add rule-based expert routing.
- Route coding, reasoning, memory, summary, and research tasks.
- Keep router config-driven.

## Milestone 7: Dashboard

Goals:
- Add management and monitoring dashboard.
- Show PC1 and PC2 status.
- Show Docker services.
- Show GPU, CPU, RAM, disk status.
- Show model endpoints and memory service status.

## Milestone 8: Deploy System

Goals:
- Deploy from PC1 codebase to PC1 runtime `~/MoE`.
- Deploy from PC1 codebase to PC2 runtime `~/MoE`.
- Use passwordless SSH with user `cuneyt`.
- Keep codebase clean.

## Milestone 9: Continue / Codex Integration

Goals:
- Add prompts and workflows for Codex.
- Add Continue config examples.
- Add local model endpoint documentation.
- Add safe task boundaries for agents.

## Milestone 10: Tests and Health Checks

Goals:
- Add unit tests.
- Add integration tests.
- Add service health checks.
- Add `make test` and `make health`.
