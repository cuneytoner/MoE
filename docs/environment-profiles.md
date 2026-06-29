# Environment Profiles

Milestone 11.2 plans hardware role profiles and environment reassignment. It does not change running service behavior.

Example profile files live in `configs/environments/`. Real local files should use local-only names and must not be committed.

## Current Assumptions

PC1:

- IP: `192.168.50.1`
- Owns the source code at `/home/cuneyt/DiskD/Projects/MoE/codebase`
- Owns the host model runtime
- Uses `/home/cuneyt/MoE/runtime`
- Uses `/home/cuneyt/MoE_Models_Backup`
- Current healthy runtime model: `deepseek-coder-lite`

PC2:

- IP: `192.168.50.2`
- Can host database, vector, and research services later
- Uses `/home/cuneyt/MoE/runtime`
- May host Memory API, PostgreSQL, Qdrant, and research workers

The OpenAI-compatible model runtime endpoint currently works at:

`http://localhost:8000/v1`

## Role Definitions

- `model_runtime`: host running llama.cpp OpenAI-compatible serving
- `memory_api`: host running Memory API
- `postgres`: host running PostgreSQL runtime data
- `qdrant`: host running Qdrant vector storage
- `dashboard`: host serving management UI later
- `gateway`: host serving future central API later
- `research_worker`: host for experiments, indexing, or background research tasks
- `codebase_owner`: machine where source edits and orchestration normally happen

## Example Assignments

Two-machine baseline:

- PC1: `codebase_owner`, `model_runtime`, `dashboard`, `research_worker`
- PC2: `memory_api`, `postgres`, `qdrant`, `research_worker`

Single-machine baseline:

- One host runs all roles with localhost service URLs.

New-machine baseline:

- Start with all roles disabled.
- Enable roles after confirming IP, paths, GPU, RAM, model files, and Docker support.

## Two-Machine To Single-Machine Migration

- Copy or restore runtime data under `/home/cuneyt/MoE/runtime`.
- Set PostgreSQL and Qdrant hosts to `127.0.0.1`.
- Point Memory API and future Gateway API to localhost dependencies.
- Keep model files under `/home/cuneyt/MoE_Models_Backup`.
- Verify Docker services with `make docker-up` and `make health`.
- Verify model runtime with `make model-start` and `make model-health`.

## Old PC1 To New PC1 Migration

- Restore source to `/home/cuneyt/DiskD/Projects/MoE/codebase`.
- Restore models to `/home/cuneyt/MoE_Models_Backup`.
- Restore runtime data to `/home/cuneyt/MoE/runtime` only when the new PC owns runtime roles.
- Rebuild or verify llama.cpp at `/home/cuneyt/Apps/llama.cpp/build/bin/llama-server`.
- Update `configs/environments/new-machine.template.yaml` into a local uncommitted profile.
- Update IP addresses in docs/templates after the hardware change is stable.

## Updating IP Addresses

- Update environment profile examples if the planned topology changes.
- Update `.env.example` only for documented defaults.
- Update deployment docs when PC1 or PC2 addresses change.
- Keep real secrets and real local `.env` files out of the repository.

## Updating Paths

- Source path belongs under `/home/cuneyt/DiskD/Projects/MoE/codebase`.
- Runtime path belongs under `/home/cuneyt/MoE/runtime`.
- Model backup path belongs under `/home/cuneyt/MoE_Models_Backup`.
- llama.cpp path is documented in `configs/runtime.yaml`.

If a new machine uses different paths, update a local environment profile first, then promote stable defaults to templates only when they are generally useful.

## Selecting Runtime Model By Hardware

- Use `deepseek-coder-lite` when a known healthy coding model is needed.
- Use `qwen-coder-32b-main` when GPU/RAM headroom allows and coding quality is the priority.
- Retest `qwen-coder-14b-fast` after replacing the corrupted or incomplete GGUF file.
- Use smaller or more quantized models on weaker GPUs or when system RAM is tight.
- Verify with `make model-health` and `/v1/models` before pointing tools at the endpoint.
