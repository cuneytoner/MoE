# 05 Backup

Backups are manual operator actions. Gateway does not run these commands.

## What To Back Up

- PC-1 source repo: `~/DiskD/Projects/MoE/codebase`.
- PC-2 source repo: `~/DiskD/Projects/MoE/codebase`.
- Model backup directory on PC-1: `~/MoE_Models_Backup/`.
- Runtime directory: `~/MoE/runtime/`.
- Local configs and real `.env` files if present. Treat them as secrets.
- Postgres data using `pg_dump` or a tested database backup strategy.
- Qdrant data using snapshots or a tested volume backup strategy.

## What Not To Commit

- Runtime reports unless intentionally reviewed.
- `__pycache__`.
- Large model files.
- Real `.env` files.
- Generated media, logs, pids, checkpoints, or secrets.

## Backup From PC-1 To External Disk

Review that `/media/cuneyt/Backup` is the correct external disk before running.

### Run on PC-1

```bash
rsync -a --info=progress2 ~/DiskD/Projects/MoE/codebase/ /media/cuneyt/Backup/MoE/codebase/
rsync -a --info=progress2 ~/MoE_Models_Backup/ /media/cuneyt/Backup/MoE_Models_Backup/
rsync -a --info=progress2 ~/MoE/runtime/ /media/cuneyt/Backup/MoE/runtime/
```

Expected good sign: rsync finishes without errors.

## Backup PC-2 From PC-1 Over SSH

### Run on PC-1 to check PC-2

```bash
rsync -a --info=progress2 cuneyt@192.168.50.2:~/DiskD/Projects/MoE/codebase/ /media/cuneyt/Backup/PC2/MoE/codebase/
```

Replace `cuneyt` only if the PC-2 Linux username is different.

## Postgres Backup Example

### Run on the machine where Postgres container is running

```bash
mkdir -p ~/MoE/runtime/backups
docker exec moe-postgres pg_dump -U aiuser aibrain > ~/MoE/runtime/backups/aibrain.sql
```

If your current `.env.example` defaults are in use, the database user and database may be `moe` instead:

### Run on the machine where Postgres container is running

```bash
mkdir -p ~/MoE/runtime/backups
docker exec moe-postgres pg_dump -U moe moe > ~/MoE/runtime/backups/moe.sql
```

Expected good sign: the `.sql` file appears under `~/MoE/runtime/backups/`. This is a runtime backup location, not a source repo file.
