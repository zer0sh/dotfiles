#!/usr/bin/env bash
set -euo pipefail

THEME="${1:-md3-cobalt-night}"

THEME_DIR="$HOME/.config/themes/current"
mkdir -p "$THEME_DIR"

case "$THEME" in
  md3-cobalt-night)
    BG="#0F1117"
    TEXT="#E0E2F0"
    ACCENT="#9BBDE8"
    WARNING="#F2D479"
    CRITICAL="#F2A8B8"
    CHARGING="#86D5A0"
    BORDER_ACTIVE="9BBDE8cc"
    BORDER_INACTIVE="2E3148aa"
    SURFACE_CONTAINER="#252740"
    SURFACE_CONTAINER_HIGH="#2E3148"
    SURFACE_BRIGHT="#3A3E60"
    TEXT_SECONDARY="#8E90A8"
    KITTY_BG="#0F1117"
    KITTY_FG="#E0E2F0"
    KITTY_CURSOR="#9BBDE8"
    KITTY_SEL_BG="#1E3058"
    KITTY_SEL_FG="#E0E2F0"
    KITTY_COLOR0="#1A1C28"
    KITTY_COLOR1="#F28B82"
    KITTY_COLOR2="#6898C8"
    KITTY_COLOR3="#F2D479"
    KITTY_COLOR4="#7AA8D8"
    KITTY_COLOR5="#C090F0"
    KITTY_COLOR6="#60B8D8"
    KITTY_COLOR7="#E0E2F0"
    KITTY_COLOR8="#2E3148"
    KITTY_COLOR9="#F5A0A8"
    KITTY_COLOR10="#9BBDE8"
    KITTY_COLOR11="#F5E090"
    KITTY_COLOR12="#9BBDE8"
    KITTY_COLOR13="#D8B8F8"
    KITTY_COLOR14="#82CCEC"
    KITTY_COLOR15="#FFFFFF"
    ;;
  md3-amethyst)
    BG="#110E18"
    TEXT="#E8E0F5"
    ACCENT="#C8B0F0"
    WARNING="#F0D478"
    CRITICAL="#F5A0A8"
    CHARGING="#86D0C0"
    BORDER_ACTIVE="C8B0F0cc"
    BORDER_INACTIVE="3A3050aa"
    SURFACE_CONTAINER="#2C2440"
    SURFACE_CONTAINER_HIGH="#3A3050"
    SURFACE_BRIGHT="#504068"
    TEXT_SECONDARY="#9A90B8"
    KITTY_BG="#110E18"
    KITTY_FG="#E8E0F5"
    KITTY_CURSOR="#C8B0F0"
    KITTY_SEL_BG="#3A2870"
    KITTY_SEL_FG="#E8E0F5"
    KITTY_COLOR0="#1E1A2C"
    KITTY_COLOR1="#F5A0A8"
    KITTY_COLOR2="#9068C0"
    KITTY_COLOR3="#F0D478"
    KITTY_COLOR4="#8870C8"
    KITTY_COLOR5="#C8B0F0"
    KITTY_COLOR6="#A090D8"
    KITTY_COLOR7="#E8E0F5"
    KITTY_COLOR8="#3A3050"
    KITTY_COLOR9="#F8B8C0"
    KITTY_COLOR10="#C8B0F0"
    KITTY_COLOR11="#F8E890"
    KITTY_COLOR12="#B8A0F0"
    KITTY_COLOR13="#E0D0FF"
    KITTY_COLOR14="#D0C0F8"
    KITTY_COLOR15="#FFFFFF"
  ;;
  md3-arctic-mist)
    BG="#080F14"
    TEXT="#D8EEF5"
    ACCENT="#7ECCE8"
    WARNING="#F0D478"
    CRITICAL="#F2A8A8"
    CHARGING="#90D4A8"
    BORDER_ACTIVE="7ECCE8cc"
    BORDER_INACTIVE="1E3848aa"
    SURFACE_CONTAINER="#162838"
    SURFACE_CONTAINER_HIGH="#1E3848"
    SURFACE_BRIGHT="#2A4A60"
    TEXT_SECONDARY="#7A9AA8"
    KITTY_BG="#080F14"
    KITTY_FG="#D8EEF5"
    KITTY_CURSOR="#7ECCE8"
    KITTY_SEL_BG="#103858"
    KITTY_SEL_FG="#D8EEF5"
    KITTY_COLOR0="#101C26"
    KITTY_COLOR1="#F2A8A8"
    KITTY_COLOR2="#50A8C8"
    KITTY_COLOR3="#F0D478"
    KITTY_COLOR4="#60B0D0"
    KITTY_COLOR5="#A8A0E0"
    KITTY_COLOR6="#50A8C8"
    KITTY_COLOR7="#D8EEF5"
    KITTY_COLOR8="#1E3848"
    KITTY_COLOR9="#F8C0C0"
    KITTY_COLOR10="#7ECCE8"
    KITTY_COLOR11="#F8E890"
    KITTY_COLOR12="#7ECCE8"
    KITTY_COLOR13="#C0B8F0"
    KITTY_COLOR14="#68C8E0"
    KITTY_COLOR15="#FFFFFF"
    ;;
  md3-crimson-night)
    BG="#0A0A0C"
    TEXT="#EDEDF2"
    ACCENT="#FF2B44"
    WARNING="#F0D478"
    CRITICAL="#FF5C6C"
    CHARGING="#70DF9A"
    BORDER_ACTIVE="FF2B44cc"
    BORDER_INACTIVE="222226aa"
    SURFACE_CONTAINER="#18181C"
    SURFACE_CONTAINER_HIGH="#222226"
    SURFACE_BRIGHT="#323238"
    TEXT_SECONDARY="#9B9BA6"
    KITTY_BG="#0A0A0C"
    KITTY_FG="#EDEDF2"
    KITTY_CURSOR="#FF2B44"
    KITTY_SEL_BG="#3E0D15"
    KITTY_SEL_FG="#EDEDF2"
    KITTY_COLOR0="#18181C"
    KITTY_COLOR1="#FF2B44"
    KITTY_COLOR2="#5DC984"
    KITTY_COLOR3="#E5C07B"
    KITTY_COLOR4="#61AFEF"
    KITTY_COLOR5="#C678DD"
    KITTY_COLOR6="#56B6C2"
    KITTY_COLOR7="#EDEDF2"
    KITTY_COLOR8="#35353D"
    KITTY_COLOR9="#FF5C6E"
    KITTY_COLOR10="#7BE8A2"
    KITTY_COLOR11="#F5D68C"
    KITTY_COLOR12="#82BFFF"
    KITTY_COLOR13="#DDA0EE"
    KITTY_COLOR14="#70D4E0"
    KITTY_COLOR15="#FFFFFF"
    ;;
  custom)
    ACCENT_FILE="$HOME/.config/quickshell/custom-accent"
    if [[ -f "$ACCENT_FILE" ]]; then
      RAW_ACCENT="$(cat "$ACCENT_FILE" | tr -d '[:space:]')"
      if [[ "$RAW_ACCENT" =~ ^#[0-9a-fA-F]{6}$ ]]; then
        ACCENT="$RAW_ACCENT"
      else
        ACCENT="#FF2B44"
      fi
    else
      ACCENT="#FF2B44"
    fi

    BG="#0A0A0C"
    TEXT="#EDEDF2"
    WARNING="#F0D478"
    CRITICAL="#FF5C6C"
    CHARGING="#70DF9A"
    BORDER_ACTIVE="${ACCENT#\#}cc"
    BORDER_INACTIVE="222226aa"
    SURFACE_CONTAINER="#18181C"
    SURFACE_CONTAINER_HIGH="#222226"
    SURFACE_BRIGHT="#323238"
    TEXT_SECONDARY="#9B9BA6"
    KITTY_BG="#0A0A0C"
    KITTY_FG="#EDEDF2"
    KITTY_CURSOR="${ACCENT}"
    KITTY_SEL_BG="#2A1820"
    KITTY_SEL_FG="#EDEDF2"
    KITTY_COLOR0="#18181C"
    KITTY_COLOR1="${ACCENT}"
    KITTY_COLOR2="#5DC984"
    KITTY_COLOR3="#E5C07B"
    KITTY_COLOR4="#61AFEF"
    KITTY_COLOR5="#C678DD"
    KITTY_COLOR6="#56B6C2"
    KITTY_COLOR7="#EDEDF2"
    KITTY_COLOR8="#35353D"
    KITTY_COLOR9="${ACCENT}"
    KITTY_COLOR10="#7BE8A2"
    KITTY_COLOR11="#F5D68C"
    KITTY_COLOR12="#82BFFF"
    KITTY_COLOR13="#DDA0EE"
    KITTY_COLOR14="#70D4E0"
    KITTY_COLOR15="#FFFFFF"
    ;;
  cyberpunk)
    BG="#0B0A14"
    TEXT="#F6EFFF"
    ACCENT="#00F5D4"
    WARNING="#FFD166"
    CRITICAL="#FF4D8D"
    CHARGING="#B8FF6A"
    BORDER_ACTIVE="00F5D4cc"
    BORDER_INACTIVE="21183Aaa"
    SURFACE_CONTAINER="#21183A"
    SURFACE_CONTAINER_HIGH="#302252"
    SURFACE_BRIGHT="#49326B"
    TEXT_SECONDARY="#BBA9D1"
    KITTY_BG="#0B0A14"
    KITTY_FG="#F6EFFF"
    KITTY_CURSOR="#00F5D4"
    KITTY_SEL_BG="#3A165C"
    KITTY_SEL_FG="#FFD6FF"
    KITTY_COLOR0="#141126"
    KITTY_COLOR1="#FF4D8D"
    KITTY_COLOR2="#B8FF6A"
    KITTY_COLOR3="#FFD166"
    KITTY_COLOR4="#00B4D8"
    KITTY_COLOR5="#FF4DDA"
    KITTY_COLOR6="#00F5D4"
    KITTY_COLOR7="#F6EFFF"
    KITTY_COLOR8="#302252"
    KITTY_COLOR9="#FF85B3"
    KITTY_COLOR10="#D0FF9C"
    KITTY_COLOR11="#FFE09A"
    KITTY_COLOR12="#65FFF0"
    KITTY_COLOR13="#FF9AE8"
    KITTY_COLOR14="#70EFFF"
    KITTY_COLOR15="#FFFFFF"
    ;;
  *)
    echo "Unknown theme: $THEME"
    exit 1
    ;;
esac

# Helper: convert #RRGGBB to "R, G, B"
hex_to_rgb() {
    local hex="${1#\#}"
    printf "%d, %d, %d" "0x${hex:0:2}" "0x${hex:2:2}" "0x${hex:4:2}"
}

# A) Write the centralized Waybar palette.
cat > "$THEME_DIR/waybar.css" << CSSEOF
/* Auto-generated by apply-theme.sh — do not edit */
@define-color bg ${BG};
@define-color text ${TEXT};
@define-color accent ${ACCENT};
@define-color warning ${WARNING};
@define-color critical ${CRITICAL};
@define-color charging ${CHARGING};
CSSEOF
pkill -SIGUSR2 waybar || true

# B) Write the centralized Wofi palette.
cat > "$THEME_DIR/wofi.css" << WOFIEOF
/* Generated by apply-theme.sh — do not edit */
@define-color bg_panel ${BG};
@define-color bg_input ${SURFACE_CONTAINER};
@define-color bg_selection ${ACCENT};
@define-color text ${TEXT};
@define-color text_secondary ${TEXT_SECONDARY};
@define-color text_selection ${BG};
@define-color outline ${SURFACE_BRIGHT};
WOFIEOF

# C) Write the centralized Hyprlock palette.
cat > "$THEME_DIR/hyprlock.conf" << HYPRLOCKEOF
# Generated by apply-theme.sh — do not edit
\$textColor = rgb(${TEXT#\#})
\$textColorHex = ${TEXT#\#}
\$textColorDanger = rgb(${CRITICAL#\#})
\$bgColorSecondary = rgb(${SURFACE_CONTAINER#\#})
\$accentColorPurple = rgb(${ACCENT#\#})
\$accentColorPurpleHex = ${ACCENT#\#}
\$accentColorAttention = rgb(${WARNING#\#})
HYPRLOCKEOF

# D) Apply Kitty colors (persisted for new windows)
KITTY_COLORS_FILE="$THEME_DIR/kitty.conf"
cat > "$KITTY_COLORS_FILE" << KITTYEOF
background ${KITTY_BG}
foreground ${KITTY_FG}
cursor ${KITTY_CURSOR}
selection_background ${KITTY_SEL_BG}
selection_foreground ${KITTY_SEL_FG}
color0 ${KITTY_COLOR0}
color1 ${KITTY_COLOR1}
color2 ${KITTY_COLOR2}
color3 ${KITTY_COLOR3}
color4 ${KITTY_COLOR4}
color5 ${KITTY_COLOR5}
color6 ${KITTY_COLOR6}
color7 ${KITTY_COLOR7}
color8 ${KITTY_COLOR8}
color9 ${KITTY_COLOR9}
color10 ${KITTY_COLOR10}
color11 ${KITTY_COLOR11}
color12 ${KITTY_COLOR12}
color13 ${KITTY_COLOR13}
color14 ${KITTY_COLOR14}
color15 ${KITTY_COLOR15}
KITTYEOF
# Note: kitty @ set-colors is omitted to prevent 10s socket timeouts when remote control socket is absent.

# E) Write the Alacritty palette consumed by ~/.config/alacritty/alacritty.toml.
ALACRITTY_COLORS_FILE="$THEME_DIR/alacritty.toml"
cat > "$ALACRITTY_COLORS_FILE" << ALACRITTYEOF
# Generated by apply-theme.sh — do not edit.

[colors.primary]
background = '${KITTY_BG}'
foreground = '${KITTY_FG}'

[colors.cursor]
cursor = '${KITTY_CURSOR}'
text = '${KITTY_BG}'

[colors.selection]
background = '${KITTY_SEL_BG}'
text = '${KITTY_SEL_FG}'

[colors.normal]
black = '${KITTY_COLOR0}'
red = '${KITTY_COLOR1}'
green = '${KITTY_COLOR2}'
yellow = '${KITTY_COLOR3}'
blue = '${KITTY_COLOR4}'
magenta = '${KITTY_COLOR5}'
cyan = '${KITTY_COLOR6}'
white = '${KITTY_COLOR7}'

[colors.bright]
black = '${KITTY_COLOR8}'
red = '${KITTY_COLOR9}'
green = '${KITTY_COLOR10}'
yellow = '${KITTY_COLOR11}'
blue = '${KITTY_COLOR12}'
magenta = '${KITTY_COLOR13}'
cyan = '${KITTY_COLOR14}'
white = '${KITTY_COLOR15}'
ALACRITTYEOF

# F) Apply Hyprland border colors
hyprctl keyword general:col.active_border "rgba(${BORDER_ACTIVE})" 2>/dev/null || true
hyprctl keyword general:col.inactive_border "rgba(${BORDER_INACTIVE})" 2>/dev/null || true

# G) Write Rofi launcher colors (legacy)
if [[ -d "$HOME/.config/rofi" ]]; then
  mkdir -p "$HOME/.config/rofi/themes"
  cat > "$HOME/.config/rofi/themes/colors.rasi" << ROFIEOF
* {
    bg-panel:         rgba($(hex_to_rgb "$BG"), 80%);
    bg-container:     rgba($(hex_to_rgb "$SURFACE_CONTAINER"), 80%);
    bg-container-hi:  ${SURFACE_CONTAINER_HIGH};
    bg-bright:        ${SURFACE_BRIGHT};
    accent:           ${ACCENT};
    accent-dim:       rgba($(hex_to_rgb "$ACCENT"), 18%);
    text-primary:     ${TEXT};
    text-secondary:   ${TEXT_SECONDARY};
    separator-line:   rgba($(hex_to_rgb "$TEXT"), 10%);
}
ROFIEOF
fi

# H) Write GTK 3 and GTK 4 / Libadwaita stylesheets
for gtk_out in "$THEME_DIR/gtk-3.0.css" "$THEME_DIR/gtk-4.0.css"; do
cat > "$gtk_out" << GTKEOF
/* Auto-generated by apply-theme.sh — do not edit */
@define-color accent_color ${ACCENT};
@define-color accent_bg_color ${ACCENT};
@define-color accent_fg_color ${BG};

@define-color destructive_color ${CRITICAL};
@define-color destructive_bg_color ${CRITICAL};
@define-color destructive_fg_color #ffffff;

@define-color success_color ${CHARGING};
@define-color success_bg_color ${CHARGING};
@define-color success_fg_color ${BG};

@define-color warning_color ${WARNING};
@define-color warning_bg_color ${WARNING};
@define-color warning_fg_color ${BG};

@define-color error_color ${CRITICAL};
@define-color error_bg_color ${CRITICAL};
@define-color error_fg_color #ffffff;

@define-color window_bg_color ${BG};
@define-color window_fg_color ${TEXT};

@define-color view_bg_color ${BG};
@define-color view_fg_color ${TEXT};

@define-color headerbar_bg_color @window_bg_color;
@define-color headerbar_fg_color @window_fg_color;
@define-color headerbar_border_color transparent;
@define-color headerbar_backdrop_color @window_bg_color;
@define-color headerbar_shade_color rgba(0, 0, 0, 0.04);

@define-color card_bg_color ${SURFACE_CONTAINER};
@define-color card_fg_color ${TEXT};
@define-color card_shade_color rgba(0, 0, 0, 0.05);

@define-color dialog_bg_color ${SURFACE_CONTAINER_HIGH};
@define-color dialog_fg_color ${TEXT};

@define-color popover_bg_color ${SURFACE_CONTAINER_HIGH};
@define-color popover_fg_color ${TEXT};

@define-color shade_color rgba(0, 0, 0, 0.07);
@define-color scrollbar_outline_color ${SURFACE_BRIGHT};

@define-color theme_bg_color @window_bg_color;
@define-color theme_fg_color @window_fg_color;
@define-color theme_base_color @view_bg_color;
@define-color theme_text_color @view_fg_color;
@define-color theme_selected_bg_color @accent_bg_color;
@define-color theme_selected_fg_color @accent_fg_color;
@define-color borders ${SURFACE_CONTAINER_HIGH};

windowcontrols,
headerbar windowcontrols,
headerbar .titlebutton,
headerbar button.titlebutton {
    min-width: 0;
    min-height: 0;
    padding: 0;
    margin: 0;
    opacity: 0;
}

headerbar, .titlebar, actionbar {
    background-color: @headerbar_bg_color;
    border-bottom: none;
    box-shadow: none;
}
GTKEOF
done

# Briefly trigger gsettings to signal GTK apps
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
gsettings set org.gnome.desktop.interface gtk-theme 'custom-dark' 2>/dev/null || true


