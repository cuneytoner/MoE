from typing import Any


DEFAULT_MODELS: list[dict[str, Any]] = [
    {
        "id": "qwen-coder-14b-fast",
        "name": "Qwen2.5 Coder 14B Instruct IQ4 XS",
        "path": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-14B-Instruct-IQ4_XS.gguf",
        "context": 32768,
        "gpu_layers": 999,
        "threads": 8,
        "batch_size": 512,
        "ubatch_size": 128,
        "cache_type_k": "q8_0",
        "cache_type_v": "q8_0",
        "flash_attention": True,
    },
    {
        "id": "qwen-coder-32b-main",
        "name": "Qwen2.5 Coder 32B Instruct IQ4 XS",
        "path": "/home/cuneyt/MoE_Models_Backup/Qwen2.5-Coder-32B-Instruct-IQ4_XS.gguf",
        "context": 32768,
        "gpu_layers": 999,
        "threads": 8,
        "batch_size": 512,
        "ubatch_size": 128,
        "cache_type_k": "q8_0",
        "cache_type_v": "q8_0",
        "flash_attention": True,
    },
    {
        "id": "deepseek-coder-lite",
        "name": "DeepSeek Coder V2 Lite Instruct IQ4 XS",
        "path": "/home/cuneyt/MoE_Models_Backup/DeepSeek-Coder-V2-Lite-Instruct-IQ4_XS.gguf",
        "context": 32768,
        "gpu_layers": 999,
        "threads": 8,
        "batch_size": 512,
        "ubatch_size": 128,
        "cache_type_k": "q8_0",
        "cache_type_v": "q8_0",
        "flash_attention": True,
    },
]


DEFAULT_RUNTIME: dict[str, Any] = {
    "llama_server": "/home/cuneyt/Apps/llama.cpp/build/bin/llama-server",
    "host": "0.0.0.0",
    "port": 8000,
    "openai_base_url": "http://localhost:8000/v1",
    "runtime_dir": "/home/cuneyt/MoE/runtime",
    "log_file": "/home/cuneyt/MoE/runtime/logs/llama-server.log",
    "pid_file": "/home/cuneyt/MoE/runtime/pids/llama-server.pid",
    "metadata_file": "/home/cuneyt/MoE/runtime/pids/llama-server.env",
    "default_model": "qwen-coder-32b-main",
}
