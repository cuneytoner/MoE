#!/usr/bin/env python3
"""Generate a deterministic demo SVG for the generic drawing engine."""

from __future__ import annotations

import argparse
import html
import json
from datetime import datetime, timezone
from pathlib import Path


PAGE_WIDTH = 1000
PAGE_HEIGHT = 700
RUNTIME_ROOT = Path("/home/cuneyt/MoE/runtime")
DEFAULT_OUTPUT_DIR = "/home/cuneyt/MoE/runtime/drawings/demo"


def svg_header(width: int, height: int) -> str:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{width}" height="{height}" viewBox="0 0 {width} {height}">\n'
    )


def svg_footer() -> str:
    return "</svg>\n"


def line(x1: float, y1: float, x2: float, y2: float, stroke: str = "#111", width: float = 2) -> str:
    return (
        f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" '
        f'stroke="{stroke}" stroke-width="{width}" />\n'
    )


def rect(
    x: float,
    y: float,
    width: float,
    height: float,
    stroke: str = "#111",
    fill: str = "none",
    stroke_width: float = 2,
) -> str:
    return (
        f'<rect x="{x:.1f}" y="{y:.1f}" width="{width:.1f}" height="{height:.1f}" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}" />\n'
    )


def circle(
    cx: float,
    cy: float,
    radius: float,
    stroke: str = "#111",
    fill: str = "none",
    stroke_width: float = 2,
) -> str:
    return (
        f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{radius:.1f}" '
        f'fill="{fill}" stroke="{stroke}" stroke-width="{stroke_width}" />\n'
    )


def text(x: float, y: float, value: str, size: int = 18, anchor: str = "start") -> str:
    safe_value = html.escape(value)
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" font-family="Arial, sans-serif" '
        f'font-size="{size}" text-anchor="{anchor}" fill="#111">{safe_value}</text>\n'
    )


def polyline(points: list[tuple[float, float]], stroke: str = "#111", width: float = 2, fill: str = "none") -> str:
    point_text = " ".join(f"{x:.1f},{y:.1f}" for x, y in points)
    return (
        f'<polyline points="{point_text}" fill="{fill}" '
        f'stroke="{stroke}" stroke-width="{width}" />\n'
    )


def save_svg(output_dir: Path, filename: str, content: str) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / filename
    output_path.write_text(content, encoding="utf-8")
    return output_path


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def relative_runtime_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(RUNTIME_ROOT.resolve()))
    except (OSError, ValueError):
        return path.name


def drawing_kind_from_filename(filename: str) -> str:
    return Path(filename).stem


def write_json_metadata(svg_path: Path) -> Path:
    metadata_path = svg_path.with_suffix(".json")
    metadata = {
        "schema_version": "1.0",
        "asset_type": "drawing_svg",
        "asset_name": svg_path.name,
        "asset_path": str(svg_path),
        "relative_runtime_path": relative_runtime_path(svg_path),
        "created_at": utc_now_iso(),
        "source": "deterministic-svg",
        "script": "tools/drawing-engine/generate_demo_svg.py",
        "project": "generic-drawing-engine-demo",
        "drawing_kind": drawing_kind_from_filename(svg_path.name),
        "units": "px",
        "geometry": {
            "page_width": PAGE_WIDTH,
            "page_height": PAGE_HEIGHT,
        },
        "safety_label": "draft_drawing",
        "notes": "Demo deterministic SVG. Not a construction document.",
    }
    metadata_path.write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return metadata_path


def build_demo_svg() -> str:
    parts = [
        svg_header(PAGE_WIDTH, PAGE_HEIGHT),
        rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, stroke="none", fill="#fff", stroke_width=0),
        text(PAGE_WIDTH / 2, 54, "Generic Drawing Engine Demo", size=30, anchor="middle"),
        text(PAGE_WIDTH / 2, 84, "Simple deterministic SVG primitives", size=16, anchor="middle"),
        line(90, 160, 430, 160, stroke="#111", width=3),
        text(90, 140, "line primitive", size=16),
        rect(90, 220, 260, 130, stroke="#1f4f82", fill="#eef6ff", stroke_width=3),
        text(220, 292, "rectangle", size=18, anchor="middle"),
        circle(560, 285, 65, stroke="#7a3f00", fill="#fff4df", stroke_width=3),
        text(560, 292, "circle", size=18, anchor="middle"),
        line(90, 430, 430, 430, stroke="#555", width=1.5),
        polyline([(105, 420), (90, 430), (105, 440)], stroke="#555", width=1.5),
        polyline([(415, 420), (430, 430), (415, 440)], stroke="#555", width=1.5),
        text(260, 414, "arrow / dimension line placeholder", size=15, anchor="middle"),
        text(90, 500, "text label primitive", size=20),
        rect(610, 500, 320, 90, stroke="#111", fill="none", stroke_width=1.5),
        line(610, 530, 930, 530, stroke="#111", width=1),
        line(745, 500, 745, 590, stroke="#111", width=1),
        text(625, 522, "Title block", size=15),
        text(760, 522, "Demo sheet", size=15),
        text(625, 560, "Scale: none", size=14),
        text(760, 560, "Status: demo only", size=14),
        text(PAGE_WIDTH / 2, 660, "Demo SVG. Not a construction document.", size=16, anchor="middle"),
        svg_footer(),
    ]
    return "".join(parts)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate a generic drawing engine demo SVG.")
    parser.add_argument(
        "--output-dir",
        default=DEFAULT_OUTPUT_DIR,
        help=f"Output directory. Defaults to {DEFAULT_OUTPUT_DIR}",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output_path = save_svg(Path(args.output_dir), "demo_sheet.svg", build_demo_svg())
    metadata_path = write_json_metadata(output_path)
    print("Generated:")
    print(f"- {output_path.name} -> {output_path}")
    print(f"- {metadata_path.name} -> {metadata_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
