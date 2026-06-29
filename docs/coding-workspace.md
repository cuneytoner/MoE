# Coding Workspace Roadmap

The local AI stack becomes practically useful for day-to-day code development after two near-term milestones:

- Milestone 20: Local Coding Workspace Integration
- Milestone 21: Continue.dev / VS Code Gateway Integration

These milestones should keep the repository source-only and preserve strict separation between code, runtime state, and model files.

Nightly learning begins later, after Milestone 24. It can summarize coding activity and store useful lessons, but it remains read-only and report-first. Automatic self-modification is explicitly out of scope until a later approval-gated milestone.

## Milestone 20: Local Coding Workspace Integration

Goal: give Gateway safe read-only awareness of a repository without enabling file writes.

Implemented scope:

- Read-only workspace context provider.
- Repo file tree endpoint: `GET /gateway/workspace/tree`.
- Safe file read endpoint: `GET /gateway/workspace/file`.
- Safe file search endpoint: `POST /gateway/workspace/search`.
- Context bundle endpoint: `POST /gateway/workspace/context`.
- Read-only workspace tools through `/gateway/tools/execute`.
- No file writes.
- No patch application.
- No shell execution.

The Gateway container mounts the source code as `/workspace:ro`. The provider only reads allowed paths and returns bounded context. It avoids runtime folders, model files, caches, virtual environments, database data, Docker volumes, logs, and generated artifacts.

Security model:

- Resolve every path under `WORKSPACE_ROOT`.
- Reject path traversal and absolute paths.
- Return workspace-relative paths only.
- Exclude ignored directories such as `.git`, `node_modules`, `runtime`, `models`, `data`, and virtual environments.
- Read only allowed text-like files.
- Reject binary files.
- Reject files larger than `WORKSPACE_MAX_FILE_BYTES`.

Supported file names and extensions are configured with `WORKSPACE_ALLOWED_EXTENSIONS`.

Current limitation: this milestone prepares context only. It does not generate patches, apply edits, or run commands.

## Milestone 21: Continue.dev / VS Code Gateway Integration

Goal: make the local stack comfortable from the editor.

Implemented integration docs:

- Point Continue.dev to Gateway or directly to the host OpenAI-compatible model runtime.
- Add coding model profiles for `qwen-coder-14b-fast`, `qwen-coder-32b-main`, and `deepseek-coder-lite`.
- Add local prompt templates for common coding tasks.
- Document how to use the stack as a coding assistant from VS Code.

See `docs/continue-dev.md` and the templates under `configs/continue/`.

The default editor workflow should be read-first: Continue.dev calls Gateway's OpenAI-compatible adapter, Gateway routes the request, optionally uses memory, and calls the current model runtime. Workspace context is available through Gateway endpoints and read-only tools; automatic repo-aware context selection is planned for Milestone 22.

## Milestone 22: Repo-Aware Coding Agent

Goal: combine workspace context, memory, router metadata, and model runtime into a coherent coding assistant.

Implemented read-only agent layer:

- `POST /gateway/code/context` searches the workspace, includes explicit paths, de-duplicates files, and builds selected-file context.
- `POST /gateway/code/ask` builds selected-file context, adds a repo-aware system prompt, and calls the existing Gateway chat flow.
- Selected files include workspace-relative paths and reasons such as query matches or explicit selection.
- Responses include routing and memory metadata when the model-backed ask endpoint succeeds.

The repo-aware agent remains read-only:

- No file writes.
- No shell execution.
- No patch application.
- No automatic editing.
- No host runtime control or model switching.

If the model runtime is unavailable, `/gateway/code/ask` returns a controlled unavailable response. The default Gateway tests do not require generated model content.

## Milestone 23: Safe Write/Edit Plan for Code

Goal: design the write boundary before any editing automation exists.

Planned safety model:

- Generate patches only.
- Do not auto-apply changes.
- Present diffs for review.
- Keep edit approval explicit.
- Preserve user changes and avoid unrelated rewrites.

Automatic patch application belongs only after this workflow is reviewed and deliberately enabled.
