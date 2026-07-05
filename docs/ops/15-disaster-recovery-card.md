# 15 Disaster Recovery Card

Use this as a one-page emergency checklist. It is not a substitute for the full [14 Backup Restore Drill](14-backup-restore-drill.md).

## If PC-1 Dies, What Do I Need?

- Source repo backup or Git remote.
- PC-1 configs and secrets if any real local `.env` files were used.
- Model backup directory: `~/MoE_Models_Backup/`.
- Runtime backup: `~/MoE/runtime/` if local runtime state matters.
- llama.cpp install or rebuild plan for `~/Apps/llama.cpp/build/bin/llama-server`.

## If PC-2 Dies, What Do I Need?

- PC-2 source repo backup or Git remote.
- Worker configs and secrets.
- Postgres backup if PC-2 owns Postgres.
- Qdrant backup/snapshot or volume backup if PC-2 owns Qdrant.
- Network settings for `192.168.50.2`.

## If Model Disk Dies, What Do I Need?

- Backup of `~/MoE_Models_Backup/`.
- Enough disk space to restore large model files.
- `make check-models` after restore.

## If Docker Data Is Lost, What Do I Need?

- Source repo.
- `.env` or local environment configuration if used.
- Postgres dump or tested volume backup.
- Qdrant snapshot or tested volume backup.
- Rebuild containers after data restore.

## Minimum Restore Order

1. Restore repo.
2. Restore configs/secrets.
3. Restore models.
4. Rebuild Docker containers.
5. Restore DB/vector data if needed.
6. Start llama-server manually.
7. Verify Gateway.
8. Verify Continue.

## Emergency Verification Commands

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
ls -lh ~/MoE_Models_Backup/
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8000/v1/models | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good sign: repo exists, model folder exists, Gateway health returns JSON, and both model endpoints return JSON.

### Run on PC-1 to check PC-2

```bash
ping -c 3 192.168.50.2
curl -fsS http://192.168.50.2:8101/health | jq .
curl -fsS http://192.168.50.2:8102/health | jq .
curl -fsS http://192.168.50.2:6333/readyz
```

Expected good sign: PC-2 network and support services respond.

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
docker ps
```

Expected good sign: PC-2 repo exists and expected support containers are running.

## Do Not Do In A Panic

- Do not restore over the live repo until you have tested restore into a temporary folder.
- Do not run `docker volume prune`.
- Do not delete `~/MoE/runtime`.
- Do not commit restored backups or secrets.
- Do not expect Gateway to switch models or recover services automatically.
