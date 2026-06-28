from pathlib import Path

BASE = Path("~/MoE").expanduser().resolve()

def safe_path(path: str) -> Path:
    p = Path(path).expanduser().resolve()

    if BASE not in p.parents and p != BASE:
        raise PermissionError(f"Blocked path: {p}")

    return p