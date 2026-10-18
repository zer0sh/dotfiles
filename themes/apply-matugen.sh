#!/usr/bin/env bash
set -euo pipefail

WALLPAPER="${1:-}"
MODE="${2:-}"
STATE_FILE="$HOME/.config/themes/current/wallpaper"
MODE_FILE="$HOME/.config/themes/current/mode"

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

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Wallpaper not found: ${WALLPAPER:-<empty>}" >&2
    exit 1
fi

mkdir -p "$HOME/.config/themes/current"
printf '%s\n' "$WALLPAPER" > "$STATE_FILE"
printf '%s\n' "$MODE" > "$MODE_FILE"

matugen image "$WALLPAPER" \
    --config "$HOME/.config/matugen/config.toml" \
    --mode "$MODE" --source-color-index 0 --quiet

hyprctl reload 2>/dev/null || true
pkill -SIGUSR2 waybar 2>/dev/null || true
# Alacritty watches the generated import and reloads its colors automatically.

# Keep the generated outputs in sync with the palette consumed by Quickshell.
printf '%s\n' "matugen" > "$HOME/.config/quickshell/current-theme"

# Sync GTK color-scheme and force reload of gtk.css
CURRENT_GTK_THEME="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'" || echo "Adwaita-dark")"
if [[ "$MODE" == "light" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
fi
# Toggle theme name briefly to trigger GTK stylesheet re-read in running apps
gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme "$CURRENT_GTK_THEME" 2>/dev/null || true

# Refresh Spicetify theme colors if active theme is matugen
if [[ -f "$HOME/.config/spicetify/config-xpui.ini" ]] && grep -q "current_theme *= *matugen" "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null; then
    spicetify apply -n 2>/dev/null || true
fi

# Refresh wallpaper thumbnails after the color/theme change has been applied.
if [[ -x "$HOME/.config/themes/update-wallpaper-cache.sh" ]]; then
    "$HOME/.config/themes/update-wallpaper-cache.sh" 2>/dev/null || true
fi
