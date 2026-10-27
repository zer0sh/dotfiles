#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WALLPAPER="${1:-}"
MODE="${2:-}"
TYPE="${3:-}"
STATE_FILE="$HOME/.config/themes/current/wallpaper"
MODE_FILE="$HOME/.config/themes/current/mode"
TYPE_FILE="$HOME/.config/themes/current/scheme_type"

if [[ -z "$WALLPAPER" && -f "$STATE_FILE" ]]; then
    WALLPAPER="$(<"$STATE_FILE")"
fi

if [[ -z "$MODE" ]]; then
    if [[ -f "$MODE_FILE" ]]; then
        MODE="$(<"$MODE_FILE")"
    else
        MODE="dark"
    fi
fi

if [[ -z "$TYPE" ]]; then
    if [[ -f "$TYPE_FILE" ]]; then
        TYPE="$(<"$TYPE_FILE")"
    else
        TYPE="scheme-vibrant"
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Wallpaper not found: ${WALLPAPER:-<empty>}" >&2
    exit 1
fi

mkdir -p "$HOME/.config/themes/current"
printf '%s\n' "$WALLPAPER" > "$STATE_FILE"
printf '%s\n' "$MODE" > "$MODE_FILE"
printf '%s\n' "$TYPE" > "$TYPE_FILE"

matugen image "$WALLPAPER" \
    --config "$HOME/.config/matugen/config.toml" \
    -t "$TYPE" --contrast 0.2 \
    --mode "$MODE" --source-color-index 0 --quiet

hyprctl reload 2>/dev/null || true
pkill -SIGUSR2 waybar 2>/dev/null || true
# Alacritty watches the generated import and reloads its colors automatically.

# Keep the generated outputs in sync with the palette consumed by Quickshell.
printf '%s\n' "matugen" > "$HOME/.config/quickshell/current-theme"

# Sync Material Bibata cursor with active palette (SakibShahariar/material-bibata-cursor)
TARGET_CURSOR_THEME="Bibata-Material-Classic"
PALETTE_FILE="$HOME/.config/themes/current/palette.json"
COLOR_MATCH_SCRIPT="$SCRIPT_DIR/color_match.py"
BIBATA_THEMES_DEF="$SCRIPT_DIR/bibata-themes.json"

if [[ -f "$PALETTE_FILE" && -f "$COLOR_MATCH_SCRIPT" && -f "$BIBATA_THEMES_DEF" ]]; then
    PRIMARY_HEX="$(jq -r '.primary // empty' "$PALETTE_FILE" 2>/dev/null || true)"
    if [[ -n "$PRIMARY_HEX" ]]; then
        MATCHED_BIBATA="$(python3 "$COLOR_MATCH_SCRIPT" "$PRIMARY_HEX" "$BIBATA_THEMES_DEF" 2>/dev/null || true)"
        if [[ -n "$MATCHED_BIBATA" ]]; then
            if [[ "$MODE" == "light" && "$MATCHED_BIBATA" != "Classic" ]]; then
                TARGET_CURSOR_THEME="Bibata-Material-${MATCHED_BIBATA}-Light"
            else
                TARGET_CURSOR_THEME="Bibata-Material-${MATCHED_BIBATA}"
            fi
        fi
    fi
fi
printf '%s\n' "$TARGET_CURSOR_THEME" > "$HOME/.config/themes/current/cursor-theme"

# Apply cursor to Hyprland and GNOME/GTK
hyprctl setcursor "$TARGET_CURSOR_THEME" 24 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme "$TARGET_CURSOR_THEME" 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true

# Update XCursor fallback configuration
mkdir -p "$HOME/.icons/default"
cat > "$HOME/.icons/default/index.theme" << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$TARGET_CURSOR_THEME
EOF

# Sync GTK color-scheme and force reload of gtk.css
if [[ "$MODE" == "light" ]]; then
    TARGET_GTK_THEME="custom-light"
    TARGET_ICON_THEME="Papirus-Matugen-Light"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
else
    TARGET_GTK_THEME="custom-dark"
    TARGET_ICON_THEME="Papirus-Matugen-Dark"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi
gsettings set org.gnome.desktop.wm.preferences button-layout ":" 2>/dev/null || true
# Update GTK settings.ini files
for ver in gtk-3.0 gtk-4.0; do
    mkdir -p "$HOME/.config/$ver"
    cat > "$HOME/.config/$ver/settings.ini" << EOF
[Settings]
gtk-theme-name=$TARGET_GTK_THEME
gtk-icon-theme-name=$TARGET_ICON_THEME
gtk-cursor-theme-name=$TARGET_CURSOR_THEME
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=$([[ "$MODE" == "light" ]] && echo "0" || echo "1")
gtk-decoration-layout=:
EOF
done

# Toggle theme name briefly to trigger GTK stylesheet re-read in running apps
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "$TARGET_GTK_THEME" 2>/dev/null || true
# Toggle icon theme briefly to trigger folder color re-read in running apps
gsettings set org.gnome.desktop.interface icon-theme 'Adwaita' 2>/dev/null || true
gsettings set org.gnome.desktop.interface icon-theme "$TARGET_ICON_THEME" 2>/dev/null || true

# Refresh Spicetify theme colors in background if active theme is matugen
SPICETIFY_BIN="$(which spicetify 2>/dev/null || echo "$HOME/.spicetify/spicetify")"
if [[ -x "$SPICETIFY_BIN" ]] && [[ -f "$HOME/.config/spicetify/config-xpui.ini" ]] && grep -q "current_theme *= *matugen" "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null; then
    (
        "$SPICETIFY_BIN" apply -n 2>/dev/null || true
        # If Spotify is currently open in Hyprland, reload its interface live without restarting
        if command -v hyprctl >/dev/null 2>&1 && hyprctl clients 2>/dev/null | grep -q "class: Spotify"; then
            hyprctl dispatch sendshortcut "CTRL SHIFT, R, class:^(Spotify)$" 2>/dev/null || true
        fi
    ) &
fi

# Refresh wallpaper thumbnails after the color/theme change has been applied.
if [[ -x "$HOME/.config/themes/update-wallpaper-cache.sh" ]]; then
    "$HOME/.config/themes/update-wallpaper-cache.sh" 2>/dev/null || true
fi
