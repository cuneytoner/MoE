import ast


class Verifier:
    """
    Static code verification layer
    """

    def check_syntax(self, code: str) -> dict:
        try:
            ast.parse(code)
            return {"syntax_ok": True, "error": None}
        except Exception as e:
            return {"syntax_ok": False, "error": str(e)}

    def check_imports(self, code: str) -> dict:
        errors = []

        for line in code.split("\n"):
            if line.strip().startswith("import ") or line.strip().startswith("from "):
                if " " not in line:
                    errors.append(f"Malformed import: {line}")

        return {
            "import_ok": len(errors) == 0,
            "errors": errors
        }

    def verify(self, code: str) -> dict:
        syntax = self.check_syntax(code)
        imports = self.check_imports(code)

        return {
            "valid": syntax["syntax_ok"] and imports["import_ok"],
            "syntax": syntax,
            "imports": imports
        }