import requests

class LLMClient:
    def __init__(self, base_url="http://localhost:8000/v1"):
        self.base_url = base_url

    def chat(self, prompt, model="qwen"):
        url = f"{self.base_url}/chat/completions"

        payload = {
            "model": model,
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.7,
            "stream": False
        }

        response = requests.post(url, json=payload, timeout=600)
        response.raise_for_status()

        data = response.json()
        return data["choices"][0]["message"]["content"]