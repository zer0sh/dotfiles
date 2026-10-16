#!/usr/bin/env bash
set -euo pipefail

# Script to synchronize or clean up Matugen themes for user and root environments
# Usage: sudo ./sync-root-theme.sh [OPTIONS]

show_help() {
    cat << 'EOF'
Usage: sync-root-theme.sh [OPTIONS]

Synchronizes or cleans up dynamic Matugen themes across user and root environments.

Options:
  --sync              Synchronize root theme from active user theme (default)
  --cleanup-user      Revert user GTK3 and GTK4 configurations to default
  --cleanup-root      Revert root GTK and btop configurations to default (requires sudo)
  --cleanup, --cleanup-all
                      Revert both user and root configurations to default (requires sudo)
  -h, --help          Display this help message and exit

Examples:
  sudo ./sync-root-theme.sh                  # Synchronize root theme
  sudo ./sync-root-theme.sh --sync           # Explicit synchronize
  ./sync-root-theme.sh --cleanup-user        # Revert user theme without sudo
  sudo ./sync-root-theme.sh --cleanup-root   # Revert only root theme
  sudo ./sync-root-theme.sh --cleanup-all    # Revert all (user + root)
EOF
}

# Resolve target user and home directory
if [ "$(id -u)" -eq 0 ]; then
    TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "zero")}"
else
    TARGET_USER="$(id -un)"
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    echo "[ERROR] Could not resolve home directory for user '$TARGET_USER'." >&2
    exit 1
fi

THEMES_CURRENT="$TARGET_HOME/.config/themes/current"

# Helper function to safely create symlinks with backup protection
safe_link() {
    local src="$1"
    local dest="$2"
    local backup="${dest}.bak"

    if [ -L "$dest" ]; then
        local current_target
        current_target="$(readlink "$dest")"
        if [ "$current_target" = "$src" ]; then
            echo "[OK] Already synchronized: $dest"
            return 0
        fi
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        echo "[BACKUP] Existing file found. Backing up $dest -> $backup"
        [ -e "$backup" ] && backup="${backup}_$(date +%Y%m%d_%H%M%S)"
        mv "$dest" "$backup"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "[LINK] Linked $dest -> $src"
}

# Function to synchronize root theme
do_sync_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "[ERROR] Synchronizing root theme requires sudo or root privileges: sudo $0 --sync" >&2
        exit 1
    fi

    if [ ! -d "$THEMES_CURRENT" ]; then
        echo "[ERROR] Themes store not found at '$THEMES_CURRENT'." >&2
        echo "        Run Matugen or apply-matugen.sh as your regular user first." >&2
        exit 1
    fi

    echo "[INFO] Checking root theme synchronization for user '$TARGET_USER'..."

    mkdir -p /root/.config/gtk-3.0 /root/.config/gtk-4.0

    SETTINGS_FILE="/root/.config/gtk-3.0/settings.ini"
    EXPECTED_SETTINGS=$(cat << 'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF
)

    if [ -f "$SETTINGS_FILE" ] && [ "$(cat "$SETTINGS_FILE")" = "$EXPECTED_SETTINGS" ]; then
        echo "[OK] Already up to date: $SETTINGS_FILE"
    else
        [ -f "$SETTINGS_FILE" ] && [ ! -L "$SETTINGS_FILE" ] && cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak"
        echo "$EXPECTED_SETTINGS" > "$SETTINGS_FILE"
        echo "[WRITE] Configured $SETTINGS_FILE"
    fi

    safe_link "$THEMES_CURRENT/gtk-3.0.css" "/root/.config/gtk-3.0/gtk.css"
    safe_link "$THEMES_CURRENT/gtk-4.0.css" "/root/.config/gtk-4.0/gtk.css"

    if [ -d "$TARGET_HOME/.config/btop" ]; then
        mkdir -p /root/.config/btop/themes
        safe_link "$THEMES_CURRENT/btop.theme" "/root/.config/btop/themes/matugen.theme"
        if [ -f "$TARGET_HOME/.config/btop/btop.conf" ]; then
            safe_link "$TARGET_HOME/.config/btop/btop.conf" "/root/.config/btop/btop.conf"
        fi
    fi

    chmod o+x "$TARGET_HOME" "$TARGET_HOME/.config" "$TARGET_HOME/.config/themes" "$THEMES_CURRENT" 2>/dev/null || true
    echo "[SUCCESS] Root theme synchronization completed cleanly."
}

# Function to clean up user theme
do_cleanup_user() {
    echo "[INFO] Restoring user GTK theme to system defaults for '$TARGET_USER'..."
    local changed=0

    for css_file in "$TARGET_HOME/.config/gtk-3.0/gtk.css" "$TARGET_HOME/.config/gtk-4.0/gtk.css"; do
        if [ -L "$css_file" ] || [ -f "$css_file" ]; then
            rm -f "$css_file"
            echo "[REMOVED] $css_file"
            changed=1
        fi
        if [ -f "${css_file}.bak" ]; then
            mv "${css_file}.bak" "$css_file"
            echo "[RESTORED] $css_file from backup"
            changed=1
        fi
    done

    if [ "$changed" -eq 1 ]; then
        echo "[SUCCESS] User GTK theme restored to default."
    else
        echo "[OK] User GTK theme was already at system default."
    fi
}

# Function to clean up root theme
do_cleanup_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "[ERROR] Cleaning up root configurations requires sudo: sudo $0 --cleanup-root" >&2
        exit 1
    fi

    echo "[INFO] Restoring root theme configurations to defaults..."
    local changed=0

    for file in "/root/.config/gtk-3.0/gtk.css" "/root/.config/gtk-4.0/gtk.css" "/root/.config/btop/themes/matugen.theme" "/root/.config/btop/btop.conf"; do
        if [ -L "$file" ] || [ -f "$file" ]; then
            rm -f "$file"
            echo "[REMOVED] $file"
            changed=1
        fi
        if [ -f "${file}.bak" ]; then
            mv "${file}.bak" "$file"
            echo "[RESTORED] $file from backup"
            changed=1
        fi
    done

    if [ -f "/root/.config/gtk-3.0/settings.ini.bak" ]; then
        mv "/root/.config/gtk-3.0/settings.ini.bak" "/root/.config/gtk-3.0/settings.ini"
        echo "[RESTORED] /root/.config/gtk-3.0/settings.ini from backup"
        changed=1
    fi

    if [ "$changed" -eq 1 ]; then
        echo "[SUCCESS] Root theme configurations restored to defaults."
    else
        echo "[OK] Root configurations were already at system defaults."
    fi
}

# Parse command-line arguments
ACTION="${1:---sync}"

case "$ACTION" in
    --sync)
        do_sync_root
        ;;
    --cleanup-user)
        do_cleanup_user
        ;;
    --cleanup-root)
        do_cleanup_root
        ;;
    --cleanup|--cleanup-all)
        do_cleanup_user
        do_cleanup_root
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "[ERROR] Unknown option: $ACTION" >&2
        echo "        Run '$0 --help' for available options." >&2
        exit 1
        ;;
esac
