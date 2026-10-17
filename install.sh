#!/usr/bin/env bash

# Multi-module Dotfiles Installation Script

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_DIR="$HOME/.config"

# Applications to link into ~/.config/
# Format: "repo_folder_name:config_folder_name"
APPS=(
    "hypr:hypr"
    "waybar:waybar"
    "quickshell:quickshell"
    "kitty:kitty"
    "alacritty:alacritty"
    "wofi:wofi"
    "yazi:yazi"
    "btop:btop"
    "fastfetch:fastfetch"
    "bat:bat"
    "matugen:matugen"
)

echo "[INFO] Starting dotfiles deployment..."
mkdir -p "$CONFIG_DIR"

# Function to safely create symlinks with backups
link_config() {
    local src="$1"
    local dest="$2"
    local backup="${dest}.bak"

    if [ -d "$dest" ] || [ -f "$dest" ]; then
        if [ -L "$dest" ]; then
            rm "$dest"
        else
            echo "[BACKUP] $dest -> $backup"
            [ -e "$backup" ] && backup="${backup}_$(date +%Y%m%d_%H%M%S)"
            mv "$dest" "$backup"
        fi
    fi

    echo "[LINK] $dest -> $src"
    ln -s "$src" "$dest"
}

# Link applications into ~/.config
for item in "${APPS[@]}"; do
    IFS=":" read -r repo_folder config_folder <<< "$item"
    link_config "$REPO_DIR/$repo_folder" "$CONFIG_DIR/$config_folder"
done

# Btop Matugen theme link
if [ -d "$CONFIG_DIR/btop/themes" ]; then
    mkdir -p "$CONFIG_DIR/themes/current"
    ln -sf "$CONFIG_DIR/themes/current/btop.theme" "$CONFIG_DIR/btop/themes/matugen.theme"
fi

# GTK 3 & GTK 4 Matugen themes
mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0"
ln -sf "$CONFIG_DIR/themes/current/gtk-3.0.css" "$CONFIG_DIR/gtk-3.0/gtk.css"
ln -sf "$CONFIG_DIR/themes/current/gtk-4.0.css" "$CONFIG_DIR/gtk-4.0/gtk.css"

# Steam (AdwSteamGtk) Matugen theme
mkdir -p "$CONFIG_DIR/AdwSteamGtk" "$CONFIG_DIR/themes/current"
ln -sf "$CONFIG_DIR/themes/current/steam.css" "$CONFIG_DIR/AdwSteamGtk/custom.css"
if [ -d "$HOME/.var/app/io.github.Foldex.AdwSteamGtk" ]; then
    mkdir -p "$HOME/.var/app/io.github.Foldex.AdwSteamGtk/config/AdwSteamGtk"
    ln -sf "$CONFIG_DIR/themes/current/steam.css" "$HOME/.var/app/io.github.Foldex.AdwSteamGtk/config/AdwSteamGtk/custom.css"
fi

# Vim
if [ -d "$REPO_DIR/vim" ]; then
    echo "[INFO] Setting up Vim configuration..."
    [ -f "$REPO_DIR/vim/vimrc" ] && link_config "$REPO_DIR/vim/vimrc" "$HOME/.vimrc"
    [ -d "$REPO_DIR/vim/dot-vim" ] && link_config "$REPO_DIR/vim/dot-vim" "$HOME/.vim"

    # Debian & Wayland clipboard dependencies check
    vim_deps=()
    if ! vim --version 2>/dev/null | grep -q '\+clipboard'; then
        vim_deps+=("vim-gtk3")
    fi
    if ! command -v wl-copy >/dev/null 2>&1; then
        vim_deps+=("wl-clipboard")
    fi
    if [ ${#vim_deps[@]} -gt 0 ]; then
        echo "[NOTE] To enable system clipboard integration on Wayland (Debian), consider installing:"
        echo "       sudo apt install ${vim_deps[*]}"
    fi
fi

# Zsh
if [ -d "$REPO_DIR/zsh" ]; then
    echo "[INFO] Setting up Zsh configuration..."
    [ -f "$REPO_DIR/zsh/zshrc" ] && link_config "$REPO_DIR/zsh/zshrc" "$HOME/.zshrc"
    [ -f "$REPO_DIR/zsh/zshrc_aliases" ] && link_config "$REPO_DIR/zsh/zshrc_aliases" "$HOME/.zshrc_aliases"
    
    mkdir -p "$HOME/.zsh"
    [ -d "$REPO_DIR/zsh/prompts" ] && link_config "$REPO_DIR/zsh/prompts" "$HOME/.zsh/prompts"

    # Auto-clone lightweight plugins
    ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"
    mkdir -p "$ZSH_PLUGINS_DIR"
    PLUGINS=(
        "https://github.com/zsh-users/zsh-autosuggestions.git|zsh-autosuggestions"
        "https://github.com/zsh-users/zsh-syntax-highlighting.git|zsh-syntax-highlighting"
        "https://github.com/zsh-users/zsh-completions.git|zsh-completions"
        "https://github.com/zsh-users/zsh-history-substring-search.git|zsh-history-substring-search"
    )
    for item in "${PLUGINS[@]}"; do
        IFS="|" read -r plugin_url plugin_name <<< "$item"
        if [ ! -d "$ZSH_PLUGINS_DIR/$plugin_name" ]; then
            echo "[INFO] Downloading plugin: $plugin_name..."
            git clone --depth 1 "$plugin_url" "$ZSH_PLUGINS_DIR/$plugin_name"
        fi
    done

    # Optional utilities check
    for cmd in fzf zoxide; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "[NOTE] '$cmd' is not installed. Consider installing it for full functionality (e.g., sudo apt install $cmd)."
        fi
    done
fi

# Bat symlink for Debian/Ubuntu (batcat -> bat)
if command -v batcat >/dev/null 2>&1 && [ ! -L "$HOME/.local/bin/bat" ] && [ ! -f "$HOME/.local/bin/bat" ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    echo "[LINK] Created bat symlink: ~/.local/bin/bat -> $(command -v batcat)"
fi

# Root themes reminder
if [ -f "$REPO_DIR/scripts/sync-root-theme.sh" ]; then
    echo "[NOTE] To synchronize dynamic themes for applications launched with sudo (root):"
    echo "       sudo $REPO_DIR/scripts/sync-root-theme.sh"
fi

echo "[INFO] Installation completed successfully."
