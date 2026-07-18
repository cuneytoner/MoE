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
| Real pergola technical drawing prompt pack | [79-real-pergola-technical-drawing-prompt-pack.md](79-real-pergola-technical-drawing-prompt-pack.md) |
| Pergola measured view prompts | [80-pergola-measured-view-prompts.md](80-pergola-measured-view-prompts.md) |
| Pergola connection detail prompts | [81-pergola-connection-detail-prompts.md](81-pergola-connection-detail-prompts.md) |
| Pergola fastener and drilling prompt pack | [82-pergola-fastener-and-drilling-prompt-pack.md](82-pergola-fastener-and-drilling-prompt-pack.md) |
| Pergola technical drawing review template | [83-pergola-technical-drawing-review-template.md](83-pergola-technical-drawing-review-template.md) |
| Technical drawing safety notes | [84-technical-drawing-safety-notes.md](84-technical-drawing-safety-notes.md) |
| Technical drawing run result review | [85-technical-drawing-run-result-review.md](85-technical-drawing-run-result-review.md) |
| Technical drawing prompt lessons | [86-technical-drawing-prompt-lessons.md](86-technical-drawing-prompt-lessons.md) |
| Next simplified technical drawing prompts | [87-next-simplified-technical-drawing-prompts.md](87-next-simplified-technical-drawing-prompts.md) |
| Technical drawing selection notes | [88-technical-drawing-selection-notes.md](88-technical-drawing-selection-notes.md) |
| Simplified technical drawing run review | [89-simplified-technical-drawing-run-review.md](89-simplified-technical-drawing-run-review.md) |
| CAD-like prompt lessons | [90-cad-like-prompt-lessons.md](90-cad-like-prompt-lessons.md) |
| Next CAD-like geometry-only prompts | [91-next-cad-like-geometry-only-prompts.md](91-next-cad-like-geometry-only-prompts.md) |
| Manual labeling plan | [92-manual-labeling-plan.md](92-manual-labeling-plan.md) |
| Geometry-only CAD run review | [93-geometry-only-cad-run-review.md](93-geometry-only-cad-run-review.md) |
| Deterministic pergola drawing plan | [94-deterministic-pergola-drawing-plan.md](94-deterministic-pergola-drawing-plan.md) |
| Pergola drawing geometry spec | [95-pergola-drawing-geometry-spec.md](95-pergola-drawing-geometry-spec.md) |
| SVG drawing safety and Git policy | [96-svg-drawing-safety-and-git-policy.md](96-svg-drawing-safety-and-git-policy.md) |
| Pergola drawing implementation roadmap | [97-pergola-drawing-implementation-roadmap.md](97-pergola-drawing-implementation-roadmap.md) |
| SVG drawing tool skeleton | [98-svg-drawing-tool-skeleton.md](98-svg-drawing-tool-skeleton.md) |
| Pergola SVG output review template | [99-pergola-svg-output-review-template.md](99-pergola-svg-output-review-template.md) |
| Side elevation + top plan SVG | [100-side-elevation-top-plan-svg.md](100-side-elevation-top-plan-svg.md) |
| Side/top SVG review template | [101-side-top-svg-review-template.md](101-side-top-svg-review-template.md) |
| Generic image + architecture drawing roadmap | [104-generic-image-architecture-drawing-roadmap.md](104-generic-image-architecture-drawing-roadmap.md) |
| Pergola as case study | [105-pergola-as-case-study.md](105-pergola-as-case-study.md) |
| Generic media generation roadmap | [106-generic-media-generation-roadmap.md](106-generic-media-generation-roadmap.md) |
| Generic drawing engine roadmap | [107-generic-drawing-engine-roadmap.md](107-generic-drawing-engine-roadmap.md) |
| Roadmap reset decision log | [108-roadmap-reset-decision-log.md](108-roadmap-reset-decision-log.md) |
| Generic prompt pack structure | [109-generic-prompt-pack-structure.md](109-generic-prompt-pack-structure.md) |
| Prompt pack review template | [110-prompt-pack-review-template.md](110-prompt-pack-review-template.md) |
| Generic image generation safety | [111-generic-image-generation-safety.md](111-generic-image-generation-safety.md) |
| Generic drawing engine skeleton | [112-generic-drawing-engine-skeleton.md](112-generic-drawing-engine-skeleton.md) |
| Drawing engine demo review template | [113-drawing-engine-demo-review-template.md](113-drawing-engine-demo-review-template.md) |
| Media dashboard output cards plan | [114-media-dashboard-output-cards-plan.md](114-media-dashboard-output-cards-plan.md) |
| Output card API contract | [115-output-card-api-contract.md](115-output-card-api-contract.md) |
| Output card UI plan | [116-output-card-ui-plan.md](116-output-card-ui-plan.md) |
| Output card source scanning policy | [117-output-card-source-scanning-policy.md](117-output-card-source-scanning-policy.md) |
| Output card review template | [118-output-card-review-template.md](118-output-card-review-template.md) |
| Prompt metadata capture plan | [119-prompt-metadata-capture-plan.md](119-prompt-metadata-capture-plan.md) |
| Image metadata schema | [120-image-metadata-schema.md](120-image-metadata-schema.md) |
| Drawing metadata schema | [121-drawing-metadata-schema.md](121-drawing-metadata-schema.md) |
| Metadata sidecar policy | [122-metadata-sidecar-policy.md](122-metadata-sidecar-policy.md) |
| Output card metadata integration | [123-output-card-metadata-integration.md](123-output-card-metadata-integration.md) |
| Metadata review template | [124-metadata-review-template.md](124-metadata-review-template.md) |
| Output cards API implementation | [125-output-cards-api-implementation.md](125-output-cards-api-implementation.md) |
| Output cards API review template | [126-output-cards-api-review-template.md](126-output-cards-api-review-template.md) |
| Dashboard output cards UI | [127-dashboard-output-cards-ui.md](127-dashboard-output-cards-ui.md) |
| Dashboard output cards UI review template | [128-dashboard-output-cards-ui-review-template.md](128-dashboard-output-cards-ui-review-template.md) |
| Drawing metadata sidecar implementation | [129-drawing-metadata-sidecar-implementation.md](129-drawing-metadata-sidecar-implementation.md) |
| Drawing metadata sidecar review template | [130-drawing-metadata-sidecar-review-template.md](130-drawing-metadata-sidecar-review-template.md) |
| Reference board selection plan | [131-reference-board-selection-plan.md](131-reference-board-selection-plan.md) |
| Reference board schema | [132-reference-board-schema.md](132-reference-board-schema.md) |
| Reference board storage policy | [133-reference-board-storage-policy.md](133-reference-board-storage-policy.md) |
| Reference board UI plan | [134-reference-board-ui-plan.md](134-reference-board-ui-plan.md) |
| Reference board API plan | [135-reference-board-api-plan.md](135-reference-board-api-plan.md) |
| Reference board review template | [136-reference-board-review-template.md](136-reference-board-review-template.md) |
| Image metadata sidecar implementation | [137-image-metadata-sidecar-implementation.md](137-image-metadata-sidecar-implementation.md) |
| Image metadata sidecar review template | [138-image-metadata-sidecar-review-template.md](138-image-metadata-sidecar-review-template.md) |
| Output card preview serving plan | [139-output-card-preview-serving-plan.md](139-output-card-preview-serving-plan.md) |
| Preview serving API contract | [140-preview-serving-api-contract.md](140-preview-serving-api-contract.md) |
| Preview serving security policy | [141-preview-serving-security-policy.md](141-preview-serving-security-policy.md) |
| Preview serving UI plan | [142-preview-serving-ui-plan.md](142-preview-serving-ui-plan.md) |
| Preview serving review template | [143-preview-serving-review-template.md](143-preview-serving-review-template.md) |
| Output preview API implementation | [144-output-preview-api-implementation.md](144-output-preview-api-implementation.md) |
| Output preview API review template | [145-output-preview-api-review-template.md](145-output-preview-api-review-template.md) |
| Dashboard preview UI implementation | [146-dashboard-preview-ui-implementation.md](146-dashboard-preview-ui-implementation.md) |
| Dashboard preview UI review template | [147-dashboard-preview-ui-review-template.md](147-dashboard-preview-ui-review-template.md) |
| Output card metadata detail API | [148-output-card-metadata-detail-api.md](148-output-card-metadata-detail-api.md) |
| Dashboard metadata detail drawer | [149-dashboard-metadata-detail-drawer.md](149-dashboard-metadata-detail-drawer.md) |
| Output card metadata detail review template | [150-output-card-metadata-detail-review-template.md](150-output-card-metadata-detail-review-template.md) |
| Reference board safe runtime store | [151-reference-board-safe-runtime-store.md](151-reference-board-safe-runtime-store.md) |
| Reference board store review template | [152-reference-board-store-review-template.md](152-reference-board-store-review-template.md) |
| Reference board API implementation | [153-reference-board-api-implementation.md](153-reference-board-api-implementation.md) |
| Reference board API review template | [154-reference-board-api-review-template.md](154-reference-board-api-review-template.md) |
| Reference board item selection API | [155-reference-board-item-selection-api.md](155-reference-board-item-selection-api.md) |
| Reference board item selection review template | [156-reference-board-item-selection-review-template.md](156-reference-board-item-selection-review-template.md) |
| Reference board UI implementation | [157-reference-board-ui-implementation.md](157-reference-board-ui-implementation.md) |
| Reference board UI review template | [158-reference-board-ui-review-template.md](158-reference-board-ui-review-template.md) |
| Reference board UI CORS + card ID fix | [159-reference-board-ui-cors-card-id-fix.md](159-reference-board-ui-cors-card-id-fix.md) |
| Reference board UI CORS + card ID review template | [160-reference-board-ui-cors-card-id-review-template.md](160-reference-board-ui-cors-card-id-review-template.md) |
| Reference board detail view | [161-reference-board-detail-view.md](161-reference-board-detail-view.md) |
| Reference board detail view review template | [162-reference-board-detail-view-review-template.md](162-reference-board-detail-view-review-template.md) |
| Reference board item note edit API | [163-reference-board-item-note-edit-api.md](163-reference-board-item-note-edit-api.md) |
| Reference board item note edit review template | [164-reference-board-item-note-edit-review-template.md](164-reference-board-item-note-edit-review-template.md) |
| Reference board export plan | [165-reference-board-export-plan.md](165-reference-board-export-plan.md) |
| Reference board export schema | [166-reference-board-export-schema.md](166-reference-board-export-schema.md) |
| Reference board export security policy | [167-reference-board-export-security-policy.md](167-reference-board-export-security-policy.md) |
| Reference board export review template | [168-reference-board-export-review-template.md](168-reference-board-export-review-template.md) |
| Reference board JSON export implementation | [169-reference-board-json-export-implementation.md](169-reference-board-json-export-implementation.md) |
| Reference board JSON export review template | [170-reference-board-json-export-review-template.md](170-reference-board-json-export-review-template.md) |
| Reference board Markdown export implementation | [171-reference-board-markdown-export-implementation.md](171-reference-board-markdown-export-implementation.md) |
| Reference board Markdown export review template | [172-reference-board-markdown-export-review-template.md](172-reference-board-markdown-export-review-template.md) |
| Reference board export UI | [173-reference-board-export-ui.md](173-reference-board-export-ui.md) |
| Reference board export UI review template | [174-reference-board-export-ui-review-template.md](174-reference-board-export-ui-review-template.md) |
| Reference board export download plan | [175-reference-board-export-download-plan.md](175-reference-board-export-download-plan.md) |
| Reference board download filename policy | [176-reference-board-download-filename-policy.md](176-reference-board-download-filename-policy.md) |
| Reference board download security policy | [177-reference-board-download-security-policy.md](177-reference-board-download-security-policy.md) |
| Reference board download review template | [178-reference-board-download-review-template.md](178-reference-board-download-review-template.md) |
| Reference board Markdown download implementation | [179-reference-board-markdown-download-implementation.md](179-reference-board-markdown-download-implementation.md) |
| Reference board Markdown download review template | [180-reference-board-markdown-download-review-template.md](180-reference-board-markdown-download-review-template.md) |
| Reference board JSON download implementation | [181-reference-board-json-download-implementation.md](181-reference-board-json-download-implementation.md) |
| Reference board JSON download review template | [182-reference-board-json-download-review-template.md](182-reference-board-json-download-review-template.md) |
| Reference board download UI | [183-reference-board-download-ui.md](183-reference-board-download-ui.md) |
| Reference board download UI review template | [184-reference-board-download-ui-review-template.md](184-reference-board-download-ui-review-template.md) |
| Reference board export regression review | [185-reference-board-export-regression-review.md](185-reference-board-export-regression-review.md) |
| Reference board export regression template | [186-reference-board-export-regression-template.md](186-reference-board-export-regression-template.md) |
| Reference board export polish | [187-reference-board-export-polish.md](187-reference-board-export-polish.md) |
| Reference board export polish review template | [188-reference-board-export-polish-review-template.md](188-reference-board-export-polish-review-template.md) |
| Reference board workflow summary | [189-reference-board-workflow-summary.md](189-reference-board-workflow-summary.md) |
| Reference board workflow review template | [190-reference-board-workflow-review-template.md](190-reference-board-workflow-review-template.md) |
| Reference board hardening plan | [191-reference-board-hardening-plan.md](191-reference-board-hardening-plan.md) |
| Reference board hardening review template | [192-reference-board-hardening-review-template.md](192-reference-board-hardening-review-template.md) |
| Reference board error handling polish | [193-reference-board-error-handling-polish.md](193-reference-board-error-handling-polish.md) |
| Reference board error handling review template | [194-reference-board-error-handling-review-template.md](194-reference-board-error-handling-review-template.md) |
| Reference board validation limits | [195-reference-board-validation-limits.md](195-reference-board-validation-limits.md) |
| Reference board validation limits review template | [196-reference-board-validation-limits-review-template.md](196-reference-board-validation-limits-review-template.md) |
| Reference board malformed store regression | [197-reference-board-malformed-store-regression.md](197-reference-board-malformed-store-regression.md) |
| Reference board malformed store regression review template | [198-reference-board-malformed-store-regression-review-template.md](198-reference-board-malformed-store-regression-review-template.md) |
| Reference board store repair plan | [199-reference-board-store-repair-plan.md](199-reference-board-store-repair-plan.md) |
| Reference board store repair review template | [200-reference-board-store-repair-review-template.md](200-reference-board-store-repair-review-template.md) |
| Reference board store backup plan | [201-reference-board-store-backup-plan.md](201-reference-board-store-backup-plan.md) |
| Reference board store backup review template | [202-reference-board-store-backup-review-template.md](202-reference-board-store-backup-review-template.md) |
| Reference board store repair CLI plan | [203-reference-board-store-repair-cli-plan.md](203-reference-board-store-repair-cli-plan.md) |
| Reference board store repair CLI review template | [204-reference-board-store-repair-cli-review-template.md](204-reference-board-store-repair-cli-review-template.md) |
| Reference board store validate CLI implementation | [205-reference-board-store-validate-cli-implementation.md](205-reference-board-store-validate-cli-implementation.md) |
| Reference board store validate CLI review template | [206-reference-board-store-validate-cli-review-template.md](206-reference-board-store-validate-cli-review-template.md) |
| Reference board store backup CLI implementation | [207-reference-board-store-backup-cli-implementation.md](207-reference-board-store-backup-cli-implementation.md) |
| Reference board store backup CLI review template | [208-reference-board-store-backup-cli-review-template.md](208-reference-board-store-backup-cli-review-template.md) |
| Reference board store repair CLI implementation | [209-reference-board-store-repair-cli-implementation.md](209-reference-board-store-repair-cli-implementation.md) |
| Reference board store repair CLI review template | [210-reference-board-store-repair-cli-review-template.md](210-reference-board-store-repair-cli-review-template.md) |
| Reference board store repair regression | [211-reference-board-store-repair-regression.md](211-reference-board-store-repair-regression.md) |
| Reference board store repair regression review template | [212-reference-board-store-repair-regression-review-template.md](212-reference-board-store-repair-regression-review-template.md) |
| Reference board duplicate item repair plan | [213-reference-board-duplicate-item-repair-plan.md](213-reference-board-duplicate-item-repair-plan.md) |
| Reference board duplicate item repair review template | [214-reference-board-duplicate-item-repair-review-template.md](214-reference-board-duplicate-item-repair-review-template.md) |
| Reference board stale item handling plan | [215-reference-board-stale-item-handling-plan.md](215-reference-board-stale-item-handling-plan.md) |
| Reference board stale item handling review template | [216-reference-board-stale-item-handling-review-template.md](216-reference-board-stale-item-handling-review-template.md) |
| Reference board duplicate item repair implementation | [217-reference-board-duplicate-item-repair-implementation.md](217-reference-board-duplicate-item-repair-implementation.md) |
| Reference board duplicate item repair review template | [218-reference-board-duplicate-item-repair-review-template.md](218-reference-board-duplicate-item-repair-review-template.md) |
| Reference board duplicate item repair regression | [219-reference-board-duplicate-item-repair-regression.md](219-reference-board-duplicate-item-repair-regression.md) |
| Reference board duplicate item repair regression review template | [220-reference-board-duplicate-item-repair-regression-review-template.md](220-reference-board-duplicate-item-repair-regression-review-template.md) |
| Reference board stale item marking implementation | [221-reference-board-stale-item-marking-implementation.md](221-reference-board-stale-item-marking-implementation.md) |
| Reference board stale item marking review template | [222-reference-board-stale-item-marking-review-template.md](222-reference-board-stale-item-marking-review-template.md) |
| Reference board stale item regression | [223-reference-board-stale-item-regression.md](223-reference-board-stale-item-regression.md) |
| Reference board stale item regression review template | [224-reference-board-stale-item-regression-review-template.md](224-reference-board-stale-item-regression-review-template.md) |
| Reference board repair CLI operator runbook | [225-reference-board-repair-cli-operator-runbook.md](225-reference-board-repair-cli-operator-runbook.md) |
| Reference board repair CLI operator runbook review template | [226-reference-board-repair-cli-operator-runbook-review-template.md](226-reference-board-repair-cli-operator-runbook-review-template.md) |
| Reference board repair CLI summary review | [227-reference-board-repair-cli-summary-review.md](227-reference-board-repair-cli-summary-review.md) |
| Reference board repair CLI summary review template | [228-reference-board-repair-cli-summary-review-template.md](228-reference-board-repair-cli-summary-review-template.md) |
| Reference board export stale duplicate status polish | [229-reference-board-export-stale-duplicate-status-polish.md](229-reference-board-export-stale-duplicate-status-polish.md) |
| Reference board export stale duplicate status polish review template | [230-reference-board-export-stale-duplicate-status-polish-review-template.md](230-reference-board-export-stale-duplicate-status-polish-review-template.md) |
| Reference board backup retention plan | [231-reference-board-backup-retention-plan.md](231-reference-board-backup-retention-plan.md) |
| Reference board backup retention review template | [232-reference-board-backup-retention-review-template.md](232-reference-board-backup-retention-review-template.md) |
| Reference board export review UI polish | [233-reference-board-export-review-ui-polish.md](233-reference-board-export-review-ui-polish.md) |
| Reference board export review UI polish review template | [234-reference-board-export-review-ui-polish-review-template.md](234-reference-board-export-review-ui-polish-review-template.md) |
| Reference board phase closure and M35 roadmap | [235-reference-board-phase-closure-and-m35-roadmap.md](235-reference-board-phase-closure-and-m35-roadmap.md) |
| Reference board phase closure review template | [236-reference-board-phase-closure-review-template.md](236-reference-board-phase-closure-review-template.md) |
| 3D Blender parametric pipeline foundation | [237-3d-blender-parametric-pipeline-foundation.md](237-3d-blender-parametric-pipeline-foundation.md) |
| 3D Blender parametric pipeline foundation review template | [238-3d-blender-parametric-pipeline-foundation-review-template.md](238-3d-blender-parametric-pipeline-foundation-review-template.md) |
| Generic parametric Blender prototype plan | [239-generic-parametric-blender-prototype-plan.md](239-generic-parametric-blender-prototype-plan.md) |
| Generic parametric Blender prototype review template | [240-generic-parametric-blender-prototype-review-template.md](240-generic-parametric-blender-prototype-review-template.md) |
| Blender runtime output safety plan | [241-blender-runtime-output-safety-plan.md](241-blender-runtime-output-safety-plan.md) |
| Blender runtime output safety review template | [242-blender-runtime-output-safety-review-template.md](242-blender-runtime-output-safety-review-template.md) |
| Generic parametric Blender script skeleton | [243-generic-parametric-blender-script-skeleton.md](243-generic-parametric-blender-script-skeleton.md) |
| Generic parametric Blender script skeleton review template | [244-generic-parametric-blender-script-skeleton-review-template.md](244-generic-parametric-blender-script-skeleton-review-template.md) |
| Generic 3D parameter config draft | [245-generic-3d-parameter-config-draft.md](245-generic-3d-parameter-config-draft.md) |
| Generic 3D parameter config review template | [246-generic-3d-parameter-config-review-template.md](246-generic-3d-parameter-config-review-template.md) |
| First dry-run Blender script review | [247-first-dry-run-blender-script-review.md](247-first-dry-run-blender-script-review.md) |
| First dry-run Blender script review template | [248-first-dry-run-blender-script-review-template.md](248-first-dry-run-blender-script-review-template.md) |
| Guarded first Blender generation drill plan | [249-guarded-first-blender-generation-drill-plan.md](249-guarded-first-blender-generation-drill-plan.md) |
| Guarded first Blender generation drill review template | [250-guarded-first-blender-generation-drill-review-template.md](250-guarded-first-blender-generation-drill-review-template.md) |
| 3D metadata sidecar plan | [251-3d-metadata-sidecar-plan.md](251-3d-metadata-sidecar-plan.md) |
| 3D metadata sidecar review template | [252-3d-metadata-sidecar-review-template.md](252-3d-metadata-sidecar-review-template.md) |
| 3D output cards plan | [253-3d-output-cards-plan.md](253-3d-output-cards-plan.md) |
| 3D output cards review template | [254-3d-output-cards-review-template.md](254-3d-output-cards-review-template.md) |
| Guarded Blender generation implementation | [255-guarded-blender-generation-implementation.md](255-guarded-blender-generation-implementation.md) |
| Guarded Blender generation implementation review template | [256-guarded-blender-generation-implementation-review-template.md](256-guarded-blender-generation-implementation-review-template.md) |
| 3D metadata sidecar writer | [257-3d-metadata-sidecar-writer.md](257-3d-metadata-sidecar-writer.md) |
| 3D metadata sidecar writer review template | [258-3d-metadata-sidecar-writer-review-template.md](258-3d-metadata-sidecar-writer-review-template.md) |
| 3D metadata sidecar validator | [259-3d-metadata-sidecar-validator.md](259-3d-metadata-sidecar-validator.md) |
| 3D metadata sidecar validator review template | [260-3d-metadata-sidecar-validator-review-template.md](260-3d-metadata-sidecar-validator-review-template.md) |
| Generic primitive builder core | [261-generic-primitive-builder-core.md](261-generic-primitive-builder-core.md) |
| Generic primitive builder core review template | [262-generic-primitive-builder-core-review-template.md](262-generic-primitive-builder-core-review-template.md) |
| Blender adapter implementation | [263-blender-adapter-implementation.md](263-blender-adapter-implementation.md) |
| Blender adapter implementation review template | [264-blender-adapter-implementation-review-template.md](264-blender-adapter-implementation-review-template.md) |
| First guarded local Blender generation drill | [265-first-guarded-local-blender-generation-drill.md](265-first-guarded-local-blender-generation-drill.md) |
| First guarded local Blender generation drill review template | [266-first-guarded-local-blender-generation-drill-review-template.md](266-first-guarded-local-blender-generation-drill-review-template.md) |
| Generated 3D artifact verification | [267-generated-3d-artifact-verification.md](267-generated-3d-artifact-verification.md) |
| Generated 3D artifact verification review template | [268-generated-3d-artifact-verification-review-template.md](268-generated-3d-artifact-verification-review-template.md) |
| 3D output card API | [269-3d-output-card-api.md](269-3d-output-card-api.md) |
| 3D output card API review template | [270-3d-output-card-api-review-template.md](270-3d-output-card-api-review-template.md) |
| Dashboard 3D output cards UI | [271-dashboard-3d-output-cards-ui.md](271-dashboard-3d-output-cards-ui.md) |
| Dashboard 3D output cards UI review template | [272-dashboard-3d-output-cards-ui-review-template.md](272-dashboard-3d-output-cards-ui-review-template.md) |
| 3D reference board selection | [273-3d-reference-board-selection.md](273-3d-reference-board-selection.md) |
| 3D reference board selection review template | [274-3d-reference-board-selection-review-template.md](274-3d-reference-board-selection-review-template.md) |
| M35 3D pipeline phase closure | [275-m35-3d-pipeline-phase-closure.md](275-m35-3d-pipeline-phase-closure.md) |
| M35 3D pipeline phase closure review template | [276-m35-3d-pipeline-phase-closure-review-template.md](276-m35-3d-pipeline-phase-closure-review-template.md) |
| Animation pipeline foundation | [277-animation-pipeline-foundation.md](277-animation-pipeline-foundation.md) |
| Animation pipeline foundation review template | [278-animation-pipeline-foundation-review-template.md](278-animation-pipeline-foundation-review-template.md) |
| Animation plan schema | [279-animation-plan-schema.md](279-animation-plan-schema.md) |
| Animation plan schema review template | [280-animation-plan-schema-review-template.md](280-animation-plan-schema-review-template.md) |
| Animation plan validator | [281-animation-plan-validator.md](281-animation-plan-validator.md) |
| Animation plan validator review template | [282-animation-plan-validator-review-template.md](282-animation-plan-validator-review-template.md) |
| Timeline keyframe planner core | [283-timeline-keyframe-planner-core.md](283-timeline-keyframe-planner-core.md) |
| Timeline keyframe planner core review template | [284-timeline-keyframe-planner-core-review-template.md](284-timeline-keyframe-planner-core-review-template.md) |
| Camera animation planner | [285-camera-animation-planner.md](285-camera-animation-planner.md) |
| Camera animation planner review template | [286-camera-animation-planner-review-template.md](286-camera-animation-planner-review-template.md) |
| Object transform animation planner | [287-object-transform-animation-planner.md](287-object-transform-animation-planner.md) |
| Object transform animation planner review template | [288-object-transform-animation-planner-review-template.md](288-object-transform-animation-planner-review-template.md) |
| Blender animation adapter plan | [289-blender-animation-adapter-plan.md](289-blender-animation-adapter-plan.md) |
| Blender animation adapter plan review template | [290-blender-animation-adapter-plan-review-template.md](290-blender-animation-adapter-plan-review-template.md) |
| Guarded Blender animation implementation | [291-guarded-blender-animation-implementation.md](291-guarded-blender-animation-implementation.md) |
| Guarded Blender animation implementation review template | [292-guarded-blender-animation-implementation-review-template.md](292-guarded-blender-animation-implementation-review-template.md) |
| Animation metadata sidecar writer | [293-animation-metadata-sidecar-writer.md](293-animation-metadata-sidecar-writer.md) |
| Animation metadata sidecar writer review template | [294-animation-metadata-sidecar-writer-review-template.md](294-animation-metadata-sidecar-writer-review-template.md) |
| Animation metadata validator | [295-animation-metadata-validator.md](295-animation-metadata-validator.md) |
| Animation metadata validator review template | [296-animation-metadata-validator-review-template.md](296-animation-metadata-validator-review-template.md) |
| Preview render safety plan | [297-preview-render-safety-plan.md](297-preview-render-safety-plan.md) |
| Preview render safety plan review template | [298-preview-render-safety-plan-review-template.md](298-preview-render-safety-plan-review-template.md) |

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
73. [79 Real Pergola Technical Drawing Prompt Pack](79-real-pergola-technical-drawing-prompt-pack.md)
74. [80 Pergola Measured View Prompts](80-pergola-measured-view-prompts.md)
75. [81 Pergola Connection Detail Prompts](81-pergola-connection-detail-prompts.md)
76. [82 Pergola Fastener And Drilling Prompt Pack](82-pergola-fastener-and-drilling-prompt-pack.md)
77. [83 Pergola Technical Drawing Review Template](83-pergola-technical-drawing-review-template.md)
78. [84 Technical Drawing Safety Notes](84-technical-drawing-safety-notes.md)
79. [85 Technical Drawing Run Result Review](85-technical-drawing-run-result-review.md)
80. [86 Technical Drawing Prompt Lessons](86-technical-drawing-prompt-lessons.md)
81. [87 Next Simplified Technical Drawing Prompts](87-next-simplified-technical-drawing-prompts.md)
82. [88 Technical Drawing Selection Notes](88-technical-drawing-selection-notes.md)
83. [89 Simplified Technical Drawing Run Review](89-simplified-technical-drawing-run-review.md)
84. [90 CAD-like Prompt Lessons](90-cad-like-prompt-lessons.md)
85. [91 Next CAD-like Geometry-only Prompts](91-next-cad-like-geometry-only-prompts.md)
86. [92 Manual Labeling Plan](92-manual-labeling-plan.md)
87. [93 Geometry-only CAD Run Review](93-geometry-only-cad-run-review.md)
88. [94 Deterministic Pergola Drawing Plan](94-deterministic-pergola-drawing-plan.md)
89. [95 Pergola Drawing Geometry Spec](95-pergola-drawing-geometry-spec.md)
90. [96 SVG Drawing Safety And Git Policy](96-svg-drawing-safety-and-git-policy.md)
91. [97 Pergola Drawing Implementation Roadmap](97-pergola-drawing-implementation-roadmap.md)
92. [98 SVG Drawing Tool Skeleton](98-svg-drawing-tool-skeleton.md)
93. [99 Pergola SVG Output Review Template](99-pergola-svg-output-review-template.md)
94. [100 Side Elevation + Top Plan SVG](100-side-elevation-top-plan-svg.md)
95. [101 Side/Top SVG Review Template](101-side-top-svg-review-template.md)
96. [104 Generic Image + Architecture Drawing Roadmap](104-generic-image-architecture-drawing-roadmap.md)
97. [105 Pergola As Case Study](105-pergola-as-case-study.md)
98. [106 Generic Media Generation Roadmap](106-generic-media-generation-roadmap.md)
99. [107 Generic Drawing Engine Roadmap](107-generic-drawing-engine-roadmap.md)
100. [108 Roadmap Reset Decision Log](108-roadmap-reset-decision-log.md)
101. [109 Generic Prompt Pack Structure](109-generic-prompt-pack-structure.md)
102. [110 Prompt Pack Review Template](110-prompt-pack-review-template.md)
103. [111 Generic Image Generation Safety](111-generic-image-generation-safety.md)
104. [112 Generic Drawing Engine Skeleton](112-generic-drawing-engine-skeleton.md)
105. [113 Drawing Engine Demo Review Template](113-drawing-engine-demo-review-template.md)
106. [114 Media Dashboard Output Cards Plan](114-media-dashboard-output-cards-plan.md)
107. [115 Output Card API Contract](115-output-card-api-contract.md)
108. [116 Output Card UI Plan](116-output-card-ui-plan.md)
109. [117 Output Card Source Scanning Policy](117-output-card-source-scanning-policy.md)
110. [118 Output Card Review Template](118-output-card-review-template.md)
111. [119 Prompt Metadata Capture Plan](119-prompt-metadata-capture-plan.md)
112. [120 Image Metadata Schema](120-image-metadata-schema.md)
113. [121 Drawing Metadata Schema](121-drawing-metadata-schema.md)
114. [122 Metadata Sidecar Policy](122-metadata-sidecar-policy.md)
115. [123 Output Card Metadata Integration](123-output-card-metadata-integration.md)
116. [124 Metadata Review Template](124-metadata-review-template.md)
117. [125 Output Cards API Implementation](125-output-cards-api-implementation.md)
118. [126 Output Cards API Review Template](126-output-cards-api-review-template.md)
119. [127 Dashboard Output Cards UI](127-dashboard-output-cards-ui.md)
120. [128 Dashboard Output Cards UI Review Template](128-dashboard-output-cards-ui-review-template.md)
121. [129 Drawing Metadata Sidecar Implementation](129-drawing-metadata-sidecar-implementation.md)
122. [130 Drawing Metadata Sidecar Review Template](130-drawing-metadata-sidecar-review-template.md)
123. [131 Reference Board Selection Plan](131-reference-board-selection-plan.md)
124. [132 Reference Board Schema](132-reference-board-schema.md)
125. [133 Reference Board Storage Policy](133-reference-board-storage-policy.md)
126. [134 Reference Board UI Plan](134-reference-board-ui-plan.md)
127. [135 Reference Board API Plan](135-reference-board-api-plan.md)
128. [136 Reference Board Review Template](136-reference-board-review-template.md)

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

For real pergola technical drawing prompts and safety notes, read 79 through 84 before preparing a controlled drawing run.

After technical drawing runs, read 85 through 88 before selecting outputs or preparing simplified prompts.

After simplified drawing runs, read 89 through 92 before preparing geometry-only CAD-style prompts or manual labels.

For deterministic pergola drawing planning, read 93 through 97 before creating any SVG/PDF/DXF files.

For the first SVG skeleton tool and output review, read 98 and 99.

For side elevation and top plan SVG outputs, read 100 and 101.

For dashboard reference-board UI review, read 157 and 158.

For the generic image, architecture, and drawing roadmap, read 104 through 108.

For generic prompt pack structure and safe prompt reuse, read 109 through 111.

For the generic drawing engine demo skeleton, read 112 and 113.

For media dashboard output cards planning, read 114 through 118.

For prompt metadata capture planning, read 119 through 124.

For the read-only output cards API, read 125 and 126.

For dashboard output cards UI review, read 127 and 128.

For deterministic drawing metadata sidecars, read 129 and 130.

For reference-board selection planning, read 131 through 136.

For 3D reference-board selection, read 273 and 274.

For M35 phase closure, read 275 and 276.

For M36 animation pipeline foundation, read 277 and 278.
