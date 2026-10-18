#!/usr/bin/env bash
set -euo pipefail

# Configure Steam dynamic Material You theming via Matugen and the native
# Adwaita-for-Steam installer (python3 only, no Flatpak and no GUI wrapper).

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_CURRENT="$CONFIG_DIR/themes/current"
WALLPAPER_FILE="$THEMES_CURRENT/wallpaper"
MODE_FILE="$THEMES_CURRENT/mode"
ADW_REPO="$HOME/.local/share/Adwaita-for-Steam"
ADW_URL="https://github.com/Foldex/Adwaita-for-Steam.git"
ADW_CUSTOM="$ADW_REPO/custom/custom.css"
STEAM_UI="$HOME/.local/share/Steam/steamui"

echo "[INFO] Configuring Steam integration with Matugen (native install.py route)..."

# 1. Dependency checks
if ! command -v steam >/dev/null 2>&1 && [ ! -d "$HOME/.steam/steam" ]; then
    echo "[WARN] Steam was not detected. The theme will be injected once Steam is installed."
fi
if ! command -v python3 >/dev/null 2>&1; then
    echo "[ERROR] python3 is required to run the Adwaita-for-Steam installer." >&2
    exit 1
fi
if ! command -v git >/dev/null 2>&1; then
    echo "[ERROR] git is required to clone the Adwaita-for-Steam installer." >&2
    exit 1
fi

# 2. Clone the installer once (idempotent)
if [ ! -f "$ADW_REPO/install.py" ]; then
    echo "[INFO] Cloning Adwaita-for-Steam into $ADW_REPO..."
    git clone --depth 1 "$ADW_URL" "$ADW_REPO"
fi

# 3. Link the generated palette as the installer custom stylesheet.
#    install.py dereferences the symlink while staging, so Steam always
#    receives the current palette on every run.
echo "[INFO] Linking Matugen Steam theme..."
mkdir -p "$THEMES_CURRENT" "$ADW_REPO/custom"
ln -sf "$THEMES_CURRENT/steam.css" "$ADW_CUSTOM"

# 4. Generate the palette from the active wallpaper (same flags as apply-matugen.sh)
if command -v matugen >/dev/null 2>&1 && [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER="$(<"$WALLPAPER_FILE")"
    MODE="dark"
    if [ -f "$MODE_FILE" ]; then
        MODE="$(<"$MODE_FILE")"
    fi
    if [ -f "$WALLPAPER" ]; then
        echo "[INFO] Generating Steam theme from active wallpaper: $WALLPAPER"
        matugen image "$WALLPAPER" \
            --config "$CONFIG_DIR/matugen/config.toml" \
            -t scheme-vibrant --contrast 0.2 \
            --mode "$MODE" --source-color-index 0 --quiet || true
    fi
fi

# 5. Inject the theme into the Steam client (idempotent)
if [ -f "$THEMES_CURRENT/steam.css" ]; then
    echo "[INFO] Applying Adwaita-for-Steam theme into Steam..."
    ( cd "$ADW_REPO" && python3 install.py --custom-css -t normal ) || \
        echo "[WARN] install.py reported an error. It can be re-run safely."
else
    echo "[WARN] $THEMES_CURRENT/steam.css has not been generated yet. Run matugen to populate it."
fi

# 6. Verification
if grep -q "custom/custom.css" "$STEAM_UI/libraryroot.custom.css" 2>/dev/null; then
    echo "[SUCCESS] Steam theme injected: steamui/libraryroot.custom.css imports custom/custom.css"
else
    echo "[WARN] Steam injection not detected yet (the Steam client creates its CSS entry points on first run)."
fi
echo "[SUCCESS] Palette store: $THEMES_CURRENT/steam.css"
echo "[SUCCESS] Installer link: $ADW_CUSTOM"
echo "[INFO] Restart Steam completely to load the refreshed theme."
echo "[INFO] Steam Matugen integration is ready."
