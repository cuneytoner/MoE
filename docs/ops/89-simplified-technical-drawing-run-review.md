# 89 Simplified Technical Drawing Run Review

This review records the simplified technical drawing controlled run results.

The run was performed manually by the operator. This document records outputs and lessons without running generation or committing generated image binaries.

Geometry-only CAD-style run results are reviewed in [93-geometry-only-cad-run-review.md](93-geometry-only-cad-run-review.md).

## What This Review Is For

- Record the simplified technical drawing run outputs.
- Compare S1 Simple side elevation, S2 Simple top plan, and S3 Beam-post schematic.
- Capture output paths, sizes, dashboard visibility, safe shutdown, and VRAM observations.
- Identify why geometry-only CAD-like prompts are the next direction.
- Preserve safety boundaries around technical-looking generated images.

## What This Review Does NOT Do

- It does not run image generation.
- It does not delete generated images.
- It does not alter Gateway runtime behavior.
- It does not alter Docker Compose.
- It does not create runtime files.
- It does not treat AI-generated drawings as engineering drawings.

## Run Summary

The operator manually ran 3 simplified technical drawing prompts:

- S1 Simple side elevation
- S2 Simple top plan
- S3 Beam-post schematic

Run state:

- ComfyUI workflow submit succeeded for all 3.
- Outputs surfaced under `/home/cuneyt/MoE/runtime/media/outputs/images/flux-first`.
- Media dashboard `latest_images` showed the new outputs.
- ComfyUI/Flux used around 13.8-13.9 GB VRAM.
- Free VRAM during generation was around 0.9-1.0 GB.
- llama-server was not running during image mode.
- Safe shutdown stopped ComfyUI.
- Safe shutdown restarted `qwen-coder-14b-fast`.
- `media_real_generation_enabled` returned false after safe shutdown.
- Generated outputs were not deleted.

## Variant Table

| Variant | Output filename | Size bytes | Result |
| --- | --- | ---: | --- |
| S1 Side elevation | `moe_pergola_s1_side_elevation_20260707_140401_00001_.png` | 150624 | success, simpler but still perspective-like |
| S2 Top plan | `moe_pergola_s2_top_plan_20260707_140418_00001_.png` | 108870 | success, not true top-down plan |
| S3 Beam-post schematic | `moe_pergola_s3_beam_post_schematic_20260707_140427_00001_.png` | 155384 | success, best simplified connection direction |

## Output Paths

S1 Simple side elevation:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_s1_side_elevation_20260707_140401_00001_.png
```

S2 Simple top plan:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_s2_top_plan_20260707_140418_00001_.png
```

S3 Beam-post schematic:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_s3_beam_post_schematic_20260707_140427_00001_.png
```

## Output Sizes

| Variant | Size bytes |
| --- | ---: |
| S1 Simple side elevation | 150624 |
| S2 Simple top plan | 108870 |
| S3 Beam-post schematic | 155384 |

## Prompt Text

S1 Simple side elevation:

```text
simple 2D black line schematic of a lean-to wooden pergola side view, house wall on left, front post on right, roof slope shown, depth 1.90 m, roof overhang 30 cm, 10x10 cm posts, 5x10 cm rafters, no perspective, white background, minimal labels only
```

S2 Simple top plan:

```text
simple top-down 2D black line plan of wall-side wooden pergola, total width 5.10 m, depth 1.90 m, post positions as squares, rafters as parallel lines, roof overhang shown, right-side door canopy extension shown, no perspective, white background, minimal labels only
```

S3 Beam-post schematic:

```text
simple 2D black line schematic of wooden pergola beam-to-post connection, 10x10 post, 5x10 beam, two galvanized L brackets, four bolts with washers, no decorative wood texture, no perspective, white background, labels A B C only
```

## Visual Result Notes

S1 Simple side elevation:

- Generated successfully.
- Simpler than earlier technical drawings.
- Still drifted into a perspective/isometric pergola sketch instead of a true side elevation.
- Useful only as visual schematic direction, not as a measured side plan.

S2 Simple top plan:

- Generated successfully.
- Better simplified drawing style.
- Includes a visible `5.10 m` label.
- Not a true top-down plan.
- Resembles a front/elevation drawing with door/wall context.
- Useful for layout intent, not reliable plan geometry.

S3 Beam-post schematic:

- Generated successfully.
- Best simplified technical direction in this run.
- Shows bracket/bolt/support idea more clearly than earlier attempts.
- Should not be copied as a structural connection detail.

## VRAM Notes

ComfyUI/Flux used around 13.8-13.9 GB VRAM.

Free VRAM during generation was around 0.9-1.0 GB.

Continue running drawing prompts one at a time until a future run proves more headroom.

## Dashboard Result

Media dashboard `latest_images` showed the new outputs.

Use [51-media-dashboard-output-review.md](51-media-dashboard-output-review.md) and [52-media-dashboard-latest-images-schema.md](52-media-dashboard-latest-images-schema.md) for future dashboard evidence checks.

## Safe Shutdown Result

Safe shutdown succeeded:

- ComfyUI stopped.
- `qwen-coder-14b-fast` restarted.
- `media_real_generation_enabled` returned false after safe shutdown.
- Generated outputs were not deleted.

## Lessons Learned

- Even with `no perspective` and `2D`, Flux may still produce perspective/isometric technical-looking drawings.
- S1 and S2 are simpler, but not true orthographic drawings.
- S3 is the best simplified connection direction so far.
- Text labels and dimension labels remain unreliable.
- Exact measurements should be added manually after generation.
- The next prompt strategy should use stronger CAD-like geometry-only language.

## Recommended Next Direction

Move to geometry-only CAD-style prompts using [91-next-cad-like-geometry-only-prompts.md](91-next-cad-like-geometry-only-prompts.md).

Use [92-manual-labeling-plan.md](92-manual-labeling-plan.md) to add dimensions and labels manually after image generation.
