#!/usr/bin/env bash

# --- Script de Instalación de Dotfiles (Agnóstico y Seguro) ---

# Obtener la ruta absoluta del repositorio donde se encuentra este script
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DOT_HYPR="$REPO_DIR/hypr"
CONFIG_DIR="$HOME/.config"
TARGET_HYPR="$CONFIG_DIR/hypr"
BACKUP_HYPR="$CONFIG_DIR/hypr.bak"

echo "🚀 Iniciando despliegue de dotfiles..."

# Asegurarse de que ~/.config existe
mkdir -p "$CONFIG_DIR"

# 1. Gestión de Seguridad (Backup)
if [ -d "$TARGET_HYPR" ]; then
    if [ -L "$TARGET_HYPR" ]; then
        echo "ℹ️  Nota: $TARGET_HYPR ya es un enlace simbólico. No es necesario backup."
        # Lo eliminamos para recrearlo con la ruta actual (por si se movió el repo)
        rm "$TARGET_HYPR"
    else
        echo "📦 Creando backup de la configuración actual en $BACKUP_HYPR..."
        if [ -d "$BACKUP_HYPR" ]; then
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            BACKUP_HYPR_NEW="${BACKUP_HYPR}_${TIMESTAMP}"
            echo "⚠️  Ya existía un backup. Usando nombre: $BACKUP_HYPR_NEW"
            mv "$TARGET_HYPR" "$BACKUP_HYPR_NEW"
        else
            mv "$TARGET_HYPR" "$BACKUP_HYPR"
        fi
    fi
fi

# 2. Creación del Symlink
echo "🔗 Vinculando $TARGET_HYPR -> $DOT_HYPR"
ln -s "$DOT_HYPR" "$TARGET_HYPR"

echo "✅ ¡Instalación completada con éxito!"
echo "Tu configuración de Hyprland ahora está centralizada en: $REPO_DIR"
