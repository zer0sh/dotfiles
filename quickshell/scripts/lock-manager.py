#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
import time

CONF_PATH = os.path.realpath(os.path.expanduser("~/.config/hypr/hypridle.conf"))

DEFAULT_GENERAL = """general {
    before_sleep_cmd = hyprlock
    after_sleep_cmd = hyprctl dispatch dpms on
    ignore_dbus_inhibit = false
    lock_cmd = hyprlock
}"""

def format_time(seconds: int) -> str:
    if seconds <= 0:
        return "Never"
    if seconds < 60:
        return f"{seconds} seconds"
    minutes = seconds // 60
    rem = seconds % 60
    if rem == 0:
        if minutes == 1:
            return "1 minute"
        elif minutes == 60:
            return "1 hour"
        elif minutes > 60 and minutes % 60 == 0:
            return f"{minutes // 60} hours"
        return f"{minutes} minutes"
    return f"{minutes}m {rem}s"

def read_config():
    if not os.path.exists(CONF_PATH):
        return {"enabled": False, "timeout": 0, "minutes": 0, "formatted": "Never"}
    
    try:
        with open(CONF_PATH, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        return {"enabled": False, "timeout": 0, "minutes": 0, "formatted": "Never", "error": str(e)}

    # Look for listener block
    listener_match = re.search(r"listener\s*\{([^}]+)\}", content, re.MULTILINE | re.DOTALL)
    if not listener_match:
        return {"enabled": False, "timeout": 0, "minutes": 0, "formatted": "Never"}

    block = listener_match.group(1)
    timeout_match = re.search(r"timeout\s*=\s*(\d+)", block)
    if not timeout_match:
        return {"enabled": False, "timeout": 0, "minutes": 0, "formatted": "Never"}

    seconds = int(timeout_match.group(1))
    if seconds <= 0:
        return {"enabled": False, "timeout": 0, "minutes": 0, "formatted": "Never"}

    return {
        "enabled": True,
        "timeout": seconds,
        "minutes": round(seconds / 60, 1),
        "formatted": format_time(seconds)
    }

def write_config(seconds: int):
    # Read existing content if possible to preserve any custom general config
    general_block = DEFAULT_GENERAL
    if os.path.exists(CONF_PATH):
        try:
            with open(CONF_PATH, "r", encoding="utf-8") as f:
                content = f.read()
            gen_match = re.search(r"(general\s*\{[^}]+\})", content, re.MULTILINE | re.DOTALL)
            if gen_match:
                general_block = gen_match.group(1).strip()
        except Exception:
            pass

    if seconds <= 0:
        new_content = f"{general_block}\n"
    else:
        new_content = f"{general_block}\n\nlistener {{\n    timeout = {seconds}\n    on-timeout = hyprlock\n}}\n"

    # Write config
    os.makedirs(os.path.dirname(CONF_PATH), exist_ok=True)
    with open(CONF_PATH, "w", encoding="utf-8") as f:
        f.write(new_content)

    # Restart hypridle cleanly
    try:
        subprocess.run(["pkill", "-x", "hypridle"], capture_output=True)
        time.sleep(0.2)
        subprocess.run(["hyprctl", "dispatch", "exec", "hypridle"], capture_output=True)
    except Exception as e:
        pass

    return read_config()

def lock_now():
    try:
        subprocess.Popen(["hyprlock"])
        return {"status": "ok", "message": "Lock screen launched"}
    except Exception as e:
        return {"status": "error", "error": str(e)}

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "get":
        print(json.dumps(read_config()))
        return

    cmd = sys.argv[1].lower()

    if cmd == "disable":
        print(json.dumps(write_config(0)))
    elif cmd == "set":
        if len(sys.argv) < 3:
            print(json.dumps({"error": "Missing timeout value in seconds"}))
            sys.exit(1)
        try:
            sec = int(sys.argv[2])
            print(json.dumps(write_config(sec)))
        except ValueError:
            print(json.dumps({"error": "Invalid integer timeout"}))
            sys.exit(1)
    elif cmd == "lock":
        print(json.dumps(lock_now()))
    else:
        print(json.dumps({"error": f"Unknown command: {cmd}"}))
        sys.exit(1)

if __name__ == "__main__":
    main()
