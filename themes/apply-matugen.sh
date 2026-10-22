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
    -t scheme-vibrant --contrast 0.2 \
    --mode "$MODE" --source-color-index 0 --quiet

hyprctl reload 2>/dev/null || true
pkill -SIGUSR2 waybar 2>/dev/null || true
# Alacritty watches the generated import and reloads its colors automatically.

# Keep the generated outputs in sync with the palette consumed by Quickshell.
printf '%s\n' "matugen" > "$HOME/.config/quickshell/current-theme"

# Sync GTK color-scheme and force reload of gtk.css
if [[ "$MODE" == "light" ]]; then
    TARGET_GTK_THEME="custom-light"
    TARGET_ICON_THEME="Papirus-Light"
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
else
    TARGET_GTK_THEME="custom-dark"
    TARGET_ICON_THEME="Papirus-Dark"
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

# Refresh Spicetify theme colors if active theme is matugen
if [[ -f "$HOME/.config/spicetify/config-xpui.ini" ]] && grep -q "current_theme *= *matugen" "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null; then
    spicetify apply -n 2>/dev/null || true
fi

# Refresh wallpaper thumbnails after the color/theme change has been applied.
if [[ -x "$HOME/.config/themes/update-wallpaper-cache.sh" ]]; then
    "$HOME/.config/themes/update-wallpaper-cache.sh" 2>/dev/null || true
fi
