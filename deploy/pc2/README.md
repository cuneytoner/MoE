# PC-2 Deployment Preparation

PC-2 deployment files are examples and helper commands for explicit activation only.

PC-2 planned role:

- Background worker node.
- Telemetry source.
- Nightly Learning Worker host.
- Research Ingestion Worker host.
- Report generation host.
- Backup and maintenance host.
- Optional future PostgreSQL, Qdrant, and Memory API host.

PC-2 is not a heavy LLM inference node by default and is not a media generation node by default.

Recommended source checkout path on PC-2:

```text
/home/cuneyt/MoE/codebase
```

Runtime root on PC-2:

```text
/home/cuneyt/MoE
```

Runtime directories are created manually only when PC-2 activation is approved:

```bash
ssh cuneyt@192.168.50.2 'mkdir -p ~/MoE/runtime/{logs,pids,reports,backups,tmp}'
```

Until then, `make pc2-check-layout` may report `/home/cuneyt/MoE/runtime` as missing. That is acceptable during preparation. PC-2 checks are optional and are not part of default `make test`.

The example files in this directory are source-only templates:

- `.env.example`
- `docker-compose.worker.example.yml`

## Nightly Learning Worker Activation Flow

Run these commands from PC-1 only when PC-2 activation is explicitly intended:

```bash
make pc2-check-connectivity
make pc2-check-layout
make pc2-sync-code
make pc2-nightly-up
make pc2-nightly-health
make pc2-nightly-dry-run
ssh cuneyt@192.168.50.2 'ls -lah /home/cuneyt/MoE/runtime/reports/nightly'
```

The helper targets do not run from default `make test`.

The Nightly Learning Worker starts through the `learning` profile:

```bash
docker compose --env-file deploy/pc2/.env.example -f deploy/pc2/docker-compose.worker.example.yml --profile learning up -d nightly-learning-worker
```

The source checkout is mounted read-only at `/workspace`, and reports are written to `/home/cuneyt/MoE/runtime/reports/nightly`. The compose service uses `restart: "no"` conservatively, so worker restart policy can be chosen later after dry-run behavior is reviewed.

The dry-run request uses `store_lessons=false` by default and references PC-1 services through:

- Gateway: `http://192.168.50.1:8100`
- Memory API: `http://192.168.50.1:8101`

Do not commit real secrets or real local `.env` files. Do not run PC-2 Docker profiles until a task explicitly asks to activate PC-2.

Optional read-only checks from PC-1:

```bash
make pc2-check-connectivity
make pc2-check-layout
```

Optional activation helpers:

```bash
make pc2-sync-code
make pc2-nightly-up
make pc2-nightly-down
make pc2-nightly-health
make pc2-nightly-dry-run
```

## Research Ingestion Worker

The Research Ingestion Worker is optional and runs through the `research` profile only. It processes approved local markdown/text sources, skips remote URL placeholders, and writes reports under `/home/cuneyt/MoE/runtime/reports/research`.

Activation flow from PC-1:

```bash
make pc2-sync-code
make pc2-research-up
make pc2-research-health
make pc2-research-dry-run
ssh cuneyt@192.168.50.2 'ls -lah /home/cuneyt/MoE/runtime/reports/research'
```

Stop only the research worker:

```bash
make pc2-research-down
```
