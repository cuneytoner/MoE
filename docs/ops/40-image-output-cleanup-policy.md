# 40 Image Output Cleanup Policy

Generated image outputs are runtime artifacts. They should not be deleted during normal workflow.

The default policy is:

- Keep generated outputs in runtime storage.
- Archive selected outputs when they are important.
- Delete only after backup and explicit review.
- Never clean model files as part of image output cleanup.

## What Not To Do

Do not run broad cleanup commands to solve image output clutter.

Do not use:

```bash
docker volume prune
```

Do not delete or clean:

- `/home/cuneyt/MoE_Models_Backup`
- ComfyUI model folders
- `.safetensors`, `.gguf`, `.ckpt`, `.pt`, or `.pth` files
- Docker volumes unless a separate recovery plan explicitly asks for it

Image output cleanup is not model cleanup.

## Manual Archive Flow

Archive only reviewed outputs. Replace placeholders with real paths after inspection.

### Run on PC-1

```bash
mkdir -p <external-archive-folder>
cp <reviewed-output-image.png> <external-archive-folder>/
```

Then record the archive location in your notes or success record.

Good archive targets are outside the repo, such as:

- An external backup drive
- A dedicated media archive folder outside the codebase
- A reviewed folder under `/home/cuneyt/MoE` intended for archived media

## Manual Delete Flow

Delete only after:

- You inspected the file.
- You confirmed it is backed up if it matters.
- You confirmed the path is under `/home/cuneyt/MoE/runtime/media/outputs/images`.
- You confirmed the path is not a model file or source file.

Use placeholder commands only. Do not copy and paste a delete command until the placeholder is replaced with one reviewed file path.

### Run on PC-1

```bash
# Manual only: replace <reviewed-output-image.png> with one known image output after backup.
# rm <reviewed-output-image.png>
```

Do not use recursive deletes for normal output cleanup.

## Git Safety After Cleanup

Cleanup should not affect Git because generated outputs are outside the repo. Still verify before committing source changes.

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

Expected good sign: Git does not show generated media or model files.
