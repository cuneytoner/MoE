from core.router.agent_router import AgentRouter
from core.agents.executor import ExecutorAgent
from core.agents.planner import PlannerAgent
from core.agents.reviewer import ReviewerAgent

router = AgentRouter()

def handle(prompt, client):
    decision = router.route(prompt)

    if decision["agent"] == "planner":
        agent = PlannerAgent(client, open("core/prompts/planner.md").read())

    elif decision["agent"] == "executor":
        agent = ExecutorAgent(client, open("core/prompts/executor.md").read())

    else:
        agent = ReviewerAgent(client, open("core/prompts/reviewer.md").read())

    return agent.run(prompt)