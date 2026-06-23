import os
import threading
import requests

from config import ENV_FILE
from config import TARGET_DIR


def load_hf_token():
    if not os.path.exists(ENV_FILE):
        return None

    with open(ENV_FILE, "r") as f:
        for line in f:
            if line.startswith("HF_TOKEN="):
                return (
                    line.replace("HF_TOKEN=", "")
                    .strip()
                    .strip('"')
                    .strip("'")
                )

    return None


def core_download_worker(repo_id, filename, token):
    try:
        dest_path = os.path.join(TARGET_DIR, filename)

        hf_url = (
            f"https://huggingface.co/"
            f"{repo_id}/resolve/main/{filename}"
        )

        headers = (
            {"Authorization": f"Bearer {token}"}
            if token else {}
        )

        with requests.get(
            hf_url,
            headers=headers,
            stream=True,
            timeout=60
        ) as r:

            r.raise_for_status()

            with open(dest_path, "wb") as f:
                for chunk in r.iter_content(
                    chunk_size=1024 * 1024
                ):
                    if chunk:
                        f.write(chunk)

    except Exception as e:
        print(e)


def start_download(repo_id, filename):
    token = load_hf_token()

    thread = threading.Thread(
        target=core_download_worker,
        args=(repo_id, filename, token)
    )

    thread.start()
