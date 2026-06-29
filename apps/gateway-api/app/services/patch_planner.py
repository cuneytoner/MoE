import json
from typing import Any


PATCH_PLAN_SYSTEM_PROMPT = """You are a safe patch planning assistant.
Use the provided read-only repository context.
Do not claim files were edited.
Do not apply patches.
Return a concise JSON object with these keys:
summary: string
affected_files: array of strings
proposed_steps: array of strings
risks: array of strings
tests_to_run: array of strings
"""


DIFF_SUGGEST_SYSTEM_PROMPT = """You are a safe diff suggestion assistant.
Use the provided read-only repository context.
Do not claim files were edited.
Do not apply patches.
If you are confident, output a unified diff suggestion.
If you are not confident, explain why and output no diff.
"""


def patch_plan_system_prompt(context: str) -> str:
    return f"{PATCH_PLAN_SYSTEM_PROMPT}\n\nRepository context:\n{context}"


def diff_suggest_system_prompt(context: str) -> str:
    return f"{DIFF_SUGGEST_SYSTEM_PROMPT}\n\nRepository context:\n{context}"


def parse_patch_plan(content: str, selected_files: list[dict[str, Any]]) -> dict[str, Any]:
    data = _parse_json_object(content)
    fallback_files = [
        str(file["path"])
        for file in selected_files
        if isinstance(file, dict) and file.get("path")
    ]

    return {
        "summary": _string_value(data.get("summary")) or _fallback_summary(content),
        "affected_files": _string_list(data.get("affected_files")) or fallback_files,
        "proposed_steps": _string_list(data.get("proposed_steps"))
        or _fallback_steps(content),
        "risks": _string_list(data.get("risks")) or ["Review the suggested change manually before applying it."],
        "tests_to_run": _string_list(data.get("tests_to_run"))
        or ["make check-python-syntax", "make test"],
    }


def parse_diff_suggestion(content: str) -> dict[str, str]:
    diff = _extract_unified_diff(content)
    if not diff:
        return {
            "diff": "",
            "explanation": content.strip()
            or "The model did not return a unified diff suggestion.",
        }

    explanation = content.replace(diff, "").strip()
    return {
        "diff": diff.strip(),
        "explanation": explanation
        or "Review this unified diff suggestion manually before applying it.",
    }


def _parse_json_object(content: str) -> dict[str, Any]:
    text = content.strip()
    if text.startswith("```"):
        lines = text.splitlines()
        if lines and lines[0].startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].startswith("```"):
            lines = lines[:-1]
        text = "\n".join(lines).strip()

    start = text.find("{")
    end = text.rfind("}")
    if start == -1 or end == -1 or end <= start:
        return {}

    try:
        data = json.loads(text[start : end + 1])
    except json.JSONDecodeError:
        return {}
    return data if isinstance(data, dict) else {}


def _extract_unified_diff(content: str) -> str:
    lines = content.splitlines()
    start = None
    for index, line in enumerate(lines):
        if line.startswith("diff --git ") or line.startswith("--- "):
            start = index
            break

    if start is None:
        return ""

    return "\n".join(lines[start:]).strip()


def _string_value(value: Any) -> str:
    return value.strip() if isinstance(value, str) else ""


def _string_list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item).strip() for item in value if str(item).strip()]


def _fallback_summary(content: str) -> str:
    compact = " ".join(content.strip().split())
    return compact[:500] if compact else "Patch plan suggestion is empty."


def _fallback_steps(content: str) -> list[str]:
    lines = [line.strip("-* 0123456789.") for line in content.splitlines()]
    steps = [line for line in lines if line]
    return steps[:8] or ["Review the selected files and draft the change manually."]
