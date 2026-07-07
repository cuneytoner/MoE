# 59 Git Binary Safety Check

Generated images and model files must not enter Git.

Use an extension-anchored check so normal source filenames containing words like `prompt` do not create false positives.

## Why Generated Images Must Not Enter Git

Generated images are runtime artifacts. They can be large, noisy in reviews, and easy to regenerate or archive outside the repo.

Generated images belong under:

```text
/home/cuneyt/MoE/runtime/media/outputs/images
```

## Why Model Files Must Not Enter Git

Model files and checkpoints are large runtime assets. They must stay outside the source repo.

Model files belong under:

```text
/home/cuneyt/MoE_Models_Backup
```

## Why Broad grep Patterns Can Create False Positives

This broad check is too loose:

```bash
git ls-files | grep -Ei 'png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth' || true
```

It can match normal source filenames that contain these letters. For example, it matches `prompt` because `prompt` contains `pt`.

## Good Extension-Only Check

Use this extension-anchored check instead:

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
git ls-files | grep -Ei '\.(png|jpg|jpeg|webp|safetensors|gguf|ckpt|pt|pth)$' || true
```

Expected good sign: no generated images, model files, or checkpoints are listed as tracked source files.

## If A File Appears

Stop before committing.

Check whether the listed file is:

- A generated image
- A model file
- A checkpoint
- A source file that should be renamed or exempted with human review

Use [37-generated-image-git-safety.md](37-generated-image-git-safety.md) for the broader Git safety workflow.
