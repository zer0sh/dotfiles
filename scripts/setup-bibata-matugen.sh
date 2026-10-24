#!/usr/bin/env bash
set -euo pipefail

# Setup Material Bibata Cursor with Matugen dynamic theming
# Original project & author credits:
#   Sakib Shahariar - https://github.com/SakibShahariar/material-bibata-cursor
#   Bibata Cursor artwork originally by Abdulkaiz Khatri (ful1e5)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
ICONS_DIR="$HOME/.local/share/icons"
LEGACY_ICONS_DIR="$HOME/.icons"
VERSION="v1.5.0"
BASE_URL="https://github.com/SakibShahariar/material-bibata-cursor/releases/download/${VERSION}"

mkdir -p "$ICONS_DIR" "$LEGACY_ICONS_DIR"

# Check if at least one Bibata-Material theme exists
if [ ! -d "$ICONS_DIR/Bibata-Material-Classic" ] && [ ! -d "$LEGACY_ICONS_DIR/Bibata-Material-Classic" ]; then
    echo "[INFO] Material Bibata Cursors not found in $ICONS_DIR."
    echo "[INFO] Downloading prebuilt v1.5.0 packages from SakibShahariar/material-bibata-cursor..."

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TMP_DIR"' EXIT

    # Download and extract Dark themes (+ Classic)
    echo "[INFO] Fetching Dark themes..."
    curl -sSL "${BASE_URL}/bibata-material-dark-${VERSION}.tar.gz" | tar -xz -C "$ICONS_DIR/" --strip-components=1

    # Download and extract Light themes
    echo "[INFO] Fetching Light themes..."
    curl -sSL "${BASE_URL}/bibata-material-light-${VERSION}.tar.gz" | tar -xz -C "$ICONS_DIR/" --strip-components=1

    echo "[SUCCESS] Material Bibata Cursors installed to $ICONS_DIR."
else
    echo "[INFO] Material Bibata Cursors are already installed."
fi

# Ensure default fallback cursor theme directory exists
mkdir -p "$LEGACY_ICONS_DIR/default"

# Trigger initial cursor match if wallpaper state exists
if [ -x "$DOTFILES_DIR/themes/apply-matugen.sh" ]; then
    echo "[INFO] Applying active wallpaper palette to cursor theme..."
    "$DOTFILES_DIR/themes/apply-matugen.sh" >/dev/null 2>&1 || true
fi

echo "[SUCCESS] Material Bibata Cursor integration ready."
