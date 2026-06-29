# PC-2 Worker Node Roadmap

Milestone 23.5 prepares PC-2 as a background worker node before Nightly Learning begins.

PC-1 remains the interactive workstation for coding, model runtime, Dashboard, and future media GPU workloads. PC-2 should focus on services and jobs that can run quietly in the background.

## Network Assumptions

- PC-1 IP: `192.168.50.1`
- PC-2 IP: `192.168.50.2`
- PC-1 and PC-2 are connected over the local direct network.
- Services should use explicit host/IP configuration when crossing machines.
- Cross-machine service URLs should be documented before any migration.

## SSH Assumptions

- SSH user: `cuneyt`
- Passwordless SSH from PC-1 to PC-2 is expected.
- SSH is for deployment and maintenance workflows, not for Gateway runtime command execution.
- Gateway must not use SSH to control PC-2.

## Runtime Paths

PC-2 must keep runtime data outside the source repository:

```text
/home/cuneyt/MoE/runtime
```

If PC-2 needs local model references for lightweight embedding or future worker tasks, model files remain outside the codebase:

```text
/home/cuneyt/MoE_Models_Backup
```

Do not copy runtime data, database files, vector data, reports, caches, or model files into `/home/cuneyt/DiskD/Projects/MoE/codebase`.

## Docker Profile Plan

PC-2 deployment should become reproducible through Docker Compose profiles and docs.

Planned profile examples:

- `pc2-db`: PostgreSQL and Qdrant.
- `pc2-memory`: Memory API and dependencies when memory services move to PC-2.
- `pc2-learning`: Nightly Learning Worker, Research Ingestion Worker, and report jobs.
- `pc2-maintenance`: backup, maintenance, and telemetry jobs.

This milestone is planning-only. Do not move services until URLs, data migration, backup, restore, and rollback steps are documented.

## Planned PC-1 Role

PC-1 owns interactive and GPU-heavy work:

- Gateway API.
- Model runtime.
- VS Code / Continue.dev interaction.
- Workspace context.
- Dashboard.
- Media Lab GPU workloads.

## Planned PC-2 Role

PC-2 owns background and storage-oriented work:

- PostgreSQL and Qdrant optional migration target.
- Memory service optional deployment.
- Nightly Learning Worker.
- Research Ingestion Worker.
- Report generation.
- Backup and maintenance jobs.
- Telemetry source.

## What PC-2 Should Not Do Initially

- Do not run heavy LLM inference by default.
- Do not host interactive coding workflows.
- Do not control PC-1 model runtime.
- Do not run Gateway shell commands or Docker control actions.
- Do not store runtime data inside the codebase.
- Do not become required for default single-machine development until migration is deliberate.

## Activation Checklist

- Confirm PC-2 network reachability from PC-1.
- Confirm passwordless SSH from PC-1 to PC-2.
- Create `/home/cuneyt/MoE/runtime` on PC-2.
- Verify Docker and Docker Compose on PC-2.
- Document PC-2 environment profile values.
- Add Docker Compose profiles for PC-2 roles.
- Decide whether PostgreSQL/Qdrant move to PC-2 or remain on PC-1.
- Plan database and vector backup before migration.
- Plan rollback to PC-1 runtime services.
- Add health checks for cross-machine service URLs.
- Keep PC-1 interactive workflows working during activation.
