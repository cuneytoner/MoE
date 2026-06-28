from core.agents.base import BaseAgent


class ReviewerAgent(BaseAgent):

    def run(self, user_input: str):
        prompt = self.build_prompt(user_input)
        return self.client.chat(prompt, model="deepseek")