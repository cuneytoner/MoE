# 3D Generator

## Purpose

This directory holds source-only planning code for future generic parametric Blender generation.

## Current Status

M35.4 is dry-run only. The skeleton does not run Blender, import `bpy` at module import time, or generate 3D assets.

## Runtime Output Root

Future generated outputs are planned under:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

This milestone does not create runtime folders or generated outputs.

## Generation Guard

`REAL_3D_GENERATION=0` is the default. Future real generation must require an explicit reviewed milestone and explicit operator enablement.

Generated binaries must never be committed to Git. Future milestones will add guarded generation only after the dry-run plan and runtime safety boundaries are reviewed.
