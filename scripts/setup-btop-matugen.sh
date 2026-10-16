#!/usr/bin/env bash
set -euo pipefail

# Script to configure btop dynamic Material You theming via Matugen
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_CURRENT="$CONFIG_DIR/themes/current"
BTOP_THEMES_DIR="$CONFIG_DIR/btop/themes"
WALLPAPER_FILE="$THEMES_CURRENT/wallpaper"

echo "[INFO] Configuring btop integration with Matugen..."

# 1. Dependency checks
if ! command -v btop >/dev/null 2>&1; then
    echo "[WARN] btop is not installed. You can install it with: sudo apt install btop"
fi

if ! command -v matugen >/dev/null 2>&1; then
    echo "[WARN] matugen is not installed. Ensure matugen is available in your PATH."
fi

# 2. Ensure destination directories exist
mkdir -p "$THEMES_CURRENT"
mkdir -p "$BTOP_THEMES_DIR"

# 3. Setup symlink for btop theme
echo "[INFO] Linking Matugen btop theme..."
ln -sf "$THEMES_CURRENT/btop.theme" "$BTOP_THEMES_DIR/matugen.theme"

# 4. Generate current theme if wallpaper is known
if command -v matugen >/dev/null 2>&1 && [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER="$(cat "$WALLPAPER_FILE")"
    if [ -f "$WALLPAPER" ]; then
        echo "[INFO] Generating btop theme from active wallpaper: $WALLPAPER"
        matugen image "$WALLPAPER" \
            --config "$CONFIG_DIR/matugen/config.toml" \
            --mode dark --source-color-index 0 --quiet || true
    fi
elif [ -f "$CONFIG_DIR/themes/apply-matugen.sh" ]; then
    echo "[INFO] Sourcing current theme via apply-matugen.sh..."
    bash "$CONFIG_DIR/themes/apply-matugen.sh" || true
fi

# 5. Verification
if [ -f "$THEMES_CURRENT/btop.theme" ]; then
    echo "[SUCCESS] btop theme generated at: $THEMES_CURRENT/btop.theme"
    echo "[SUCCESS] Symlink active at: $BTOP_THEMES_DIR/matugen.theme"
else
    echo "[WARN] $THEMES_CURRENT/btop.theme has not been generated yet. Run matugen to populate it."
fi

echo "[INFO] btop Matugen integration is ready."
