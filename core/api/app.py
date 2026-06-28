from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"service": "MoE Router", "status": "running"}

@app.get("/health")
def read_health():
    return {"status": "healthy"}