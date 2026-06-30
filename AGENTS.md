# MoE / AI-Brain-OS Codex Instructions

## 1. Project Identity

This repo is the source-only codebase for the local MoE / AI-Brain-OS system.

- Main source path: `~/DiskD/Projects/MoE/codebase`
- Runtime path: `~/MoE/runtime`
- Model backup path: `~/MoE_Models_Backup`

Never place runtime data, generated media, logs, pids, model files, checkpoints, or secrets inside the repo.

## 2. Golden Rules

- Keep codebase source-only.
- Do not create real `.env` files.
- Use `.env.example` only.
- Do not download models.
- Do not copy models into codebase.
- Do not modify model files.
- Do not write runtime data into the repo.
- Do not create `__pycache__`.
- Do not use `python3 -m py_compile` in docs or tests.
- Prefer AST-based syntax checks or existing `make check-python-syntax`.
- Never run destructive commands unless explicitly requested by the user.
- Never execute Docker/model runtime changes unless the task specifically asks for it.
- Keep changes milestone-scoped.
- Do not commit unless explicitly asked.

## 3. Current Architecture

- Gateway API runs on port `8100`.
- Memory API runs on port `8101`.
- Embed Worker runs on port `8102`.
- `llama.cpp` model runtime runs on port `8000`.
- PostgreSQL runs on port `5432`.
- Qdrant runs on port `6333`.
- Workspace is mounted read-only into Gateway as `/workspace`.
- Gateway must not write files, execute shell commands, or switch models automatically.

## 4. Current Model Inventory

- `qwen-coder-14b-fast`
  - Path: `/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf`
  - Status: healthy
- `deepseek-coder-lite`
  - Path: `/home/cuneyt/MoE_Models_Backup/DeepSeek-Coder-V2-Lite-Instruct-IQ4_XS.gguf`
  - Status: healthy fallback
- `qwen-coder-32b-main`
  - Path: `/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-32B-Instruct-IQ4_XS.gguf`
  - Status: available/heavy
- `BGE-M3`
  - Path: `/home/cuneyt/MoE_Models_Backup/bge-m3`
  - Status: healthy, 1024-dimensional embeddings

## 5. Completed Milestones Summary

- Docker foundation
- Memory API
- Embed Worker
- BGE-M3 runtime
- Dimension-aware memory search
- Model Runtime Management
- Gateway API
- Memory-augmented chat
- Intent-aware router
- Router-aware chat
- Model routing map
- Runtime switch planning
- Tool-aware routing
- Controlled read-only tool execution
- Read-only coding workspace context
- Continue.dev / VS Code integration

## 6. Current And Planned Milestones

- Milestone 24.0.1: PC-2 Nightly Worker Activation in progress
- Milestone 24.1: Research Ingestion Worker
- Milestone 25: Media Lab Foundation
- Milestone 26: Image Generation Service
- Milestone 27: Video Generation Service
- Milestone 28: 3D Model Generation Pipeline
- Milestone 29: Rigging Pipeline
- Milestone 30: Animation Pipeline
- Milestone 31: Media Workflow Orchestrator

## 7. Standard Verification Commands

```bash
cd ~/DiskD/Projects/MoE/codebase
find . -type d -name "__pycache__" -prune -exec rm -rf {} +
make check-layout
make check-python-syntax
make check-models
make test
git status --short
git diff --stat
```

## 8. Docker Verification

```bash
make docker-down
docker compose -f infra/docker/docker-compose.yml up -d --build
make docker-ps
make test
```

## 9. Model Runtime Verification

```bash
make model-switch MODEL=qwen-coder-14b-fast
make model-health
curl -s http://localhost:8000/v1/models | jq '.data[0].id'
```

## 10. Gateway Smoke Tests

```bash
curl -s http://localhost:8100/gateway/workspace/status | jq .
curl -s http://localhost:8100/gateway/model-routing | jq .
curl -s http://localhost:8100/gateway/runtime/status | jq .
```

## 11. Codex Work Style

- First inspect relevant files.
- Then propose minimal changes.
- Prefer small, reviewable diffs.
- Update docs and tests together with code.
- Show changed files and exact test commands.
- Do not hide uncertainty.
- If a requested change may violate source/runtime/model separation, stop and explain.
- Keep user-facing instructions terminal-first.
- Preserve Turkish project context when updating docs if already Turkish; otherwise keep technical docs in English.

## 12. New Task Startup Prompt

```text
I am working in ~/DiskD/Projects/MoE/codebase on the local MoE / AI-Brain-OS project. First read AGENTS.md and the relevant docs/milestones.md, docs/architecture.md, and docs/codex-prompts.md sections. Respect source-only repo rules: runtime data stays in ~/MoE/runtime, models stay in ~/MoE_Models_Backup, no real .env files, no model downloads, no commits unless explicitly asked. Keep changes milestone-scoped. After changes, show changed files and exact verification commands.
```
