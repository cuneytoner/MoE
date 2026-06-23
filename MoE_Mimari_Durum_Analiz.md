🧠 MOE GERÇEK MİMARİ DURUMU (ANALİZ)
📦 Mevcut güçlü taraflar
Dashboard var (frontend + backend)
Docker infra var
Model management var
Scripts layer var (research worker vs.)
Docs var (olgun proje sinyali)
❌ EKSİK OLAN (KRİTİK)
1. Execution separation yok
PC1 / PC2 ayrımı yok
2. Job system yok
Redis yok (veya merkezi queue yok)
3. Agent brain layer yok
router / planner yok
4. Model runtime abstraction yok
“hangi model nerede çalışır” tanımı yok
🎯 HEDEF (DEĞİŞMEZ)

“Codebase-first distributed offline AI coding OS”

🧱 YENİ MİMARİ (SENİN REPO ÜZERİNE OTURAN)
MoE/
│
├── pc1-runtime/        ← GPU MACHINE (5060 Ti)
│   ├── inference/
│   ├── models/
│   ├── worker/
│   └── export/
│
├── pc2-brain/          ← CONTROL MACHINE (1650)
│   ├── api/
│   ├── router/
│   ├── planner/
│   ├── memory/
│   └── scheduler/
│
├── shared/
│   ├── redis/
│   ├── schemas/
│   └── job_types/
│
├── dashboard/          ← KEEP (UI)
│   ├── backend/
│   └── frontend/
│
├── docker/             ← REVISED
├── scripts/            ← EXTEND (deployment aware)
└── deploy.sh           ← SPLIT PC1/PC2 aware
⚙️ 1. EN KRİTİK REFACTOR (FIRST MOVE)
❗ SENİN PROJEDE EN ÖNEMLİ ADIM

👉 mevcut sistemi iki node’a “physically deployable” hale getirmek

🖥 PC1 (GPU NODE) — ~/MoE
İçine çıkacaklar:
inference runtime
model folder
worker loop
ComfyUI (ileride video için)
PC1 görevleri:
- Qwen2.5-Coder-32B Q4
- DeepSeek Coder fallback
- inference API (FastAPI or llama.cpp server)
- streaming response endpoint
🧠 PC2 (BRAIN NODE) — ~/MoE
İçine çıkacaklar:
dashboard backend logic (partial move)
router logic
planner
memory system
job creation
redis producer
PC2 görevleri:
- /generate API
- intent classification
- job dispatch
- memory search (Qdrant)
- night scheduler
🔥 2. EN KRİTİK EKLEME: REDIS (MERKEZ SINIR SİSTEMİ)

Şu an yok → EKLEME ZORUNLU

shared/redis/
redis:
  image: redis:7-alpine
  ports:
    - "6379:6379"
queue standard
code_jobs
chat_jobs
memory_jobs
agent_jobs
🔄 3. DASHBOARD ROLE REWRITE

Şu an:

👉 dashboard = UI + backend mixed

YENİ ROLE:
dashboard/backend
sadece API gateway
PC2 brain’e bağlanır
job status gösterir
🧠 4. ROUTER (PC2’ye EKLENECEK)

Yeni dosya:

pc2-brain/router/router.py
logic:
def route(task):
    if task == "complex_code":
        return "qwen32b_gpu"

    if task == "autocomplete":
        return "deepseek_fast"

    return "small_cpu_model"
⚙️ 5. PC1 INFERENCE NODE

Yeni servis:

pc1-runtime/worker/main.py

Loop:

while True:
    job = redis.brpop("code_jobs")

    result = run_model(job)

    return_stream(result)
🧠 6. MEMORY SYSTEM (YENİ KATMAN)

PC2:

Qdrant
Postgres
memory:
  - code patterns
  - past solutions
  - architecture decisions
🌙 7. NIGHT LEARNING (SENİN EKLEDİĞİN PARÇA)

PC2:

night_scheduler:
  - topic list
  - LLM summarization
  - embedding
  - store
💻 8. VS CODE / AIDER
hedef:
VSCode → PC2 → Redis → PC1 → response
🚀 9. DEPLOYMENT STRATEGY (EN ÖNEMLİ)
deploy.sh split olacak:
./deploy.sh pc1
./deploy.sh pc2
PC1 deploy:
cd pc1-runtime
docker compose up -d
PC2 deploy:
cd pc2-brain
docker compose up -d
🧯 10. SİL / BİRLEŞTİR
kaldır veya merge et:
script karmaşası → pc2 scheduler içine al
research_worker → memory pipeline
sync_rag.py → qdrant pipeline
watch.sh → optional debug tool
⚡ 11. MVP ROADMAP (REPO ÖZEL)
PHASE 1
 Redis ekle
 PC1 inference node ayır
 PC2 brain API oluştur
 job system kur
PHASE 2
 Qwen2.5-Coder çalıştır
 DeepSeek fallback
 streaming response
PHASE 3
 memory system
 VSCode integration
PHASE 4
 night learning system
 self-improving loop
🧠 SON DURUM (ÇOK ÖNEMLİ)

Senin repo şu anda:

“monolithic AI dashboard + scripts”

Bunu şuna çeviriyoruz:

“distributed offline AI coding operating system”

👉 SONRAKİ ADIM (GERÇEK REFACTOR BAŞLANGICI)

Eğer “devam” dersen bir sonraki mesajda sana:

🔧 1. EXACT FILE MOVE PLAN
hangi dosya nereye taşınacak (line-by-line değil file-by-file)
🔧 2. docker-compose REWRITE (PC1 + PC2 split)
🔧 3. FIRST RUN WORKFLOW
curl /generate
streaming test
VSCode hook
🔧 4. MINIMAL RUNNING MVP CODE

hazırlayacağım.