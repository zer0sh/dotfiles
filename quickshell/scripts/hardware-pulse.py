#!/usr/bin/env python3
import json
import os
import shutil
import time

def get_cpu_and_temp():
    usage = 0.0
    try:
        with open("/proc/stat") as f:
            fields1 = [float(x) for x in f.readline().strip().split()[1:]]
        idle1, total1 = fields1[3], sum(fields1)
        time.sleep(0.06)
        with open("/proc/stat") as f:
            fields2 = [float(x) for x in f.readline().strip().split()[1:]]
        idle2, total2 = fields2[3], sum(fields2)
        total_delta = total2 - total1
        idle_delta = idle2 - idle1
        if total_delta > 0:
            usage = round((1.0 - (idle_delta / total_delta)) * 100, 1)
    except Exception:
        pass

    temp = 0
    try:
        # Check thermal zones
        for i in range(5):
            path = f"/sys/class/thermal/thermal_zone{i}/temp"
            if os.path.exists(path):
                with open(path) as f:
                    raw = int(f.read().strip())
                    if raw > 1000:
                        temp = raw // 1000
                        break
    except Exception:
        pass

    return usage, temp

def get_mem():
    total_mb, avail_mb = 0, 0
    try:
        with open("/proc/meminfo") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    total_mb = int(line.split()[1]) // 1024
                elif line.startswith("MemAvailable:"):
                    avail_mb = int(line.split()[1]) // 1024
    except Exception:
        pass

    used_mb = max(0, total_mb - avail_mb)
    percent = round((used_mb / total_mb) * 100, 1) if total_mb else 0.0
    return {
        "used_gb": round(used_mb / 1024, 1),
        "total_gb": round(total_mb / 1024, 1),
        "percent": percent
    }

def get_battery():
    level = -1
    status = "Unknown"
    for bat in ["BAT0", "BAT1"]:
        cap_path = f"/sys/class/power_supply/{bat}/capacity"
        stat_path = f"/sys/class/power_supply/{bat}/status"
        if os.path.exists(cap_path):
            try:
                with open(cap_path) as f:
                    level = int(f.read().strip())
                if os.path.exists(stat_path):
                    with open(stat_path) as f:
                        status = f.read().strip()
                break
            except Exception:
                pass
    return level, status

def main():
    cpu_usage, cpu_temp = get_cpu_and_temp()
    mem = get_mem()
    bat_level, bat_status = get_battery()

    out = {
        "cpu_percent": cpu_usage,
        "cpu_temp": cpu_temp,
        "mem_used_gb": mem["used_gb"],
        "mem_total_gb": mem["total_gb"],
        "mem_percent": mem["percent"],
        "battery_level": bat_level,
        "battery_status": bat_status
    }
    print(json.dumps(out))

if __name__ == "__main__":
    main()
