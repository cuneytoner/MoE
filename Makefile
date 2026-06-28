.RECIPEPREFIX := >

.PHONY: help check-layout status tree

help:
> @echo "MoE / AI-Brain-OS"
> @echo ""
> @echo "Available commands:"
> @echo "  make check-layout   Validate repository layout"
> @echo "  make status         Show git status"
> @echo "  make tree           Show repository tree"

check-layout:
> @./scripts/check-layout.sh

status:
> @git status --short

tree:
> @tree -a -I '.git' -L 3
