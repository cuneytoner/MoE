# Deployment

## Source

All source code lives on PC1:

/home/cuneyt/DiskD/Projects/MoE/codebase

## Runtime Targets

PC1 runtime target:

/home/cuneyt/MoE

PC2 runtime target:

cuneyt@192.168.50.2:/home/cuneyt/MoE

## Deployment User

User:

cuneyt

Passwordless SSH is expected from PC1 to PC2.

## Deployment Rule

Deploy scripts must copy only source and configuration needed to run services.

They must not copy:

- .git
- .env
- virtual environments
- node_modules
- logs
- data
- runtime files
- models
- checkpoints
- caches
- database volumes
- temporary files

## Planned Commands

Deploy to PC1:

make deploy-pc1

Deploy to PC2:

make deploy-pc2

Deploy to both machines:

make deploy-all

Check runtime health:

make health

## PC1 Deployment

Source:

/home/cuneyt/DiskD/Projects/MoE/codebase

Target:

/home/cuneyt/MoE

Deployed source/config checkout:

/home/cuneyt/MoE/codebase

PC1 deployment should prepare services that run locally on the main workstation.

Possible PC1 services:

- gateway-api
- dashboard
- local model endpoint bridge
- local inference helpers
- embed-worker if needed

Dashboard UI start/stop helpers should run from `/home/cuneyt/MoE/codebase` by default. The authoring source checkout can be used only with an explicit development fallback flag.

## PC2 Deployment

Source:

/home/cuneyt/DiskD/Projects/MoE/codebase

Target:

cuneyt@192.168.50.2:/home/cuneyt/MoE

PC2 deployment should prepare worker and memory services.

Possible PC2 services:

- memory-api
- PostgreSQL
- Qdrant
- embed-worker
- background workers

## Future Deployment Strategy

The deploy system should use rsync.

Recommended rsync excludes:

- .git
- .env
- .venv
- venv
- node_modules
- logs
- data
- runtime
- models
- checkpoints
- .cache
- __pycache__
- *.pyc

## Safety Principle

A deploy should never destroy source code.

A deploy should never write runtime data into codebase.

A deploy should be repeatable.
