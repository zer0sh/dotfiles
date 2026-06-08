#!/usr/bin/env bash

# --- Script de Instalación de Dotfiles Multimódulo ---

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$HOME/.config"

# Lista de aplicaciones a vincular en ~/.config/
# Formato: "nombre_carpeta_repo:nombre_carpeta_config"
APPS=(
    "hypr:hypr"
    "waybar:waybar"
    "quickshell:quickshell"
    "kitty:kitty"
    "wofi:wofi"
    "yazi:yazi"
    "btop:btop"
    "fastfetch:fastfetch"
    "bat:bat"
)

echo "🚀 Iniciando despliegue de dotfiles..."
mkdir -p "$CONFIG_DIR"

# Función para crear symlinks de forma segura
link_config() {
    local src="$1"
    local dest="$2"
    local backup="${dest}.bak"

    if [ -d "$dest" ] || [ -f "$dest" ]; then
        if [ -L "$dest" ]; then
            rm "$dest"
        else
            echo "📦 Backup: $dest -> $backup"
            [ -e "$backup" ] && backup="${backup}_$(date +%Y%m%d_%H%M%S)"
            mv "$dest" "$backup"
        fi
    fi

    echo "🔗 Vinculando: $dest -> $src"
    ln -s "$src" "$dest"
}

# Vincular aplicaciones de ~/.config
for item in "${APPS[@]}"; do
    IFS=":" read -r repo_folder config_folder <<< "$item"
    link_config "$REPO_DIR/$repo_folder" "$CONFIG_DIR/$config_folder"
done

# Casos especiales (fuera de ~/.config)
# Vim
if [ -d "$REPO_DIR/vim" ]; then
    # .vimrc
    [ -f "$REPO_DIR/vim/vimrc" ] && link_config "$REPO_DIR/vim/vimrc" "$HOME/.vimrc"
    # .vim directory
    [ -d "$REPO_DIR/vim/dot-vim" ] && link_config "$REPO_DIR/vim/dot-vim" "$HOME/.vim"
fi

echo "✅ ¡Instalación completada con éxito!"
