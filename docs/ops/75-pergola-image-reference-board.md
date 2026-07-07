# 75 Pergola Image Reference Board

This reference board classifies useful generated pergola images as visual references.

Generated images are visual references only. They are not engineering drawings, static calculations, or safe construction details.

Reference images can support technical drawing prompt generation, but generated drawings still require review.

## What This Reference Board Is For

- Select useful generated pergola images for visual discussion.
- Group images by project overview, rain protection, and technical/detail direction.
- Track which images are useful enough to show as intent references.
- Preserve output paths and filenames without committing generated image binaries.
- Prepare the next usta/carpenter briefing step.

## What This Reference Board Does NOT Do

- It does not run image generation.
- It does not copy generated images.
- It does not delete generated images.
- It does not create runtime files.
- It does not validate joinery, brackets, bolts, load paths, or structural layout.
- It does not replace real measurements, material sizing, connection plans, or engineering review.

## Selection Criteria

Select images that help explain:

- narrow wall-side walkway pergola direction
- covered translucent/polycarbonate roof
- practical backyard construction rather than luxury styling
- rain protection over the walking path
- visible timber frame
- visible connection-detail intent

Reject or downgrade images that show:

- open decorative roof
- luxury resort styling
- huge pavilion scale
- impossible floating beams
- no visible timber frame
- confusing or unsafe-looking structural details

## Selected Reference Images

| Ref ID | Image filename | Category | Usefulness | Notes |
| --- | --- | --- | --- | --- |
| R1 | `moe_pergola_p1_project_overview_20260707_132558_00001_.png` | project overview | high | best wall-side project direction |
| R2 | `moe_pergola_project_20260707_131301_00001_.png` | project overview | medium-high | good covered roof / practical build direction |
| R3 | `moe_pergola_p4_rain_protection_20260707_132700_00001_.png` | rain protection | high | best wet walkway / rain protection direction |
| R4 | `moe_pergola_rain_protection_20260707_131327_00001_.png` | rain comparison | medium | useful comparison image |
| R5 | `moe_pergola_t1_beam_post_joint_20260707_132730_00001_.png` | technical detail | medium-high | good close-up direction, not structurally exact |
| R6 | `moe_pergola_construction_doc_20260707_131336_00001_.png` | construction documentation | medium | useful but not detailed enough |

## Selected Runtime Paths

R1:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_p1_project_overview_20260707_132558_00001_.png
```

R2:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_project_20260707_131301_00001_.png
```

R3:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_p4_rain_protection_20260707_132700_00001_.png
```

R4:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_rain_protection_20260707_131327_00001_.png
```

R5:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_t1_beam_post_joint_20260707_132730_00001_.png
```

R6:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_construction_doc_20260707_131336_00001_.png
```

## Rejected / Low-Use Images

Use a low-use or rejected category for images that:

- look too decorative or resort-like
- do not show a covered roof
- do not match the narrow wall-side walkway idea
- obscure the timber frame
- imply unsafe or impossible construction details
- are visually interesting but not useful for the actual build discussion

Record rejected images in [76-pergola-reference-board-review-template.md](76-pergola-reference-board-review-template.md) if they teach a useful prompt lesson.

## How To Use These Images With An Usta/Carpenter

- Use R1 and R2 to explain the general look.
- Use R3 and R4 to explain rain protection and covered walkway intent.
- Use R5 and R6 only to explain the wish for visible connection details.
- Bring real measurements separately.
- Bring the material list separately.
- Bring real connection/detail plans separately.
- Ask the usta to judge what is buildable and safe.

## How Not To Use These Images

- Do not copy AI-generated bracket details blindly.
- Do not treat AI joinery as structurally valid.
- Do not infer post spacing or beam sizing from the images.
- Do not treat the roof slope, flashing, gutter, or fasteners as correct unless verified.
- Do not commit generated images to Git.

## Next Reference Needs

Useful next references:

- more exact `5.1 m` wall-line and `1.9 m` depth overview
- roof drainage and gutter detail
- real bracket and through-bolt detail
- post base detail
- right-side door canopy extension
- left-side half-height protection option

## Git Safety Reminder

Generated media must stay outside the source repo.

Use [78-pergola-reference-board-file-handling.md](78-pergola-reference-board-file-handling.md) if selected outputs need to be copied into a runtime reference-board folder.

Before committing docs, check:

```bash
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```
