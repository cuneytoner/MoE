# PC-2 Worker Node Preparation

## Purpose

Milestone 23.5 prepares PC-2 as a background worker node before Nightly Learning begins. This milestone is planning, source configuration, and read-only validation only. It does not deploy services, SSH into PC-2 automatically, start Docker, or modify runtime state.

## PC-1 vs PC-2 Role Split

PC-1 remains the interactive workstation:

- Source owner.
- Codex and Continue.dev workspace.
- Gateway API.
- Host model runtime.
- Dashboard access point.
- Media GPU workloads.

PC-2 is prepared as a background worker node:

- Telemetry source.
- Nightly Learning Worker host.
- Research Ingestion Worker host.
- Report generation host.
- Backup and maintenance host.
- Optional future PostgreSQL, Qdrant, and Memory API host.

PC-2 is not a heavy LLM inference node by default and is not a media generation node by default.

## Network Assumptions

- PC-1 IP: `192.168.50.1`
- PC-2 IP: `192.168.50.2`
- PC-1 and PC-2 are connected over the local Cat5 network.
- Gateway on PC-1 is expected at `http://192.168.50.1:8100`.
- Memory API on PC-1 is expected at `http://192.168.50.1:8101`.
- Embed Worker on PC-1 is expected at `http://192.168.50.1:8102`.

## SSH Assumptions

- SSH user: `cuneyt`
- Passwordless SSH is expected from PC-1 to PC-2.
- Validation scripts use `ssh -o BatchMode=yes` and must not prompt for passwords.
- PC-2 validation scripts are optional and are not part of default `make test`.

## Runtime Paths

PC-2 runtime root:

```text
/home/cuneyt/MoE
```

PC-2 runtime data:

```text
/home/cuneyt/MoE/runtime
```

Reports should live under:

```text
/home/cuneyt/MoE/runtime/reports
```

Runtime data, logs, reports, Docker volumes, caches, and generated files must stay outside the source checkout.

PC-2 runtime directories are initialized manually during activation, not by default tests. When PC-2 activation is approved, run from PC-1:

```bash
ssh cuneyt@192.168.50.2 'mkdir -p ~/MoE/runtime/{logs,pids,reports,backups,tmp}'
```

Until that activation step is done, `pc2-check-layout` may report `/home/cuneyt/MoE/runtime` as missing. That is acceptable during preparation.

## Source Checkout Path Recommendation

Recommended PC-2 source checkout path:

```text
/home/cuneyt/MoE/codebase
```

This keeps PC-2 simple: `/home/cuneyt/MoE` owns runtime and deployment-adjacent files, while `/home/cuneyt/MoE/codebase` is a source-only checkout. If another path is used later, update environment profiles and deployment docs together.

## Services Planned For PC-2

Phase A:

- Telemetry check scripts.
- Worker health placeholder.
- Report output directory structure.

Phase B:

- `nightly-learning-worker`.
- `research-ingestion-worker`.

Phase C optional:

- PostgreSQL migration target.
- Qdrant migration target.
- Memory API migration target.

## Services Not Planned For PC-2 Initially

- Heavy LLM inference.
- Media generation.
- Gateway as the primary interactive endpoint.
- Dashboard as the primary UI.
- Automatic code editing.
- Automatic patch application.

## Docker Compose Worker Profile Plan

The source-only example compose file is:

```text
deploy/pc2/docker-compose.worker.example.yml
```

Profiles:

- `telemetry`
- `learning`
- `research`
- `memory-services`

The example compose file is not used by default tests and should not be run until PC-2 activation is explicitly requested.

## Health Checks

Optional read-only checks:

```bash
make pc2-check-connectivity
make pc2-check-layout
```

These checks inspect network and expected paths only. They do not create directories, install packages, start services, stop services, or modify PC-2.

`pc2-check-layout` is optional and is not part of default `make test`.

## Backup / Restore Relationship

PC-1 remains the source owner and deployment controller. PC-2 can later host backup and maintenance jobs, but source, runtime data, model backups, database dumps, and reports must remain clearly separated.

Backups should exclude pid files and transient logs unless explicitly requested. Model files remain under `/home/cuneyt/MoE_Models_Backup` and should be validated with checksums rather than copied into the repository.

## Activation Checklist

Before activating PC-2 worker services:

- Confirm PC-2 is reachable from PC-1.
- Confirm passwordless SSH works.
- Confirm `/home/cuneyt/MoE` exists.
- Confirm `/home/cuneyt/MoE/runtime` exists.
- Confirm Docker is installed.
- Confirm Docker Compose is available.
- Confirm source checkout path.
- Review `deploy/pc2/.env.example` and create a real runtime env file outside source control if needed.
- Decide which compose profile to activate.
- Run only explicitly approved deployment commands.

## Future Nightly Learning Handoff

Milestone 24 can build on this PC-2 preparation by adding a read-only Nightly Learning Worker. That worker should write reports under `/home/cuneyt/MoE/runtime/reports/nightly`, store useful lessons through Memory API, and never modify code or restart services automatically.
