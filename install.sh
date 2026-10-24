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
    "themes:themes"
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

# GTK 3 & GTK 4 Matugen themes (Mitsugen-inspired clean layout)
mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0" "$HOME/.local/share/themes"
ln -sf "$CONFIG_DIR/themes/current/gtk-3.0.css" "$CONFIG_DIR/gtk-3.0/gtk.css"
ln -sf "$CONFIG_DIR/themes/current/gtk-4.0.css" "$CONFIG_DIR/gtk-4.0/gtk.css"

# Install custom-dark and custom-light base GTK themes
if [ -d "$REPO_DIR/themes/gtk" ]; then
    cp -ru "$REPO_DIR/themes/gtk/"* "$HOME/.local/share/themes/"
fi

# Clean GTK settings: hide window control buttons & set custom-dark default
for ver in gtk-3.0 gtk-4.0; do
    cat > "$CONFIG_DIR/$ver/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=custom-dark
gtk-icon-theme-name=Papirus-Matugen-Dark
gtk-cursor-theme-name=Bibata-Material-Classic
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=:
EOF
done

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.wm.preferences button-layout ":" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "custom-dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Matugen-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Material-Classic" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
fi

# Papirus Folders Matugen integration (user-level dynamic folder coloring)
if [ -f "$REPO_DIR/scripts/setup-papirus-matugen.sh" ]; then
    "$REPO_DIR/scripts/setup-papirus-matugen.sh"
fi

# Material Bibata Cursor Matugen integration (dynamic cursor theming by Sakib Shahariar)
if [ -f "$REPO_DIR/scripts/setup-bibata-matugen.sh" ]; then
    "$REPO_DIR/scripts/setup-bibata-matugen.sh"
fi

# Steam (Adwaita-for-Steam) Matugen theme - native install.py route, no Flatpak
if command -v steam >/dev/null 2>&1 || [ -d "$HOME/.steam/steam" ]; then
    echo "[INFO] Setting up Steam Matugen integration..."
    "$REPO_DIR/scripts/setup-steam-matugen.sh"
else
    echo "[NOTE] Steam not detected; skipping Matugen integration."
fi

# Optional AdwSteamGtk GUI stylesheet links (only when the GUI wrapper exists)
if command -v adwaita-steam-gtk >/dev/null 2>&1 || [ -d "$HOME/.var/app/io.github.Foldex.AdwSteamGtk" ]; then
    mkdir -p "$CONFIG_DIR/AdwSteamGtk" "$CONFIG_DIR/themes/current"
    ln -sf "$CONFIG_DIR/themes/current/steam.css" "$CONFIG_DIR/AdwSteamGtk/custom.css"
    if [ -d "$HOME/.var/app/io.github.Foldex.AdwSteamGtk" ]; then
        mkdir -p "$HOME/.var/app/io.github.Foldex.AdwSteamGtk/config/AdwSteamGtk"
        ln -sf "$CONFIG_DIR/themes/current/steam.css" "$HOME/.var/app/io.github.Foldex.AdwSteamGtk/config/AdwSteamGtk/custom.css"
    fi
fi

# Zen Browser Matugen theme (userChrome.css / userContent.css integration)
if [ -f "$HOME/.zen/profiles.ini" ] || [ -f "$HOME/.var/app/app.zen_browser.zen/.zen/profiles.ini" ]; then
    echo "[INFO] Setting up Zen Browser Matugen integration..."
    "$REPO_DIR/scripts/setup-zen-matugen.sh"
else
    echo "[NOTE] Zen Browser not detected; skipping Matugen integration."
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
    for cmd in fzf zoxide uv; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "[NOTE] '$cmd' is not installed. Consider installing it for full functionality (e.g., sudo apt install $cmd or curl -LsSf https://astral.sh/uv/install.sh | sh)."
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
