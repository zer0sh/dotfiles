#!/usr/bin/env bash
# Genera (o refresca) miniaturas en ~/.cache/wallpapers para el selector de
# wallpapers de Quickshell. Se ejecuta tras aplicar un cambio de color/tema.
set -euo pipefail

SRC_DIR="${1:-/home/zero/Pictures/walls/}"
CACHE_DIR="${CACHE_DIR:-$HOME/.cache/wallpapers}"

mkdir -p "$CACHE_DIR"

if command -v magick >/dev/null 2>&1; then
    find "$SRC_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.gif' -o -iname '*.bmp' -o -iname '*.webp' \) -print0 \
    | while IFS= read -r -d '' img; do
        base="$(basename "$img")"
        thumb="$CACHE_DIR/$base.jpg"
        if [[ ! -f "$thumb" || "$img" -nt "$thumb" ]]; then
            magick "$img" -thumbnail 200x -strip "$thumb" 2>/dev/null || true
        fi
    done
fi
