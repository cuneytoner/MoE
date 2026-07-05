# Operator Runbook Pack

This folder is the beginner operator guide for the local MoE / AI-Brain-OS system. It tells you which machine to use, which command to run, and what a good result usually looks like.

## Fixed Machine Facts

| Machine | IP | Role | Main paths |
| --- | --- | --- | --- |
| PC-1 | `192.168.50.1` | Main workstation/operator machine | `~/DiskD/Projects/MoE/codebase`, `~/MoE_Models_Backup/`, `~/Apps/llama.cpp/build/bin/llama-server` |
| PC-2 | `192.168.50.2` | Worker/support machine | `~/DiskD/Projects/MoE/codebase` |

PC-1 runs Continue.dev, Gateway API on port `8100`, llama-server on port `8000`, and local operator commands.

PC-2 runs or supports Memory API on port `8101`, Embed Worker on port `8102`, Postgres on port `5432`, Qdrant on ports `6333` and `6334`, and background workers when enabled.

Continue.dev runs on PC-1 and should point to:

```yaml
apiBase: http://localhost:8100/v1
model: gateway-auto
```

Gateway runs on PC-1. It must not switch models automatically. Runtime profile endpoints are read-only and advisory.

## Command Labels Used In This Folder

Every command block should tell you where to run it:

- `[PC-1 terminal]` means open a terminal on PC-1.
- `[PC-2 terminal]` means open a terminal on PC-2.
- `[PC-1 terminal checking PC-2]` means run the command from PC-1 against PC-2 at `192.168.50.2`.

Verify first, act second.

If you are unsure where to run a command, stop and check [13-service-location-reference.md](13-service-location-reference.md).

## Which Document Should I Open?

| Situation | Open this |
| --- | --- |
| New installation PC-1 only | [01-fresh-install-pc1.md](01-fresh-install-pc1.md) |
| New installation PC-2 | [02-fresh-install-pc2.md](02-fresh-install-pc2.md) |
| Daily startup both PCs | [03-daily-startup.md](03-daily-startup.md) |
| Daily shutdown | [04-daily-shutdown.md](04-daily-shutdown.md) |
| Backup | [05-backup.md](05-backup.md) |
| Restore to new PC | [06-restore-new-machine.md](06-restore-new-machine.md) |
| Troubleshooting | [07-troubleshooting.md](07-troubleshooting.md) |
| Command cheat sheet | [08-command-cheatsheet.md](08-command-cheatsheet.md) |
| Git workflow | [09-git-workflow.md](09-git-workflow.md) |
| Runtime profile endpoints | [10-runtime-profile-guide.md](10-runtime-profile-guide.md) |
| First day complete walkthrough | [11-first-day-walkthrough.md](11-first-day-walkthrough.md) |
| Zero to running compact checklist | [12-zero-to-running-checklist.md](12-zero-to-running-checklist.md) |
| Service location reference | [13-service-location-reference.md](13-service-location-reference.md) |
| Backup restore drill | [14-backup-restore-drill.md](14-backup-restore-drill.md) |
| Disaster recovery card | [15-disaster-recovery-card.md](15-disaster-recovery-card.md) |

If you are lost, open [11-first-day-walkthrough.md](11-first-day-walkthrough.md), then [12-zero-to-running-checklist.md](12-zero-to-running-checklist.md), then [13-service-location-reference.md](13-service-location-reference.md).

## Recommended Reading Order

1. [00 System Map](00-system-map.md)
2. [13 Service Location Reference](13-service-location-reference.md)
3. [11 First Day Walkthrough](11-first-day-walkthrough.md)
4. [12 Zero To Running Checklist](12-zero-to-running-checklist.md)
5. [03 Daily Startup](03-daily-startup.md)
6. [07 Troubleshooting](07-troubleshooting.md)
7. [08 Command Cheatsheet](08-command-cheatsheet.md)
8. [14 Backup Restore Drill](14-backup-restore-drill.md)
9. [15 Disaster Recovery Card](15-disaster-recovery-card.md)

Run the backup drill after major milestones or before moving to a new machine.
