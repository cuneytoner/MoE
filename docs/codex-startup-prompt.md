# Codex Startup Prompt

## Purpose

Use this document to start new Codex chats with the correct MoE / AI-Brain-OS project boundaries, source/runtime separation rules, and documentation context.

`AGENTS.md` is the primary rule source. If another doc conflicts with `AGENTS.md`, follow `AGENTS.md` first and ask before changing runtime, model, Docker, or secret-related files.

## Reusable New-Chat Startup Prompt

```text
I am working in ~/DiskD/Projects/MoE/codebase on the local MoE / AI-Brain-OS project. First read AGENTS.md and the relevant docs/milestones.md, docs/architecture.md, and docs/codex-prompts.md sections. Respect source-only repo rules: runtime data stays in ~/MoE/runtime, models stay in ~/MoE_Models_Backup, no real .env files, no model downloads, no commits unless explicitly asked. Keep changes milestone-scoped. After changes, show changed files and exact verification commands.
```

## When To Use It

Use this prompt at the start of a new Codex chat, especially before milestone work, architecture changes, Gateway/API changes, model-runtime-adjacent changes, or documentation updates that mention paths and operating rules.

## Docs Codex Should Read First

- `AGENTS.md`
- `docs/milestones.md`
- `docs/architecture.md`
- `docs/codex-prompts.md`
- Any milestone-specific doc relevant to the task

## Standard Verification Commands

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
