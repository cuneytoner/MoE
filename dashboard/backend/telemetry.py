import subprocess
from config import REMOTE_NODE


def get_local_telemetry():
    try:
        with open("/proc/loadavg", "r") as f:
            cpu_load = int(float(f.readline().split()[0]) * 12.5)
            cpu_load = min(cpu_load, 100)

        with open("/proc/meminfo", "r") as f:
            lines = f.readlines()
            total = int([x for x in lines if "MemTotal" in x][0].split()[1])
            free = int([x for x in lines if "MemAvailable" in x][0].split()[1])

            ram_usage = int(((total - free) / total) * 100)

    except Exception:
        cpu_load = 0
        ram_usage = 0

    try:
        gpu_raw = subprocess.check_output(
            "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits",
            shell=True,
            text=True
        )

        g_util, v_used, v_total = map(int, gpu_raw.strip().split(","))

        vram_usage = int((v_used / v_total) * 100)

    except Exception:
        g_util = 0
        vram_usage = 0

    return {
        "cpu": cpu_load,
        "ram": ram_usage,
        "gpu": g_util,
        "vram": vram_usage
    }


def get_remote_telemetry():
    try:
        user = REMOTE_NODE["user"]
        ip = REMOTE_NODE["ip"]

        gpu_raw = subprocess.check_output(
            f"ssh -o ConnectTimeout=1 {user}@{ip} "
            "'nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits'",
            shell=True,
            text=True
        )

        g_util, v_used, v_total = map(int, gpu_raw.strip().split(","))

        vram_usage = int((v_used / v_total) * 100)

        cpu_raw = subprocess.check_output(
            f"ssh -o ConnectTimeout=1 {user}@{ip} 'cat /proc/loadavg'",
            shell=True,
            text=True
        )

        cpu_load = int(float(cpu_raw.split()[0]) * 25)

        return {
            "cpu": min(cpu_load, 100),
            "ram": 45,
            "gpu": g_util,
            "vram": vram_usage
        }

    except Exception:
        return {
            "cpu": 0,
            "ram": 0,
            "gpu": 0,
            "vram": 0
        }
