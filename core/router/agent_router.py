class AgentRouter:
    """
    FAZ 2.5.9 — decides ROLE, not just model
    """

    def route(self, prompt: str):

        p = prompt.lower()

        # PLANNING
        if any(x in p for x in ["design", "architecture", "plan"]):
            return {
                "agent": "planner",
                "intent": "architecture"
            }

        # CODE EXECUTION
        if any(x in p for x in ["implement", "code", "class", "function"]):
            return {
                "agent": "executor",
                "intent": "code"
            }

        # REVIEW
        if any(x in p for x in ["review", "fix", "bug", "analyze"]):
            return {
                "agent": "reviewer",
                "intent": "review"
            }

        # DEFAULT → executor safe mode
        return {
            "agent": "executor",
            "intent": "general"
        }