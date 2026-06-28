from core.execution.fs_guard import safe_path

def write_file(file_path: str, content: str):
    path = safe_path(file_path)

    path.parent.mkdir(parents=True, exist_ok=True)

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)

    return {
        "status": "success",
        "file": str(path)
    }
