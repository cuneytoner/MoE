# 100 Side Elevation + Top Plan SVG

M33.6 extends the deterministic pergola SVG tool with separate side elevation and top plan drawings.

These outputs are pergola case-study outputs and should inform the generic deterministic drawing engine.

## What This Milestone Adds

- `side_elevation.svg`
- `top_plan.svg`
- deterministic geometry for the first side and plan views
- labels for main project dimensions and placeholders
- runtime output through the existing SVG generator

## What It Does NOT Do

- It does not create final construction drawings.
- It does not create PDF or DXF files.
- It does not validate post placement, loads, brackets, anchors, or weatherproofing.
- It does not write generated SVG files into the repo by default.

## Generated Files

- `overview_skeleton.svg`
- `side_elevation.svg`
- `top_plan.svg`

## Geometry Used

- wall-side width: `5100 mm`
- depth: `1900 mm`
- roof overhang: `300 mm`
- post section: `100x100 mm`
- beam/rafter placeholder: `50x100 mm`
- rear height placeholder: `3000 mm`
- front height placeholder: `2500 mm`

## How To Run

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
python3 tools/pergola-drawings/generate_pergola_svg.py
```

## How To Inspect Outputs

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/pergola/drawings \
  -maxdepth 1 -type f -name '*.svg' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' | sort
```

### Run on PC-1

```bash
grep -R "Pergola Side Elevation\|Pergola Top Plan\|5100 mm\|1900 mm\|300 mm" -n \
  /home/cuneyt/MoE/runtime/pergola/drawings/*.svg
```

## How To Review Side Elevation

Check whether `side_elevation.svg` shows:

- house wall vertical line at rear
- ground line
- rear side higher than front side
- front post
- rear support/wall-side post placeholder
- sloped roof line
- `1900 mm` depth label
- `300 mm` front roof overhang label
- `10x10` post label
- `5x10` rafter label

## How To Review Top Plan

Check whether `top_plan.svg` shows:

- `5100 mm` wall-side width
- `1900 mm` depth
- roof outline with `300 mm` overhang
- `100x100` post markers
- rafter placeholder lines
- right-side door canopy / extension placeholder

## Git Safety

Generated SVG files are runtime outputs by default.

Do not commit generated SVG/PDF/DXF outputs unless they are explicitly reviewed and intentionally added as small documentation assets.
