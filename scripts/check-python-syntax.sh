#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$ROOT" <<'PY'
import ast
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
excluded_dirs = {
    ".git",
    ".venv",
    "venv",
    "node_modules",
    "__pycache__",
}

failed = False

for path in sorted(root.rglob("*.py")):
    if any(part in excluded_dirs for part in path.relative_to(root).parts):
        continue

    try:
        ast.parse(path.read_text(encoding="utf-8"), filename=str(path))
    except SyntaxError as exc:
        print(f"Syntax error: {path.relative_to(root)}:{exc.lineno}:{exc.offset}: {exc.msg}")
        failed = True

if failed:
    sys.exit(1)

print("Python syntax OK")
PY
