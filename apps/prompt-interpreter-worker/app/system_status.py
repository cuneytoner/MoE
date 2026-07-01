import os
import shutil
from pathlib import Path
from typing import Any


def build_system_status() -> dict[str, Any]:
    return {
        "status": "ok",
        "service": "pc2-system-status",
        "read_only": True,
        "host_role": "helper worker node",
        "memory": _memory_status(),
        "cpu": _cpu_status(),
        "disk": _disk_status("/"),
        "uptime": _uptime_status(),
    }


def _memory_status() -> dict[str, Any]:
    values = _read_meminfo()
    total_mb = _kb_to_mb(values.get("MemTotal", 0))
    free_mb = _kb_to_mb(values.get("MemFree", 0))
    available_mb = _kb_to_mb(values.get("MemAvailable", values.get("MemFree", 0)))
    used_mb = max(0, total_mb - available_mb)
    used_percent = round((used_mb / total_mb) * 100, 1) if total_mb else 0.0
    return {
        "total_mb": total_mb,
        "used_mb": used_mb,
        "free_mb": free_mb,
        "available_mb": available_mb,
        "used_percent": used_percent,
    }


def _read_meminfo() -> dict[str, int]:
    values: dict[str, int] = {}
    try:
        for line in Path("/proc/meminfo").read_text(encoding="utf-8").splitlines():
            key, raw_value = line.split(":", 1)
            parts = raw_value.strip().split()
            if parts:
                values[key] = int(parts[0])
    except (OSError, ValueError):
        return {}
    return values


def _cpu_status() -> dict[str, Any]:
    try:
        parts = Path("/proc/loadavg").read_text(encoding="utf-8").split()
        load_1m = float(parts[0])
        load_5m = float(parts[1])
        load_15m = float(parts[2])
    except (OSError, ValueError, IndexError):
        load_1m = 0.0
        load_5m = 0.0
        load_15m = 0.0
    return {
        "load_1m": load_1m,
        "load_5m": load_5m,
        "load_15m": load_15m,
        "cpu_count": os.cpu_count() or 0,
    }


def _disk_status(path: str) -> dict[str, Any]:
    try:
        usage = shutil.disk_usage(path)
    except OSError:
        return {
            "path": path,
            "total_gb": 0.0,
            "used_gb": 0.0,
            "free_gb": 0.0,
            "used_percent": 0.0,
        }
    used_percent = round((usage.used / usage.total) * 100, 1) if usage.total else 0.0
    return {
        "path": path,
        "total_gb": _bytes_to_gb(usage.total),
        "used_gb": _bytes_to_gb(usage.used),
        "free_gb": _bytes_to_gb(usage.free),
        "used_percent": used_percent,
    }


def _uptime_status() -> dict[str, Any]:
    try:
        seconds = int(float(Path("/proc/uptime").read_text(encoding="utf-8").split()[0]))
    except (OSError, ValueError, IndexError):
        seconds = 0
    return {
        "seconds": seconds,
        "human": _human_duration(seconds),
    }


def _kb_to_mb(value: int) -> int:
    return int(round(value / 1024))


def _bytes_to_gb(value: int) -> float:
    return round(value / (1024**3), 1)


def _human_duration(seconds: int) -> str:
    days, remainder = divmod(max(0, seconds), 86400)
    hours, remainder = divmod(remainder, 3600)
    minutes, _ = divmod(remainder, 60)
    parts = []
    if days:
        parts.append(f"{days}d")
    if hours or parts:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")
    return " ".join(parts)
