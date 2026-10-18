#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys

CONFIG_DIR = os.path.expanduser("~/.config/quickshell")
ICONS_FILE = os.path.join(CONFIG_DIR, "bluetooth_icons.json")
CACHE_FILE = os.path.expanduser("~/.cache/quickshell/bluetooth_status.json")

def load_user_icons():
    if os.path.exists(ICONS_FILE):
        try:
            with open(ICONS_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {}

def save_user_icon(mac, icon_type):
    os.makedirs(CONFIG_DIR, exist_ok=True)
    icons = load_user_icons()
    icons[mac] = icon_type
    try:
        with open(ICONS_FILE, "w") as f:
            json.dump(icons, f, indent=2)
    except Exception:
        pass

def infer_icon_type(name, hint=""):
    name_l = name.lower()
    hint_l = hint.lower()

    if "mouse" in name_l or "mouse" in hint_l:
        return "mouse"
    if "keyboard" in name_l or "keychron" in name_l or "keyboard" in hint_l:
        return "keyboard"
    if any(k in name_l for k in ["buds", "headset", "headphone", "tws", "airpod", "hp-", "ear"]) or "headset" in hint_l:
        return "headphones"
    if any(k in name_l for k in ["speaker", "echo", "jbl", "sound", "go 3", "audio-card"]) or "audio-card" in hint_l:
        return "speaker"
    if any(k in name_l for k in ["controller", "xbox", "ps4", "ps5", "gamepad", "joystick"]) or "gaming" in hint_l:
        return "gamepad"
    return "device"

def get_bluetooth_state():
    # 1. Check powered status
    powered = False
    try:
        res = subprocess.run(["bluetoothctl", "show"], capture_output=True, text=True, timeout=1.5)
        powered = "Powered: yes" in res.stdout
    except Exception:
        pass

    if not powered:
        return {"powered": False, "devices": [], "connected": None}

    user_icons = load_user_icons()

    # 2. Get paired devices
    paired = []
    try:
        res = subprocess.run(["bluetoothctl", "devices", "Paired"], capture_output=True, text=True, timeout=1.5)
        for line in res.stdout.strip().split("\n"):
            parts = line.split(" ")
            if len(parts) >= 3 and parts[0] == "Device":
                paired.append({"mac": parts[1], "name": " ".join(parts[2:])})
    except Exception:
        pass

    devices = []
    connected_device = None

    for d in paired:
        mac = d["mac"]
        name = d["name"]
        is_conn = False
        battery = None
        hint = ""

        try:
            info_res = subprocess.run(["bluetoothctl", "info", mac], capture_output=True, text=True, timeout=1.2)
            is_conn = "Connected: yes" in info_res.stdout
            m_bat = re.search(r"Battery Percentage:\s*0x[0-9a-fA-F]+\s*\((\d+)\)", info_res.stdout)
            if not m_bat:
                m_bat = re.search(r"Battery Percentage:\s*(\d+)", info_res.stdout)
            if m_bat:
                battery = int(m_bat.group(1))
            m_ico = re.search(r"Icon:\s*(\S+)", info_res.stdout)
            if m_ico:
                hint = m_ico.group(1)
        except Exception:
            pass

        # Determine icon type: user override takes priority, then inferred
        icon_type = user_icons.get(mac)
        if not icon_type:
            icon_type = infer_icon_type(name, hint)

        entry = {
            "mac": mac,
            "name": name,
            "connected": is_conn,
            "battery": battery,
            "icon_type": icon_type
        }
        devices.append(entry)

        if is_conn and not connected_device:
            connected_device = entry

    data = {
        "powered": powered,
        "devices": devices,
        "connected": connected_device
    }

    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE + ".tmp", "w") as f:
            json.dump(data, f)
        os.replace(CACHE_FILE + ".tmp", CACHE_FILE)
    except Exception:
        pass

    return data

def main():
    if len(sys.argv) >= 3 and sys.argv[1] == "set-icon":
        mac = sys.argv[2]
        icon_type = sys.argv[3] if len(sys.argv) >= 4 else "device"
        save_user_icon(mac, icon_type)
        print(json.dumps({"success": True, "mac": mac, "icon_type": icon_type}))
        return

    data = get_bluetooth_state()
    print(json.dumps(data))

if __name__ == "__main__":
    main()
