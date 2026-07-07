# 96 SVG Drawing Safety And Git Policy

This policy covers deterministic pergola drawing outputs.

## Deterministic SVG

SVG generated from code is deterministic.

That makes it better than AI-generated image output for measured lines, labels, and repeatable drawing views.

## Output Location

Generated output path should be runtime by default:

```text
/home/cuneyt/MoE/runtime/pergola/drawings
```

The repo should track source scripts and docs, not large generated media.

## Repo Policy

- Source scripts can live in the repo.
- Generated SVG files may be small, but still should be reviewed before adding.
- PDF/DXF should not be committed by default.
- Do not commit generated media by accident.
- Do not run destructive cleanup.

## Git Safety Commands

```bash
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth|pdf|dxf)$' || true
```

## Review Rule

Before adding any generated SVG to Git, confirm:

- it is intentionally being added as a small documentation asset
- it does not contain runtime-only paths or temporary data
- it is useful for source documentation
- it has been manually reviewed

Otherwise keep generated drawings under runtime.
