# PC-2 Deployment Preparation

PC-2 deployment files are examples only until activation is explicitly requested.

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

After explicit PC-2 activation, the Nightly Learning Worker can be started through the `learning` profile. Example command only:

```bash
docker compose --env-file deploy/pc2/.env.example -f deploy/pc2/docker-compose.worker.example.yml --profile learning up -d nightly-learning-worker
```

Do not run this until PC-2 activation and deployment are explicitly requested. The source checkout is mounted read-only at `/workspace`, and reports are written to `/home/cuneyt/MoE/runtime/reports/nightly`.

Do not commit real secrets or real local `.env` files. Do not run PC-2 Docker profiles until a task explicitly asks to activate PC-2.

Optional read-only checks from PC-1:

```bash
make pc2-check-connectivity
make pc2-check-layout
```
