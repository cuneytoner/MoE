from core.memory.memory_store import MemoryStore


class OfflineTrainer:
    """
    PC2 NIGHT TRAINING LOOP
    """

    def __init__(self):
        self.memory = MemoryStore()

    def run(self):
        data = self.memory.get_recent(1000)

        stats = {}

        for prompt, intent, model, conf, reward in data:

            if model not in stats:
                stats[model] = {"reward": 0, "count": 0}

            stats[model]["reward"] += reward
            stats[model]["count"] += 1

        for model in stats:
            avg = stats[model]["reward"] / stats[model]["count"]

            print(f"[TRAIN] {model} avg reward: {avg:.3f}")

        return stats