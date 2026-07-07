# 72 Technical Detail Image Run Result Review

This review records the first project-specific pergola image run results.

The run was performed manually by the operator. This document records outputs, lessons, and the next direction without committing generated image binaries.

Reference-board selection is handled in [75-pergola-image-reference-board.md](75-pergola-image-reference-board.md).

## What This Review Is For

- Record the results for P1 Project overview, P4 Rain protection, and T1 Beam-post joint.
- Capture output paths and file sizes.
- Preserve visual review notes for the next selection/reference-board milestone.
- Record VRAM, dashboard, shutdown, and coding-mode restore observations.
- Identify the next project-specific prompt improvements.

## What This Review Does NOT Do

- It does not run image generation.
- It does not delete generated images.
- It does not alter Gateway runtime behavior.
- It does not alter Docker Compose.
- It does not add automatic generation.
- It does not create runtime files.
- It does not treat AI-generated construction details as structurally valid.

## Run Summary

The operator manually ran 3 project-specific prompts:

- P1 Project overview
- P4 Rain protection
- T1 Beam-post joint

Run state:

- ComfyUI workflow submit succeeded for all 3.
- Outputs were surfaced under `/home/cuneyt/MoE/runtime/media/outputs/images/flux-first`.
- Media dashboard `latest_images` showed the new outputs.
- ComfyUI/Flux used around 13.8-13.9 GB VRAM.
- Free VRAM during generation was around 0.8-1.0 GB.
- llama-server was not running during image mode.
- Safe shutdown stopped ComfyUI.
- Safe shutdown restarted `qwen-coder-14b-fast`.
- Generated outputs were not deleted.

## Variant Table

| Variant | Output filename | Size bytes | Result |
| --- | --- | ---: | --- |
| P1 Project overview | `moe_pergola_p1_project_overview_20260707_132558_00001_.png` | 522694 | success, best project overview so far |
| P4 Rain protection | `moe_pergola_p4_rain_protection_20260707_132700_00001_.png` | 505487 | success, good rain/wet walkway concept |
| T1 Beam-post joint | `moe_pergola_t1_beam_post_joint_20260707_132730_00001_.png` | 403154 | success, best technical close-up so far |

## Output Paths

P1 Project overview:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_p1_project_overview_20260707_132558_00001_.png
```

P4 Rain protection:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_p4_rain_protection_20260707_132700_00001_.png
```

T1 Beam-post joint:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_t1_beam_post_joint_20260707_132730_00001_.png
```

## Output Sizes

| Variant | Size bytes |
| --- | ---: |
| P1 Project overview | 522694 |
| P4 Rain protection | 505487 |
| T1 Beam-post joint | 403154 |

## Prompt Text

P1 Project overview:

```text
realistic photo of a DIY wooden lean-to pergola beside a house wall, approximately 5.1 meters wide and 1.9 meters deep, natural pine wood, 10x10 cm posts, 5x10 cm beams, fully covered translucent polycarbonate roof panels, simple practical backyard construction, narrow garden walkway, soft daylight, not luxury, not resort style
```

P4 Rain protection:

```text
realistic rainy weather photo of a narrow wall-side wooden pergola, wet stone walkway, damp pine wood, visible rain streaks, translucent covered roof protecting the walking path, cloudy sky, realistic reflections, practical backyard structure
```

T1 Beam-post joint:

```text
realistic close-up construction photo of a DIY wooden pergola beam-to-post joint, 10x10 cm pine post, 5x10 cm horizontal beam, galvanized metal angle brackets, bolts, washers, screw heads, visible wood grain, pencil marks, practical backyard construction, documentary style
```

## Visual Result Notes

P1 Project overview:

- Successful.
- Best project-overview direction so far.
- Shows narrow wall-side pergola, timber frame, translucent covered roof, and brick wall / walkway feel.
- Still not dimensionally exact, but visually close to the intended project.

P4 Rain protection:

- Successful.
- Wet walkway and rain protection concept are clear.
- Good atmosphere and improved over earlier rainy prompts.
- Needs roof runoff, gutter, and wall flashing details later.

T1 Beam-post joint:

- Successful.
- Best technical detail direction so far.
- Shows close-up connection with bolts/screws and wood grain.
- Still not structurally exact, and bracket geometry may be unrealistic.
- Needs more explicit real-world bracket types and fastening logic.

## VRAM Notes

ComfyUI/Flux used around 13.8-13.9 GB VRAM.

Free VRAM during generation was around 0.8-1.0 GB.

Keep future runs one prompt at a time unless a later milestone proves more headroom.

## Dashboard Result

Media dashboard `latest_images` showed the new outputs.

Use [51-media-dashboard-output-review.md](51-media-dashboard-output-review.md) and [52-media-dashboard-latest-images-schema.md](52-media-dashboard-latest-images-schema.md) for future dashboard evidence checks.

## Safe Shutdown Result

Safe shutdown succeeded:

- ComfyUI stopped.
- Generated outputs were not deleted.
- Image mode ended cleanly.

## Coding Mode Restore Result

Coding mode restored successfully:

- `qwen-coder-14b-fast` restarted.
- llama-server had not been running during image mode.

## Lessons Learned

- P1 is the strongest project-overview reference so far.
- P4 is the strongest rain-protection reference so far.
- T1 is the strongest technical close-up direction so far.
- Dimensions in prompts help, but output should still be treated as approximate.
- Rain prompts benefit from wet floor, damp wood, rain streaks, and reflections.
- Technical prompts need real-world bracket specificity and fastening logic.
- AI-generated joinery is visual inspiration only, not engineering guidance.

## Recommended Next Direction

Move into selection/reference-board review using [73-pergola-image-selection-notes.md](73-pergola-image-selection-notes.md).

For the next prompt iteration, use [74-next-project-specific-prompt-improvements.md](74-next-project-specific-prompt-improvements.md), focusing on:

- more exact wall-side dimensions
- roof drainage details
- real bracket types
- post base detail
- right-side door canopy extension
