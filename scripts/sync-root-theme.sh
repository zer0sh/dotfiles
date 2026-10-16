#!/usr/bin/env bash
set -euo pipefail

# Script to synchronize Matugen themes for applications executed with sudo (root)
# Fully idempotent: safe to run multiple times without unintended side effects.

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run with sudo or as root: sudo $0" >&2
    exit 1
fi

# Detect actual non-root user
TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "zero")}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    echo "[ERROR] Could not resolve home directory for user '$TARGET_USER'." >&2
    exit 1
fi

THEMES_CURRENT="$TARGET_HOME/.config/themes/current"

if [ ! -d "$THEMES_CURRENT" ]; then
    echo "[ERROR] Themes store not found at '$THEMES_CURRENT'." >&2
    echo "        Run Matugen or apply-matugen.sh as your regular user first." >&2
    exit 1
fi

echo "[INFO] Checking root theme synchronization for user '$TARGET_USER'..."

# Helper function to safely create symlinks with idempotency and backup protection
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

# 1. Ensure root config directories exist
mkdir -p /root/.config/gtk-3.0 /root/.config/gtk-4.0

# 2. Settings for GTK 3 (idempotent write if missing or different)
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

# 3. Synchronize GTK 3 and GTK 4 stylesheets
safe_link "$THEMES_CURRENT/gtk-3.0.css" "/root/.config/gtk-3.0/gtk.css"
safe_link "$THEMES_CURRENT/gtk-4.0.css" "/root/.config/gtk-4.0/gtk.css"

# 4. Optional: Synchronize btop monitor theme for root
if [ -d "$TARGET_HOME/.config/btop" ]; then
    mkdir -p /root/.config/btop/themes
    safe_link "$THEMES_CURRENT/btop.theme" "/root/.config/btop/themes/matugen.theme"
    if [ -f "$TARGET_HOME/.config/btop/btop.conf" ]; then
        safe_link "$TARGET_HOME/.config/btop/btop.conf" "/root/.config/btop/btop.conf"
    fi
fi

# 5. Ensure root has traversal permissions to user themes directory
chmod o+x "$TARGET_HOME" "$TARGET_HOME/.config" "$TARGET_HOME/.config/themes" "$THEMES_CURRENT" 2>/dev/null || true

echo "[SUCCESS] Synchronization check completed cleanly."
