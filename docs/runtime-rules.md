# Runtime Rules

This repository is source code only.

## Source Path

PC1 source code lives here:

/home/cuneyt/DiskD/Projects/MoE/codebase

## Runtime Paths

PC1 runtime:

/home/cuneyt/MoE

PC2 runtime:

/home/cuneyt/MoE

## Strict Rule

Do not write runtime artifacts into the codebase.

Forbidden inside codebase:

- database data
- Docker volumes
- model files
- model checkpoints
- logs
- runtime cache
- temporary generated files
- local .env
- Python virtual environments
- Node node_modules
- SQLite runtime databases
- generated runtime files
- service state files
- downloaded model weights

## Allowed Inside Codebase

Allowed:

- source code
- Dockerfiles
- docker-compose templates
- documentation
- deployment scripts
- example configuration files
- tests
- schemas
- small sample fixtures
- Makefile
- source-controlled helper scripts

## Environment Rule

Real .env files must not be committed.

Use:

.env.example

for documented environment variables.

Actual runtime .env files should live under runtime paths, not inside source code.

## Deploy Rule

The codebase is deployed to runtime folders.

codebase -> PC1 ~/MoE
codebase -> PC2 ~/MoE

Deploy scripts must copy only source and configuration needed to run services.

Deploy scripts must exclude:

- .git
- .env
- venv
- .venv
- node_modules
- logs
- data
- runtime
- models
- checkpoints
- caches
- temporary files

## Network

PC1:

192.168.50.1

PC2:

192.168.50.2

Deploy user:

cuneyt

Passwordless SSH is expected between PC1 and PC2.

## Why This Rule Exists

The codebase must stay clean so Codex, Continue, Git, and future automation tools can understand the project.

Runtime state changes constantly.

Source code should be stable, reviewable, and version-controlled.

The codebase is the blueprint.

~/MoE is the machine room.
## Gateway Runtime Switch Plans

M29.13 makes `/gateway/runtime/switch-plan` planning-only. Gateway returns guardrails, human preflight checks, and natural-language next steps, not executable command fields. Gateway must not start, stop, restart, or switch runtime models automatically. Any future real runtime switching requires a separate guarded milestone and human operation.
