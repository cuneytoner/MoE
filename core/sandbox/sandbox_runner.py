import subprocess
import tempfile
import os

from core.sandbox.resource_limits import ResourceLimits
from core.sandbox.safety_policy import is_safe


class SandboxRunner:
    """
    Isolated execution environment
    """

    def run(self, code: str) -> dict:

        # 1. safety check
        safe, reason = is_safe(code)
        if not safe:
            return {
                "status": "BLOCKED",
                "reason": reason
            }

        # 2. write temp file
        with tempfile.NamedTemporaryFile(suffix=".py", delete=False) as f:
            f.write(code.encode())
            path = f.name

        try:
            # 3. run isolated process
            result = subprocess.run(
                ["python3", path],
                capture_output=True,
                text=True,
                timeout=3,
                preexec_fn=ResourceLimits().apply
            )

            return {
                "status": "EXECUTED",
                "returncode": result.returncode,
                "stdout": result.stdout,
                "stderr": result.stderr
            }

        except subprocess.TimeoutExpired:
            return {
                "status": "TIMEOUT",
                "stdout": "",
                "stderr": "Execution timeout"
            }

        finally:
            os.remove(path)