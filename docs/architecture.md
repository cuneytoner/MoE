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

Central API and router entrypoint. It exposes Gateway health, model discovery, chat proxying to the local OpenAI-compatible runtime, optional memory-augmented chat through Memory API search, deterministic intent-aware route decisions, router-aware chat prompt shaping, and advisory model mapping metadata.

apps/memory-api:

Memory storage and search API. It will store memory metadata in PostgreSQL and vector embeddings in Qdrant.

apps/embed-worker:

Embedding generation worker. It will create vectors from text using local embedding models.

The embedding layer now has two planning concerns:

- runtime backend support for local models such as BGE-M3
- model integrity validation so local mounts and files are trustworthy before other layers depend on them

Host model runtime:

Host-managed llama.cpp serving layer for local GGUF chat and coding models. It exposes an OpenAI-compatible endpoint at `http://localhost:8000/v1`, with model files loaded from `/home/cuneyt/MoE_Models_Backup` and runtime logs/pids stored under `/home/cuneyt/MoE/runtime`.

Backup and environment planning:

Backup planning covers source, runtime, PostgreSQL, Qdrant, model backups, llama.cpp, and docs without copying runtime data into the codebase. Environment profile templates describe how PC1, PC2, single-machine, and future machines can own roles without rewriting the project.

Future local AI stack layers expected around it:

- advanced model routing through future Gateway work
- document RAG ingestion and vector workflows
- local chat UI integration
- coding agent integration
- automation layer such as n8n
- homelab operations and container management

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
