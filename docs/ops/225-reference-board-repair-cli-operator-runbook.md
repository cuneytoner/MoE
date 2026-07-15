# Reference Board Repair CLI Operator Runbook

## Purpose

Explain how to safely inspect, back up, and repair reference board runtime JSON files.

M34.51 summarizes the completed repair CLI workflow and remaining gaps.

## Safety Model

- validate first
- dry-run first
- backup before `APPLY=1`
- `APPLY=1` only after human review
- source assets are never modified
- metadata sidecars are never modified
- output cards are never deleted
- stale items are marked, not removed
- duplicate item repair removes only duplicate board item entries
- no generation
- no shell execution through Gateway/Dashboard

## Tool Summary

- `make reference-board-store-validate`
- `make reference-board-store-backup`
- `make reference-board-store-repair`
- `make reference-board-store-repair-regression`
- `make reference-board-duplicate-item-repair-regression`
- `make reference-board-stale-item-regression`

## Standard Safe Flow

```bash
cd ~/DiskD/Projects/MoE/codebase
```

```bash
BOARD_ID=api-test-board make reference-board-store-validate
jq . /tmp/moe-reference-board-store-validate-report.json
```

```bash
BOARD_ID=api-test-board make reference-board-store-backup
jq . /tmp/moe-reference-board-store-backup-report.json
```

```bash
BOARD_ID=api-test-board make reference-board-store-repair
jq . /tmp/moe-reference-board-store-repair-report.json
```

## repair-schema Flow

Dry-run:

```bash
BOARD_ID=api-test-board MODE=repair-schema make reference-board-store-repair
```

Apply:

```bash
BOARD_ID=api-test-board make reference-board-store-backup
BOARD_ID=api-test-board MODE=repair-schema APPLY=1 make reference-board-store-repair
```

## Duplicate Item Repair Flow

Dry-run:

```bash
BOARD_ID=api-test-board MODE=remove-duplicate-items make reference-board-store-repair
```

Apply:

```bash
BOARD_ID=api-test-board make reference-board-store-backup
BOARD_ID=api-test-board MODE=remove-duplicate-items APPLY=1 make reference-board-store-repair
```

## Stale Item Marking Flow

Dry-run:

```bash
BOARD_ID=api-test-board MODE=mark-stale-items make reference-board-store-repair
```

Apply:

```bash
BOARD_ID=api-test-board make reference-board-store-backup
BOARD_ID=api-test-board MODE=mark-stale-items APPLY=1 make reference-board-store-repair
```

`mark-stale-items` does not delete stale items. Stale items remain visible in board JSON and exports. Stale markers are review hints for operators.

After repair or stale marking, use JSON and Markdown exports to review item status.

## Regression Flow

```bash
make reference-board-export-regression
make reference-board-malformed-store-regression
make reference-board-store-validate
make reference-board-store-repair-regression
make reference-board-duplicate-item-repair-regression
make reference-board-stale-item-regression
```

Expected outputs:

- `Reference board export regression OK`
- `Reference board malformed store regression OK`
- `Reference board store validation OK`
- `Reference board store repair regression OK`
- `Reference board duplicate item repair regression OK`
- `Reference board stale item regression OK`

`Reference board store repair failed` can be expected inside regression scripts when they test backup-required failure paths.

## Report Files

- `/tmp/moe-reference-board-store-validate-report.json`
- `/tmp/moe-reference-board-store-backup-report.json`
- `/tmp/moe-reference-board-store-repair-report.json`

## Backup Review

Backups are stored under:

```text
/home/cuneyt/MoE/runtime/reference-boards/backups
```

Backup filename pattern:

```text
reference-board-{board_id}-{YYYYMMDD-HHMMSS}.json.bak
```

## Stop Conditions

Do not apply repair if:

- validate report has unexpected errors
- backup was not created
- `BOARD_ID` is wrong
- report proposes removals you do not understand
- stale marks point to unexpected real assets
- any command tries to touch source assets
- git status shows generated binaries in repo
- runtime path looks wrong

## Git Safety

```bash
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth|pdf|dxf|svg)$' || true
```

Expected:

```text
No output.
```

## Non-Goals

- no automatic repair
- no dashboard repair button
- no backend repair endpoint
- no stale deletion
- no source asset deletion
- no metadata sidecar deletion
- no generation
- no ZIP/PDF
