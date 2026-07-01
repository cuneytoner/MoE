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

The authoritative source-controlled registry is `configs/models.yaml`.

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
