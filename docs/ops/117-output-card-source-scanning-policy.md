# Output Card Source Scanning Policy

## Purpose

This policy defines where a future output card API may look for files. The goal is safe, read-only review of known media and drawing outputs.

## Allowlisted Runtime Folders

- `/home/cuneyt/MoE/runtime/media/outputs/images`
- `/home/cuneyt/MoE/runtime/pergola/drawings`
- `/home/cuneyt/MoE/runtime/drawings`

Future implementation must scan only these allowlisted runtime folders unless a later milestone explicitly expands the list.

M34.5 implements allowlisted scanning for images and SVG drawings.

Gateway scans allowlisted runtime folders only after those folders are mounted read-only into the container.

## Supported Extensions

- `.png`
- `.jpg`
- `.jpeg`
- `.webp`
- `.svg`
- `.pdf` later

Sidecar `.json` files are allowed only when matched to supported media/drawing assets.

## Explicit Deny

- no model files
- no `.gguf`
- no `.safetensors`
- no `.pt`
- no `.pth`
- no hidden folders
- no arbitrary user-provided paths
- no recursive scan outside allowlist
- no delete
- no move
- no rename

## Result Boundaries

The future scanner should limit result count, sort newest first, and report metadata only. It should not open files for arbitrary content inspection except for safe preview behavior planned in a later milestone.
