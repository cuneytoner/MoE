# Reference Board Repair CLI Summary Review

## Purpose

Summarize the completed reference board repair CLI workflow.

## Completed Tooling

- `reference-board-store-validate`
- `reference-board-store-backup`
- `reference-board-store-repair`
- `repair-schema` mode
- `remove-duplicate-items` mode
- `mark-stale-items` mode
- repair regression
- duplicate repair regression
- stale item regression
- operator runbook

## Safety Boundary Review

Confirmed boundaries:

- dry-run default
- `APPLY=1` required for writes
- backup required before `APPLY=1`
- no source asset modification
- no metadata sidecar modification
- no output card deletion
- stale items are marked, not removed
- duplicate repair removes only duplicate board JSON entries
- no generation
- no Gateway/Dashboard repair buttons
- no shell execution through Gateway/Dashboard
- runtime/source/model separation preserved

## Mode Matrix

| command/mode | writes board file? | requires APPLY=1? | requires backup? | modifies source assets? | modifies metadata? | intended use |
| --- | --- | --- | --- | --- | --- | --- |
| `make reference-board-store-validate` | no | no | no | no | no | inspect board store shape and safety findings |
| `make reference-board-store-backup` | no board write | no | no | no | no | copy one board JSON to runtime backup folder before repair |
| `MODE=repair-schema make reference-board-store-repair` | only with apply | yes | yes for apply | no | no | normalize safe schema details such as tags and trim-only fields |
| `MODE=remove-duplicate-items make reference-board-store-repair` | only with apply | yes | yes for apply | no | no | remove later duplicate board JSON item entries only |
| `MODE=mark-stale-items make reference-board-store-repair` | only with apply | yes | yes for apply | no | no | add stale review markers to stale board item references |

## Regression Matrix

| target | fixture or real board? | expected OK message | expected intentional failure messages | cleanup behavior |
| --- | --- | --- | --- | --- |
| `reference-board-export-regression` | real `api-test-board` review flow | `Reference board export regression OK` | none expected | no fixture cleanup |
| `reference-board-malformed-store-regression` | temporary malformed board fixture | `Reference board malformed store regression OK` | controlled non-2xx API responses expected | removes malformed fixture board |
| `reference-board-store-repair-regression` | temporary repair board fixture | `Reference board store repair regression OK` | `Reference board store repair failed` during no-backup apply check | removes fixture board and matching backups |
| `reference-board-duplicate-item-repair-regression` | temporary duplicate board fixture | `Reference board duplicate item repair regression OK` | `Reference board store repair failed` during no-backup apply check | removes fixture board and matching backups |
| `reference-board-stale-item-regression` | temporary stale board fixture | `Reference board stale item regression OK` | `Reference board store repair failed` during no-backup apply check | removes fixture board and matching backups |

## Report Files

- `/tmp/moe-reference-board-store-validate-report.json`
- `/tmp/moe-reference-board-store-backup-report.json`
- `/tmp/moe-reference-board-store-repair-report.json`

## Known Observations

- Regression scripts may print `Reference board store repair failed` when intentionally testing `APPLY=1` without backup.
- Existing `api-test-board` may show `metadata_path_unsafe` if its `metadata_path` is absolute.
- That should be reviewed before applying stale marks to real boards.
- Runtime backup files can accumulate under `reference-boards/backups` and should be managed by a future retention policy.

## Remaining Gaps

- export/dashboard polish for stale/duplicate status
- backup retention policy
- optional restore workflow
- optional stale marker cleanup
- optional stale removal plan, not implemented
- operator review before applying to real boards

## Recommended Next Milestone

Recommended next milestone:

```text
M34.52 Reference Board Export Stale/Duplicate Status Polish
```

Exports should clearly surface duplicate/stale status before any dashboard polish or cleanup policy.

## Non-Goals

- no code changes
- no runtime mutation
- no source asset mutation
- no generation
- no ZIP/PDF
- no dashboard repair controls
