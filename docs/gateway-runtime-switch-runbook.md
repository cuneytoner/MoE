# Gateway Runtime Switch Runbook

M29.14 links Gateway runtime switch planning to this manual runbook. Gateway-Auto is advisory-only, and Gateway does not switch models automatically.

## Safety Contract

- `/gateway/runtime/switch-plan` returns planning metadata only.
- A human operator must stop and start `llama-server` manually.
- Gateway does not start, stop, restart, or switch model runtimes.
- Gateway does not execute terminal actions, control Docker, write files, or call Memory API write routes.
- No `APPLY=1` is involved.
- Tests do not run real runtime switching.

## Manual Review Flow

1. Read the `/gateway/runtime/switch-plan` response and confirm it is `status: plan_only`.
2. Check `/v1/models` before any manual runtime change.
3. Confirm Continue still points to Gateway-Auto through `http://localhost:8100/v1`.
4. If a runtime change is still desired, the human operator manually stops the current `llama-server` process and starts the desired model using the documented local process.
5. Check `/v1/models` after the manual runtime change.
6. Verify `/v1/chat/completions` through Gateway after the runtime change.
7. If the new runtime is unhealthy, rollback means manually restarting the previous known-good `llama-server` command.

## Continue Checks

- Keep Continue configured for Gateway-Auto rather than direct model paths.
- Confirm the selected Continue profile still uses the Gateway base URL.
- Reconnect Continue after the manual runtime change if the client held an old connection.

This runbook is documentation only. Any future real guarded switching would require a separate milestone and human-reviewed safety design.
