# Docker Foundation

Milestone 2 adds Docker services for PostgreSQL and Qdrant only. It does not add application business logic, model files, checkpoints, or runtime data to the source repository.

## Runtime Location

Runtime data belongs under:

`/home/cuneyt/MoE/runtime`

Service data paths:

- PostgreSQL: `/home/cuneyt/MoE/runtime/postgres`
- Qdrant: `/home/cuneyt/MoE/runtime/qdrant`

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

## Environment

Documented defaults live in `.env.example`. Do not create a real `.env` inside this repository.
