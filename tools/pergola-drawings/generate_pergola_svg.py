#!/usr/bin/env python3
"""Generate deterministic draft SVG drawings for the pergola project."""

from __future__ import annotations

import argparse
import html
from pathlib import Path


DEFAULT_OUTPUT_DIR = Path("/home/cuneyt/MoE/runtime/pergola/drawings")

WALL_WIDTH_MM = 5100
DEPTH_MM = 1900
ROOF_OVERHANG_MM = 300
POST_SIZE_MM = 100
RAFTER_SPACING_MM = 600

PAGE_WIDTH = 1000
PAGE_HEIGHT = 680
MARGIN = 70


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


def text(x: float, y: float, value: str, size: int = 18, anchor: str = "start") -> str:
    safe_value = html.escape(value)
    return (
        f'<text x="{x:.1f}" y="{y:.1f}" font-family="Arial, sans-serif" '
        f'font-size="{size}" text-anchor="{anchor}" fill="#111">{safe_value}</text>\n'
    )


def save_svg(output_dir: Path, filename: str, content: str) -> Path:
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / filename
    output_path.write_text(content, encoding="utf-8")
    return output_path


def scale_mm(value_mm: float, scale: float) -> float:
    return value_mm * scale


def build_overview_skeleton() -> str:
    total_width_mm = WALL_WIDTH_MM + (ROOF_OVERHANG_MM * 2)
    total_depth_mm = DEPTH_MM + (ROOF_OVERHANG_MM * 2)
    drawing_width = PAGE_WIDTH - (MARGIN * 2)
    drawing_height = PAGE_HEIGHT - 230
    scale = min(drawing_width / total_width_mm, drawing_height / total_depth_mm)

    roof_x = MARGIN
    roof_y = 150
    plan_x = roof_x + scale_mm(ROOF_OVERHANG_MM, scale)
    plan_y = roof_y + scale_mm(ROOF_OVERHANG_MM, scale)
    roof_w = scale_mm(total_width_mm, scale)
    roof_h = scale_mm(total_depth_mm, scale)
    plan_w = scale_mm(WALL_WIDTH_MM, scale)
    plan_h = scale_mm(DEPTH_MM, scale)
    post = scale_mm(POST_SIZE_MM, scale)

    parts = [
        svg_header(PAGE_WIDTH, PAGE_HEIGHT),
        rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, stroke="none", fill="#fff", stroke_width=0),
        text(PAGE_WIDTH / 2, 44, "Pergola SVG Skeleton", size=28, anchor="middle"),
        text(PAGE_WIDTH / 2, 74, "Draft drawing. Verify before build.", size=16, anchor="middle"),
        rect(roof_x, roof_y, roof_w, roof_h, stroke="#666", fill="none", stroke_width=1.5),
        text(roof_x + roof_w + 16, roof_y + 18, "300 mm roof overhang", size=14),
        rect(plan_x, plan_y, plan_w, plan_h, stroke="#111", fill="none", stroke_width=2.5),
        text(plan_x + (plan_w / 2), plan_y - 18, "5100 mm wall line", size=16, anchor="middle"),
        text(plan_x + plan_w + 18, plan_y + (plan_h / 2), "1900 mm depth", size=16),
    ]

    post_positions = [
        (plan_x, plan_y),
        (plan_x + plan_w - post, plan_y),
        (plan_x, plan_y + plan_h - post),
        (plan_x + plan_w - post, plan_y + plan_h - post),
    ]
    for x, y in post_positions:
        parts.append(rect(x, y, post, post, stroke="#111", fill="#ddd", stroke_width=1.5))

    parts.append(text(plan_x, plan_y + plan_h + 32, "100x100 posts", size=15))

    rafter_x = plan_x + scale_mm(RAFTER_SPACING_MM, scale)
    while rafter_x < plan_x + plan_w:
        parts.append(line(rafter_x, plan_y, rafter_x, plan_y + plan_h, stroke="#777", width=1.2))
        rafter_x += scale_mm(RAFTER_SPACING_MM, scale)

    parts.append(text(plan_x + plan_w, plan_y + plan_h + 32, "5x10 rafters placeholder", size=15, anchor="end"))
    parts.append(text(MARGIN, PAGE_HEIGHT - 48, "Output: overview_skeleton.svg", size=14))
    parts.append(text(MARGIN, PAGE_HEIGHT - 24, "Source geometry uses millimeters. Review all dimensions before build.", size=14))
    parts.append(svg_footer())
    return "".join(parts)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate deterministic pergola SVG skeleton drawings.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=DEFAULT_OUTPUT_DIR,
        help=f"Directory for generated SVG files. Default: {DEFAULT_OUTPUT_DIR}",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output_path = save_svg(args.output_dir, "overview_skeleton.svg", build_overview_skeleton())
    print(f"Wrote {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
