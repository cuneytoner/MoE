# 09 Git Workflow

Small docs changes can be done on `main`. Runtime/app changes should use a feature branch unless the task explicitly says to skip branching.

## Before Every Change

### Run on PC-1

```bash
cd ~/DiskD/Projects/MoE/codebase
git status --short
find . -maxdepth 1 -type f -name '@*' -print
```

Expected good sign: no unexpected files. Do not commit `@*` files.

## Before Every Commit

### Run on PC-1

```bash
git status
git diff --stat
find . -maxdepth 1 -type f -name '@*' -print
```

Expected good signs:

- You recognize every changed file.
- No `@*` pasted-output files are present.
- No model files, runtime files, real `.env` files, or `__pycache__` are staged.

## Commit A Small Docs Change

### Run on PC-1

```bash
git add docs/ops docs/index.md docs/milestones.md docs/codex-prompts.md
git commit -m "Improve M30.0 operator runbooks"
```

Do not commit unless you intentionally want a commit.

## Use A Feature Branch For Runtime/App Work

### Run on PC-1

```bash
git switch -c feat/milestone-name
```

## Wrong Branch Recovery

If you have uncommitted changes on the wrong branch:

### Run on PC-1

```bash
git status --short
git switch -c feat/correct-branch-name
```

If you already committed on the wrong branch, stop and inspect before resetting:

### Run on PC-1

```bash
git branch backup/wrong-branch-safety
git status --short
```

Ask before destructive commands such as reset, checkout of files, or branch deletion.

## Avoid Pasting Output Into Terminal

Read command output first. Copy only the command you intend to run, not the output that the previous command printed.
