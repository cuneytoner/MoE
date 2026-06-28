from abc import ABC, abstractmethod


class BaseAgent(ABC):
    def __init__(self, model_client, prompt_template: str):
        self.client = model_client
        self.prompt_template = prompt_template

    def build_prompt(self, user_input: str) -> str:
        return self.prompt_template.replace("{{input}}", user_input)

    @abstractmethod
    def run(self, user_input: str):
        pass