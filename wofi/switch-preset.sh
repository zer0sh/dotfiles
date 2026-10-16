#!/usr/bin/env bash
# ==============================================================================
# Script de selección de presets Material Design para Wofi
# Uso: ./switch-preset.sh [card | spotlight | grid]
# ==============================================================================

set -euo pipefail

WOFI_DIR="$HOME/dotfiles/wofi"
PRESETS_DIR="$WOFI_DIR/presets"

apply_preset() {
    local preset="$1"
    local preset_path="$PRESETS_DIR/$preset"

    if [[ ! -d "$preset_path" ]]; then
        echo "Error: El preset '$preset' no existe."
        echo "Presets disponibles: card, spotlight, grid"
        exit 1
    fi

    cp "$preset_path/config" "$WOFI_DIR/config"
    cp "$preset_path/style.css" "$WOFI_DIR/style.css"
    echo "Preset '$preset' aplicado correctamente a Wofi."
}

CHOICE="${1:-}"

if [[ -z "$CHOICE" ]]; then
    echo "Selecciona un preset de Wofi (Material Design):"
    echo "  1) card      - Floating Card con cápsula de búsqueda e indicador de acento (Recomendado)"
    echo "  2) spotlight - Minimalista apaisado estilo Search Hub"
    echo "  3) grid      - Bento Grid / App Drawer en 2 columnas"
    echo ""
    read -rp "Elige una opción [1-3 o nombre]: " input
    case "$input" in
        1|card) CHOICE="material-card" ;;
        2|spotlight) CHOICE="material-spotlight" ;;
        3|grid) CHOICE="material-grid" ;;
        *) echo "Opción inválida."; exit 1 ;;
    esac
else
    case "$CHOICE" in
        card|material-card) CHOICE="material-card" ;;
        spotlight|material-spotlight) CHOICE="material-spotlight" ;;
        grid|material-grid) CHOICE="material-grid" ;;
        *)
            echo "Error: Preset desconocido '$CHOICE'."
            echo "Opciones: card, spotlight, grid"
            exit 1
            ;;
    esac
fi

apply_preset "$CHOICE"
