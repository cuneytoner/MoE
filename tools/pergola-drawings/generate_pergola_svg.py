#!/usr/bin/env python3
"""Generate deterministic draft SVG drawings for the pergola project."""

from __future__ import annotations

import argparse
import html
import json
from datetime import datetime, timezone
from pathlib import Path


RUNTIME_ROOT = Path("/home/cuneyt/MoE/runtime")
DEFAULT_OUTPUT_DIR = Path("/home/cuneyt/MoE/runtime/pergola/drawings")

WALL_WIDTH_MM = 5100
DEPTH_MM = 1900
ROOF_OVERHANG_MM = 300
POST_MM = 100
BEAM_WIDTH_MM = 50
BEAM_HEIGHT_MM = 100
REAR_HEIGHT_MM = 3000
FRONT_HEIGHT_MM = 2500
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


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def relative_runtime_path(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(RUNTIME_ROOT.resolve()))
    except (OSError, ValueError):
        return path.name


def drawing_kind_from_filename(filename: str) -> str:
    return Path(filename).stem


def pergola_geometry() -> dict[str, int]:
    return {
        "wall_width_mm": WALL_WIDTH_MM,
        "depth_mm": DEPTH_MM,
        "roof_overhang_mm": ROOF_OVERHANG_MM,
        "post_mm": POST_MM,
        "beam_width_mm": BEAM_WIDTH_MM,
        "beam_height_mm": BEAM_HEIGHT_MM,
    }


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
        "script": "tools/pergola-drawings/generate_pergola_svg.py",
        "project": "pergola-case-study",
        "drawing_kind": drawing_kind_from_filename(svg_path.name),
        "units": "mm",
        "geometry": pergola_geometry(),
        "safety_label": "draft_drawing",
        "notes": "Draft deterministic SVG. Verify dimensions before build.",
    }
    metadata_path.write_text(
        json.dumps(metadata, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return metadata_path


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
    post = scale_mm(POST_MM, scale)

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


def build_side_elevation() -> str:
    total_width_mm = DEPTH_MM + ROOF_OVERHANG_MM
    total_height_mm = REAR_HEIGHT_MM
    drawing_width = PAGE_WIDTH - (MARGIN * 2)
    drawing_height = PAGE_HEIGHT - 190
    scale = min(drawing_width / total_width_mm, drawing_height / total_height_mm)

    ground_y = PAGE_HEIGHT - 110
    rear_x = MARGIN + 80
    front_x = rear_x + scale_mm(DEPTH_MM, scale)
    overhang_x = front_x + scale_mm(ROOF_OVERHANG_MM, scale)
    rear_top_y = ground_y - scale_mm(REAR_HEIGHT_MM, scale)
    front_top_y = ground_y - scale_mm(FRONT_HEIGHT_MM, scale)
    overhang_drop = scale_mm(ROOF_OVERHANG_MM, scale) * (
        (REAR_HEIGHT_MM - FRONT_HEIGHT_MM) / DEPTH_MM
    )
    overhang_y = front_top_y + overhang_drop
    post_w = max(scale_mm(POST_MM, scale), 8)
    rafter_h = max(scale_mm(BEAM_WIDTH_MM, scale), 4)

    parts = [
        svg_header(PAGE_WIDTH, PAGE_HEIGHT),
        rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, stroke="none", fill="#fff", stroke_width=0),
        text(PAGE_WIDTH / 2, 44, "Pergola Side Elevation", size=28, anchor="middle"),
        text(PAGE_WIDTH / 2, 74, "Draft side elevation. Verify dimensions before build.", size=16, anchor="middle"),
        line(rear_x - 36, ground_y, overhang_x + 60, ground_y, stroke="#111", width=2),
        text(rear_x - 36, ground_y + 28, "ground line", size=14),
        line(rear_x, ground_y, rear_x, rear_top_y - 28, stroke="#333", width=3),
        text(rear_x - 12, rear_top_y - 42, "house wall / rear high side", size=14),
        rect(rear_x - (post_w / 2), rear_top_y, post_w, ground_y - rear_top_y, stroke="#111", fill="#ddd", stroke_width=1.5),
        rect(front_x - (post_w / 2), front_top_y, post_w, ground_y - front_top_y, stroke="#111", fill="#ddd", stroke_width=1.5),
        line(rear_x, rear_top_y, overhang_x, overhang_y, stroke="#111", width=4),
        line(rear_x, rear_top_y + rafter_h, overhang_x, overhang_y + rafter_h, stroke="#777", width=1.5),
        text((rear_x + front_x) / 2, ground_y + 52, "1900 mm depth", size=16, anchor="middle"),
        line(rear_x, ground_y + 34, front_x, ground_y + 34, stroke="#555", width=1.2),
        text((front_x + overhang_x) / 2, overhang_y - 22, "300 mm front roof overhang", size=14, anchor="middle"),
        line(front_x, overhang_y - 10, overhang_x, overhang_y - 10, stroke="#555", width=1.2),
        text(front_x + 18, (front_top_y + ground_y) / 2, "10x10 post", size=15),
        text((rear_x + overhang_x) / 2, rear_top_y - 10, "5x10 rafter placeholder", size=15, anchor="middle"),
        text(MARGIN, PAGE_HEIGHT - 34, "Draft side elevation. Verify dimensions before build.", size=14),
        svg_footer(),
    ]
    return "".join(parts)


def build_top_plan() -> str:
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
    post = scale_mm(POST_MM, scale)
    canopy_w = scale_mm(700, scale)
    canopy_h = scale_mm(700, scale)

    parts = [
        svg_header(PAGE_WIDTH, PAGE_HEIGHT),
        rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, stroke="none", fill="#fff", stroke_width=0),
        text(PAGE_WIDTH / 2, 44, "Pergola Top Plan", size=28, anchor="middle"),
        text(PAGE_WIDTH / 2, 74, "Draft top plan. Verify post placement before build.", size=16, anchor="middle"),
        rect(roof_x, roof_y, roof_w, roof_h, stroke="#666", fill="none", stroke_width=1.5),
        rect(plan_x, plan_y, plan_w, plan_h, stroke="#111", fill="none", stroke_width=2.5),
        text(plan_x + (plan_w / 2), plan_y - 18, "5100 mm wall line", size=16, anchor="middle"),
        text(plan_x + plan_w + 18, plan_y + (plan_h / 2), "1900 mm depth", size=16),
        text(roof_x + roof_w + 16, roof_y + 18, "300 mm roof overhang", size=14),
    ]

    post_positions = [
        (plan_x, plan_y),
        (plan_x + plan_w - post, plan_y),
        (plan_x, plan_y + plan_h - post),
        (plan_x + plan_w - post, plan_y + plan_h - post),
    ]
    for x, y in post_positions:
        parts.append(rect(x, y, post, post, stroke="#111", fill="#ddd", stroke_width=1.5))

    rafter_x = plan_x + scale_mm(RAFTER_SPACING_MM, scale)
    while rafter_x < plan_x + plan_w:
        parts.append(line(rafter_x, plan_y, rafter_x, plan_y + plan_h, stroke="#777", width=1.2))
        rafter_x += scale_mm(RAFTER_SPACING_MM, scale)

    canopy_x = plan_x + plan_w - canopy_w
    canopy_y = plan_y + plan_h + scale_mm(120, scale)
    parts.extend(
        [
            rect(canopy_x, canopy_y, canopy_w, canopy_h, stroke="#444", fill="none", stroke_width=1.5),
            text(canopy_x + (canopy_w / 2), canopy_y + canopy_h + 24, "right-side door canopy placeholder", size=14, anchor="middle"),
            text(plan_x, plan_y + plan_h + 34, "100x100 posts", size=15),
            text(plan_x + plan_w, plan_y + plan_h + 34, "5x10 rafters placeholder", size=15, anchor="end"),
            text(MARGIN, PAGE_HEIGHT - 34, "Draft top plan. Verify post placement before build.", size=14),
            svg_footer(),
        ]
    )
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
    generated = [
        ("overview_skeleton.svg", build_overview_skeleton()),
        ("side_elevation.svg", build_side_elevation()),
        ("top_plan.svg", build_top_plan()),
    ]
    output_pairs = []
    for filename, content in generated:
        svg_path = save_svg(args.output_dir, filename, content)
        metadata_path = write_json_metadata(svg_path)
        output_pairs.append((svg_path, metadata_path))

    print("Generated:")
    for svg_path, metadata_path in output_pairs:
        print(f"- {svg_path.name} -> {svg_path}")
        print(f"- {metadata_path.name} -> {metadata_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
