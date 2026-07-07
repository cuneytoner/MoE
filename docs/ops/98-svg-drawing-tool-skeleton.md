# 98 SVG Drawing Tool Skeleton

M33.5 adds the first deterministic pergola SVG drawing tool skeleton.

M33.6 extends the skeleton with `side_elevation.svg` and `top_plan.svg`.

The pergola SVG tool is a prototype and may later be generalized into `tools/drawing-engine`.

## What Was Added

- `tools/pergola-drawings/generate_pergola_svg.py`
- `tools/pergola-drawings/README.md`
- `make pergola-svg-skeleton`

The tool uses Python standard library only and writes generated SVG output to runtime by default.

## How To Run

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
python3 tools/pergola-drawings/generate_pergola_svg.py
```

### Run on PC-1

```bash
make pergola-svg-skeleton
```

## Output Path

Default output directory:

```text
/home/cuneyt/MoE/runtime/pergola/drawings
```

## Generated File

```text
overview_skeleton.svg
```

## Confirm Output

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/pergola/drawings \
  -maxdepth 1 -type f -name '*.svg' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' | sort
```

## What The Drawing Includes

- white background
- title: `Pergola SVG Skeleton`
- top plan rectangle for `5100 mm` width and `1900 mm` depth
- roof overhang outline for `300 mm`
- `100x100` post markers
- simple rafter placeholder lines
- deterministic labels
- footer warning: `Draft drawing. Verify before build.`

## What The Drawing Does Not Include Yet

- final construction drawings
- side elevation
- front elevation
- beam-post detail
- roof sheet layout detail
- PDF export
- DXF export
- verified structural details

## Git Safety

Generated SVG files are written to runtime by default, not the repo.

Do not commit generated SVG/PDF/DXF files unless they are explicitly reviewed and intentionally added as small documentation assets.

## Next Milestones

- M33.6 Side Elevation + Top Plan SVG
- M33.7 Beam-post + Roof Sheet SVG Details
- M33.8 PDF Export Plan
