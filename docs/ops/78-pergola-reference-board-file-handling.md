# 78 Pergola Reference Board File Handling

This guide explains how to locate and optionally copy selected reference images to an external runtime review folder without committing them to Git.

This copies only selected outputs inside runtime.

Do not copy images into the Git repo.

Do not commit generated images.

## Create Reference Board Folder

### Run on PC-1

```bash
mkdir -p /home/cuneyt/MoE/runtime/media/reference-boards/pergola-m32
```

## Copy Selected Reference Images

### Run on PC-1

```bash
cp /home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_p1_project_overview_20260707_132558_00001_.png \
  /home/cuneyt/MoE/runtime/media/reference-boards/pergola-m32/
```

### Run on PC-1

```bash
cp /home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_p4_rain_protection_20260707_132700_00001_.png \
  /home/cuneyt/MoE/runtime/media/reference-boards/pergola-m32/
```

### Run on PC-1

```bash
cp /home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_pergola_t1_beam_post_joint_20260707_132730_00001_.png \
  /home/cuneyt/MoE/runtime/media/reference-boards/pergola-m32/
```

## Confirm Runtime Reference Board Files

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/media/reference-boards/pergola-m32 \
  -maxdepth 1 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' | sort
```

## Confirm Git Safety

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

## Safety Notes

- This copies only selected outputs inside runtime.
- Do not copy images into the Git repo.
- Do not commit generated images.
- Do not delete generated images during reference-board preparation.
- Use notes and runtime paths in Git, not binary image files.
