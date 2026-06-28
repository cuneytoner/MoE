# Qdrant

Qdrant runtime storage is bind-mounted from:

`/home/cuneyt/MoE/runtime/qdrant`

Do not place Qdrant collections, snapshots, backups, or generated storage inside this source repository.

The Docker Compose service exposes:

- HTTP: `6333`
- gRPC: `6334`
