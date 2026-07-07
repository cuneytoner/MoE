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
| Generated image output handling | [38-generated-image-output-handling.md](38-generated-image-output-handling.md) |
| First image success record | [39-first-image-success-record.md](39-first-image-success-record.md) |
| Image output cleanup policy | [40-image-output-cleanup-policy.md](40-image-output-cleanup-policy.md) |
| ComfyUI workflow inventory | [41-comfyui-workflow-inventory.md](41-comfyui-workflow-inventory.md) |
| Flux Schnell parameter guide | [42-flux-schnell-parameter-guide.md](42-flux-schnell-parameter-guide.md) |
| ComfyUI workflow change log | [43-comfyui-workflow-change-log.md](43-comfyui-workflow-change-log.md) |
| Gateway real image run drill | [44-gateway-real-image-run-drill.md](44-gateway-real-image-run-drill.md) |
| Gateway real image evidence template | [45-gateway-real-image-evidence-template.md](45-gateway-real-image-evidence-template.md) |
| Gateway real image troubleshooting | [46-gateway-real-image-troubleshooting.md](46-gateway-real-image-troubleshooting.md) |
| Prompt variants plan | [47-prompt-variants-plan.md](47-prompt-variants-plan.md) |
| Small batch image safety | [48-small-batch-image-safety.md](48-small-batch-image-safety.md) |
| Image comparison notes template | [49-image-comparison-notes-template.md](49-image-comparison-notes-template.md) |
| Batch output naming policy | [50-batch-output-naming-policy.md](50-batch-output-naming-policy.md) |
| Media dashboard output review | [51-media-dashboard-output-review.md](51-media-dashboard-output-review.md) |
| Media dashboard latest images schema | [52-media-dashboard-latest-images-schema.md](52-media-dashboard-latest-images-schema.md) |
| Media dashboard review template | [53-media-dashboard-review-template.md](53-media-dashboard-review-template.md) |
| Controlled prompt variant generation | [54-controlled-prompt-variant-generation.md](54-controlled-prompt-variant-generation.md) |
| Prompt variant run template | [55-prompt-variant-run-template.md](55-prompt-variant-run-template.md) |
| Controlled variant evidence template | [56-controlled-variant-evidence-template.md](56-controlled-variant-evidence-template.md) |
| Prompt variant stop conditions | [57-prompt-variant-stop-conditions.md](57-prompt-variant-stop-conditions.md) |
| Prompt variant result review | [58-prompt-variant-result-review.md](58-prompt-variant-result-review.md) |
| Git binary safety check | [59-git-binary-safety-check.md](59-git-binary-safety-check.md) |
| Prompt quality improvement plan | [60-prompt-quality-improvement-plan.md](60-prompt-quality-improvement-plan.md) |
| Next pergola prompt set | [61-next-pergola-prompt-set.md](61-next-pergola-prompt-set.md) |
| Negative prompt notes | [62-negative-prompt-notes.md](62-negative-prompt-notes.md) |
| Prompt quality review template | [63-prompt-quality-review-template.md](63-prompt-quality-review-template.md) |
| Improved prompt run result review | [64-improved-prompt-run-result-review.md](64-improved-prompt-run-result-review.md) |
| Pergola prompt lessons learned | [65-pergola-prompt-lessons-learned.md](65-pergola-prompt-lessons-learned.md) |
| Next technical detail prompt set | [66-next-technical-detail-prompt-set.md](66-next-technical-detail-prompt-set.md) |
| Pergola project-specific prompt pack | [67-pergola-project-specific-prompt-pack.md](67-pergola-project-specific-prompt-pack.md) |
| Pergola project overview prompts | [68-pergola-project-overview-prompts.md](68-pergola-project-overview-prompts.md) |
| Pergola technical detail prompts | [69-pergola-technical-detail-prompts.md](69-pergola-technical-detail-prompts.md) |
| Pergola prompt negative pack | [70-pergola-prompt-negative-pack.md](70-pergola-prompt-negative-pack.md) |
| Pergola project prompt run plan | [71-pergola-project-prompt-run-plan.md](71-pergola-project-prompt-run-plan.md) |
| Technical detail image run result review | [72-technical-detail-image-run-result-review.md](72-technical-detail-image-run-result-review.md) |
| Pergola image selection notes | [73-pergola-image-selection-notes.md](73-pergola-image-selection-notes.md) |
| Next project-specific prompt improvements | [74-next-project-specific-prompt-improvements.md](74-next-project-specific-prompt-improvements.md) |
| Pergola image reference board | [75-pergola-image-reference-board.md](75-pergola-image-reference-board.md) |
| Pergola reference board review template | [76-pergola-reference-board-review-template.md](76-pergola-reference-board-review-template.md) |
| Pergola usta briefing notes | [77-pergola-usta-briefing-notes.md](77-pergola-usta-briefing-notes.md) |
| Pergola reference board file handling | [78-pergola-reference-board-file-handling.md](78-pergola-reference-board-file-handling.md) |

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
32. [38 Generated Image Output Handling](38-generated-image-output-handling.md)
33. [39 First Image Success Record](39-first-image-success-record.md)
34. [40 Image Output Cleanup Policy](40-image-output-cleanup-policy.md)
35. [41 ComfyUI Workflow Inventory](41-comfyui-workflow-inventory.md)
36. [42 Flux Schnell Parameter Guide](42-flux-schnell-parameter-guide.md)
37. [43 ComfyUI Workflow Change Log](43-comfyui-workflow-change-log.md)
38. [44 Gateway Real Image Run Drill](44-gateway-real-image-run-drill.md)
39. [45 Gateway Real Image Evidence Template](45-gateway-real-image-evidence-template.md)
40. [46 Gateway Real Image Troubleshooting](46-gateway-real-image-troubleshooting.md)
41. [47 Prompt Variants Plan](47-prompt-variants-plan.md)
42. [48 Small Batch Image Safety](48-small-batch-image-safety.md)
43. [49 Image Comparison Notes Template](49-image-comparison-notes-template.md)
44. [50 Batch Output Naming Policy](50-batch-output-naming-policy.md)
45. [51 Media Dashboard Output Review](51-media-dashboard-output-review.md)
46. [52 Media Dashboard Latest Images Schema](52-media-dashboard-latest-images-schema.md)
47. [53 Media Dashboard Review Template](53-media-dashboard-review-template.md)
48. [54 Controlled Prompt Variant Generation](54-controlled-prompt-variant-generation.md)
49. [55 Prompt Variant Run Template](55-prompt-variant-run-template.md)
50. [56 Controlled Variant Evidence Template](56-controlled-variant-evidence-template.md)
51. [57 Prompt Variant Stop Conditions](57-prompt-variant-stop-conditions.md)
52. [58 Prompt Variant Result Review](58-prompt-variant-result-review.md)
53. [59 Git Binary Safety Check](59-git-binary-safety-check.md)
54. [60 Prompt Quality Improvement Plan](60-prompt-quality-improvement-plan.md)
55. [61 Next Pergola Prompt Set](61-next-pergola-prompt-set.md)
56. [62 Negative Prompt Notes](62-negative-prompt-notes.md)
57. [63 Prompt Quality Review Template](63-prompt-quality-review-template.md)
58. [64 Improved Prompt Run Result Review](64-improved-prompt-run-result-review.md)
59. [65 Pergola Prompt Lessons Learned](65-pergola-prompt-lessons-learned.md)
60. [66 Next Technical Detail Prompt Set](66-next-technical-detail-prompt-set.md)
61. [67 Pergola Project-Specific Prompt Pack](67-pergola-project-specific-prompt-pack.md)
62. [68 Pergola Project Overview Prompts](68-pergola-project-overview-prompts.md)
63. [69 Pergola Technical Detail Prompts](69-pergola-technical-detail-prompts.md)
64. [70 Pergola Prompt Negative Pack](70-pergola-prompt-negative-pack.md)
65. [71 Pergola Project Prompt Run Plan](71-pergola-project-prompt-run-plan.md)
66. [72 Technical Detail Image Run Result Review](72-technical-detail-image-run-result-review.md)
67. [73 Pergola Image Selection Notes](73-pergola-image-selection-notes.md)
68. [74 Next Project-Specific Prompt Improvements](74-next-project-specific-prompt-improvements.md)
69. [75 Pergola Image Reference Board](75-pergola-image-reference-board.md)
70. [76 Pergola Reference Board Review Template](76-pergola-reference-board-review-template.md)
71. [77 Pergola Usta Briefing Notes](77-pergola-usta-briefing-notes.md)
72. [78 Pergola Reference Board File Handling](78-pergola-reference-board-file-handling.md)

Run the backup drill after major milestones or before moving to a new machine.

M31.0 defines the image pipeline. M31.1 adds the ComfyUI / Flux startup checklist. Real generation remains explicit operator action.

Before real image generation, read 25 through 33.

Real image generation requires explicit `APPLY=1` and `MEDIA_REAL_GENERATION_ENABLED=true`. Do not run those commands unless you intentionally want generation.

After real image generation, read 38 through 40 before archiving, deleting, or recording generated outputs.

Before changing workflow parameters, read 41 through 43 and record future edits in the workflow change log.

For the full Gateway/media real image path, read 44 through 46 before running any guarded real command.

For prompt variants or small batch planning, read 47 through 50 before preparing a real run.

For dashboard output review, read 51 through 53 before relying on `latest_images` for evidence.

For controlled prompt variant generation, read 54 through 57 before preparing image mode.

For project-specific pergola prompt planning, read 67 through 71 before preparing the next controlled run.

After project-specific pergola image runs, read 72 through 74 before selecting references or preparing the next prompt iteration.

For selected pergola visual references and usta briefing notes, read 75 through 78.
