# MoE Architecture v1

## PC1 (Execution Node)

Hardware:

* RTX 5060 Ti 16GB
* Ryzen 7 7700X3D
* 32GB DDR5

Responsibilities:

* Qwen2.5-Coder
* DeepSeek-Coder
* CogVideo GGUF
* ComfyUI
* llama.cpp server

Services:

* llama-cpp-engine
* media-inference-engine
* redis-worker

---

## PC2 (Brain Node)

Hardware:

* GTX 1650 4GB
* Ryzen 3 3100
* 32GB DDR4

Responsibilities:

* Scheduler
* Night Learning
* Research Processing
* Memory Building
* Routing

Services:

* dashboard-backend
* redis
* memory-worker

---

## Communication

Dashboard → Brain API → Redis Queue → Execution Workers

---

## Memory Pipeline

Night Learning Queue → Research Worker → Chunk Processor → Vector Store → Knowledge Memory

---

## Coding Pipeline

VSCode/Aider → Brain Router → Qwen Worker → Result
