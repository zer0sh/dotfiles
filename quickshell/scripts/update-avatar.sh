#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-}"

if [[ -z "$FILE" ]]; then
    FILE="$(zenity --file-selection --title="Select Profile Picture" --file-filter="Images (*.png, *.jpg, *.jpeg, *.webp) | *.png *.jpg *.jpeg *.webp" 2>/dev/null || true)"
fi

if [[ -n "$FILE" && -f "$FILE" ]]; then
    CONFIG_DIR="$HOME/.config/quickshell"
    mkdir -p "$CONFIG_DIR"

    # Copy to system standard ~/.face
    cp -f "$FILE" "$HOME/.face"
    chmod 644 "$HOME/.face" 2>/dev/null || true

    # Also keep a copy in quickshell config directory
    cp -f "$FILE" "$CONFIG_DIR/avatar.png" 2>/dev/null || true

    printf '%s\n' "$HOME/.face"
fi
