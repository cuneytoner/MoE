# Backup, Restore, and Disaster Recovery

Milestone 11.1 defines the backup and restore plan. It does not add backup scripts yet.

## What To Back Up

- Source code: `/home/cuneyt/DiskD/Projects/MoE/codebase`
- Runtime data: `/home/cuneyt/MoE/runtime`
- PostgreSQL logical dumps from the running database
- Qdrant snapshots or exports from the running Qdrant service
- Model backup directory: `/home/cuneyt/MoE_Models_Backup`
- llama.cpp source/build location: `/home/cuneyt/Apps/llama.cpp`
- Environment templates: `.env.example`, `configs/runtime.yaml`, `configs/models.yaml`, and `configs/environments/*.example.yaml`
- Project docs under `docs/`

## What Not To Back Up

- Runtime pid files under `/home/cuneyt/MoE/runtime/pids`
- Temporary files
- Python virtual environments
- `node_modules`
- Docker image cache
- Generated `__pycache__` or `*.pyc`
- Real secrets or local `.env` files

Logs under `/home/cuneyt/MoE/runtime/logs` are optional. Keep them only when debugging history matters.

## Backup Commands Draft

Create a dated backup root outside the source repository:

```bash
BACKUP_ROOT=/home/cuneyt/MoE_Backups/$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_ROOT"
```

Archive source:

```bash
tar --exclude .git -czf "$BACKUP_ROOT/codebase.tgz" -C /home/cuneyt/DiskD/Projects/MoE codebase
```

Archive runtime without pid files and with optional logs excluded:

```bash
tar --exclude pids --exclude logs -czf "$BACKUP_ROOT/runtime.tgz" -C /home/cuneyt/MoE runtime
```

Archive model backups separately:

```bash
tar -czf "$BACKUP_ROOT/model-backup.tgz" -C /home/cuneyt MoE_Models_Backup
```

## PostgreSQL Dump And Restore Plan

Dump:

```bash
docker compose --env-file .env.example -f infra/docker/docker-compose.yml exec postgres pg_dump -U moe -d moe --format=custom --file=/tmp/moe.dump
docker cp moe-postgres:/tmp/moe.dump "$BACKUP_ROOT/postgres-moe.dump"
```

Restore draft:

```bash
docker cp "$BACKUP_ROOT/postgres-moe.dump" moe-postgres:/tmp/moe.dump
docker compose --env-file .env.example -f infra/docker/docker-compose.yml exec postgres pg_restore -U moe -d moe --clean --if-exists /tmp/moe.dump
```

## Qdrant Snapshot / Export Plan

Use Qdrant snapshots for each collection and store them under the external backup root. Collection names are dimension-aware, such as:

- `moe_memories_fake_384`
- `moe_memories_bge_m3_1024`

Snapshot draft:

```bash
curl -fsS -X POST http://localhost:6333/collections/moe_memories_fake_384/snapshots | jq
```

After snapshot creation, copy snapshot files from the Qdrant runtime storage under `/home/cuneyt/MoE/runtime/qdrant` into the external backup root. Do not copy snapshots into the source repository.

## Model Checksum Manifest Plan

Generate a checksum manifest outside the codebase:

```bash
find /home/cuneyt/MoE_Models_Backup -type f -name '*.gguf' -print0 | sort -z | xargs -0 sha256sum > "$BACKUP_ROOT/model-sha256.txt"
```

Verify after restore:

```bash
sha256sum -c "$BACKUP_ROOT/model-sha256.txt"
```

This catches incomplete or corrupted model files, such as a partial GGUF download.

## llama.cpp Rebuild / Verify Plan

Verify the server binary:

```bash
/home/cuneyt/Apps/llama.cpp/build/bin/llama-server --version
```

If the binary is missing on a new PC, rebuild llama.cpp from its source or reinstall it outside the codebase, then update `configs/runtime.yaml` or `.env.example` if the path changes.

## New PC Restore Checklist

- Install system dependencies, Docker, and Docker Compose.
- Restore or clone the source code to `/home/cuneyt/DiskD/Projects/MoE/codebase`.
- Restore model files to `/home/cuneyt/MoE_Models_Backup`.
- Verify model checksums.
- Restore runtime directories under `/home/cuneyt/MoE/runtime`.
- Rebuild or verify llama.cpp at `/home/cuneyt/Apps/llama.cpp/build/bin/llama-server`.
- Run `make check-layout`.
- Run `make check-models` when model files are expected to exist.
- Start Docker services with `make docker-up`.
- Restore PostgreSQL dump.
- Restore Qdrant snapshots.
- Start model runtime with `make model-start MODEL=deepseek-coder-lite`.
- Check `make model-health`.
- Check Memory API and stack tests.

## Disaster Recovery Checklist

- Confirm whether source, runtime, model backup, or llama.cpp build was lost.
- Stop affected services before restoring mutable runtime data.
- Restore source first, then runtime data, then model files.
- Restore PostgreSQL and Qdrant from service-aware dumps/snapshots.
- Exclude stale pid files.
- Treat logs as optional unless needed for incident review.
- Verify model checksums before starting model runtime.
- Run health checks before reconnecting clients.
