🌙 1. YENİ MODÜL: NIGHT LEARNER NODE
🧠 PC-2 (GTX 1650) → GECE ÖĞRENME MAKİNESİ

Yeni servis:

pc2-brain/
 ├── night_learner/
 │    ├── runner.py
 │    ├── syllabus_loader.py
 │    ├── summarizer.py
 │    ├── embedder.py
 │    └── memory_writer.py
📚 2. SENİN “CONTEXT LIST” MODELİ

Sen liste veriyorsun:

1. Docker networking basics
2. Redis queue patterns
3. ComfyUI workflow structure
4. GGUF quantization concept
5. MoE routing strategies

Bu liste:

👉 “gece curriculum” oluyor

🔄 3. GECE AKIŞI (AUTONOMOUS LEARNING LOOP)
23:00 → scheduler trigger
        ↓
load context list
        ↓
select item #1
        ↓
LLM (CPU Qwen 7B / small model)
        ↓
"teach + summarize"
        ↓
embedding 생성
        ↓
Qdrant memory store
        ↓
next topic
🧠 4. ÖĞRENME MEKANİZMASI (KRİTİK)

Bu sistem 3 şey üretir:

1. Knowledge Summary
{
  "topic": "Redis queue patterns",
  "summary": "Redis list + stream based job queue design...",
  "key_points": ["BRPOP", "retry pattern", "dead letter queue"]
}
2. Embedding Memory
Qdrant’a kaydedilir
semantic search için
3. “Engineering Notes”
If system grows:
- split queues per task type
- isolate GPU workers
- avoid blocking BRPOP loops
🧠 5. MOE İÇİN ENTEGRASYON

PC-2 artık sadece router değil:

PC-2 Brain:

- routing
- planning
- memory
- NIGHT LEARNING
🔗 6. MEMORY NASIL KULLANILACAK?
Yeni endpoint:
GET /memory/search?q=redis queue

veya:

{
  "context": "video worker design",
  "enhance_prompt": true
}
🧠 7. MOE PLANNER GELİŞİMİ

Planner artık şunu yapar:

“Bu task daha önce öğrenilmiş mi?”

if memory.exists("comfyui workflow"):
    use_memory_context()
else:
    route_to_llm()
🌙 8. NIGHT LEARNER SCHEDULER

CRON:

0 23 * * * python runner.py

veya systemd service:

night-learner.service
⚙️ 9. MODEL STRATEJİSİ (PC-2)

GTX 1650 için:

Qwen 7B Instruct (GGUF Q4)
Tiny DeepSeek variant
CPU fallback llama.cpp

👉 amaç: hız değil, bilgi üretimi

🧠 10. ASIL GÜÇLÜ KISIM (BURASI ÖNEMLİ)

Bu sistem sana şunu verir:

🔥 “SELF-EVOLVING DEV ENVIRONMENT”

Yani:

sen bir şey öğretiyorsun
sistem gece sindiriyor
sabah coding assistant daha iyi oluyor
📦 11. MEMORY STRUCTURE (QDRANT)
collection: moe_knowledge

payload:
- topic
- summary
- tags
- timestamp
- source: night_learning
🚀 12. SENİN MOE ARTIK 3 PARÇALI
1. REALTIME BRAIN (PC-2)
   - routing
   - coding assistant

2. GPU FACTORY (PC-1)
   - Qwen / CogVideo / inference

3. NIGHT LEARNER (PC-2 CPU)
   - knowledge accumulation
   - memory building
💡 GERÇEK FAYDA

Bu sistem sana şunu sağlar:

StackOverflow dependency azalır
kod pattern memory oluşur
MoE kendi “dev experience” kazanır
uzun vadede daha az prompt engineering gerekir
🧭 İstersen sonraki adım

Sana direkt çıkarabilirim:

🔧 1. night_learner/runner.py (production code)
🧠 2. Qdrant memory schema
⚙️ 3. PC-2 full FastAPI (memory + routing + learning)
🔁 4. docker-compose update
💻 5. VSCode extension “memory-aware autocomplete”

İstersen bunu bir üst seviyeye de çıkarabiliriz:

“Gece öğrendiği şeyleri sabah coding sırasında otomatik öneren sistem”

O zaman MoE artık bir tool değil, kendini geliştiren coding OS olur.

şimdi bu konuştuklarımızı bana bir proje planı md olarak ver. sonra repoyu inceleyip adım adım ilerleyelim

Aşağıda konuştuğumuz sistemi MoE Offline AI Coding Grid + Night Learning + GPU/CPU dağıtık inference olarak tek bir proje planı (README/PROJECT_PLAN.md formatında) haline getirdim.

# 🧠 MoE Offline AI Coding Grid

> Distributed offline AI system for coding, reasoning and continuous learning  
> PC-1 (GPU) + PC-2 (CPU Brain) + Night Learning Memory System  
> No API tokens, fully local inference

---

# 🎯 1. GOAL

Build a **self-hosted AI coding environment** that:

- Runs fully offline
- Uses distributed inference (GPU + CPU split)
- Supports coding assistant workflows (VSCode / Aider)
- Maintains persistent memory (Qdrant + PostgreSQL)
- Improves itself via nightly learning cycles
- Routes tasks intelligently (MoE router)

---

# 🖥 2. SYSTEM ARCHITECTURE

## 🔵 PC-1 (GPU NODE - 5060 Ti)
**Role: Inference / Generation Engine**

Runs:
- ComfyUI (future video/image extensions)
- Qwen2.5-Coder-32B-Instruct (Q4_K_M)
- DeepSeek Coder (fallback / fast mode)
- llama.cpp GPU offload models
- Code generation / completion / refactor tasks

Responsibilities:
- Heavy LLM inference
- Code generation
- Optional multimodal (future)

---

## 🟡 PC-2 (CPU NODE - GTX 1650)
**Role: Brain / Orchestrator / Memory**

Runs:
- FastAPI (MoE API Gateway)
- Redis (job queue)
- Qdrant (vector memory)
- PostgreSQL (metadata)
- Planner LLM (CPU / quantized models)
- Night Learning System

Responsibilities:
- Task routing
- Memory management
- Job scheduling
- Learning pipeline
- VSCode / Aider integration backend

---

# 🔄 3. CORE FLOW

```text
VSCode / Aider
      ↓
PC-2 API (Brain)
      ↓
Router / Planner
      ↓
Redis Queue
      ↓
PC-1 GPU Worker
      ↓
LLM Inference (Qwen / DeepSeek)
      ↓
Response
      ↓
Memory Storage (Qdrant + Postgres)
⚙️ 4. MODEL STRATEGY
Primary Models
Qwen2.5-Coder-32B-Instruct (Q4_K_M)
DeepSeek Coder (fast fallback)
Execution Rules
Complex reasoning → Qwen 32B GPU
Fast autocomplete → DeepSeek small model
Lightweight tasks → CPU fallback models
📦 5. REDIS JOB SYSTEM

Queues:

code_jobs
chat_jobs
agent_jobs
memory_jobs

Job format:

{
  "id": "uuid",
  "type": "code_generation",
  "prompt": "...",
  "context": "...",
  "target": "pc1",
  "model": "qwen2.5-coder"
}
🧠 6. MOE ROUTER (PC-2)

Responsibilities:

Intent classification
Model selection
Task splitting
Load balancing between models

Routing logic:

High complexity → Qwen 32B GPU
Fast completion → DeepSeek
Simple tasks → CPU model
💻 7. VS CODE / AIDER INTEGRATION
Goals
Replace OpenAI API dependency
Enable local coding assistant
Streaming completions
Modes
Inline autocomplete
Chat-based coding assistant
Refactor agent
🧠 8. MEMORY SYSTEM
Components
Qdrant (vector DB)
PostgreSQL (structured logs)
Stored Data
Code patterns
Refactor history
Prompt-response pairs
Architecture decisions
Memory Query
GET /memory/search?q=redis queue design
🌙 9. NIGHT LEARNING SYSTEM (PC-2)
Purpose

Offline autonomous learning from curated context list.

Workflow
Scheduled (23:00)
      ↓
Load context list (syllabus)
      ↓
Iterate topics
      ↓
LLM explanation (CPU model)
      ↓
Summarize
      ↓
Embed
      ↓
Store in Qdrant
Output
Topic summaries
Engineering notes
Architecture patterns
Retrieval knowledge base
Example Context List
- Redis queue patterns
- Docker networking
- ComfyUI workflows
- GGUF quantization
- MoE routing strategies
🔁 10. SELF-IMPROVING LOOP

System improves by:

Using memory before inference
Storing new knowledge after tasks
Night learning expanding knowledge base
Reusing learned patterns in routing
⚡ 11. PERFORMANCE TARGET
Qwen 32B Q4: ~8–14 tok/s
DeepSeek small: ~20–40 tok/s
CPU fallback: high latency, low cost

Target:

≥ 10 tok/s for coding tasks
🧱 12. REPOSITORY STRUCTURE
MoE/
 ├── pc2-brain/
 │    ├── api/
 │    ├── router/
 │    ├── planner/
 │    ├── memory/
 │    ├── night_learner/
 │
 ├── pc1-gpu/
 │    ├── inference/
 │    ├── worker/
 │    ├── models/
 │
 ├── shared/
 │    ├── redis/
 │    ├── job_schema/
 │
 ├── vscode-extension/
 ├── aider-wrapper/
 ├── docker/
 └── docker-compose.yml
🚀 13. DEVELOPMENT PHASES
Phase 1 — Core Infrastructure
Redis job system
PC-2 FastAPI brain
PC-1 inference node
Basic routing
Phase 2 — Coding Assistant
VSCode integration
Aider wrapper
Streaming responses
Phase 3 — Memory System
Qdrant integration
Code embedding pipeline
Retrieval augmentation
Phase 4 — Night Learning
Scheduler
Context learning system
Knowledge accumulation
🧯 14. DESIGN PRINCIPLES
Fully offline
Minimal dependencies
No external APIs
Redis as only coordination layer
GPU reserved for inference only
CPU handles orchestration and memory
🧠 RESULT

This system becomes:

A distributed offline AI coding operating system that learns over time and accelerates development workflows locally.


---

## ➜ Sonraki adım

Şimdi çok doğru noktadayız.

Bir sonraki adımda şunu yapalım:

### 🔧 Repo inceleme + gerçek refactor planı

Sen bana şunu gönder:
- `docker-compose.yml`
- `tree -L 3`

Ben sana:

👉 mevcut repo + bu planı “merge edip”
- hangi dosya silinecek
- hangisi split olacak
- Redis nereye girecek
- PC-1 / PC-2 nasıl ayrılacak
- ilk çalışır MVP adımı

hepsini **commit seviyesinde adım adım** çıkaracağım.