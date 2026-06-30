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

Milestone 25: Media Lab Foundation in progress

Next planned milestone:

Milestone 26: Image Generation Service
