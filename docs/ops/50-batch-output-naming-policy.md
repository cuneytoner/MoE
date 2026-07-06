# 50 Batch Output Naming Policy

Use clear filename prefixes for future prompt variant and batch image outputs.

Good names make it easier to compare results without opening every image.

## Prefix Format Suggestions

Use this shape:

```text
moe_<subject>_<variant>_YYYYMMDD_HHMMSS
```

Examples:

```text
moe_pergola_base_YYYYMMDD_HHMMSS
moe_pergola_rain_YYYYMMDD_HHMMSS
moe_pergola_evening_YYYYMMDD_HHMMSS
moe_pergola_technical_YYYYMMDD_HHMMSS
```

## Naming Rules

- Include date/time.
- Include a short variant name.
- Avoid spaces.
- Avoid Turkish special chars in filenames.
- Use lowercase letters where practical.
- Use underscores between words.
- Keep generated outputs under runtime paths.
- Do not store generated outputs under the repo path.

## Good Variant Names

Examples:

- `base`
- `wide_angle`
- `rain`
- `evening`
- `technical`
- `cedar`
- `overcast`

## Runtime Output Path

Generated outputs should stay under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

Do not store generated outputs under:

```text
/home/cuneyt/DiskD/Projects/MoE/codebase
```

## Inspect Recent Outputs

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/media/outputs/images \
  -maxdepth 3 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -30
```

Expected good sign: output files are visible under runtime media folders, not the repo.
