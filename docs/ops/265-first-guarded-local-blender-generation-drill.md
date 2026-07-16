# First Guarded Local Blender Generation Drill

## What Was Implemented

M35.15 adds a safe operator-run drill plan command pack for the first local Blender generation.

The implementation emits a reviewed JSON plan and command preview. It does not run Blender in tests and does not generate assets automatically.

## Drill Plan JSON

The generator supports:

```bash
python3 apps/3d-generator/generic_parametric_blender.py \
  --config configs/3d/generic-object.example.json \
  --generation-drill-plan-json
```

The plan includes:

- config preflight status
- scene plan status
- Blender operation plan status
- metadata plan availability
- planned runtime-relative output names
- operator command preview
- stop conditions
- non-generating safety flags

## Operator Command Is Not Executed By Tests

The drill plan includes a future operator command:

```text
REAL_3D_GENERATION=1 blender --background --python apps/3d-generator/generic_parametric_blender.py -- --config configs/3d/generic-object.example.json --execute-generation
```

Tests only inspect this command text. They do not run Blender.

## Why safe_to_run_manually Is False

`safe_to_run_manually` remains `false` by default because an operator must review:

- config
- scene plan
- Blender operation plan
- metadata plan
- runtime output root
- stop conditions
- current Git status

## Planned Runtime-Relative Outputs

Planned outputs are runtime-relative:

- `blender/simple_frame_example-{timestamp}.blend`
- `glb/simple_frame_example-{timestamp}.glb`
- `metadata/simple_frame_example-{timestamp}.json`
- `reports/simple_frame_example-{timestamp}.json`

The plan includes the runtime output root separately:

```text
/home/cuneyt/MoE/runtime/media/outputs/3d
```

## Stop Conditions

Stop if:

- Blender is unavailable or version is unknown.
- Config, scene plan, Blender operation plan, or metadata plan fails review.
- Operator has not explicitly approved `REAL_3D_GENERATION=1`.
- Output root is not `/home/cuneyt/MoE/runtime/media/outputs/3d`.
- Any planned output would be written inside the repo.
- Git status shows unexpected generated binary files.

## No Automatic Generation

M35.15 does not trigger generation from tests, Gateway, Dashboard, or scripts.

## No Runtime Writes During Tests

Tests write only temporary drill reports under `/tmp` when `REPORT_PATH` is set. They do not write runtime files, sidecars, generated assets, or previews.

## How To Test

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make test-3d-first-generation-drill-plan
```

Expected:

- drill plan JSON is valid
- required operator command contains `REAL_3D_GENERATION=1`
- required operator command contains `blender --background`
- required operator command contains `--execute-generation`
- `/tmp` report path works
- repo report path is rejected
- no generated 3D files appear in the repo

## Fixed Roadmap

Next milestone: M35.16 Generated 3D Artifact Verification.

- M35.16 Generated 3D Artifact Verification
- M35.17 3D Output Card API
- M35.18 Dashboard 3D Output Cards UI
- M35.19 3D Reference Board Selection
- M35.20 M35 Phase Closure
