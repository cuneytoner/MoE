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

## Milestone 10 Next Prompt Placeholder

Implement Memory Search with real embeddings.

Expected boundaries:

- Embed search queries through Embed Worker.
- Query Qdrant for nearest vectors.
- Return simple ranked results from Memory API.
- Keep the search behavior small and explainable.
- Do not implement Gateway API or Dashboard.

## Milestone 10 Prompt Placeholder

Add Memory API search using real embeddings and Qdrant lookup.

Expected boundaries:

- Embed search queries through Embed Worker.
- Query Qdrant for nearest vectors.
- Return simple ranked memory candidates.
- Keep ranking logic understandable and easy to test.
- Avoid broad routing or UI work in this step.

## Milestone 11 Prompt Placeholder

Add a local model runtime and OpenAI-compatible serving layer.

Expected boundaries:

- Prepare llama.cpp or a similar local model server.
- Expose an OpenAI-compatible endpoint.
- Keep model files outside the codebase.
- Avoid bundling chat UI and gateway work into the same task.

## Milestone 17 Prompt Placeholder

Add an automation layer for local workflows.

Expected boundaries:

- Prepare n8n or a similar automation service.
- Connect it to local APIs with explicit credentials and URLs.
- Keep automation state outside the source repository.
- Avoid mixing this work with dashboard or homelab ops changes.

## Milestone 18 Prompt Placeholder

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
