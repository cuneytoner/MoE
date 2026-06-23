from fastapi import FastAPI
import redis
import uuid
import json

app = FastAPI()
r = redis.Redis(host="localhost", port=6379, decode_responses=True)

@app.post("/generate")
def generate(payload: dict):
    job_id = str(uuid.uuid4())

    job = {
        "id": job_id,
        "type": "code_generation",
        "prompt": payload["prompt"],
        "model": "qwen",
        "target": "pc1"
    }

    r.lpush("code_jobs", json.dumps(job))

    return {"job_id": job_id, "status": "queued"}


@app.get("/health")
def health():
    return {"status": "ok"}
