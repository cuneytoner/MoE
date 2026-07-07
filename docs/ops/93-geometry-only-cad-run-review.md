# 93 Geometry-only CAD Run Review

This review records the geometry-only CAD-style drawing prompt run.

The run was performed manually by the operator. This document records the outputs and final lesson without creating drawing files or committing generated image binaries.

## What This Review Is For

- Record the G1, G2, and G3 geometry-only prompt outputs.
- Capture what worked and what failed.
- Preserve output paths and file sizes.
- Document the decision to stop relying on Flux for real technical drawings.
- Point the project toward deterministic code-generated drawings.

## What This Review Does NOT Do

- It does not run image generation.
- It does not create SVG, PDF, or DXF files.
- It does not create runtime files.
- It does not delete generated images.
- It does not alter Gateway runtime behavior.
- It does not treat AI-generated drawings as CAD plans.

## Run Summary

The operator manually ran 3 geometry-only CAD-style prompts:

- G1 Side geometry
- G2 Top plan geometry
- G3 Beam-post geometry

All outputs were generated successfully and surfaced under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first
```

## Variant Table

| Variant | Output filename | Size bytes | Result |
| --- | --- | ---: | --- |
| G1 Side geometry | `moe_pergola_g1_side_geometry_20260707_153819_00001_.png` | 79048 | success, closest side/elevation sketch, not CAD |
| G2 Top plan geometry | `moe_pergola_g2_top_plan_geometry_20260707_153834_00001_.png` | 72489 | success, not a true top-down plan |
| G3 Beam-post geometry | `moe_pergola_g3_beam_post_geometry_20260707_153843_00001_.png` | 81201 | success, useful schematic direction only |

## Output Paths

G1 Side geometry:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_g1_side_geometry_20260707_153819_00001_.png
```

G2 Top plan geometry:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_g2_top_plan_geometry_20260707_153834_00001_.png
```

G3 Beam-post geometry:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_g3_beam_post_geometry_20260707_153843_00001_.png
```

## Output Sizes

| Variant | Size bytes |
| --- | ---: |
| G1 Side geometry | 79048 |
| G2 Top plan geometry | 72489 |
| G3 Beam-post geometry | 81201 |

## Visual Notes

G1 Side geometry:

- Closest output to a side/elevation drawing.
- Still added house/door details.
- Not a real CAD plan.

G2 Top plan geometry:

- Did not become a true top-down plan.
- Looked more like a front/elevation sketch.
- Not reliable for plan geometry.

G3 Beam-post geometry:

- Cleaner schematic direction than earlier attempts.
- Still not a real connection detail.
- Useful only as visual intent.

## What Worked

- Geometry-only prompts reduced visual clutter.
- G1 moved closer to elevation language.
- G3 produced a cleaner connection schematic direction.
- Smaller, stricter prompts were better than multi-view sheets.

## What Failed

- Flux still did not reliably produce true CAD/orthographic drawings.
- Top-down plan intent was not followed.
- Generated images still invented context and details.
- Connection geometry remained unsuitable as a source of truth.
- AI output cannot be trusted for measured labels, joinery, or technical layout.

## Final Lesson

Flux is useful for visual references and intent images, but not reliable for measured technical drawings, exact plans, joinery, labels, or CAD-style output.

## Decision To Move To Deterministic Drawings

Real technical drawing generation should move to deterministic code-generated drawings:

- SVG first
- optional PDF export later
- optional DXF later
- no AI-generated dimensions
- no AI-generated bracket geometry as source of truth

Use [94-deterministic-pergola-drawing-plan.md](94-deterministic-pergola-drawing-plan.md) for the implementation plan.
