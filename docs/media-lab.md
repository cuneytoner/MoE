# Media Lab Roadmap

The media lab is a future expansion of the local AI stack for image, video, 3D, rigging, animation, and workflow orchestration.

It is planning-only for now. Do not implement services, download models, or place generated assets in the codebase during these milestones.

## Boundaries

- Generated media belongs under `/home/cuneyt/MoE/runtime/media`.
- Media model files belong under `/home/cuneyt/MoE_Models_Backup`.
- Source code remains under `/home/cuneyt/DiskD/Projects/MoE/codebase`.
- Runtime logs, job state, temporary files, previews, and exports must stay outside the codebase.

## Milestone 25: Media Lab Foundation

Goal: define the architecture before adding workers.

Planned capabilities:

- Define `media-api` and `media-worker` responsibilities.
- Define runtime output directories under `/home/cuneyt/MoE/runtime/media`.
- Define model path conventions under `/home/cuneyt/MoE_Models_Backup`.
- Define job, status, asset, and provenance concepts.

## Milestone 26: Image Generation Service

Goal: add image generation through ComfyUI or a dedicated image worker.

Planned capabilities:

- Flux-style image generation.
- Queued jobs.
- Job status and asset tracking.
- Runtime-only output storage.

## Milestone 27: Video Generation Service

Goal: add video and image-to-video workflows.

Planned capabilities:

- CogVideoX-style generation.
- Queued jobs.
- Preview and final asset tracking.
- Runtime-only output storage.

## Milestone 28: 3D Model Generation Pipeline

Goal: start with deterministic, inspectable 3D generation.

Planned capabilities:

- Parametric Blender Python generation.
- Export `.blend`, `.glb`, and `.obj`.
- Support technical structures such as pergola before broad creative modeling.

## Milestone 29: Rigging Pipeline

Goal: add basic rig and armature generation.

Planned capabilities:

- Mechanical and object rigs first.
- Character rigs later after the simpler pipeline is stable.
- Store generated rigs and previews under runtime media storage.

## Milestone 30: Animation Pipeline

Goal: turn text requests into Blender animation plans.

Planned capabilities:

- Text-to-keyframe planning.
- Camera and object animation.
- Preview renders.

## Milestone 31: Media Workflow Orchestrator

Goal: chain media jobs across modalities.

Planned capabilities:

- Chain image, video, 3D, rig, and animation jobs.
- Track workflow status.
- Track generated assets and dependencies.
- Keep orchestration state outside the codebase.
