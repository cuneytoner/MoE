import subprocess
import tempfile
import os


class TestRunner:
    """
    Executes generated code safely (sandbox-style basic execution)
    """

    def run(self, code: str) -> dict:
        with tempfile.NamedTemporaryFile(suffix=".py", delete=False) as f:
            f.write(code.encode())
            path = f.name

        try:
            result = subprocess.run(
                ["python3", path],
                capture_output=True,
                text=True,
                timeout=5
            )

            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr
            }

        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "stdout": "",
                "stderr": "TIMEOUT"
            }

        finally:
            os.remove(path)