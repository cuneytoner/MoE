# System Architecture Specification

## 1. Physical Node Topography
- **PC-1 (Master Core Orchestrator)**: Pop!_OS | Ryzen 7 7700X3D | 32GB System RAM | RTX 5060Ti (16GB VRAM). Hosts primary high-reasoning heavy inference engines (Llama 3.3 70B, Flux.1, CogVideoX).
- **PC-2 (Autonomous Worker Node)**: Ubuntu 24.04 LTS | Ryzen 3 3100 | 32GB System RAM | GTX 1650 (4GB VRAM). Handles autonomous background pipelines, asynchronous web scrapers, and local vector indexing.

## 2. Network Topology
- Isolated 1Gbit Ethernet physical cross-connect.
- Master node resolves target tasks to workers via keyless SSH handshakes.
- System communication parameters are entirely parsed from the root configuration profile (`.env`).
