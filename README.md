# MoE / AI-Brain-OS

Clean source code repository for the local multi-PC MoE system.

## Repository Rule

This folder is source code only.

Runtime files, database volumes, logs, model caches, temporary files, and generated artifacts must not be written into this repository.

## Paths

PC1 source code:

/home/cuneyt/DiskD/Projects/MoE/codebase

PC1 runtime:

/home/cuneyt/MoE

PC2 runtime:

/home/cuneyt/MoE

## Network

PC1:

192.168.50.1

PC2:

192.168.50.2

Deploy user:

cuneyt

Passwordless SSH is expected between PC1 and PC2.

## Components

apps:

- gateway-api
- memory-api
- embed-worker
- nightly-learning-worker
- research-ingestion-worker
- feedback-worker
- media-api
- media-worker
- control-api
- prompt-interpreter-worker
- dashboard

packages:

- shared
- schemas
- clients

infra:

- docker
- postgres
- qdrant
- scripts

deploy:

- pc1
- pc2

docs:

- architecture.md
- milestones.md
- continue-gateway-config.md
- gateway-chat.md

## Current Media UI

- M35.18 adds a read-only Dashboard panel for 3D output cards.
- The panel consumes `GET /gateway/media/3d/cards`.
- It shows guarded Blender metadata verification without generation, shell, Docker, delete, move, rename, repair, cleanup, or absolute path actions.
- M35.19 adds 3D reference-board selection through `POST /gateway/media/reference-boards/{board_id}/items/3d`.
- 3D reference-board selection writes only reference metadata. It does not copy, move, delete, regenerate, repair, or modify 3D assets.
- memory-injection.md
- feedback.md
- feedback-worker.md
- feedback-sync.md
- learning-loop.md
- improvement-plan.md
- improvement-patch-planner.md
- router-prompt-approval.md
- feedback-memory-candidates.md
- memory-store-workflow.md
- memory-store-audit.md
- memory-store-apply-log.md
- memory-candidate-approval-helper.md
- memory-approval-dry-run-e2e.md
- memory-approval-dashboard.md
- memory-approval-manual-store-runbook.md
- models.md
- runtime-rules.md
- deployment.md
- codex-prompts.md
- research-ingestion.md
- feedback-success-memory.md
- control-plane.md
- prompt-interpreter.md
- media-lab.md

scripts:

- check-layout.sh

## Commands

Validate layout:

make check-layout

Show git status:

make status

Show repository tree:

make tree

## Current Milestone

Current active phase: M36 Animation Pipeline.

M35 is closed.

Completed through Milestone 36.15: Dashboard Animation Cards UI

Next planned milestone:

Milestone 36.16: Animation Reference Board Selection

## Model Inventory

Active model files live under `/home/cuneyt/MoE_Models_Backup`.

Archived inactive models live under `/media/cuneyt/Disk2TB/model_backup/MoE_Models_Archive`.

`make check-models` validates only active required models and active required media assets from `configs/models.yaml`. Archived models are documented under `archived_models` and do not need to exist in the active model path.

`configs/model-registry.example.yaml` documents the active/archive inventory used by:

make model-inventory
make model-registry-check

`make model-inventory` writes its generated report only under `/home/cuneyt/MoE/runtime/reports/models/model-inventory.json`.

Optional image planning commands:

make check-image-models
make plan-image-model-downloads
make plan-flux-schnell-models
make download-flux-schnell-models-plan
make check-flux-schnell-models
make check-comfyui-layout
make check-comfyui-runtime
make comfyui-flux-smoke-test
make comfyui-first-image-plan
make media-image-dry-run
make media-latest-images
make gateway-media-plan
make gateway-media-dry-run
make gateway-media-real-plan
make media-dashboard-status
make media-dashboard-open
make image-readiness
make image-dry-run
make image-latest
make image-full-cycle
make dashboard-ui-up
make dashboard-ui-health
make dashboard-ui-open
make runtime-dashboard-status
make test-openai-compatible-gateway
make test-gateway-chat-proxy
make test-gateway-chat-router
make test-gateway-memory-injection
make test-gateway-feedback
make feedback-summary-local
make test-feedback-worker-bridge
make feedback-sync-status
make feedback-sync-to-pc2
make test-feedback-sync
make learning-loop-report-local
make test-learning-loop-report
make improvement-plan-local
make test-improvement-plan
make improvement-patch-plan-local
make test-improvement-patch-plan
make router-prompt-approval-local
make test-router-prompt-approval
make feedback-memory-candidates-local
make test-feedback-memory-candidates
make memory-store-plan-local
make memory-store-approved
make test-memory-store-workflow
make memory-store-audit-local
make test-memory-store-audit
make memory-store-apply-log-status
make test-memory-store-apply-log
make memory-candidate-approval-helper-local
make memory-candidate-list-local
make test-memory-candidate-approval-helper
make memory-approval-dry-run-e2e-local
make memory-approval-dry-run-e2e-status
make test-memory-approval-dry-run-e2e
make test-memory-approval-dashboard
make memory-store-manual-preflight
make test-memory-store-manual-preflight
make pc2-system-status
make docker-summary-snapshot
make docker-summary-status

M29.9 memory approval manual store runbook:

`make memory-store-manual-preflight` validates the manual store checklist before any real write. `make test-memory-store-manual-preflight` covers the preflight script in dry-run-safe tests. Real Memory API writes remain manual only through `APPLY=1 make memory-store-approved`; tests never run `APPLY=1`.

Optional runtime command pack:

make pc1-status
make pc1-startup-coding
make pc1-startup-media-dry
make cluster-status
make cluster-startup-coding
make cluster-startup-media-dry

Optional control planning commands:

make runtime-status
make runtime-mode-coding-plan
make runtime-mode-image-plan
make runtime-mode-video-plan
make runtime-mode-3d-suite-plan
make runtime-mode-media-off-plan
