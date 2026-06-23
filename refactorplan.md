🧠 MOE REPO REFACTOR PLAN (REALISTIC + MINIMAL + SCALABLE)
🎯 HEDEF

Şu 3 şeyi elde edeceğiz:

Offline coding AI (VSCode + Aider uyumlu)
PC-1 GPU inference node
PC-2 brain + memory + router
Redis job-based execution (tek gerçek backbone)
🧱 PHASE 0 — CLEAN ARCHITECTURE DECISION
❌ SİL / BASİTLEŞTİR

Repo’da varsa:

fazla dashboard logic
gereksiz “observability / logging UI”
multi-agent karmaşık orchestrator denemeleri

👉 hepsi “PC-2 brain içine merge”

✅ YENİ MİMARİ KURALI

“Everything is a job”

🧠 PHASE 1 — CORE SPLIT (EN KRİTİK)
📁 YENİ REPO STRUCTURE
MoE/
 ├── pc2-brain/        ← CONTROL PLANE
 │    ├── api/
 │    ├── router/
 │    ├── planner/
 │    ├── memory/
 │    ├── night_learning/
 │
 ├── pc1-gpu/         ← EXECUTION PLANE
 │    ├── worker/
 │    ├── inference/
 │    ├── models/
 │    ├── comfyui/
 │
 ├── shared/
 │    ├── redis/
 │    ├── schemas/
 │
 ├── clients/
 │    ├── vscode-extension/
 │    ├── aider-wrapper/
 │
 ├── docker/
 └── docker-compose.yml
⚙️ PHASE 2 — REDIS CORE (MERKEZ SİSTEM)
❗ EKLENECEK TEK GERÇEK INFRA
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
QUEUE MODEL
code_jobs
chat_jobs
refactor_jobs
embedding_jobs
memory_jobs
JOB FORMAT (STANDARDIZATION)
{
  "id": "uuid",
  "type": "code_generation",
  "prompt": "...",
  "context": "...",
  "model": "qwen2.5-coder",
  "target": "pc1"
}
🧠 PHASE 3 — PC-2 (BRAIN NODE)
📌 SORUMLULUK
intent detection
model routing
memory retrieval
job creation
VSCode API backend
FASTAPI CORE
POST /generate
POST /chat
GET  /memory/search
POST /job/dispatch
ROUTER LOGIC
if task == "code_complex":
    model = "qwen32b"
    target = "pc1"

elif task == "autocomplete":
    model = "deepseek_fast"
    target = "pc1"

elif task == "memory_query":
    return qdrant_search()
🧠 PHASE 4 — PC-1 (GPU NODE)
📌 SORUMLULUK
LLM inference
model execution
streaming output
MODELS
Qwen2.5-Coder-32B-Instruct
DeepSeek Coder
WORKER LOOP
while True:
    job = redis.brpop("code_jobs")

    if job.model == "qwen":
        run_qwen()

    elif job.model == "deepseek":
        run_deepseek()

    stream_response()
🧠 PHASE 5 — MEMORY SYSTEM (QDRANT + POSTGRES)
📌 AMAÇ
code patterns
past solutions
architecture decisions
FLOW
response → embedding → qdrant
MEMORY QUERY
GET /memory/search?q=redis queue design
🌙 PHASE 6 — NIGHT LEARNING SYSTEM (PC-2)
📌 YENİ MODÜL
night_learning/
    runner.py
    syllabus.json
    summarizer.py
SÜREÇ
23:00
  ↓
load topics
  ↓
LLM explain
  ↓
summarize
  ↓
store in Qdrant
OUTPUT
engineering notes
architecture patterns
reusable knowledge
💻 PHASE 7 — VS CODE + AIDER INTEGRATION
🎯 HEDEF

OpenAI API yerine:

👉 local MoE endpoint

VS CODE EXTENSION
prompt gönder
streaming response
inline edit
AIDER WRAPPER
export OPENAI_API_BASE=http://pc2:8000
⚡ PHASE 8 — PERFORMANCE TARGET
Model	Target
Qwen 32B Q4	8–14 tok/s
DeepSeek coder	20–40 tok/s
fallback	50+ tok/s
🧯 PHASE 9 — SIMPLIFICATION RULES
❌ REMOVE
heavy dashboard systems
unnecessary microservices
over-engineered agent graphs
✅ KEEP
Redis
FastAPI
worker loop
memory (Qdrant)
model router
🚀 FINAL SYSTEM DEFINITION

MoE = Distributed Offline Coding OS

PC-2 (Brain)
thinks
routes
remembers
PC-1 (GPU)
executes
generates
streams
Redis
nervous system
🧭 NEXT STEP (REPO-BASED ACTION)

Şimdi sıradaki adım:

👉 sen bana sadece şunu at:

tree -L 4

veya docker-compose.yml

Ben sana bir sonraki adımda şunu çıkaracağım:

🔧 “EXACT REFACTOR PATCH PLAN”
hangi dosya silinecek
hangi dosya split olacak
hangi service nereye taşınacak
Redis nasıl bağlanacak
PC-1 / PC-2 net deployment planı
ilk çalışan MVP commit sırası

Bu noktadan sonra artık tasarım değil:

repo dönüşüm planı + production build path yapacağız.