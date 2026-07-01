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

Milestone 26.6: Guided Image Generation Command Pack in progress

Next planned milestone:

Milestone 26.7: Image Prompt Presets and History

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
