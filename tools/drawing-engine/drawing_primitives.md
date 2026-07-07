# Drawing Primitives

This note tracks the generic drawing primitives available in `tools/drawing-engine`.

## Current Primitive List

- `svg_header`
- `svg_footer`
- `line`
- `rect`
- `circle`
- `text`
- `polyline`
- `save_svg`

## Planned Primitive List

- arrows
- dimension labels
- leader lines
- dashed lines
- section markers
- title blocks
- sheet borders
- scaled coordinate helpers
- reusable material hatching
- multiple-sheet helpers

## How Future Scripts Should Reuse Helpers

Future scripts should keep primitive helpers small and predictable. Project-specific scripts should pass geometry and labels into generic helpers instead of copying large blocks of SVG formatting.

When a helper becomes useful across two or more drawing scripts, move it into a shared module in this folder during a dedicated milestone.

## Coordinate Assumptions

- SVG coordinates start at the top-left corner.
- Positive `x` moves right.
- Positive `y` moves down.
- Current demo units are SVG canvas units, not millimeters.
- Future measured scripts should clearly define scale and source units.

## SVG Safety Notes

- Escape text before writing it into SVG.
- Keep generated SVG output under runtime or `/tmp` by default.
- Do not write generated SVG files into the repo by default.
- Do not treat demo SVG output as a construction document.
- Review dimensions and labels before using any drawing for real-world work.
