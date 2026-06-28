DANGEROUS_IMPORTS = [
    "os",
    "subprocess",
    "socket",
    "shutil",
    "requests",
    "multiprocessing"
]


def is_safe(code: str) -> tuple[bool, str]:
    """
    Very simple static safety filter
    """

    for bad in DANGEROUS_IMPORTS:
        if f"import {bad}" in code or f"from {bad}" in code:
            return False, f"Blocked dangerous import: {bad}"

    if "__import__" in code:
        return False, "Blocked dynamic import"

    return True, ""