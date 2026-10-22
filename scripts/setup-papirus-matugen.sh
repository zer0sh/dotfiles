#!/usr/bin/env bash
set -euo pipefail

# Setup Papirus Folders with Matugen dynamic theming (custom user themes, no sudo required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
ICONS_DIR="$HOME/.local/share/icons"

mkdir -p "$BIN_DIR" "$ICONS_DIR"

# Install papirus-folders binary if not in PATH
if ! command -v papirus-folders >/dev/null 2>&1; then
    if [ -f "$SCRIPT_DIR/papirus-folders" ]; then
        cp "$SCRIPT_DIR/papirus-folders" "$BIN_DIR/papirus-folders"
        chmod +x "$BIN_DIR/papirus-folders"
    fi
fi

# Create dedicated user-space themes that GTK prioritizes without colliding with /usr/share/
setup_user_theme() {
    local src_name="$1"
    local dst_name="$2"
    local inherits="$3"

    if [ -d "/usr/share/icons/$src_name" ] && [ ! -d "$ICONS_DIR/$dst_name" ]; then
        echo "[INFO] Creating user icon theme $dst_name from $src_name..."
        cp -r "/usr/share/icons/$src_name" "$ICONS_DIR/$dst_name"
        sed -i "s/^Name=.*/Name=$dst_name/" "$ICONS_DIR/$dst_name/index.theme"
        sed -i "s/^Inherits=.*/Inherits=$inherits/" "$ICONS_DIR/$dst_name/index.theme"
        gtk-update-icon-cache -f "$ICONS_DIR/$dst_name" 2>/dev/null || true
    fi
}

setup_user_theme "Papirus" "Papirus-Matugen" "Papirus,breeze,hicolor"
setup_user_theme "Papirus-Dark" "Papirus-Matugen-Dark" "Papirus-Dark,Papirus,breeze-dark,hicolor"
setup_user_theme "Papirus-Light" "Papirus-Matugen-Light" "Papirus-Light,Papirus,breeze,hicolor"

echo "[SUCCESS] Papirus-Matugen user icon themes initialized."
