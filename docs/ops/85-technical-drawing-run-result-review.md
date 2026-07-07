# 85 Technical Drawing Run Result Review

This review records the first technical drawing controlled run results.

The run was performed manually by the operator. This document records outputs and lessons without running generation or committing generated image binaries.

## What This Review Is For

- Record the first technical drawing-style outputs.
- Compare V4 Combined usta sheet, C1 Beam-post connection, and D2 Roof screw pattern.
- Capture output paths, sizes, dashboard visibility, and VRAM observations.
- Identify prompt lessons for simplified drawing prompts.
- Preserve safety boundaries around AI-generated technical-looking images.

## What This Review Does NOT Do

- It does not run image generation.
- It does not delete generated images.
- It does not alter Gateway runtime behavior.
- It does not alter Docker Compose.
- It does not create runtime files.
- It does not treat AI-generated drawings as engineering drawings.

## Run Summary

The operator manually ran 3 technical drawing prompts:

- V4 Combined usta sheet
- C1 Beam-post connection detail
- D2 Roof screw pattern

Run state:

- ComfyUI workflow submit succeeded.
- Outputs surfaced under `/home/cuneyt/MoE/runtime/media/outputs/images/flux-first`.
- Media dashboard `latest_images` showed the new outputs.
- ComfyUI/Flux used around 13.7-13.8 GB VRAM.
- Free VRAM during generation was around 1 GB.
- llama-server was not running during image mode.
- Generated outputs were not deleted.

## Variant Table

| Variant | Output filename | Size bytes | Result |
| --- | --- | ---: | --- |
| V4 Combined usta sheet | `moe_pergola_v4_usta_sheet_20260707_135213_00001_.png` | 178910 | success, but not a reliable technical sheet |
| C1 Beam-post connection | `moe_pergola_c1_beam_post_connection_20260707_135230_00001_.png` | 200069 | success, useful intent, labels/brackets unreliable |
| D2 Roof screw pattern | `moe_pergola_d2_roof_screw_pattern_20260707_135238_00001_.png` | 201465 | success, useful concept, not reliable spacing plan |

## Output Paths

V4 Combined usta sheet:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_v4_usta_sheet_20260707_135213_00001_.png
```

C1 Beam-post connection:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_c1_beam_post_connection_20260707_135230_00001_.png
```

D2 Roof screw pattern:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_d2_roof_screw_pattern_20260707_135238_00001_.png
```

## Output Sizes

| Variant | Size bytes |
| --- | ---: |
| V4 Combined usta sheet | 178910 |
| C1 Beam-post connection | 200069 |
| D2 Roof screw pattern | 201465 |

## Prompt Text

V4 Combined usta sheet:

```text
single-page carpenter plan sheet for a DIY wooden pergola, includes front elevation, side elevation, top plan view, simple dimension labels, 10x10 posts, 5x10 beams, translucent roof panels, practical Turkish backyard construction, black line drawing on white background
```

C1 Beam-post connection:

```text
technical close-up line drawing of wooden pergola beam-to-post connection, 10x10 cm pine post, 5x10 cm beam sitting on or bolted to post, galvanized L angle brackets, through bolts, washers, screw heads, hole positions marked, black line drawing with labels
```

D2 Roof screw pattern:

```text
top detail technical drawing of translucent polycarbonate roof panel screw pattern on wooden rafters, screws with rubber washers, spacing marks, overlap direction, drip edge, labels, practical roof fastening guide, black line drawing on white background
```

## Visual Result Notes

V4 Combined usta sheet:

- Generated successfully.
- Looks like a pergola sketch/drawing.
- Not a reliable combined technical sheet.
- Does not clearly separate front elevation, side elevation, and top plan view.
- Dimension labels are not trustworthy.

C1 Beam-post connection:

- Generated successfully.
- Best technical-detail direction in this run.
- Useful as visual intent only.
- Labels are garbled.
- Bracket and fastener geometry is not structurally reliable.

D2 Roof screw pattern:

- Generated successfully.
- Shows roof panel and washer/screw placement concept.
- Not a reliable screw spacing or real roof fastening plan.
- Needs simpler top-down 2D layout prompts.

## VRAM Notes

ComfyUI/Flux used around 13.7-13.8 GB VRAM.

Free VRAM during generation was around 1 GB.

Continue running technical drawing prompts one at a time until a future run proves more headroom.

## Dashboard Result

Media dashboard `latest_images` showed the new outputs.

Use [51-media-dashboard-output-review.md](51-media-dashboard-output-review.md) and [52-media-dashboard-latest-images-schema.md](52-media-dashboard-latest-images-schema.md) for future dashboard evidence checks.

## Lessons Learned

- Flux can produce technical-looking drawings.
- Text labels are often garbled.
- Dimension values are not reliable.
- Complex combined sheets are too much for one `512x512` image.
- Single-topic detail prompts work better than multi-view sheets.
- Close-up connection prompts are useful for intent but not structural plans.
- Drawing prompts should be simplified into single-topic 2D schematics.

## Recommended Next Direction

Use [86-technical-drawing-prompt-lessons.md](86-technical-drawing-prompt-lessons.md) and [87-next-simplified-technical-drawing-prompts.md](87-next-simplified-technical-drawing-prompts.md).

Keep V4, C1, and D2 as reference lessons only. Selection notes are in [88-technical-drawing-selection-notes.md](88-technical-drawing-selection-notes.md).
