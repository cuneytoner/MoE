# Model Inventory

This repository tracks model paths and model intent only. Model binaries, checkpoints, caches, and generated outputs must stay outside the source tree.

## Paths

- Active model path: `/home/cuneyt/MoE_Models_Backup`
- Archived model path: `/media/cuneyt/Disk2TB/model_backup/MoE_Models_Archive`
- Runtime path: `/home/cuneyt/MoE/runtime`

## Active Required Models

`make check-models` fails if these active required models or assets are missing or invalid:

- `/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf`
- `/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-32B-Instruct-IQ4_XS.gguf`
- `/home/cuneyt/MoE_Models_Backup/DeepSeek-Coder-V2-Lite-Instruct-IQ4_XS.gguf`
- `/home/cuneyt/MoE_Models_Backup/bge-m3`
- `/home/cuneyt/MoE_Models_Backup/flux/flux1-schnell.safetensors`
- `/home/cuneyt/MoE_Models_Backup/clip/t5xxl_fp8_e4m3fn.safetensors`
- `/home/cuneyt/MoE_Models_Backup/clip/clip_l.safetensors`
- `/home/cuneyt/MoE_Models_Backup/vae/ae.safetensors`

The active runtime model config is `configs/models.yaml`.

The source-only registry example for inventory checks is `configs/model-registry.example.yaml`.

## Archived Optional Models

Large inactive models are documented in `configs/models.yaml` under `archived_models` with `status: archived`, `required: false`, and an `archive_path`.

Archived models do not need to exist under `/home/cuneyt/MoE_Models_Backup`, and their absence must not fail `make check-models`.

Current archived inventory includes:

- `Qwen_Qwen3.6-35B-A3B-Q4_K_M.gguf`
- `qwen2.5-coder-32b-instruct-q4_k_m.gguf`
- `DeepSeek-Coder-V2-Lite-Instruct-Q8_0.gguf`
- `gemma-3-27b-it-Q4_K_M.gguf`
- `CogVideoX_5b_I2V_GGUF_Q4_0.gguf`
- `CogVideoX_5b_I2V_GGUF_Q4_0.safetensors`
- checkpoint duplicates

Do not move, delete, or restore archived files from scripts. Restore or re-activate archived models manually, then update `configs/models.yaml` intentionally.

## Commands

Validate active required registry paths and warn about optional archived paths:

```bash
make model-registry-check
```

Scan the active and archive roots and write a JSON inventory report:

```bash
make model-inventory
```

The inventory report is written to:

```text
/home/cuneyt/MoE/runtime/reports/models/model-inventory.json
```

This generated report is runtime data and must not be committed.

The inventory report includes:

- `generated_at`
- `active_root`
- `archive_root`
- `total_active_size_bytes`
- `total_archive_size_bytes`
- `active_models`
- `archived_models`
- `duplicate_candidates`
- `missing_required`

## Registry Behavior

- Active required paths must exist.
- Active GGUF models must start with `GGUF`.
- Missing archived optional paths produce warnings only.
- Duplicate filename candidates and configured optional duplicate candidates are reported as warnings for human review.
- Scripts never move, delete, download, or mutate model files.
