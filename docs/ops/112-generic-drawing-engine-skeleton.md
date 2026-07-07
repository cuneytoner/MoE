# Generic Drawing Engine Skeleton

## What Was Added

M34.2 adds the first generic deterministic SVG drawing engine skeleton:

```text
tools/drawing-engine/
  README.md
  generate_demo_svg.py
  drawing_primitives.md
```

The demo generator creates one SVG file:

```text
demo_sheet.svg
```

## Why This Exists

The pergola SVG prototype proved that deterministic SVG is the right direction for measured drawing work. The generic drawing engine begins a reusable foundation for architecture, technical, layout, and future project-specific drawings.

## Difference From Pergola-specific Tool

`tools/pergola-drawings` remains the pergola case-study prototype.

`tools/drawing-engine` is generic. It should not contain pergola assumptions unless a later adapter milestone explicitly adds them.

## Output Path

Default output directory:

```text
/home/cuneyt/MoE/runtime/drawings/demo
```

## Generated File

```text
/home/cuneyt/MoE/runtime/drawings/demo/demo_sheet.svg
```

Generated SVG files should not be written under the repo by default.

## How To Run

### Run on PC-1
```bash
cd ~/DiskD/Projects/MoE/codebase
python3 tools/drawing-engine/generate_demo_svg.py
```

You can also use the Makefile target:

### Run on PC-1
```bash
make drawing-engine-demo
```

## How To Inspect Output

### Run on PC-1
```bash
find /home/cuneyt/MoE/runtime/drawings/demo \
  -maxdepth 1 -type f -name '*.svg' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' | sort
```

### Run on PC-1
```bash
grep -R "Generic Drawing Engine Demo\|Demo SVG. Not a construction document" -n \
  /home/cuneyt/MoE/runtime/drawings/demo/*.svg
```

## Git Safety

Only source code and documentation belong in Git. Generated SVG, PDF, DXF, image, log, pid, and runtime files should stay outside the repo unless a future milestone explicitly approves a small documentation asset.

Before committing, run:

```bash
git status --short
```

Generated runtime paths should not appear as repo changes.

## Next Steps

- Keep adding reusable SVG helpers only when a real drawing need appears.
- Add title block and dimension helpers in a focused milestone.
- Keep pergola-specific code in `tools/pergola-drawings` until an explicit adapter or migration milestone.
- Plan PDF and DXF export later, after SVG behavior is stable.
