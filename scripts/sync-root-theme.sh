#!/usr/bin/env bash
set -euo pipefail

# Script to synchronize Matugen themes for applications executed with sudo (root)
# Must be executed with sudo privileges: sudo ./sync-root-theme.sh

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

echo "[INFO] Synchronizing theme configuration for root user from '$TARGET_USER'..."

# 1. GTK 3 & GTK 4 directories for root
mkdir -p /root/.config/gtk-3.0 /root/.config/gtk-4.0

# 2. Settings for GTK 3 (force dark theme preference)
cat << 'EOF' > /root/.config/gtk-3.0/settings.ini
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
EOF
echo "[LINK] Created /root/.config/gtk-3.0/settings.ini"

# 3. Symlinks to user dynamic Matugen theme store
ln -sf "$THEMES_CURRENT/gtk-3.0.css" /root/.config/gtk-3.0/gtk.css
echo "[LINK] /root/.config/gtk-3.0/gtk.css -> $THEMES_CURRENT/gtk-3.0.css"

ln -sf "$THEMES_CURRENT/gtk-4.0.css" /root/.config/gtk-4.0/gtk.css
echo "[LINK] /root/.config/gtk-4.0/gtk.css -> $THEMES_CURRENT/gtk-4.0.css"

# 4. Optional: btop root theme link
if [ -d "$TARGET_HOME/.config/btop" ]; then
    mkdir -p /root/.config/btop/themes
    ln -sf "$THEMES_CURRENT/btop.theme" /root/.config/btop/themes/matugen.theme
    if [ -f "$TARGET_HOME/.config/btop/btop.conf" ] && [ ! -f /root/.config/btop/btop.conf ]; then
        ln -sf "$TARGET_HOME/.config/btop/btop.conf" /root/.config/btop/btop.conf
        echo "[LINK] /root/.config/btop/btop.conf -> $TARGET_HOME/.config/btop/btop.conf"
    fi
fi

# 5. Ensure root can traverse to user themes directory
chmod o+x "$TARGET_HOME" "$TARGET_HOME/.config" "$TARGET_HOME/.config/themes" "$THEMES_CURRENT" 2>/dev/null || true

echo "[SUCCESS] Root theme synchronization complete."
echo "          Applications run with 'sudo' will now share your dynamic Matugen theme."
