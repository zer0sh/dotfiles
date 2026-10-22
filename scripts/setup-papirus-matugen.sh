#!/usr/bin/env bash
set -euo pipefail

# Setup Papirus Folders with Matugen dynamic theming (no sudo required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
ICONS_DIR="$HOME/.local/share/icons"

mkdir -p "$BIN_DIR" "$ICONS_DIR"

# Install papirus-folders binary if not in PATH
if ! command -v papirus-folders >/dev/null 2>&1; then
    if [ -f "$SCRIPT_DIR/papirus-folders" ]; then
        cp "$SCRIPT_DIR/papirus-folders" "$BIN_DIR/papirus-folders"
        chmod +x "$BIN_DIR/papirus-folders"
    elif [ -f "/home/zero/Workspace/playground/papirus-folders/papirus-folders" ]; then
        cp "/home/zero/Workspace/playground/papirus-folders/papirus-folders" "$BIN_DIR/papirus-folders"
        chmod +x "$BIN_DIR/papirus-folders"
    fi
fi

# Ensure user icon directories exist so papirus-folders modifies user icons without root/sudo
if [ -d "/usr/share/icons/Papirus" ] && [ ! -d "$ICONS_DIR/Papirus" ]; then
    echo "[INFO] Copying Papirus to ~/.local/share/icons/ for passwordless color switching..."
    cp -ru /usr/share/icons/Papirus "$ICONS_DIR/"
fi

if [ -d "/usr/share/icons/Papirus-Dark" ] && [ ! -d "$ICONS_DIR/Papirus-Dark" ]; then
    echo "[INFO] Copying Papirus-Dark to ~/.local/share/icons/..."
    cp -ru /usr/share/icons/Papirus-Dark "$ICONS_DIR/"
fi

echo "[SUCCESS] Papirus folders Matugen integration ready."
