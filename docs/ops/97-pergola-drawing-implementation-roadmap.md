# 97 Pergola Drawing Implementation Roadmap

This roadmap stages deterministic pergola drawing work.

It does not create drawing files yet.

## M33.5 SVG Drawing Tool Skeleton

- Create the source folder `tools/pergola-drawings`.
- Add the first Python SVG generator script.
- Default output to `/home/cuneyt/MoE/runtime/pergola/drawings`.
- Keep generated outputs outside Git by default.

## M33.6 Side Elevation + Top Plan SVG

- Generate `side_elevation.svg`.
- Generate `top_plan.svg`.
- Use millimeter-based geometry.
- Add deterministic labels and dimension lines.

## M33.7 Beam-post + Roof Sheet SVG Details

- Generate `beam_post_detail.svg`.
- Generate `roof_sheet_layout.svg`.
- Use placeholder bracket and bolt geometry.
- Keep structural details marked for manual review.

## M33.8 PDF Export Plan

- Decide whether SVG-to-PDF export is needed.
- Define page size, margins, title block, and print scale.
- Keep PDF outputs outside Git by default.

## M33.9 Usta Drawing Package Assembly

- Assemble reviewed SVG/PDF outputs with measurements and notes.
- Keep AI visual references separate from deterministic drawings.
- Include safety warnings and manual review notes.
