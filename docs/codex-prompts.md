# Codex Prompts

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
