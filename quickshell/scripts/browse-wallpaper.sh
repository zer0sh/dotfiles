#!/usr/bin/env bash
set -euo pipefail

DEST_DIR="$HOME/Pictures/walls"
mkdir -p "$DEST_DIR"

FILE="$(zenity --file-selection --title="Seleccionar Fondo de Pantalla" --file-filter="Imágenes (*.jpg, *.jpeg, *.png, *.webp, *.bmp, *.gif) | *.jpg *.jpeg *.png *.webp *.bmp *.gif" 2>/dev/null || true)"

if [[ -n "$FILE" && -f "$FILE" ]]; then
    filename="$(basename "$FILE")"
    dest="$DEST_DIR/$filename"
    if [[ "$FILE" != "$dest" ]]; then
        cp "$FILE" "$dest"
    fi
    "$HOME/.config/themes/update-wallpaper-cache.sh" "$DEST_DIR" >/dev/null 2>&1 || true
    printf '%s\n' "$dest"
fi
