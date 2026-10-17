#!/usr/bin/env python3
"""
battery-info.py — Reads battery and power metrics from /sys/class/power_supply
and outputs a JSON object for Quickshell UI consumption.
"""

import os
import json

def read_val(path, default=""):
    try:
        with open(path, "r") as f:
            return f.read().strip()
    except Exception:
        return default

def get_battery_info():
    bat = "/sys/class/power_supply/BAT0"
    ac = "/sys/class/power_supply/AC/online"

    if not os.path.exists(bat):
        return {
            "available": False,
            "capacity": 100,
            "status": "AC",
            "ac_online": True
        }

    try:
        capacity = int(read_val(f"{bat}/capacity", "0"))
    except ValueError:
        capacity = 0

    status = read_val(f"{bat}/status", "Unknown")

    try:
        energy_now = int(read_val(f"{bat}/energy_now", "0"))
    except ValueError:
        energy_now = 0

    try:
        energy_full = int(read_val(f"{bat}/energy_full", "0"))
    except ValueError:
        energy_full = 0

    try:
        energy_design = int(read_val(f"{bat}/energy_full_design", "0"))
    except ValueError:
        energy_design = 0

    try:
        power_now = int(read_val(f"{bat}/power_now", "0"))
    except ValueError:
        power_now = 0

    try:
        voltage_now = int(read_val(f"{bat}/voltage_now", "0"))
    except ValueError:
        voltage_now = 0

    try:
        cycles = int(read_val(f"{bat}/cycle_count", "0"))
    except ValueError:
        cycles = 0

    tech = read_val(f"{bat}/technology", "Li-poly")
    threshold = read_val(f"{bat}/charge_control_end_threshold", "")
    ac_online = read_val(ac, "0") == "1"

    health = round((energy_full / energy_design * 100), 1) if energy_design > 0 else 100
    power_w = round(power_now / 1e6, 1)
    voltage_v = round(voltage_now / 1e6, 2)
    wh_now = round(energy_now / 1e6, 1)
    wh_full = round(energy_full / 1e6, 1)
    wh_design = round(energy_design / 1e6, 1)

    time_min = 0
    if power_now > 0:
        if status == "Discharging":
            time_min = round((energy_now / power_now) * 60)
        elif status == "Charging" and energy_full > energy_now:
            time_min = round(((energy_full - energy_now) / power_now) * 60)

    return {
        "available": True,
        "capacity": capacity,
        "status": status,
        "ac_online": ac_online,
        "energy_now_wh": wh_now,
        "energy_full_wh": wh_full,
        "energy_design_wh": wh_design,
        "power_w": power_w,
        "voltage_v": voltage_v,
        "cycles": cycles,
        "technology": tech,
        "threshold": threshold,
        "health_percent": health,
        "time_remaining_min": time_min
    }

if __name__ == "__main__":
    print(json.dumps(get_battery_info()))
