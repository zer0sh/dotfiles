#!/usr/bin/env python3
import json
import os
import platform
import shutil
import time

def get_cpu_info():
    model = "Desconocido"
    try:
        with open("/proc/cpuinfo") as f:
            for line in f:
                if "model name" in line:
                    model = line.split(":", 1)[1].strip()
                    break
    except Exception:
        pass

    # Calcular uso de CPU en un intervalo corto (80ms)
    usage = 0.0
    try:
        with open("/proc/stat") as f:
            fields1 = [float(x) for x in f.readline().strip().split()[1:]]
        idle1, total1 = fields1[3], sum(fields1)
        time.sleep(0.08)
        with open("/proc/stat") as f:
            fields2 = [float(x) for x in f.readline().strip().split()[1:]]
        idle2, total2 = fields2[3], sum(fields2)
        total_delta = total2 - total1
        idle_delta = idle2 - idle1
        if total_delta > 0:
            usage = round((1.0 - (idle_delta / total_delta)) * 100, 1)
    except Exception:
        pass

    return model, usage

def get_mem_info():
    meminfo = {}
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                parts = line.split(":")
                if len(parts) == 2:
                    meminfo[parts[0].strip()] = int(parts[1].split()[0])
    except Exception:
        pass

    total_mb = meminfo.get("MemTotal", 0) // 1024
    avail_mb = meminfo.get("MemAvailable", 0) // 1024
    free_mb = meminfo.get("MemFree", 0) // 1024
    used_mb = total_mb - avail_mb
    percent = round((used_mb / total_mb) * 100, 1) if total_mb else 0.0

    return {
        "total_mb": total_mb,
        "used_mb": used_mb,
        "avail_mb": avail_mb,
        "free_mb": free_mb,
        "percent": percent
    }

def get_disk_info():
    try:
        total, used, free = shutil.disk_usage("/")
        total_gb = round(total / (1024**3), 1)
        used_gb = round(used / (1024**3), 1)
        free_gb = round(free / (1024**3), 1)
        percent = round((used / total) * 100, 1) if total else 0.0
        return {
            "total_gb": total_gb,
            "used_gb": used_gb,
            "free_gb": free_gb,
            "percent": percent
        }
    except Exception:
        return {"total_gb": 0, "used_gb": 0, "free_gb": 0, "percent": 0}

def get_uptime():
    try:
        with open("/proc/uptime") as f:
            seconds = float(f.readline().split()[0])
        days = int(seconds // 86400)
        hours = int((seconds % 86400) // 3600)
        mins = int((seconds % 3600) // 60)
        if days > 0:
            return f"{days}d {hours}h {mins}m"
        return f"{hours}h {mins}m"
    except Exception:
        return "N/A"

def get_distro():
    pretty = "Debian GNU/Linux"
    try:
        with open("/etc/os-release") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    pretty = line.split("=", 1)[1].strip().strip('"')
                    break
    except Exception:
        pass
    return pretty

def main():
    cpu_model, cpu_usage = get_cpu_info()
    data = {
        "distro": get_distro(),
        "kernel": platform.release(),
        "hostname": platform.node(),
        "uptime": get_uptime(),
        "cpu_model": cpu_model,
        "cpu_percent": cpu_usage,
        "memory": get_mem_info(),
        "disk": get_disk_info()
    }
    print(json.dumps(data))

if __name__ == "__main__":
    main()
