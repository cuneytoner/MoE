# 107 Generic Drawing Engine Roadmap

This roadmap plans the generic deterministic drawing engine.

## Current Prototype

```text
tools/pergola-drawings
```

The current tool is intentionally pergola-specific.

M34.2 creates `tools/drawing-engine` as the generic drawing engine skeleton.

## Future Generic Folder

```text
tools/drawing-engine
```

## Runtime Output Target

```text
/home/cuneyt/MoE/runtime/drawings
```

Drawing outputs should appear as output cards once implemented.

## Why Not Move Immediately

- The pergola tool is working as a focused prototype.
- The generic API is not designed yet.
- Moving too early may break useful case-study behavior.
- The first extraction should happen after the helper boundaries are clearer.

## Migration Stages

1. Keep pergola drawings as a case-study prototype.
2. Identify reusable SVG primitives.
3. Extract generic helpers into `tools/drawing-engine`.
4. Add project-specific geometry config.
5. Migrate or wrap pergola drawings on top of generic helpers.
6. Add PDF export after SVG structure is stable.
7. Add DXF export later.

## Future Drawing Engine Capabilities

- SVG primitives
- dimension labels
- title blocks
- multiple sheets
- PDF export
- DXF export
- templates
- project-specific geometry config
- reusable drawing modules

## Potential Modules

- line / rectangle / circle / text
- dimension line
- arrow marker
- scale-to-page
- title block
- material legend
- plan view
- elevation view
- detail view
