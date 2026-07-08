# Generic Drawing Engine

This folder is the first generic deterministic drawing engine skeleton for MoE / AI-Brain-OS.

It provides beginner-readable SVG helper code for future architecture, technical, layout, and project-specific drawings.

## What It Is

- A source-only deterministic drawing helper area.
- A place for reusable SVG primitives and drawing patterns.
- A foundation for future measured sheets, labels, title blocks, and multiple output formats.
- A generic sibling to project-specific drawing tools.

## What It Is NOT

- It is not an image generation system.
- It is not a PDF or DXF exporter yet.
- It is not a CAD replacement.
- It is not a construction document generator yet.
- It does not migrate existing pergola drawings.

## Why It Exists

The pergola prototype proved that deterministic SVG is better than AI-generated images for measured drawing intent. This folder begins extracting that lesson into a generic engine that can later support multiple projects.

## Difference From `tools/pergola-drawings`

`tools/pergola-drawings` remains the pergola-specific prototype and case study.

`tools/drawing-engine` is the generic foundation for future reusable helpers. Pergola-specific code should stay in place until an explicit migration milestone moves or adapts it.

## Runtime Output Policy

Generated drawing outputs must go under runtime by default:

```text
/home/cuneyt/MoE/runtime/drawings
```

The demo generator writes to:

```text
/home/cuneyt/MoE/runtime/drawings/demo/demo_sheet.svg
```

It also writes matching sidecar metadata:

```text
/home/cuneyt/MoE/runtime/drawings/demo/demo_sheet.json
```

Metadata is runtime output.

Use `--output-dir` for test output under `/tmp`.

## Git Policy

Commit source code and documentation only. Do not commit generated SVG, PDF, DXF, image, log, or runtime output files unless a future milestone explicitly approves a small documentation asset.

## Planned Capabilities

- SVG primitives
- dimension labels
- title blocks
- multiple sheets
- PDF export later
- DXF export later
- project-specific geometry config later
