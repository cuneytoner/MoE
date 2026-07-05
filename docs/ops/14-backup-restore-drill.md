# 14 Backup Restore Drill

This drill proves that a backup can be created, inspected, and restored into a temporary test folder without touching the live repo.

## What This Drill Proves

- PC-1 source can be copied to a backup target.
- PC-1 model backup files can be copied to a backup target.
- PC-1 runtime folder can be copied to a backup target.
- PC-2 source can be copied over SSH from `192.168.50.2`.
- A Postgres dump can be created if the Postgres container exists.
- The backed-up PC-1 repo can be restored into a `restore-test` folder.
- The restored `docs/ops` folder can be compared with the live source.

## What This Drill Does NOT Do

- It does not restore over the live repo.
- It does not delete real source folders.
- It does not prove Docker volumes can be restored unless you add a separate tested volume strategy.
- It does not prove every model file is valid; it only proves the backup copy exists.
- It does not run Gateway, llama-server, Memory API, Embed Worker, Postgres, or Qdrant.

## Before Starting

Use this backup root for the drill: `/media/cuneyt/Backup/MoE-Drill`.

Warnings:

- `--delete` is advanced/risky. It mirrors source to target, which means files removed from source can be removed from the backup target.
- Model files are large. Make sure the backup disk has enough space.
- Real `.env` files may contain secrets. Do not commit backups.
- Do not run `docker volume prune`.
- Do not restore over `~/DiskD/Projects/MoE/codebase`.

## Drill A: Verify Backup Target

### Run on PC-1

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
mkdir -p "$BACKUP_ROOT"/{pc1,pc2,db,restore-test}
find "$BACKUP_ROOT" -maxdepth 1 -type d | sort
```

Expected good sign: the output includes `pc1`, `pc2`, `db`, and `restore-test` under `/media/cuneyt/Backup/MoE-Drill`.

## Drill B: Backup PC-1 Source Repo

### Run on PC-1

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
rsync -a --delete --info=progress2 \
  ~/DiskD/Projects/MoE/codebase/ \
  "$BACKUP_ROOT/pc1/codebase/"
```

Expected good sign: rsync finishes without errors and `"$BACKUP_ROOT/pc1/codebase/.git"` exists.

## Drill C: Backup PC-1 Models

### Run on PC-1

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
rsync -a --info=progress2 \
  ~/MoE_Models_Backup/ \
  "$BACKUP_ROOT/pc1/MoE_Models_Backup/"
```

Expected good sign: rsync finishes without errors. Large model files may take time.

## Drill D: Backup PC-1 Runtime Folder

### Run on PC-1

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
rsync -a --info=progress2 \
  ~/MoE/runtime/ \
  "$BACKUP_ROOT/pc1/runtime/"
```

Expected good sign: rsync finishes without errors. Runtime reports, logs, and local state are copied to the drill target, not committed.

## Drill E: Backup PC-2 Repo Over SSH

Replace `cuneyt` only if the Linux username on PC-2 is different.

### Run on PC-1 to check PC-2

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
rsync -a --delete --info=progress2 \
  cuneyt@192.168.50.2:~/DiskD/Projects/MoE/codebase/ \
  "$BACKUP_ROOT/pc2/codebase/"
```

Expected good sign: rsync finishes without errors and `"$BACKUP_ROOT/pc2/codebase/.git"` exists.

## Drill F: Backup Postgres If Container Exists

Use this only if the Postgres container is named `moe-postgres` and the database/user are `aibrain`/`aiuser`.

### Run on the machine where Postgres container is running

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
mkdir -p "$BACKUP_ROOT/db"
docker exec moe-postgres pg_dump -U aiuser aibrain > "$BACKUP_ROOT/db/aibrain.sql"
```

Expected good sign: `"$BACKUP_ROOT/db/aibrain.sql"` exists and is not empty.

If your `.env.example` defaults are in use, the database/user may be `moe`/`moe`; review before changing the command.

## Drill G: Verify Backup Contents Without Deleting Anything

### Run on PC-1

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
find "$BACKUP_ROOT" -maxdepth 3 -type d | sort
du -sh "$BACKUP_ROOT"/*
test -d "$BACKUP_ROOT/pc1/codebase/.git"
test -d "$BACKUP_ROOT/pc1/MoE_Models_Backup"
test -s "$BACKUP_ROOT/db/aibrain.sql" || echo "No DB dump or empty DB dump; review manually."
```

Expected good sign: repo and model backup checks pass. If the DB dump message appears, review whether Postgres backup was intentionally skipped.

## Drill H: Simulate Restore Into A Temporary Folder

This restores only into `restore-test`. Do not restore over the live repo.

### Run on PC-1

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
mkdir -p "$BACKUP_ROOT/restore-test/pc1"
rsync -a "$BACKUP_ROOT/pc1/codebase/" "$BACKUP_ROOT/restore-test/pc1/codebase/"
cd "$BACKUP_ROOT/restore-test/pc1/codebase"
git status --short
git log --oneline -3
```

Expected good sign: `git status --short` is empty or only shows expected local backup differences, and `git log --oneline -3` prints recent commits.

## Drill I: Compare Restored Repo To Source

### Run on PC-1

```bash
BACKUP_ROOT=/media/cuneyt/Backup/MoE-Drill
diff -qr \
  ~/DiskD/Projects/MoE/codebase/docs/ops \
  "$BACKUP_ROOT/restore-test/pc1/codebase/docs/ops"
```

Expected good sign: no output. Any output means there is a difference to review.

## Drill J: Checklist Before Trusting The Backup

- Backup root exists: `/media/cuneyt/Backup/MoE-Drill`.
- PC-1 repo backup contains `.git`.
- PC-1 model backup folder exists and has expected model files.
- PC-1 runtime backup folder exists.
- PC-2 repo backup contains `.git` if PC-2 is used.
- Postgres dump exists or was intentionally skipped.
- Restore simulation completed under `restore-test`.
- Restored `docs/ops` matches live `docs/ops`.
- No backup files were committed to Git.

## Troubleshooting

If the backup disk is missing, mount the external disk and rerun Drill A.

If PC-2 SSH fails, read [07-troubleshooting.md#pc-1-cannot-ping-pc-2](07-troubleshooting.md#pc-1-cannot-ping-pc-2).

If Postgres dump fails, verify the container name, database name, and user before retrying.

If `diff -qr` shows differences, inspect them before trusting the backup.

Never fix a failed drill by deleting live source, pruning Docker volumes, or restoring over the live repo.
