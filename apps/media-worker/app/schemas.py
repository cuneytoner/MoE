from pydantic import BaseModel


class WorkerProcessRequest(BaseModel):
    job_id: str
    mode: str = "dry_run"
