# Feedback Sync PC1 to PC2

Milestone 28.7 adds explicit user-run sync tooling for Gateway feedback.

PC1 is the feedback producer. Gateway appends metadata-only records to:

```text
/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl
```

PC2 is the feedback summarizer and worker node. The default PC2 destination is:

```text
cuneyt@192.168.50.2:/home/cuneyt/MoE/runtime/feedback
```

## Commands

Read-only status:

```bash
make feedback-sync-status
```

Dry-run sync plan:

```bash
make feedback-sync-to-pc2
```

Actual sync:

```bash
APPLY=1 make feedback-sync-to-pc2
```

Dry-run is the default. `APPLY=1` is required before any SSH directory creation or `rsync` copy happens.

## Synced Files

The sync is intentionally narrow:

- `gateway-feedback.jsonl`
- `reports/feedback-summary.json` when present

It does not sync repository files, model files, media outputs, all runtime data, Docker state, logs, caches, prompts, or model responses.

The sync does not use deletion flags and does not remove destination files.

## Environment Overrides

```text
PC2_HOST=cuneyt@192.168.50.2
PC2_FEEDBACK_DIR=/home/cuneyt/MoE/runtime/feedback
FEEDBACK_JSONL_PATH=/home/cuneyt/MoE/runtime/feedback/gateway-feedback.jsonl
FEEDBACK_REPORTS_DIR=/home/cuneyt/MoE/runtime/feedback/reports
```

No SSH keys or real environment files are stored in the repository.

## Safety

This milestone does not train, fine-tune, mutate memory, modify prompts, change router config, switch models, control Docker, start or stop services, or add dashboard controls.

The next step is a reviewed learning loop report. It consumes aggregate summaries only and writes human-reviewable recommendations under `/home/cuneyt/MoE/runtime/reports/learning-loop/learning-loop-report.json`.

```bash
make learning-loop-report-local
```

It does not apply changes automatically.

Milestone 28.9 turns the reviewed learning-loop report into a human-approved improvement plan:

```bash
make improvement-plan-local
```

The improvement plan remains advisory and does not edit files, write memory, train models, switch models, or control services.
