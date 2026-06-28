import math


class RewardEngine:
    """
    Converts weak signals into reward score.
    This is NOT full RLHF, but lightweight reinforcement proxy.
    """

    def score(self, prompt: str, response: str, confidence: float):
        """
        Heuristic reward function.
        Later: replace with model-based evaluator.
        """

        length = len(response.split())

        # too short → low quality
        length_score = min(length / 50, 1.0)

        # confidence alignment
        confidence_score = confidence

        # basic heuristic: penalize empty or trivial outputs
        trivial_penalty = 0.2 if len(response) < 20 else 0.0

        reward = (
            0.5 * confidence_score +
            0.4 * length_score -
            trivial_penalty
        )

        return max(0.0, min(1.0, reward))