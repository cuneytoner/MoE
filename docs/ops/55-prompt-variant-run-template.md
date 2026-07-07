# 55 Prompt Variant Run Template

Use this copy/paste template for one prompt variant at a time.

Do not use this as a batch execution script. Fill it in manually before and after each reviewed variant.

## Blank Run Template

```text
Variant ID:
Variant name:
Prompt:
Size:
Steps:
Seed:
Filename prefix:
Command used:
Output path:
Output filename:
File size:
Result:
Notes:
Git safety result:
```

## Recommended Fixed Values

```text
Size: 512x512
Steps: 4
Seed: 1783334081
```

## Before Running One Variant

Confirm:

- The prompt matches one reviewed variant.
- Size, steps, and seed are still fixed.
- The filename prefix has no spaces.
- The output path is under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- You understand the exact command you are about to run.

## After Running One Variant

Record:

- Output path
- Output filename
- File size
- Visual result
- Keep/reject decision
- Git safety result

If anything is unclear, stop before starting another variant.
