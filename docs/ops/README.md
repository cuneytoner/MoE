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
| Startup service matrix | [16-startup-service-matrix.md](16-startup-service-matrix.md) |
| Mode startup recipes | [17-mode-startup-recipes.md](17-mode-startup-recipes.md) |
| Image mode entry checklist | [18-image-mode-entry-checklist.md](18-image-mode-entry-checklist.md) |
| Media readiness map | [19-media-readiness-map.md](19-media-readiness-map.md) |
| Image mode safety rules | [20-image-mode-safety-rules.md](20-image-mode-safety-rules.md) |
| Image pipeline entry plan | [21-image-pipeline-entry-plan.md](21-image-pipeline-entry-plan.md) |
| Image processing pipeline runbook | [22-image-processing-pipeline-runbook.md](22-image-processing-pipeline-runbook.md) |
| Image model inventory guide | [23-image-model-inventory-guide.md](23-image-model-inventory-guide.md) |
| Image first dry-run plan | [24-image-first-dry-run-plan.md](24-image-first-dry-run-plan.md) |
| ComfyUI Flux startup checklist | [25-comfyui-flux-startup-checklist.md](25-comfyui-flux-startup-checklist.md) |
| ComfyUI Flux blockers | [26-comfyui-flux-blockers.md](26-comfyui-flux-blockers.md) |
| ComfyUI Flux startup evidence template | [27-comfyui-flux-startup-evidence-template.md](27-comfyui-flux-startup-evidence-template.md) |
| Image mode VRAM safety | [28-image-mode-vram-safety.md](28-image-mode-vram-safety.md) |
| Manual LLM stop start plan | [29-manual-llm-stop-start-plan.md](29-manual-llm-stop-start-plan.md) |
| Image mode return to coding | [30-image-mode-return-to-coding.md](30-image-mode-return-to-coding.md) |
| First image dry-run evidence review | [31-first-image-dry-run-evidence-review.md](31-first-image-dry-run-evidence-review.md) |
| First image dry-run evidence template | [32-first-image-dry-run-evidence-template.md](32-first-image-dry-run-evidence-template.md) |
| First image dry-run review checklist | [33-first-image-dry-run-review-checklist.md](33-first-image-dry-run-review-checklist.md) |
| Image existing script map | [34-image-existing-script-map.md](34-image-existing-script-map.md) |
| First real image generation drill | [35-first-real-image-generation-drill.md](35-first-real-image-generation-drill.md) |
| First real image generation evidence template | [36-first-real-image-generation-evidence-template.md](36-first-real-image-generation-evidence-template.md) |
| Generated image Git safety | [37-generated-image-git-safety.md](37-generated-image-git-safety.md) |

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
10. [16 Startup Service Matrix](16-startup-service-matrix.md)
11. [17 Mode Startup Recipes](17-mode-startup-recipes.md)
12. [18 Image Mode Entry Checklist](18-image-mode-entry-checklist.md)
13. [19 Media Readiness Map](19-media-readiness-map.md)
14. [20 Image Mode Safety Rules](20-image-mode-safety-rules.md)
15. [21 Image Pipeline Entry Plan](21-image-pipeline-entry-plan.md)
16. [22 Image Processing Pipeline Runbook](22-image-processing-pipeline-runbook.md)
17. [23 Image Model Inventory Guide](23-image-model-inventory-guide.md)
18. [24 Image First Dry Run Plan](24-image-first-dry-run-plan.md)
19. [25 ComfyUI Flux Startup Checklist](25-comfyui-flux-startup-checklist.md)
20. [26 ComfyUI Flux Blockers](26-comfyui-flux-blockers.md)
21. [27 ComfyUI Flux Startup Evidence Template](27-comfyui-flux-startup-evidence-template.md)
22. [28 Image Mode VRAM Safety](28-image-mode-vram-safety.md)
23. [29 Manual LLM Stop Start Plan](29-manual-llm-stop-start-plan.md)
24. [30 Image Mode Return To Coding](30-image-mode-return-to-coding.md)
25. [31 First Image Dry Run Evidence Review](31-first-image-dry-run-evidence-review.md)
26. [32 First Image Dry Run Evidence Template](32-first-image-dry-run-evidence-template.md)
27. [33 First Image Dry Run Review Checklist](33-first-image-dry-run-review-checklist.md)
28. [34 Image Existing Script Map](34-image-existing-script-map.md)
29. [35 First Real Image Generation Drill](35-first-real-image-generation-drill.md)
30. [36 First Real Image Generation Evidence Template](36-first-real-image-generation-evidence-template.md)
31. [37 Generated Image Git Safety](37-generated-image-git-safety.md)

Run the backup drill after major milestones or before moving to a new machine.

M31.0 defines the image pipeline. M31.1 adds the ComfyUI / Flux startup checklist. Real generation remains explicit operator action.

Before real image generation, read 25 through 33.

Real image generation requires explicit `APPLY=1` and `MEDIA_REAL_GENERATION_ENABLED=true`. Do not run those commands unless you intentionally want generation.
