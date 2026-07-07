# 95 Pergola Drawing Geometry Spec

This spec defines the first deterministic geometry assumptions for pergola drawings.

It does not create drawing files yet.

## Coordinate / Drawing Assumptions

- use millimeters internally
- wall-side width: `5100 mm`
- depth: `1900 mm`
- roof overhang: `300 mm`
- post section: `100x100 mm`
- beam/rafter section: `50x100 mm`
- optional side panel height: `700-900 mm`
- drawing scale can be fitted to page
- labels are deterministic text, not AI-generated

## Planned Views

### Side Elevation

Include:

- house wall line
- rear high side
- front lower side
- sloped roof line
- `1900 mm` depth
- `300 mm` overhang

### Top Plan

Include:

- `5100 mm` wall line
- `1900 mm` depth
- post positions
- rafter lines
- right-side door canopy/extension placeholder

### Front Elevation

Include:

- posts
- front beam
- roof overhang

### Beam-post Detail

Include:

- `10x10` post
- `5x10` beam
- bracket placeholder
- bolt placeholder

### Roof Sheet Layout

Include:

- panel outlines
- rafter lines
- screw washer positions as circles

## Review Notes

The geometry spec is an implementation starting point.

Before real building, all dimensions, post spacing, beam spans, fasteners, anchors, waterproofing, and structural choices must be reviewed manually.
