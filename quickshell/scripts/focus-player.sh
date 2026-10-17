#!/usr/bin/env bash
# focus-player.sh — Accurately focuses the active MPRIS media player application window in Hyprland

TARGET="$1"
TITLE="$2"

[ -z "$TARGET" ] && [ -z "$TITLE" ] && exit 0

TARGET_LOWER=$(echo "$TARGET" | tr '[:upper:]' '[:lower:]')

# Find exact window address via hyprctl clients -j
ADDR=$(hyprctl clients -j 2>/dev/null | python3 -c '
import sys, json
try:
    target = sys.argv[1]
    title = sys.argv[2].lower()
    clients = json.load(sys.stdin)
    found = None
    for c in clients:
        c_class = (c.get("class") or "").lower()
        c_init = (c.get("initialClass") or "").lower()
        c_title = (c.get("title") or "").lower()
        if target and (target in c_class or target in c_init):
            found = c.get("address")
            break
        if title and title in c_title:
            found = c.get("address")
            break
    if found:
        print(found)
except Exception:
    pass
' "$TARGET_LOWER" "$TITLE" 2>/dev/null)

if [ -n "$ADDR" ]; then
    hyprctl dispatch focuswindow "address:$ADDR" >/dev/null 2>&1
    exit 0
fi

# Fallback: direct class match
hyprctl dispatch focuswindow "class:$TARGET" >/dev/null 2>&1 || \
hyprctl dispatch focuswindow "class:$TARGET_LOWER" >/dev/null 2>&1 || \
hyprctl dispatch focuswindow "title:$TITLE" >/dev/null 2>&1

# Fallback 2: launch desktop app if target exists
if [ -n "$TARGET" ]; then
    gtk-launch "$TARGET" >/dev/null 2>&1 &
fi
