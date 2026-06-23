from config import REMOTE_NODE

NODE_REGISTRY = {
    "pc1": {
        "role": "execution",
        "gpu": "RTX 5060 Ti",
        "local": True
    },
    "pc2": {
        "role": "brain",
        "gpu": "GTX 1650",
        "local": False,
        "user": REMOTE_NODE["user"],
        "ip": REMOTE_NODE["ip"]
    }
}
