# 64 Improved Prompt Run Result Review

This review records the improved prompt controlled run results.

The real improved prompt run was executed manually by the operator. This document records the outputs and lessons for the next pergola-specific prompt pack.

## What This Review Is For

- Record improved pergola prompt outputs.
- Compare the project-like, rain protection, and construction documentation directions.
- Capture VRAM, dashboard, shutdown, and coding-mode restore notes.
- Preserve output paths without committing generated image binaries.
- Identify the next technical-detail prompt direction.

## What This Review Does NOT Do

- It does not run real image generation.
- It does not delete generated images.
- It does not alter Gateway behavior.
- It does not alter Docker Compose.
- It does not add automatic generation.
- It does not create runtime files.

## Run Summary

The operator manually generated 3 improved prompt outputs:

- Project-like covered pergola
- Rain protection pergola
- Construction documentation

Run state:

- ComfyUI workflow submit succeeded for all 3.
- Outputs were surfaced under `/home/cuneyt/MoE/runtime/media/outputs/images/flux-first`.
- Media dashboard `latest_images` showed the new outputs.
- ComfyUI loaded around 13.8 GB VRAM.
- Free VRAM during generation was around 1 GB.
- llama-server was not running during image mode.
- Safe shutdown stopped ComfyUI.
- Safe shutdown restarted `qwen-coder-14b-fast`.
- Gateway health returned `model_runtime ok`.
- Generated outputs were not deleted.

## Variant Table

| Variant | Output filename | Size bytes | Result |
| --- | --- | ---: | --- |
| Project-like covered | `moe_pergola_project_20260707_131301_00001_.png` | 552560 | success, best project direction |
| Rain protection | `moe_pergola_rain_protection_20260707_131327_00001_.png` | 500944 | success, better rain result |
| Construction documentation | `moe_pergola_construction_doc_20260707_131336_00001_.png` | 547270 | success, needs more technical detail |

## Output Paths

Project-like covered:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_project_20260707_131301_00001_.png
```

Rain protection:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_rain_protection_20260707_131327_00001_.png
```

Construction documentation:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_construction_doc_20260707_131336_00001_.png
```

## Output Sizes

| Variant | Size bytes |
| --- | ---: |
| Project-like covered | 552560 |
| Rain protection | 500944 |
| Construction documentation | 547270 |

## Prompt Text

Project-like covered:

```text
realistic photo of a small DIY wooden lean-to pergola in a narrow garden, natural pine wood, fully covered translucent roof panels, simple 10x10 cm posts, visible beams, soft daylight, practical backyard construction, not luxury, not resort style
```

Rain protection:

```text
realistic photo of a small wooden pergola during rainy weather, wet stone floor, damp pine wood, visible rain streaks, cloudy overcast sky, covered roof protecting the walkway, natural backyard garden, realistic moisture and reflections
```

Construction documentation:

```text
construction documentation photo of a DIY wooden pergola frame, visible 10x10 cm posts, visible beam-to-post metal brackets, bolts and screws, unfinished pine wood, measuring tape on the ground, clear joinery details, practical workshop photo, not luxury, not decorative render
```

## Visual Result Notes

Project-like covered pergola:

- Successful.
- Closest to the desired project-like pergola.
- Shows a lean-to structure near a wall, natural pine, and translucent covered roof panels.
- Good candidate direction.

Rain protection pergola:

- Successful.
- Better than the earlier rain prompt.
- Wet floor and rainy atmosphere are visible.
- Good for rain-protection concept.

Construction documentation:

- Successful, but still not technical enough.
- Better construction feel than the first technical attempt.
- Needs closer view, clearer metal brackets, bolts, screw heads, measuring tape, labels, and joinery details.

## VRAM Notes

ComfyUI loaded around 13.8 GB VRAM.

Free VRAM during generation was around 1 GB.

Lesson: keep future technical-detail runs small and one prompt at a time until memory pressure is better understood.

## Dashboard Result

Media dashboard `latest_images` showed the new outputs.

Continue using [51-media-dashboard-output-review.md](51-media-dashboard-output-review.md) and [52-media-dashboard-latest-images-schema.md](52-media-dashboard-latest-images-schema.md) for dashboard checks.

## Safe Shutdown Result

Safe shutdown succeeded:

- ComfyUI stopped.
- Generated outputs were not deleted.
- Image mode ended cleanly.

## Coding Mode Restore Result

Coding mode restored successfully:

- `qwen-coder-14b-fast` restarted.
- Gateway health returned `model_runtime ok`.

## Lessons Learned

- The project-like prompt worked best for the practical pergola direction.
- Covered translucent roof language helped.
- Rain prompt improved when it included wet floor, damp wood, rain streaks, overcast sky, moisture, and reflections.
- Technical/construction prompts need closer framing and very explicit hardware/detail language.
- `construction documentation photo` alone is not enough.

## Recommended Next Prompt Direction

Focus next on technical detail close-ups:

- Beam-to-post connection
- Roof screw detail
- Full lean-to frame construction
- Usta/carpenter inspection view

Use [66-next-technical-detail-prompt-set.md](66-next-technical-detail-prompt-set.md).
