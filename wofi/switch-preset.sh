#!/usr/bin/env bash
# ==============================================================================
# Script de selección de presets Material Design para Wofi
# Uso: ./switch-preset.sh [card | spotlight | grid]
# ==============================================================================

set -euo pipefail

LIVE_DIR="$HOME/.config/wofi"
REPO_DIR="$HOME/dotfiles/wofi"

# Directorio base de presets (preferir LIVE_DIR si existe, sino REPO_DIR)
if [[ -d "$LIVE_DIR/presets" ]]; then
    PRESETS_DIR="$LIVE_DIR/presets"
elif [[ -d "$REPO_DIR/presets" ]]; then
    PRESETS_DIR="$REPO_DIR/presets"
else
    echo "Error: No se encontró el directorio de presets."
    exit 1
fi

apply_preset() {
    local preset="$1"
    local preset_path="$PRESETS_DIR/$preset"

    if [[ ! -d "$preset_path" ]]; then
        echo "Error: El preset '$preset' no existe."
        echo "Presets disponibles: card, spotlight, grid"
        exit 1
    fi

    # 1. Aplicar al directorio en vivo
    mkdir -p "$LIVE_DIR"
    cp "$preset_path/config" "$LIVE_DIR/config"
    cp "$preset_path/style.css" "$LIVE_DIR/style.css"
    echo "Preset '$preset' aplicado a $LIVE_DIR"

    # 2. Sincronizar al repositorio de dotfiles si es un directorio distinto
    if [[ -d "$REPO_DIR" && "$LIVE_DIR" != "$REPO_DIR" ]]; then
        mkdir -p "$REPO_DIR"
        cp "$preset_path/config" "$REPO_DIR/config"
        cp "$preset_path/style.css" "$REPO_DIR/style.css"
        echo "Sincronizado con $REPO_DIR"
    fi

    # 3. Cerrar instancia activa de Wofi para que cargue la nueva configuración al reabrir
    if pidof wofi >/dev/null 2>&1; then
        killall wofi
    fi
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
        1|card|material-card) CHOICE="material-card" ;;
        2|spotlight|material-spotlight) CHOICE="material-spotlight" ;;
        3|grid|material-grid) CHOICE="material-grid" ;;
        *) echo "Opción inválida."; exit 1 ;;
    esac
else
    case "$CHOICE" in
        1|card|material-card) CHOICE="material-card" ;;
        2|spotlight|material-spotlight) CHOICE="material-spotlight" ;;
        3|grid|material-grid) CHOICE="material-grid" ;;
        *)
            echo "Error: Preset desconocido '$CHOICE'."
            echo "Opciones: card, spotlight, grid"
            exit 1
            ;;
    esac
fi

apply_preset "$CHOICE"
