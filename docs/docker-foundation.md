# Docker Foundation

Milestone 2 adds Docker services for PostgreSQL and Qdrant only. It does not add application business logic, model files, checkpoints, or runtime data to the source repository.

## Runtime Location

Runtime data belongs under:

`/home/cuneyt/MoE/runtime`

Service data paths:

- PostgreSQL: `/home/cuneyt/MoE/runtime/postgres`
- Qdrant: `/home/cuneyt/MoE/runtime/qdrant`

PostgreSQL initialization creates the `memories` table when a fresh runtime database is first started. Existing PostgreSQL runtime data is not automatically migrated by Docker entrypoint init scripts.

## Prepare Runtime Folders

Run:

`make runtime-prepare`

This creates the runtime folders outside the codebase.

## Start Services

Run:

`make docker-up`

This starts PostgreSQL and Qdrant using `infra/docker/docker-compose.yml`.

## Stop Services

Run:

`make docker-down`

## Health Check

Run:

`make health`

The health script checks Docker availability, PostgreSQL port reachability when its container is running, and the Qdrant HTTP health endpoint when its container is running.

Qdrant readiness is checked externally by `make health` instead of a Docker container-level healthcheck. The Qdrant image may not include tools such as `wget`, `curl`, or `nc`, so an in-container probe can incorrectly mark a reachable service as unhealthy.

## Environment

Documented defaults live in `.env.example`. Do not create a real `.env` inside this repository.

Model files remain outside the codebase. BGE-M3 validation and runtime checks should use the external backup path and read-only Docker mounts.
