# Wofi Application Launcher

Wofi is the primary application launcher and menu runner used in this environment, configured with Material Design 3 surfaces and dynamic theming support.

---

## Architecture and Live Directory

* **Live Source of Truth:** `~/.config/wofi/` is a real physical directory on the system.
* **Repository Mirror:** `~/dotfiles/wofi/` stores the tracked version control copy.
* **Typography:** `BlexMono Nerd Font` (matching Alacritty terminal), falling back to `JetBrainsMono Nerd Font` and `monospace`.
* **Theme Integration:** The style automatically imports the current system color palette via `@import url("/home/zero/.config/themes/current/wofi.css");`.

---

## Key Configuration Parameters

The primary configuration resides in `config`:

```ini
width=640
height=500
location=center
prompt=Buscar aplicaciones...
improved=true
term=alacritty
matching=fuzzy
hide_scroll=true
insensitive=true
allow_images=true
image_size=32
allow_markup=true
no_actions=true
gtk_dark=true
style=/home/zero/.config/wofi/style.css
```

---

## Available Design Presets

Wofi includes three pre-configured Material Design 3 presets in `presets/`:

| Preset | Directory | Visual Characteristics |
| :--- | :--- | :--- |
| **Material Card** | `presets/material-card/` | Floating card with pill search bar, accent indicator, and translucent backdrop. |
| **Material Spotlight** | `presets/material-spotlight/` | Wide horizontal search hub layout inspired by macOS Spotlight. |
| **Material Grid** | `presets/material-grid/` | Bento-box style two-column application drawer. |

---

## Switching Presets

You can switch between presets at any time using the included CLI helper:

```bash
# Interactive selection
~/.config/wofi/switch-preset.sh

# Or direct selection by name:
~/.config/wofi/switch-preset.sh card
~/.config/wofi/switch-preset.sh spotlight
~/.config/wofi/switch-preset.sh grid
```

---

## Toggle Behavior in Hyprland

Wofi is invoked with `SUPER + Space`. The shortcut executes `~/.config/hypr/scripts/toggle-menu`:

* If an instance of Wofi is currently open, pressing `SUPER + Space` immediately closes it (`killall wofi`).
* If no instance is active, it launches `wofi --show drun`.
