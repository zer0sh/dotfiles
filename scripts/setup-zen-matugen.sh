#!/usr/bin/env bash
set -euo pipefail

# Script to configure Zen Browser dynamic Material You theming via Matugen.
# Templates adapted from InioX/matugen-themes (MIT): zen-userchrome.css and
# zen-usercontent.css are rendered into the active profile's chrome/ folder
# and imported by thin userChrome.css / userContent.css entry files.

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
THEMES_CURRENT="$CONFIG_DIR/themes/current"
WALLPAPER_FILE="$THEMES_CURRENT/wallpaper"
MODE_FILE="$THEMES_CURRENT/mode"
STYLE_PREF='toolkit.legacyUserProfileCustomizations.stylesheets'

echo "[INFO] Configuring Zen Browser integration with Matugen..."

# 1. Dependency checks
if ! command -v matugen >/dev/null 2>&1; then
    echo "[WARN] matugen is not installed."
    echo "       Install it from: https://github.com/InioX/matugen"
fi

# 2. Locate the Zen data directory (native and Flatpak installations)
ZEN_HOME=""
for candidate in \
    "$HOME/.zen" \
    "$HOME/.var/app/app.zen_browser.zen/.zen" \
    "$HOME/.var/app/app.zen_browser.zen/config/zen"; do
    if [ -f "$candidate/profiles.ini" ]; then
        ZEN_HOME="$candidate"
        break
    fi
done

if [ -z "$ZEN_HOME" ]; then
    echo "[ERROR] Zen Browser profile registry not found (expected $HOME/.zen/profiles.ini)."
    exit 1
fi
echo "[INFO] Zen data directory: $ZEN_HOME"

# 3. Resolve the default profile directory from profiles.ini
#    (falls back to the first registered profile when no Default=1 flag exists)
PROFILE_INFO="$(awk '
function flush() {
    if (path != "") {
        if (first_path == "") { first_path = path; first_rel = rel }
        if (def == "1") { chosen_path = path; chosen_rel = rel }
    }
}
/^\[/ { flush(); path = ""; rel = "1"; def = "0"; next }
/^Path=/ { path = substr($0, 6); next }
/^IsRelative=/ { rel = substr($0, 12); next }
/^Default=1/ { def = "1"; next }
END {
    flush()
    if (chosen_path != "") { print chosen_rel "\n" chosen_path }
    else { print first_rel "\n" first_path }
}' "$ZEN_HOME/profiles.ini")"

IS_RELATIVE="$(printf '%s\n' "$PROFILE_INFO" | sed -n '1p')"
PROFILE_PATH="$(printf '%s\n' "$PROFILE_INFO" | sed -n '2p')"

if [ -z "$PROFILE_PATH" ]; then
    echo "[ERROR] No profile found in $ZEN_HOME/profiles.ini."
    exit 1
fi

case "$IS_RELATIVE" in
    1) PROFILE_DIR="$ZEN_HOME/$PROFILE_PATH" ;;
    *) PROFILE_DIR="$PROFILE_PATH" ;;
esac

if [ ! -d "$PROFILE_DIR" ]; then
    echo "[ERROR] Profile directory does not exist: $PROFILE_DIR"
    exit 1
fi
echo "[INFO] Active profile: $PROFILE_DIR"

# 4. Ensure the chrome/ folder exists
CHROME_DIR="$PROFILE_DIR/chrome"
mkdir -p "$CHROME_DIR"

# 5. Create or patch the userChrome.css / userContent.css entry files.
#    The @import line must stay at the top: CSS ignores imports placed after rules.
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"
link_import() {
    local entry_file="$1"
    local target_name="$2"

    if [ -f "$entry_file" ] && grep -Fq "$target_name" "$entry_file"; then
        echo "[INFO] $entry_file already imports $target_name."
        return 0
    fi

    local import_line
    import_line="$(printf '@import url("%s");' "$CHROME_DIR/$target_name")"

    if [ -f "$entry_file" ]; then
        local backup="${entry_file}.${BACKUP_STAMP}.bak"
        echo "[BACKUP] $entry_file -> $backup"
        cp -p "$entry_file" "$backup"
        printf '%s\n%s\n' "$import_line" "$(cat "$entry_file")" > "$entry_file"
        echo "[UPDATE] $entry_file imports $target_name."
    else
        printf '%s\n' "$import_line" > "$entry_file"
        echo "[CREATE] $entry_file imports $target_name."
    fi
}

link_import "$CHROME_DIR/userChrome.css" "zen-userChrome.css"
link_import "$CHROME_DIR/userContent.css" "zen-userContent.css"

# 6. Enable loading of profile stylesheets (off by default since Zen 1.14).
#    user.js is re-applied at every startup, so the preference stays enabled.
USER_JS="$PROFILE_DIR/user.js"
if grep -Fq "\"$STYLE_PREF\", true" "$PROFILE_DIR/prefs.js" 2>/dev/null ||
   grep -Fq "\"$STYLE_PREF\", true" "$USER_JS" 2>/dev/null; then
    echo "[INFO] $STYLE_PREF is already enabled."
else
    printf 'user_pref("%s", true);\n' "$STYLE_PREF" >> "$USER_JS"
    echo "[INFO] Enabled $STYLE_PREF in $USER_JS."
fi

# 7. Generate the palette when a wallpaper is already known
if command -v matugen >/dev/null 2>&1 && [ -f "$WALLPAPER_FILE" ]; then
    WALLPAPER="$(cat "$WALLPAPER_FILE")"
    MODE="dark"
    if [ -f "$MODE_FILE" ]; then
        MODE="$(cat "$MODE_FILE")"
    fi
    if [ -f "$WALLPAPER" ]; then
        echo "[INFO] Generating Zen theme from active wallpaper: $WALLPAPER"
        matugen image "$WALLPAPER" \
            --config "$CONFIG_DIR/matugen/config.toml" \
            -t scheme-vibrant --contrast 0.2 \
            --mode "$MODE" --source-color-index 0 --quiet || true
    fi
fi

# 8. Verification
STATUS=0
for output in "$CHROME_DIR/zen-userChrome.css" "$CHROME_DIR/zen-userContent.css"; do
    if [ -s "$output" ]; then
        echo "[SUCCESS] Rendered: $output"
    else
        echo "[WARN] Missing or empty: $output (run matugen to render it)"
        STATUS=1
    fi
done

if [ "$STATUS" -eq 0 ]; then
    echo "[INFO] Zen Browser Matugen integration is ready."
    echo "[INFO] Restart Zen Browser completely (close every window and reopen it)"
    echo "[INFO] so the generated userChrome.css and userContent.css are reloaded."
fi

exit "$STATUS"
