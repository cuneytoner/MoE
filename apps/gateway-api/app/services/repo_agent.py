from typing import Any

from app.config import Settings
from app.services.workspace import WorkspaceService


class RepoAgentService:
    def __init__(self, settings: Settings) -> None:
        self._workspace = WorkspaceService(settings)

    def build_context(
        self,
        task: str,
        query: str | None,
        paths: list[str],
        max_files: int,
        max_chars: int,
    ) -> dict[str, Any]:
        selected = self._select_files(
            query=query,
            paths=paths,
            max_files=max_files,
        )
        context = self._workspace.context(
            task=task,
            paths=[file["path"] for file in selected],
            max_chars=max_chars,
        )
        included_files = {
            file["path"]: file
            for file in context.get("files", [])
            if isinstance(file, dict) and file.get("included") is True
        }
        selected_files = [
            {
                "path": path,
                "reason": file["reason"],
            }
            for path, file in ((file["path"], file) for file in selected)
            if path in included_files
        ]

        return {
            "status": "ok",
            "task": task,
            "query": query,
            "selected_files": selected_files,
            "context": context.get("context", ""),
            "truncated": bool(context.get("truncated")),
        }

    def _select_files(
        self,
        query: str | None,
        paths: list[str],
        max_files: int,
    ) -> list[dict[str, str]]:
        selected: list[dict[str, str]] = []
        seen: set[str] = set()

        for path in paths:
            self._add_selected(
                selected=selected,
                seen=seen,
                path=path,
                reason="Explicitly requested path",
                max_files=max_files,
            )

        if query and len(selected) < max_files:
            search = self._workspace.search(
                query=query,
                path=".",
                max_results=max(max_files * 4, max_files),
            )
            for result in search.get("results", []):
                if not isinstance(result, dict):
                    continue
                path = result.get("path")
                line = result.get("line")
                if not isinstance(path, str):
                    continue
                reason = (
                    f"Matched query '{query}'"
                    if not isinstance(line, int)
                    else f"Matched query '{query}' at line {line}"
                )
                self._add_selected(
                    selected=selected,
                    seen=seen,
                    path=path,
                    reason=reason,
                    max_files=max_files,
                )
                if len(selected) >= max_files:
                    break

        return selected

    def _add_selected(
        self,
        selected: list[dict[str, str]],
        seen: set[str],
        path: str,
        reason: str,
        max_files: int,
    ) -> None:
        if len(selected) >= max_files:
            return
        clean_path = path.strip()
        if not clean_path or clean_path in seen:
            return
        seen.add(clean_path)
        selected.append({"path": clean_path, "reason": reason})
