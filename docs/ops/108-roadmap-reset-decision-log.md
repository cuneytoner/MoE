# 108 Roadmap Reset Decision Log

## Decision Date

TBD

## Decision

Pergola is now a case study, not the whole roadmap.

## Reason

Pergola validated the image/media/drawing pipeline and exposed Flux limits for technical drawings.

Flux is useful for concept and reference images.

Deterministic SVG/DXF-style generation is better for measured technical drawings.

## Consequence

Continue generic media/drawing architecture.

M34 begins the generic roadmap.

## Keep

Keep `tools/pergola-drawings` as a working prototype.

Keep pergola docs as the first case-study trail.

Keep existing generated outputs under runtime.

## Later

Extract generic drawing helpers into:

```text
tools/drawing-engine
```

## Do Not

- do not move files yet
- do not break existing pergola scripts
- do not remove working outputs
- do not change runtime behavior
- do not treat AI-generated technical images as engineering truth
