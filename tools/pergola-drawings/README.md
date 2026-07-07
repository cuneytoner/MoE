# Pergola Drawings Tool

This tool generates deterministic draft SVG drawings for the pergola project.

## What This Tool Does

- Uses Python standard library only.
- Uses millimeter-based project geometry.
- Generates `overview_skeleton.svg`.
- Writes generated SVG files to runtime by default.
- Provides a source-code foundation for later side elevation, top plan, and detail drawings.

## What This Tool Does NOT Do

- It does not create final construction drawings.
- It does not create PDF or DXF files.
- It does not validate structure, load paths, post spacing, brackets, bolts, anchors, or weatherproofing.
- It does not write generated SVG files into the repo by default.

## Default Output Path

```text
/home/cuneyt/MoE/runtime/pergola/drawings
```

## How To Run

```bash
python3 tools/pergola-drawings/generate_pergola_svg.py
```

## Override Output Directory

```bash
python3 tools/pergola-drawings/generate_pergola_svg.py --output-dir /home/cuneyt/MoE/runtime/pergola/drawings-test
```

## Safety Warning

Generated SVG files are draft references only.

Verify dimensions, materials, load paths, fasteners, anchors, drainage, and weatherproofing before build.

## Git Policy

- Track source scripts and docs in Git.
- Keep generated SVG/PDF/DXF outputs under runtime by default.
- Do not commit generated drawing outputs unless explicitly reviewed and intentionally added as small documentation assets.
