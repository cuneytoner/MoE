#!/usr/bin/env python3
"""Create the minimal runtime-only Blender scene for M36.17 acceptance."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def _argv_after_blender_separator(argv: list[str] | None = None) -> list[str]:
    values = list(sys.argv[1:] if argv is None else argv)
    if "--" in values:
        return values[values.index("--") + 1 :]
    return values


def _look_at(camera: object, target_location: object) -> None:
    from mathutils import Vector  # type: ignore[import-not-found]

    direction = Vector(target_location) - camera.location
    camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Create the M36.17 acceptance scene inside Blender.")
    parser.add_argument("--output-blend", required=True, help="Runtime .blend output path.")
    return parser


def main(argv: list[str] | None = None) -> int:
    import bpy  # type: ignore[import-not-found]

    args = build_parser().parse_args(_argv_after_blender_separator(argv))
    output_blend = Path(args.output_blend)
    if not output_blend.is_absolute():
        raise SystemExit("output blend path must be absolute")
    if output_blend.suffix.lower() != ".blend":
        raise SystemExit("output blend path must use .blend")
    if "DiskD/Projects/MoE/codebase" in output_blend.as_posix():
        raise SystemExit("output blend path must not be inside the source repo")

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.frame_start = 1
    scene.frame_end = 120
    scene.render.fps = 24

    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0.0, 0.0, 0.0))
    demo_object = bpy.context.object
    demo_object.name = "demo-object"
    demo_object.data.name = "demo-object-mesh"

    bpy.ops.object.light_add(type="AREA", location=(0.0, -3.0, 4.0))
    light = bpy.context.object
    light.name = "light"
    light.data.energy = 450
    light.data.size = 4.0

    bpy.ops.object.camera_add(location=(3.5, -6.0, 3.0))
    camera = bpy.context.object
    camera.name = "camera"
    camera.data.name = "camera"
    camera.data.lens = 35.0
    _look_at(camera, demo_object.location)
    scene.camera = camera

    output_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output_blend))

    print(f"M36_ACCEPTANCE_SCENE: {output_blend}")
    print("M36_ACCEPTANCE_OBJECT: demo-object")
    print("M36_ACCEPTANCE_CAMERA: camera")
    print("M36_ACCEPTANCE_ENGINE: BLENDER_EEVEE_NEXT")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
