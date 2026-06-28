import json


class PCSync:
    """
    Simulated sync between PC1 (runtime) and PC2 (training)
    """

    def export_state(self, memory_store):
        return json.dumps(memory_store.get_recent(500))

    def import_weights(self, router, weights):
        router.model_weights.update(weights)