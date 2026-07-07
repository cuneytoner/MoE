# 52 Media Dashboard Latest Images Schema

This page documents the current `latest_images` fields returned by media dashboard status.

The dashboard is read-only. It surfaces runtime image output metadata for review.

## latest_images Fields

| Field | Example | Meaning | Operator use |
| --- | --- | --- | --- |
| `name` | `moe_flux_first_20260706_133441_00001_.png` | filename | identify output |
| `path` | `/home/cuneyt/MoE/runtime/media/outputs/images/...` | absolute runtime path | open/copy/archive |
| `modified` | `timestamp` | last modified time | sort/recent check |
| `size_bytes` | `538671` | file size | detect empty/broken outputs |

## Important Notes

- `latest_images` may include old outputs.
- Duplicated surfaced/copied paths can appear.
- Dashboard visibility does not mean the file is committed to Git.
- The dashboard is read-only.
- Generated outputs should stay under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- Model files should stay under `/home/cuneyt/MoE_Models_Backup`.

## Operator Checks

Use dashboard metadata to answer:

- Which filename is newest?
- Does the path point to runtime storage?
- Is the file size non-zero?
- Does filesystem listing show the same file?
- Does Git remain clean of generated media?

Use [51-media-dashboard-output-review.md](51-media-dashboard-output-review.md) for the review workflow.
