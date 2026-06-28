from core.agents.base import BaseAgent


class PlannerAgent(BaseAgent):

    def run(self, user_input: str):
        prompt = self.build_prompt(user_input)
        return self.client.chat(prompt, model="qwen35b")