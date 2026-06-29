# Coding Workspace Roadmap

The local AI stack becomes practically useful for day-to-day code development after two near-term milestones:

- Milestone 20: Local Coding Workspace Integration
- Milestone 21: Continue.dev / VS Code Gateway Integration

These milestones should keep the repository source-only and preserve strict separation between code, runtime state, and model files.

Nightly learning begins later, after Milestone 24. It can summarize coding activity and store useful lessons, but it remains read-only and report-first. Automatic self-modification is explicitly out of scope until a later approval-gated milestone.

## Milestone 20: Local Coding Workspace Integration

Goal: give Gateway safe read-only awareness of a repository without enabling file writes.

Planned capabilities:

- Read-only workspace context provider.
- Repo file tree endpoint.
- Safe file search endpoint.
- Code task prompt templates for explanation, debugging, review, and implementation planning.
- No file writes.
- No patch application.
- No shell execution.

The first workspace provider should only read allowed paths and return bounded context. It should avoid runtime folders, model files, caches, virtual environments, database data, Docker volumes, logs, and generated artifacts.

## Milestone 21: Continue.dev / VS Code Gateway Integration

Goal: make the local stack comfortable from the editor.

Planned capabilities:

- Point Continue.dev to Gateway or directly to the host OpenAI-compatible model runtime.
- Add coding model profiles for `qwen-coder-14b-fast`, `qwen-coder-32b-main`, and `deepseek-coder-lite`.
- Add local prompt templates for common coding tasks.
- Document how to use the stack as a coding assistant from VS Code.

The default editor workflow should be read-first: gather workspace context, route the request, optionally use memory, and call the current model runtime.

## Milestone 22: Repo-Aware Coding Agent

Goal: combine workspace context, memory, router metadata, and model runtime into a coherent coding assistant.

Initial tasks:

- Explain selected code.
- Debug errors and tracebacks.
- Review code and docs.
- Produce implementation plans.

This milestone should still avoid automatic file writes.

## Milestone 23: Safe Write/Edit Plan for Code

Goal: design the write boundary before any editing automation exists.

Planned safety model:

- Generate patches only.
- Do not auto-apply changes.
- Present diffs for review.
- Keep edit approval explicit.
- Preserve user changes and avoid unrelated rewrites.

Automatic patch application belongs only after this workflow is reviewed and deliberately enabled.
