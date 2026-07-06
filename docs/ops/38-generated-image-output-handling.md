# 38 Generated Image Output Handling

Generated images are runtime outputs. They should be easy to inspect, but they must stay outside this source-only Git repo.

## Where Images Are Stored

Generated image outputs belong under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

The first successful Flux run used:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first
```

Example output:

```text
/home/cuneyt/MoE/runtime/media/outputs/images/flux-first/moe_flux_first_20260706_133441_00001_.png
```

This path is outside:

```text
/home/cuneyt/DiskD/Projects/MoE/codebase
```

## Why Outputs Stay Outside Git

The repo is source-only. Git should track docs, scripts, configs, tests, and source code.

Generated images should not be committed because they are binary runtime artifacts. They can grow quickly, make reviews noisy, and blur the boundary between source code and runtime state.

Keep:

- Generated images under `/home/cuneyt/MoE/runtime/media/outputs/images`
- Model files under `/home/cuneyt/MoE_Models_Backup`
- Source docs and scripts under `/home/cuneyt/DiskD/Projects/MoE/codebase`

## Find Latest Generated Images

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
make image-latest
```

Expected good sign: latest image paths point under `/home/cuneyt/MoE/runtime/media/outputs/images`, not inside the repo.

For the first Flux output folder:

### Run on PC-1

```bash
find /home/cuneyt/MoE/runtime/media/outputs/images/flux-first \
  -maxdepth 1 -type f -name '*.png' \
  -printf '%TY-%Tm-%Td %TH:%TM %s %p\n' 2>/dev/null | sort | tail -20
```

This prints modified date, file size in bytes, and full path for the latest PNG files.

## Open Output Folder

### Run on PC-1

```bash
xdg-open /home/cuneyt/MoE/runtime/media/outputs/images/flux-first
```

Expected good sign: the file manager opens the runtime output folder. Do not drag image files into the codebase.

## Copy Selected Outputs To An External Archive

Use this only for selected outputs you want to preserve outside the runtime folder. Replace the placeholders with reviewed paths.

### Run on PC-1

```bash
mkdir -p <external-archive-folder>
cp <reviewed-output-image.png> <external-archive-folder>/
```

Good archive locations are outside the repo, for example an external drive, a personal media archive, or another folder under `/home/cuneyt/MoE` intended for archived outputs.

Do not copy generated images into `/home/cuneyt/DiskD/Projects/MoE/codebase`.

## Record Metadata Without Committing Binaries

Record the useful facts in notes, not the binary image file:

- Runtime output directory
- Output filename
- Prompt
- Workflow
- Size
- Steps
- Seed
- File size
- Whether ComfyUI was stopped after generation
- Whether the coding model was restored
- Gateway health after restore
- Git safety result

Use [39-first-image-success-record.md](39-first-image-success-record.md) as the template.

## Verify Coding Mode After Image Generation

After image generation and safe shutdown, coding mode should be restored before normal development continues.

Useful checks:

### Run on PC-1

```bash
make model-health
curl -fsS http://127.0.0.1:8100/gateway/health | jq .
curl -fsS http://127.0.0.1:8100/v1/models | jq .
```

Expected good sign: the model runtime and Gateway respond normally after the coding model restart.

## Verify Git Safety

### Run on PC-1

```bash
git status --short
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

Expected good sign: generated PNGs, model files, and checkpoints do not appear as tracked or staged repo files.

If a generated image appears in Git status, stop and inspect before committing.
