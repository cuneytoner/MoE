# MoE / AI-Brain-OS Architecture

## Goal

A local multi-PC AI system for coding, memory, routing, monitoring, and future agent workflows.

The system is designed around a strict separation between source code and runtime state.

Source code lives only in:

/home/cuneyt/DiskD/Projects/MoE/codebase

Runtime environments live in:

/home/cuneyt/MoE

## PC1

Role:

- Main workstation
- Source code owner
- Codex and Continue workspace
- Strong GPU inference node
- Deployment controller
- Dashboard access point

Specs:

- Ryzen 7 7700X3D
- RTX 5060 Ti
- 32 GB RAM
- IP: 192.168.50.1

Paths:

- Source: /home/cuneyt/DiskD/Projects/MoE/codebase
- Runtime: /home/cuneyt/MoE

## PC2

Role:

- Runtime worker node
- Memory services
- Database services
- Future worker and fallback services

Specs:

- Ryzen 3 3100
- GTX 1650
- 32 GB RAM
- IP: 192.168.50.2

Path:

- Runtime: /home/cuneyt/MoE

## Network

PC1 and PC2 are connected over Cat5 direct network.

SSH:

- User: cuneyt
- Passwordless SSH is expected from PC1 to PC2.

## High-Level Components

apps/gateway-api:

Central API and router entrypoint. It will eventually expose chat, routing, health, and model discovery endpoints.

apps/memory-api:

Memory storage and search API. It will store memory metadata in PostgreSQL and vector embeddings in Qdrant.

apps/embed-worker:

Embedding generation worker. It will create vectors from text using local embedding models.

apps/dashboard:

Management and monitoring UI. It will show service health, machine status, GPU status, model endpoints, and memory system status.

packages/shared:

Shared utilities used across services.

packages/schemas:

Shared API and data schemas.

packages/clients:

Internal service clients for gateway, memory, embedding, and dashboard communication.

infra/docker:

Docker and Compose-related infrastructure files.

infra/postgres:

PostgreSQL initialization and migration-related files.

infra/qdrant:

Qdrant configuration and collection setup files.

infra/scripts:

Infrastructure helper scripts.

deploy/pc1:

PC1-specific deployment configuration.

deploy/pc2:

PC2-specific deployment configuration.

scripts:

Local helper scripts used from the codebase.

## Runtime Principle

The repository is not the runtime environment.

The codebase should remain clean, portable, and source-only.

Runtime state belongs under:

/home/cuneyt/MoE

This includes:

- database data
- logs
- Docker volumes
- model caches
- temporary files
- generated runtime configuration