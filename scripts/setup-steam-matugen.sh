#!/usr/bin/env bash
set -euo pipefail

# Script to configure Steam dynamic Material You theming via Matugen and AdwSteamGtk
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_CURRENT="$CONFIG_DIR/themes/current"
ADW_STEAM_DIR="$CONFIG_DIR/AdwSteamGtk"
FLATPAK_ADW_DIR="$HOME/.var/app/io.github.Foldex.AdwSteamGtk/config/AdwSteamGtk"
WALLPAPER_FILE="$THEMES_CURRENT/wallpaper"

echo "[INFO] Configuring Steam integration with Matugen..."

# 1. Dependency checks
if ! command -v steam >/dev/null 2>&1; then
    echo "[WARN] steam is not installed. Ensure Steam is installed."
fi

HAS_ADW=0
if command -v adwaita-steam-gtk >/dev/null 2>&1; then
    HAS_ADW=1
elif command -v flatpak >/dev/null 2>&1 && flatpak list --app 2>/dev/null | grep -q "io.github.Foldex.AdwSteamGtk"; then
    HAS_ADW=2
fi

if [ "$HAS_ADW" -eq 0 ]; then
    echo "[WARN] AdwSteamGtk is not installed."
    echo "       Install via Flatpak: flatpak install flathub io.github.Foldex.AdwSteamGtk"
    echo "       Or from GitHub: https://github.com/Foldex/AdwSteamGtk"
fi

# 2. Ensure destination directories exist
mkdir -p "$THEMES_CURRENT"
mkdir -p "$ADW_STEAM_DIR"
if [ -d "$HOME/.var/app/io.github.Foldex.AdwSteamGtk" ]; then
    mkdir -p "$FLATPAK_ADW_DIR"
fi

# 3. Setup symlinks for AdwSteamGtk custom.css
echo "[INFO] Linking Matugen Steam theme..."
ln -sf "$THEMES_CURRENT/steam.css" "$ADW_STEAM_DIR/custom.css"
if [ -d "$HOME/.var/app/io.github.Foldex.AdwSteamGtk" ]; then
    ln -sf "$THEMES_CURRENT/steam.css" "$FLATPAK_ADW_DIR/custom.css"
fi

# 4. Generate current theme if wallpaper is known
if command -v matugen >/dev/null 2>&1 && [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER="$(cat "$WALLPAPER_FILE")"
    if [ -f "$WALLPAPER" ]; then
        echo "[INFO] Generating Steam theme from active wallpaper: $WALLPAPER"
        matugen image "$WALLPAPER" \
            --config "$CONFIG_DIR/matugen/config.toml" \
            --mode dark --source-color-index 0 --quiet || true
    fi
fi

# 5. Apply theme via AdwSteamGtk if installed
if [ "$HAS_ADW" -eq 1 ]; then
    echo "[INFO] Applying Adwaita-for-Steam theme..."
    adwaita-steam-gtk -i || true
elif [ "$HAS_ADW" -eq 2 ]; then
    echo "[INFO] Applying Adwaita-for-Steam theme via Flatpak..."
    flatpak run io.github.Foldex.AdwSteamGtk -i || true
fi

# 6. Verification
if [ -f "$THEMES_CURRENT/steam.css" ]; then
    echo "[SUCCESS] Steam theme generated at: $THEMES_CURRENT/steam.css"
    echo "[SUCCESS] Symlink active at: $ADW_STEAM_DIR/custom.css"
else
    echo "[WARN] $THEMES_CURRENT/steam.css has not been generated yet. Run matugen to populate it."
fi

echo "[INFO] Important: In AdwSteamGtk, ensure Preferences -> 'Custom CSS' is enabled."
echo "[INFO] Steam Matugen integration is ready."
