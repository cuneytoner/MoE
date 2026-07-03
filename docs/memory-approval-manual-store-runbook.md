# Memory Approval Manual Store Runbook

## Purpose

This runbook defines the manual, human-approved process for storing reviewed memory candidates in the Memory API.

Real memory writes are optional and manual. The default workflow is dry-run only. Tests must never run `APPLY=1`.

This runbook belongs to M29.9 and prepares the operator checklist for a future explicit manual store operation. M29.10 adds a read-only real apply guardrail review before any `APPLY=1` write.

## Safety boundaries

- Real memory writes are optional and manual.
- Tests never run `APPLY=1`.
- Only sanitized approved candidates may be stored.
- Raw prompts must not be stored.
- Raw model responses must not be stored.
- Raw feedback reason bodies must not be stored.
- Duplicate candidates should be merged or rejected before approval.
- Dashboard views are read-only.
- Runtime reports must not be committed.
- Memory writes are not automatically reversible.
- Memory cleanup/removal requires a separate reviewed procedure.
- No Docker control is part of this workflow.
- No model switching is part of this workflow.
- No training or fine-tuning is part of this workflow.

## Runtime paths

Memory candidates:

```text
/home/cuneyt/MoE/runtime/reports/memory-candidates/feedback-memory-candidates.json
```

Approval helper report:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json
```

Example approval file:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json
```

Real approval file, manually created only:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json
```

Memory store plan:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json
```

Memory store audit:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json
```

Apply log:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-log.jsonl
```

Apply summary:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json
```

Dry-run E2E report:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json
```

Read-only Dashboard endpoint:

```text
GET /gateway/memory-approval/dashboard
```

## Preconditions

Before considering any real Memory API write:

1. The repository must be clean or changes must be intentionally reviewed.
2. Candidate review must have been generated.
3. Approval helper report must exist.
4. Memory store audit must exist.
5. Duplicate groups must be reviewed.
6. E2E dry-run must pass.
7. Apply-log dry-run summary must exist.
8. The Dashboard must show read-only memory approval status.
9. The real approval file must be created manually.
10. The real approval file must contain only reviewed candidate ids.
11. No runtime report should be staged in Git.

Recommended baseline checks:

```bash
git status

make check-layout
make check-python-syntax
make memory-candidate-approval-helper-local
make memory-candidate-list-local
make memory-store-audit-local
make memory-approval-dry-run-e2e-local
```

## Candidate review steps

Generate or refresh candidate review artifacts:

```bash
make feedback-memory-candidates-local
make memory-candidate-approval-helper-local
make memory-candidate-list-local
```

Review the compact list:

```bash
make memory-candidate-list-local
```

Open the helper report:

```bash
cat /home/cuneyt/MoE/runtime/reports/memory-store/memory-candidate-approval-helper-report.json | jq
```

Check each candidate for:

- stable project-level usefulness
- sanitized text
- no raw prompt text
- no raw model response text
- no raw feedback reason body
- no secrets or credentials
- no short-lived todo disguised as memory
- no duplicate lesson already represented by another candidate

## Duplicate review steps

Generate or refresh audit:

```bash
make memory-store-audit-local
```

Inspect duplicate groups:

```bash
cat /home/cuneyt/MoE/runtime/reports/memory-store/memory-store-audit.json \
  | jq '.duplicate_groups[] | {group_id, category, normalized_title, count, candidate_ids, recommended_action}'
```

Rules:

- Prefer one representative candidate per duplicate group.
- Reject duplicate candidates unless there is a clear reason to keep them separate.
- Do not approve repeated docs/test todos as long-term memory unless they represent a durable project lesson.
- Medium-risk routing/model candidates require extra review.

## Approval file creation steps

The helper creates only an example file:

```bash
make memory-candidate-approval-helper-local
cat /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json | jq
```

Create the real approval file manually only after review:

```bash
cp /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json \
  /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json
```

Edit the real approval file manually:

```bash
nano /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json
```

Example shape:

```json
{
  "approved_candidate_ids": [
    "memory-candidate-001"
  ],
  "notes": "Manually reviewed and approved by operator."
}
```

Do not approve test fixtures for real writes.

## Dry-run steps

Regenerate the store plan after editing approvals:

```bash
make memory-store-plan-local
```

Inspect approved and blocked candidates:

```bash
cat /home/cuneyt/MoE/runtime/reports/memory-store/memory-store-plan.json \
  | jq '.approved_candidates,.blocked_candidates,.memory_write_supported,.apply_supported,.human_review_required'
```

Run dry-run store:

```bash
make memory-store-approved
```

Run dry-run with apply-log recording:

```bash
LOG_DRY_RUN=1 make memory-store-approved
make memory-store-apply-log-status
```

Expected dry-run behavior:

- no Memory API write
- no stored records
- skipped dry-run attempts may be logged when `LOG_DRY_RUN=1`
- `stored_count` remains `0`

## Dashboard verification steps

Check the read-only Gateway endpoint:

```bash
curl -s http://localhost:8100/gateway/memory-approval/dashboard \
  | jq '.service,.read_only,.apply_supported,.approval_supported,.memory_write_supported,.human_review_required,.summary,.e2e,.warnings'
```

Expected safety values:

```text
"memory-approval-dashboard"
true
false
false
false
true
```

Open Dashboard:

```bash
xdg-open http://localhost:8500
```

Dashboard must not include:

- approve button
- apply button
- store button
- Memory API write action
- script execution action

## E2E dry-run verification

Run no-fixture dry-run:

```bash
make memory-approval-dry-run-e2e-local
```

Run fixture dry-run:

```bash
USE_TEST_APPROVAL_FIXTURE=1 make memory-approval-dry-run-e2e-local
```

Check status:

```bash
make memory-approval-dry-run-e2e-status
```

Inspect report:

```bash
cat /home/cuneyt/MoE/runtime/reports/memory-store/memory-approval-dry-run-e2e-report.json \
  | jq '.service,.e2e_status,.dry_run_only,.apply_used,.memory_write_supported,.human_review_required,.test_approval_fixture_used,.test_approval_fixture_removed,.stored_count,.failed_count,.skipped_count'
```

Expected:

```text
dry_run_only: true
apply_used: false
memory_write_supported: false
stored_count: 0
```

## Final APPLY=1 preflight checklist

Before any real write, confirm:

- [ ] Branch and Git state are understood.
- [ ] No runtime reports are staged.
- [ ] Real approval file exists.
- [ ] Real approval file is not a test fixture.
- [ ] `approved_candidate_ids` contains only manually reviewed ids.
- [ ] Duplicate groups were reviewed.
- [ ] Store plan shows the expected approved candidate count.
- [ ] Real apply guardrail passes.
- [ ] Dry-run store was executed successfully.
- [ ] `LOG_DRY_RUN=1 make memory-store-approved` was executed.
- [ ] Apply summary shows `stored_count: 0` before real apply.
- [ ] Dashboard read-only endpoint is healthy if Gateway is running.
- [ ] Memory API is intentionally reachable for the manual write.
- [ ] Operator understands memory writes are not automatically reversible.

Run preflight:

```bash
make memory-store-manual-preflight
```

Run the read-only real apply guardrail:

```bash
make memory-store-real-apply-guardrail
```

The guardrail rejects test fixtures, `dry_run_only=true` approval files, missing approvals, missing approved plan entries, and raw prompt/response markers before Memory API writes. If more than one candidate is approved it prints a batch warning; `ALLOW_BATCH_MEMORY_APPLY=1` silences only that warning and does not bypass any FAIL checks.

Optional live Gateway check:

```bash
CHECK_LIVE_GATEWAY=1 make memory-store-manual-preflight
```

## Actual APPLY=1 command

The actual write command is manual only.

Tests must never run this command.

```bash
APPLY=1 make memory-store-approved
```

Recommended first real write policy:

- approve only one candidate
- run dry-run first
- run preflight
- run real apply guardrail
- run `APPLY=1 make memory-store-approved`
- inspect apply log immediately
- verify Memory API search manually after write
- do not batch-write until one-candidate flow is validated

## Post-apply verification steps

Check apply log status:

```bash
make memory-store-apply-log-status
```

Inspect apply summary:

```bash
cat /home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json \
  | jq '.service,.total_attempts,.stored_count,.failed_count,.skipped_count,.dry_run_count,.memory_write_supported,.human_review_required,.raw_prompt_included,.raw_response_included'
```

Inspect latest log entries:

```bash
tail -n 20 /home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-log.jsonl | jq
```

Expected after real apply:

- attempted approved candidates are logged
- `stored_count` increases only for successful writes
- failed writes include `error_summary`
- raw prompt included is false
- raw response included is false

## Apply log verification

Apply log path:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-log.jsonl
```

Apply summary path:

```text
/home/cuneyt/MoE/runtime/reports/memory-store/memory-store-apply-summary.json
```

The log must not include:

- raw prompt text
- raw model response text
- full raw API response body
- secrets
- credentials

## What not to do

Do not:

- run `APPLY=1` in tests
- approve duplicate candidates blindly
- approve test fixtures for real writes
- store raw prompts
- store raw model responses
- commit runtime reports
- add Dashboard approve/apply/store buttons
- call Memory API from tests
- call llama-server for this workflow
- switch models
- control Docker from app code
- treat memory writes as automatically reversible

## Troubleshooting

If no candidates are approved:

```bash
make memory-candidate-list-local
cat /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.example.json | jq
```

If store plan still shows zero approved candidates:

```bash
cat /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json | jq
make memory-store-plan-local
```

If the approval file is a test fixture:

```bash
cat /home/cuneyt/MoE/runtime/reports/memory-store/approved-memory-candidates.json | jq '.test_fixture,.dry_run_only'
```

Remove or replace it before any real write.

If Dashboard data looks stale:

```bash
curl -s http://localhost:8100/gateway/memory-approval/dashboard | jq '.reports,.warnings'
```

If apply summary is missing:

```bash
LOG_DRY_RUN=1 make memory-store-approved
make memory-store-apply-log-status
```

## Rollback limitations

Memory writes are not automatically reversible.

This workflow does not define automatic rollback. If a bad memory is stored, removal or correction must be handled by a separate reviewed cleanup procedure.

Before real writes, prefer one-candidate validation over batch writes.
