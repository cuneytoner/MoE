from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class ToolPlan:
    recommended_tools: list[str]
    requires_runtime: bool
    requires_memory: bool
    safe_to_auto_run: bool
    reason: str

    def as_dict(self) -> dict[str, Any]:
        return {
            "recommended_tools": self.recommended_tools,
            "requires_runtime": self.requires_runtime,
            "requires_memory": self.requires_memory,
            "safe_to_auto_run": self.safe_to_auto_run,
            "reason": self.reason,
        }


TOOL_CATALOG: dict[str, dict[str, Any]] = {
    "gateway_health_check": {
        "description": "Read Gateway dependency health using internal HTTP clients.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "memory_health_check": {
        "description": "Read Memory API /health status.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "memory_deep_health_check": {
        "description": "Read Memory API /health/deep status.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "embed_worker_health_check": {
        "description": "Read Embed Worker /health status.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "runtime_status_check": {
        "description": "Read model runtime status without switching models.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "runtime_profile_preflight": {
        "description": "Read Gateway runtime profile readiness without switching models.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "runtime_profile_run_catalog": {
        "description": "Read documentation-only runtime profile run settings.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "runtime_profile_compatibility_matrix": {
        "description": "Read advisory runtime profile compatibility matrix.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "runtime_profile_recommendation_summary": {
        "description": "Read advisory runtime profile recommendation summary.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "runtime_profile_dashboard_summary": {
        "description": "Read compact runtime profile dashboard summary.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "model_routing_read": {
        "description": "Read Gateway advisory model routing config.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "tools_read": {
        "description": "Read Gateway tool registry.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "workspace_status": {
        "description": "Read workspace provider status.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "workspace_tree": {
        "description": "Read a safe workspace file tree.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "workspace_file_read": {
        "description": "Read one allowed text file from the workspace.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "workspace_search": {
        "description": "Search allowed text files in the workspace.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "workspace_context": {
        "description": "Build a compact context bundle from selected workspace files.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "code_context": {
        "description": "Build read-only repo-aware coding context from selected workspace files.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
    },
    "code_ask": {
        "description": "Ask the repo-aware coding assistant using read-only workspace context.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
        "requires_runtime": True,
    },
    "code_patch_plan": {
        "description": "Generate a human-reviewable patch plan without applying changes.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
        "requires_runtime": True,
        "apply_supported": False,
    },
    "code_diff_suggest": {
        "description": "Generate a unified diff suggestion without applying changes.",
        "auto_execution_supported": False,
        "executable": True,
        "read_only": True,
        "requires_runtime": True,
        "apply_supported": False,
    },
    "model_chat": {
        "description": "Send a chat completion request to the OpenAI-compatible model runtime.",
        "auto_execution_supported": False,
        "executable": False,
        "read_only": False,
    },
    "memory_search": {
        "description": "Search local Memory API for relevant stored context.",
        "auto_execution_supported": False,
        "executable": False,
        "read_only": False,
    },
    "runtime_switch_plan": {
        "description": "Return an advisory manual runtime switch plan without executing it.",
        "auto_execution_supported": False,
        "executable": False,
        "read_only": False,
    },
    "docker_status_check": {
        "description": "Suggest Docker status checks for the user to run manually.",
        "auto_execution_supported": False,
        "executable": False,
        "read_only": False,
    },
    "shell_command_suggestion": {
        "description": "Suggest shell commands for the user to inspect before running.",
        "auto_execution_supported": False,
        "executable": False,
        "read_only": False,
    },
    "none": {
        "description": "No tool is recommended.",
        "auto_execution_supported": False,
        "executable": False,
        "read_only": False,
    },
}


TOOL_PLANS: dict[str, ToolPlan] = {
    "chat": ToolPlan(
        recommended_tools=["model_chat"],
        requires_runtime=True,
        requires_memory=False,
        safe_to_auto_run=True,
        reason="General chat can use the model runtime directly.",
    ),
    "code": ToolPlan(
        recommended_tools=["code_context", "code_ask", "code_patch_plan"],
        requires_runtime=True,
        requires_memory=False,
        safe_to_auto_run=True,
        reason="Coding requests should build read-only repo context before model chat.",
    ),
    "memory": ToolPlan(
        recommended_tools=["memory_search", "model_chat"],
        requires_runtime=True,
        requires_memory=True,
        safe_to_auto_run=True,
        reason="Memory requests should search local memory before model chat.",
    ),
    "review": ToolPlan(
        recommended_tools=[
            "code_context",
            "runtime_switch_plan",
            "code_patch_plan",
            "code_diff_suggest",
        ],
        requires_runtime=True,
        requires_memory=False,
        safe_to_auto_run=False,
        reason="A heavier model may be recommended, but runtime switching remains manual.",
    ),
    "ops": ToolPlan(
        recommended_tools=[
            "docker_status_check",
            "shell_command_suggestion",
            "model_chat",
        ],
        requires_runtime=True,
        requires_memory=False,
        safe_to_auto_run=False,
        reason="Shell and Docker actions are advisory only and are not executed by Gateway.",
    ),
}


def plan_tools(intent: str) -> ToolPlan:
    return TOOL_PLANS.get(intent, TOOL_PLANS["chat"])


def tool_catalog() -> dict[str, dict[str, Any]]:
    return {name: details.copy() for name, details in TOOL_CATALOG.items()}
