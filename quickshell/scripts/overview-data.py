#!/usr/bin/env python3
"""
overview-data.py — Gathers Hyprland monitors, workspaces, and window geometries
for the Quickshell desktop overview & window switcher module.
Outputs JSON with normalized window layout coordinates and desktop icons.
"""

import sys
import os
import json
import glob
import subprocess
import configparser

def load_desktop_entries():
    """Build a mapping from wm_class / exec / app id to (name, icon)."""
    mapping = {}
    dirs = [
        os.path.expanduser("~/.local/share/applications"),
        "/usr/local/share/applications",
        "/usr/share/applications",
        "/var/lib/flatpak/exports/share/applications",
        os.path.expanduser("~/.local/share/flatpak/exports/share/applications")
    ]
    for d in dirs:
        if not os.path.isdir(d):
            continue
        for f in glob.glob(os.path.join(d, "*.desktop")):
            try:
                base = os.path.basename(f)[:-8].lower()
                cp = configparser.ConfigParser(interpolation=None)
                cp.read(f, encoding="utf-8")
                if "Desktop Entry" not in cp:
                    continue
                sec = cp["Desktop Entry"]
                name = sec.get("Name", "").strip()
                icon = sec.get("Icon", "").strip()
                wmclass = sec.get("StartupWMClass", "").strip().lower()
                if not icon and not name:
                    continue
                info = {"name": name or base, "icon": icon or base}
                mapping[base] = info
                if wmclass:
                    mapping[wmclass] = info
            except Exception:
                pass
    return mapping

def main():
    try:
        monitors_raw = subprocess.check_output(["hyprctl", "-j", "monitors"], timeout=2)
        monitors = json.loads(monitors_raw)
    except Exception:
        monitors = []

    try:
        workspaces_raw = subprocess.check_output(["hyprctl", "-j", "workspaces"], timeout=2)
        workspaces = json.loads(workspaces_raw)
    except Exception:
        workspaces = []

    try:
        clients_raw = subprocess.check_output(["hyprctl", "-j", "clients"], timeout=2)
        clients = json.loads(clients_raw)
    except Exception:
        clients = []

    try:
        active_raw = subprocess.check_output(["hyprctl", "-j", "activewindow"], timeout=2)
        active_window = json.loads(active_raw)
    except Exception:
        active_window = {}

    focused_mon = next((m for m in monitors if m.get("focused")), monitors[0] if monitors else None)
    mon_w = focused_mon.get("width", 1920) if focused_mon else 1920
    mon_h = focused_mon.get("height", 1200) if focused_mon else 1200
    mon_x = focused_mon.get("x", 0) if focused_mon else 0
    mon_y = focused_mon.get("y", 0) if focused_mon else 0
    active_ws_id = focused_mon.get("activeWorkspace", {}).get("id", 1) if focused_mon else 1
    active_addr = active_window.get("address", "")

    desktop_apps = load_desktop_entries()

    # Guarantee all 10 workspaces (1 to 10)
    ws_sorted = list(range(1, 11))

    ws_list = []
    flat_windows = []

    # Wallpaper path
    wall_path = ""
    wall_file = os.path.expanduser("~/.config/themes/current/wallpaper")
    if os.path.exists(wall_file):
        try:
            with open(wall_file, "r") as wf:
                wall_path = wf.read().strip()
        except Exception:
            pass

    for ws_id in ws_sorted:
        ws_clients = [
            c for c in clients
            if c.get("workspace", {}).get("id") == ws_id and c.get("mapped", True) and not c.get("hidden", False)
        ]
        # Sort clients by focusHistoryID or address
        ws_clients.sort(key=lambda x: x.get("focusHistoryID", 999))

        win_list = []
        for c in ws_clients:
            addr = c.get("address", "")
            cls = c.get("class", "")
            init_cls = c.get("initialClass", "")
            title = c.get("title", "")
            at = c.get("at", [0, 0])
            sz = c.get("size", [100, 100])

            # Relative coordinates to monitor
            rel_x = max(0, at[0] - mon_x)
            rel_y = max(0, at[1] - mon_y)
            w = max(10, sz[0])
            h = max(10, sz[1])

            # Resolve app name and icon
            lookup_keys = [cls.lower(), init_cls.lower(), cls, init_cls]
            app_info = None
            for k in lookup_keys:
                if k in desktop_apps:
                    app_info = desktop_apps[k]
                    break
            
            if app_info:
                app_name = app_info["name"]
                icon = app_info["icon"]
            else:
                app_name = cls or init_cls or "Application"
                icon = cls.lower() or "application-x-executable"

            is_focused = (addr == active_addr)

            item = {
                "address": addr,
                "title": title or app_name,
                "class": cls,
                "initialClass": init_cls,
                "appName": app_name,
                "icon": icon,
                "rel_x": rel_x,
                "rel_y": rel_y,
                "width": w,
                "height": h,
                "norm_x": min(0.95, max(0.0, rel_x / mon_w)),
                "norm_y": min(0.95, max(0.0, rel_y / mon_h)),
                "norm_w": min(1.0, max(0.05, w / mon_w)),
                "norm_h": min(1.0, max(0.05, h / mon_h)),
                "floating": c.get("floating", False),
                "fullscreen": bool(c.get("fullscreen", 0)),
                "is_focused": is_focused,
                "workspace_id": ws_id
            }
            win_list.append(item)
            flat_windows.append(item)

        ws_list.append({
            "id": ws_id,
            "name": str(ws_id),
            "is_active": (ws_id == active_ws_id),
            "window_count": len(win_list),
            "windows": win_list
        })

    # Sort flat_windows so currently focused window is first, followed by others
    flat_windows.sort(key=lambda x: (not x["is_focused"], x["workspace_id"]))

    result = {
        "monitor": {
            "name": focused_mon.get("name", "eDP-1") if focused_mon else "eDP-1",
            "width": mon_w,
            "height": mon_h,
            "aspect": mon_w / mon_h if mon_h else 1.6
        },
        "activeWorkspaceId": active_ws_id,
        "activeAddress": active_addr,
        "wallpaper": wall_path,
        "workspaces": ws_list,
        "windows": flat_windows,
        "totalWindows": len(flat_windows)
    }

    print(json.dumps(result))

if __name__ == "__main__":
    main()
