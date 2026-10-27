#!/usr/bin/env python3
import json
import os
import subprocess
import sys

CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
CACHE_FILE = os.path.join(CACHE_DIR, "audio_status.json")


def run_cmd(cmd, timeout=2.0):
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return res.stdout.strip()
    except Exception:
        return ""


def get_default_sink():
    out = run_cmd(["pactl", "get-default-sink"])
    return out.strip() if out else ""


def get_default_source():
    out = run_cmd(["pactl", "get-default-source"])
    return out.strip() if out else ""


def parse_volume_percent(vol_dict):
    if not vol_dict or not isinstance(vol_dict, dict):
        return 0
    channels = list(vol_dict.values())
    if not channels:
        return 0
    pcts = []
    for ch in channels:
        if isinstance(ch, dict) and "value_percent" in ch:
            pct_str = ch["value_percent"].replace("%", "").strip()
            try:
                pcts.append(int(pct_str))
            except ValueError:
                pass
    return int(sum(pcts) / len(pcts)) if pcts else 0


def infer_sink_icon(name, desc, nick):
    text = f"{name} {desc} {nick}".lower()
    if any(k in text for k in ["headphone", "headset", "earphones", "buds"]):
        return "headphones"
    if any(k in text for k in ["hdmi", "displayport", "dp-", "pro-output"]):
        return "tv"
    if any(k in text for k in ["bluetooth", "bluez"]):
        return "headphones"
    if any(k in text for k in ["usb", "dac"]):
        return "speaker"
    return "speaker"


def infer_sink_label(sink):
    props = sink.get("properties", {})
    nick = props.get("node.nick", "").strip()
    desc = sink.get("description", "").strip()
    dev_desc = props.get("device.description", "").strip()
    name = sink.get("name", "")

    # Clean HDMI tags
    if nick.startswith("HDMI") or "HDMI" in nick:
        return f"{nick} ({dev_desc})" if dev_desc else nick
    if desc:
        return desc
    if dev_desc:
        return dev_desc
    return name


def infer_source_icon(name, desc, nick, is_monitor):
    if is_monitor:
        return "graphic_eq"
    text = f"{name} {desc} {nick}".lower()
    if any(k in text for k in ["headset", "buds"]):
        return "headset_mic"
    return "mic"


def infer_source_label(source, is_monitor):
    props = source.get("properties", {})
    nick = props.get("node.nick", "").strip()
    desc = source.get("description", "").strip()
    dev_desc = props.get("device.description", "").strip()
    name = source.get("name", "")

    if is_monitor:
        base = desc.replace("Monitor of ", "").strip()
        return f"Monitor: {base}"
    if nick:
        return nick
    if desc:
        return desc
    if dev_desc:
        return dev_desc
    return name


def infer_app_icon(app_name, binary):
    text = f"{app_name} {binary}".lower()
    if "spotify" in text:
        return "music_note"
    if any(b in text for b in ["firefox", "zen", "chrome", "chromium", "brave", "edge"]):
        return "language"
    if any(g in text for g in ["steam", "game", "retroarch", "heroic"]):
        return "videogame_asset"
    if any(m in text for m in ["mpv", "vlc", "celluloid", "video"]):
        return "movie"
    if any(c in text for c in ["discord", "telegram", "slack", "signal"]):
        return "chat"
    if "fluidsynth" in text or "midi" in text:
        return "piano"
    return "volume_up"


def get_audio_state():
    def_sink = get_default_sink()
    def_source = get_default_source()

    sinks_raw = []
    sources_raw = []
    inputs_raw = []

    try:
        raw = run_cmd(["pactl", "-f", "json", "list", "sinks"])
        if raw:
            sinks_raw = json.loads(raw)
    except Exception:
        pass

    try:
        raw = run_cmd(["pactl", "-f", "json", "list", "sources"])
        if raw:
            sources_raw = json.loads(raw)
    except Exception:
        pass

    try:
        raw = run_cmd(["pactl", "-f", "json", "list", "sink-inputs"])
        if raw:
            inputs_raw = json.loads(raw)
    except Exception:
        pass

    # Sinks (Outputs)
    sinks = []
    for s in sinks_raw:
        name = s.get("name", "")
        props = s.get("properties", {})
        nick = props.get("node.nick", "")
        desc = s.get("description", "")
        label = infer_sink_label(s)
        icon = infer_sink_icon(name, desc, nick)
        vol_pct = parse_volume_percent(s.get("volume"))
        muted = bool(s.get("mute", False))
        is_default = (name == def_sink)

        sinks.append({
            "id": s.get("index", 0),
            "name": name,
            "label": label,
            "description": desc,
            "nick": nick,
            "volume": vol_pct,
            "muted": muted,
            "isDefault": is_default,
            "state": s.get("state", "IDLE"),
            "icon": icon,
            "type": "output"
        })

    # Sources (Inputs)
    sources = []
    for src in sources_raw:
        name = src.get("name", "")
        props = src.get("properties", {})
        dev_class = props.get("device.class", "")
        is_monitor = (name.endswith(".monitor") or dev_class == "monitor")
        nick = props.get("node.nick", "")
        desc = src.get("description", "")
        label = infer_source_label(src, is_monitor)
        icon = infer_source_icon(name, desc, nick, is_monitor)
        vol_pct = parse_volume_percent(src.get("volume"))
        muted = bool(src.get("mute", False))
        is_default = (name == def_source)

        sources.append({
            "id": src.get("index", 0),
            "name": name,
            "label": label,
            "description": desc,
            "nick": nick,
            "volume": vol_pct,
            "muted": muted,
            "isDefault": is_default,
            "isMonitor": is_monitor,
            "state": src.get("state", "IDLE"),
            "icon": icon,
            "type": "input"
        })

    # Sink inputs (Application streams)
    apps = []
    for inp in inputs_raw:
        idx = inp.get("index", 0)
        props = inp.get("properties", {})
        app_name = props.get("application.name") or props.get("media.name") or "Application"
        binary = props.get("application.process.binary", "")
        media_name = props.get("media.name", "")
        vol_pct = parse_volume_percent(inp.get("volume"))
        muted = bool(inp.get("mute", False))
        sink_idx = inp.get("sink", 0)
        icon = infer_app_icon(app_name, binary)

        apps.append({
            "id": idx,
            "name": app_name,
            "title": media_name,
            "binary": binary,
            "sinkId": sink_idx,
            "volume": vol_pct,
            "muted": muted,
            "corked": bool(inp.get("corked", False)),
            "icon": icon
        })

    state = {
        "defaultSink": def_sink,
        "defaultSource": def_source,
        "sinks": sinks,
        "sources": sources,
        "apps": apps
    }

    # Cache result
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(state, f, indent=2)
    except Exception:
        pass

    return state


def main():
    if len(sys.argv) < 2 or sys.argv[1] == "status":
        state = get_audio_state()
        print(json.dumps(state))
        return

    cmd = sys.argv[1]

    if cmd == "set-sink" and len(sys.argv) >= 3:
        target = sys.argv[2]
        run_cmd(["pactl", "set-default-sink", target])
        print(json.dumps({"ok": True, "action": "set-sink", "target": target}))
        return

    if cmd == "set-source" and len(sys.argv) >= 3:
        target = sys.argv[2]
        run_cmd(["pactl", "set-default-source", target])
        print(json.dumps({"ok": True, "action": "set-source", "target": target}))
        return

    if cmd == "sink-volume" and len(sys.argv) >= 4:
        target = sys.argv[2]
        val = int(sys.argv[3])
        clamped = max(0, min(100, val))
        run_cmd(["pactl", "set-sink-volume", target, f"{clamped}%"])
        print(json.dumps({"ok": True, "action": "sink-volume", "target": target, "value": clamped}))
        return

    if cmd == "sink-mute" and len(sys.argv) >= 3:
        target = sys.argv[2]
        action = sys.argv[3] if len(sys.argv) >= 4 else "toggle"
        val = "toggle"
        if action in ["1", "true", "True"]:
            val = "1"
        elif action in ["0", "false", "False"]:
            val = "0"
        run_cmd(["pactl", "set-sink-mute", target, val])
        print(json.dumps({"ok": True, "action": "sink-mute", "target": target, "value": val}))
        return

    if cmd == "source-volume" and len(sys.argv) >= 4:
        target = sys.argv[2]
        val = int(sys.argv[3])
        clamped = max(0, min(100, val))
        run_cmd(["pactl", "set-source-volume", target, f"{clamped}%"])
        print(json.dumps({"ok": True, "action": "source-volume", "target": target, "value": clamped}))
        return

    if cmd == "source-mute" and len(sys.argv) >= 3:
        target = sys.argv[2]
        action = sys.argv[3] if len(sys.argv) >= 4 else "toggle"
        val = "toggle"
        if action in ["1", "true", "True"]:
            val = "1"
        elif action in ["0", "false", "False"]:
            val = "0"
        run_cmd(["pactl", "set-source-mute", target, val])
        print(json.dumps({"ok": True, "action": "source-mute", "target": target, "value": val}))
        return

    if cmd == "app-volume" and len(sys.argv) >= 4:
        target = sys.argv[2]
        val = int(sys.argv[3])
        clamped = max(0, min(100, val))
        run_cmd(["pactl", "set-sink-input-volume", str(target), f"{clamped}%"])
        print(json.dumps({"ok": True, "action": "app-volume", "target": target, "value": clamped}))
        return

    if cmd == "app-mute" and len(sys.argv) >= 3:
        target = sys.argv[2]
        action = sys.argv[3] if len(sys.argv) >= 4 else "toggle"
        val = "toggle"
        if action in ["1", "true", "True"]:
            val = "1"
        elif action in ["0", "false", "False"]:
            val = "0"
        run_cmd(["pactl", "set-sink-input-mute", str(target), val])
        print(json.dumps({"ok": True, "action": "app-mute", "target": target, "value": val}))
        return

    print(json.dumps({"error": f"Unknown command: {cmd}"}))


if __name__ == "__main__":
    main()
