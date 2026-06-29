from pathlib import Path
from typing import Any

from app.config import Settings

IGNORED_DIRS = {
    ".git",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    "node_modules",
    "dist",
    "build",
    ".venv",
    "venv",
    "models",
    "runtime",
    "data",
    "checkpoints",
    "custom_nodes",
}

MAX_SNIPPET_CHARS = 240


class WorkspaceService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._root = Path(settings.workspace_root).resolve()
        self._allowed = {
            item.strip()
            for item in settings.workspace_allowed_extensions.split(",")
            if item.strip()
        }

    def status(self) -> dict[str, Any]:
        if not self._settings.workspace_enabled:
            return {
                "status": "ok",
                "workspace_enabled": False,
                "read_only": True,
            }

        return {
            "status": "ok",
            "workspace_enabled": True,
            "workspace_root": str(self._root),
            "read_only": True,
            "max_file_bytes": self._settings.workspace_max_file_bytes,
            "max_tree_items": self._settings.workspace_max_tree_items,
        }

    def tree(self, path: str = ".", max_items: int | None = None) -> dict[str, Any]:
        limit = _positive_limit(max_items, self._settings.workspace_max_tree_items)
        resolved = self._resolve(path)
        if "reason" in resolved:
            return _rejected(path, str(resolved["reason"]))

        root_path = resolved["path"]
        if not root_path.exists():
            return _rejected(path, "Path not found")
        if not root_path.is_dir():
            return _rejected(path, "Path is not a directory")

        items: list[dict[str, Any]] = []
        truncated = False

        for child in self._iter_entries(root_path):
            if len(items) >= limit:
                truncated = True
                break

            relative = _relative_path(self._root, child)
            if child.is_dir():
                items.append({"path": relative, "type": "directory"})
            elif child.is_file() and self._is_allowed_file(child):
                items.append(
                    {
                        "path": relative,
                        "type": "file",
                        "size": child.stat().st_size,
                    }
                )

        return {
            "status": "ok",
            "path": _clean_request_path(path),
            "items": items,
            "truncated": truncated,
        }

    def file(self, path: str) -> dict[str, Any]:
        file_check = self._read_allowed_file(path)
        if "reason" in file_check:
            return _rejected(path, str(file_check["reason"]))

        content = str(file_check["content"])
        resolved = file_check["path"]
        return {
            "status": "ok",
            "path": _relative_path(self._root, resolved),
            "size": int(file_check["size"]),
            "content": content,
        }

    def search(
        self,
        query: str,
        path: str = ".",
        max_results: int = 20,
    ) -> dict[str, Any]:
        query = query.strip()
        if not query:
            return _rejected(path, "Query is required")

        limit = _positive_limit(max_results, 20)
        resolved = self._resolve(path)
        if "reason" in resolved:
            return _rejected(path, str(resolved["reason"]))

        root_path = resolved["path"]
        if not root_path.exists():
            return _rejected(path, "Path not found")
        if root_path.is_file():
            candidates = [root_path]
        else:
            candidates = self._iter_files(root_path)

        results: list[dict[str, Any]] = []
        truncated = False
        query_lower = query.lower()

        for candidate in candidates:
            if self._is_ignored_path(candidate) or not self._is_allowed_file(candidate):
                continue
            file_check = self._read_allowed_file(_relative_path(self._root, candidate))
            if "reason" in file_check:
                continue
            for line_number, line in enumerate(str(file_check["content"]).splitlines(), start=1):
                if query_lower not in line.lower():
                    continue
                if len(results) >= limit:
                    truncated = True
                    break
                results.append(
                    {
                        "path": _relative_path(self._root, candidate),
                        "line": line_number,
                        "snippet": _snippet(line),
                    }
                )
            if truncated:
                break

        return {
            "status": "ok",
            "query": query,
            "results": results,
            "truncated": truncated,
        }

    def context(
        self,
        task: str,
        paths: list[str],
        max_chars: int = 12000,
    ) -> dict[str, Any]:
        limit = _positive_limit(max_chars, 12000)
        remaining = limit
        chunks: list[str] = []
        files: list[dict[str, Any]] = []
        truncated = False

        header = f"Task: {task.strip()}\n\n"
        chunks.append(header[:remaining])
        remaining -= len(chunks[-1])
        if remaining <= 0:
            return {
                "status": "ok",
                "task": task,
                "context": "".join(chunks),
                "files": [],
                "truncated": True,
            }

        for requested_path in paths:
            file_check = self._read_allowed_file(requested_path)
            if "reason" in file_check:
                files.append(
                    {
                        "path": requested_path,
                        "included": False,
                        "reason": file_check["reason"],
                    }
                )
                continue

            resolved = file_check["path"]
            content = str(file_check["content"])
            section = f"--- { _relative_path(self._root, resolved) } ---\n{content}\n\n"
            if len(section) > remaining:
                chunks.append(section[:remaining])
                truncated = True
                files.append(
                    {
                        "path": _relative_path(self._root, resolved),
                        "included": True,
                        "size": int(file_check["size"]),
                        "truncated": True,
                    }
                )
                break

            chunks.append(section)
            remaining -= len(section)
            files.append(
                {
                    "path": _relative_path(self._root, resolved),
                    "included": True,
                    "size": int(file_check["size"]),
                }
            )
            if remaining <= 0:
                truncated = True
                break

        return {
            "status": "ok",
            "task": task,
            "context": "".join(chunks),
            "files": files,
            "truncated": truncated,
        }

    def _read_allowed_file(self, path: str) -> dict[str, Any]:
        resolved = self._resolve(path)
        if "reason" in resolved:
            return resolved

        file_path = resolved["path"]
        if not file_path.exists():
            return {"reason": "Path not found"}
        if not file_path.is_file():
            return {"reason": "Path is not a file"}
        if self._is_ignored_path(file_path):
            return {"reason": "Path is ignored"}
        if not self._is_allowed_file(file_path):
            return {"reason": "File extension is not allowed"}

        size = file_path.stat().st_size
        if size > self._settings.workspace_max_file_bytes:
            return {"reason": "File is too large"}

        data = file_path.read_bytes()
        if b"\x00" in data:
            return {"reason": "Binary files are not allowed"}
        try:
            content = data.decode("utf-8")
        except UnicodeDecodeError:
            return {"reason": "Binary files are not allowed"}

        return {
            "path": file_path,
            "size": size,
            "content": content,
        }

    def _resolve(self, path: str) -> dict[str, Any]:
        if not self._settings.workspace_enabled:
            return {"reason": "Workspace is disabled"}

        requested = _clean_request_path(path)
        if Path(requested).is_absolute():
            return {"reason": "Absolute paths are not allowed"}

        candidate = (self._root / requested).resolve()
        try:
            candidate.relative_to(self._root)
        except ValueError:
            return {"reason": "Path is outside workspace"}

        if _has_ignored_part(candidate, self._root):
            return {"reason": "Path is ignored"}

        return {"path": candidate}

    def _is_ignored_path(self, path: Path) -> bool:
        return _has_ignored_part(path, self._root)

    def _is_allowed_file(self, path: Path) -> bool:
        name = path.name
        return name in self._allowed or path.suffix in self._allowed

    def _iter_entries(self, root_path: Path) -> list[Path]:
        entries: list[Path] = []
        stack = [root_path]

        while stack:
            current = stack.pop()
            try:
                children = sorted(current.iterdir(), key=lambda item: item.name)
            except OSError:
                continue

            for child in children:
                if self._is_ignored_path(child):
                    continue
                entries.append(child)
                if child.is_dir():
                    stack.append(child)

        return sorted(entries, key=lambda item: _relative_path(self._root, item))

    def _iter_files(self, root_path: Path) -> list[Path]:
        return [item for item in self._iter_entries(root_path) if item.is_file()]


def _has_ignored_part(path: Path, root: Path) -> bool:
    try:
        relative = path.relative_to(root)
    except ValueError:
        return True

    for part in relative.parts:
        if part in {".", ""}:
            continue
        if part in IGNORED_DIRS:
            return True
        if part.startswith(".") and part not in {".env.example", ".gitignore", ".dockerignore"}:
            return True
    return False


def _clean_request_path(path: str) -> str:
    cleaned = (path or ".").strip()
    return cleaned if cleaned else "."


def _positive_limit(value: int | None, default: int) -> int:
    if value is None or value < 1:
        return default
    return min(value, default)


def _relative_path(root: Path, path: Path) -> str:
    return path.relative_to(root).as_posix()


def _snippet(line: str) -> str:
    compact = " ".join(line.strip().split())
    return compact[:MAX_SNIPPET_CHARS]


def _rejected(path: str, reason: str) -> dict[str, Any]:
    return {
        "status": "rejected",
        "path": path,
        "reason": reason,
    }
