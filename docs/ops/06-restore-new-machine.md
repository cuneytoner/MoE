# 06 Restore New Machine

Restore is manual. Do not download models into the repo. Do not expect Gateway to restore or switch runtime services automatically.

For emergency triage, read [15-disaster-recovery-card.md](15-disaster-recovery-card.md). To prove a backup is usable before a real restore, run [14-backup-restore-drill.md](14-backup-restore-drill.md).

## Restore PC-1

### Run on PC-1

```bash
mkdir -p ~/DiskD/Projects/MoE
mkdir -p ~/MoE_Models_Backup
mkdir -p ~/MoE/runtime
mkdir -p ~/Apps
```

Restore source from Git:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE
git clone https://github.com/cuneytoner/MoE.git codebase
cd ~/DiskD/Projects/MoE/codebase
git status --short
```

Restore from external disk if you have a backup:

### Run on PC-1

```bash
rsync -a --info=progress2 /media/cuneyt/Backup/MoE/codebase/ ~/DiskD/Projects/MoE/codebase/
rsync -a --info=progress2 /media/cuneyt/Backup/MoE_Models_Backup/ ~/MoE_Models_Backup/
rsync -a --info=progress2 /media/cuneyt/Backup/MoE/runtime/ ~/MoE/runtime/
```

## Restore PC-2

### Run on PC-2

```bash
mkdir -p ~/DiskD/Projects/MoE
mkdir -p ~/MoE/runtime
cd ~/DiskD/Projects/MoE
git clone https://github.com/cuneytoner/MoE.git codebase
cd ~/DiskD/Projects/MoE/codebase
git status --short
```

Restore PC-2 source from an SSH backup copied to PC-1:

### Run on PC-2

```bash
rsync -a --info=progress2 /media/cuneyt/Backup/PC2/MoE/codebase/ ~/DiskD/Projects/MoE/codebase/
```

Adjust the source path if the backup disk is mounted somewhere else on PC-2.

## Restore From SSH Backup

If the backup lives on another host, replace the host and path after reviewing them:

### Run on PC-1

```bash
rsync -a --info=progress2 backup-host:/backup/MoE/codebase/ ~/DiskD/Projects/MoE/codebase/
rsync -a --info=progress2 backup-host:/backup/MoE_Models_Backup/ ~/MoE_Models_Backup/
rsync -a --info=progress2 backup-host:/backup/MoE/runtime/ ~/MoE/runtime/
```

## Rebuild PC-1 Containers

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make runtime-prepare
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build gateway-api memory-api embed-worker postgres qdrant
docker ps
```

## Rebuild PC-2 Support Containers

### Run on PC-2

```bash
cd ~/DiskD/Projects/MoE/codebase
make runtime-prepare
docker compose --env-file .env.example -f infra/docker/docker-compose.yml up -d --build memory-api embed-worker postgres qdrant
docker ps
```

## Final Verification

### Run on PC-1

```bash
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8000/v1/models | jq .
```

### Run on PC-1 to check PC-2

```bash
curl -fsS http://192.168.50.2:8101/health | jq .
```

Expected good signs:

- Gateway health returns JSON.
- llama-server `/v1/models` returns a model list.
- PC-2 Memory API health returns JSON if PC-2 memory services are enabled.

Before trusting a restored machine, compare it against the drill checklist in [14-backup-restore-drill.md](14-backup-restore-drill.md).
