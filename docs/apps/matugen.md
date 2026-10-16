# Matugen Dynamic Theming Engine

Matugen is the Material You (Material Design 3) color palette generator used in this desktop environment. It extracts harmonic color palettes from wallpaper images and propagates them to all active UI components through dynamic templates.

---

## Architectural Role and Store

* **Engine Configuration:** `~/.config/matugen/config.toml` (version-controlled in `~/dotfiles/matugen/config.toml`).
* **Template Repository:** `~/.config/matugen/templates/` contains component-specific template files.
* **Central Theme Store:** Output files are rendered directly into `~/.config/themes/current/`, which acts as the single source of truth for the entire desktop.

```
Wallpaper Image (.png / .jpg)
          |
          v
   [ matugen image ]
          |
          v  (processes ~/.config/matugen/templates/)
~/.config/themes/current/
   ├── alacritty.toml  --> read by ~/.config/alacritty/alacritty.toml
   ├── wofi.css        --> imported by ~/.config/wofi/style.css
   ├── waybar.css      --> imported by ~/.config/waybar/colors.css
   ├── kitty.conf      --> included by ~/.config/kitty/kitty.conf
   ├── hyprland.conf   --> sourced by Hyprland for active/inactive borders
   ├── hyprlock.conf   --> sourced by ~/.config/hypr/hyprlock.conf
   └── palette.json    --> consumed by Quickshell Control Center & Widgets
```

---

## Configuration (`config.toml`)

The engine behavior and output mappings are defined in `config.toml`:

```toml
# Matugen is the color generator; ~/.config/themes is the central theme store.

[config]
mode = "dark"
type = "scheme-tonal-spot"
source_color_index = 0
scheme_tonal_spot_cutoff = 0.15
scheme_contrast = 1.0

[templates.waybar]
input_path = "~/.config/matugen/templates/waybar.css"
output_path = "~/.config/themes/current/waybar.css"

[templates.wofi]
input_path = "~/.config/matugen/templates/wofi.css"
output_path = "~/.config/themes/current/wofi.css"

[templates.kitty]
input_path = "~/.config/matugen/templates/kitty.conf"
output_path = "~/.config/themes/current/kitty.conf"

[templates.alacritty]
input_path = "~/.config/matugen/templates/alacritty.toml"
output_path = "~/.config/themes/current/alacritty.toml"

[templates.hyprland]
input_path = "~/.config/matugen/templates/hyprland.conf"
output_path = "~/.config/themes/current/hyprland.conf"

[templates.hyprlock]
input_path = "~/.config/matugen/templates/hyprlock.conf"
output_path = "~/.config/themes/current/hyprlock.conf"

[templates.palette]
input_path = "~/.config/matugen/templates/palette.json"
output_path = "~/.config/themes/current/palette.json"

[templates.hyprtoolkit]
input_path = "~/.config/matugen/templates/hyprtoolkit.conf"
output_path = "~/.config/hypr/hyprtoolkit.conf"
```

---

## Consumer Applications and Reload Strategies

| Target Application | Destination File | Consumed Tokens | Reload Method |
| :--- | :--- | :--- | :--- |
| **[Quickshell](../quickshell/index.md)** | `themes/current/palette.json` | Surfaces, containers, primary accents, semantic states | Automatic filesystem watcher / panel restart |
| **[Waybar](waybar.md)** | `themes/current/waybar.css` | Background, text, accent, warning, critical, charging | `pkill -SIGUSR2 waybar` |
| **[Wofi](wofi.md)** | `themes/current/wofi.css` | Panel backdrop, input field, text, selection, outline | Next instance invocation |
| **[Alacritty](../terminals/alacritty.md)** | `themes/current/alacritty.toml` | Normal, bright, primary, cursor, and selection colors | Automatic live reload |
| **Kitty** | `themes/current/kitty.conf` | ANSI 16 palette, foreground, background, cursor | `kitty @ set-colors` or new instance |
| **[Hyprland](../hyprland/index.md)** | `themes/current/hyprland.conf` | `col.active_border`, `col.inactive_border` | `hyprctl reload` or `hyprctl keyword` |
| **[Hyprlock](../hyprland/hyprlock.md)** | `themes/current/hyprlock.conf` | Lockscreen text, ring accent, error and warning colors | Next screen lock event |

---

## Core Color Roles

Each template uses standardized Material Design 3 tokens:

* `colors.background.default.hex`: Deep primary canvas background.
* `colors.surface.default.hex`: Floating surface and card backdrop.
* `colors.surface_container.default.hex`: Inactive inputs and container elements.
* `colors.surface_bright.default.hex`: Subtle highlight outlines and borders.
* `colors.primary.default.hex`: Main accent color, active borders, and focus rings.
* `colors.primary_container.default.hex`: Low-contrast selection backgrounds.
* `colors.on_surface.default.hex`: Primary text and foreground iconography.
* `colors.on_surface_variant.default.hex`: Secondary text, metadata, and hints.
* `colors.outline.default.hex`: Structural dividers and borders.
* `colors.error.default.hex`: Destructive actions and critical warnings.
* `colors.tertiary.default.hex`: Auxiliary highlights, charging states, and indicators.

---

## CLI Usage and Manual Palette Generation

To generate a new palette from any wallpaper image:

```bash
# Preview extracted palette without writing files
matugen image "/path/to/wallpaper.jpg" --mode dark --dry-run --show-colors

# Generate palette and update all theme templates
matugen image "/path/to/wallpaper.jpg" --mode dark --source-color-index 0
```

Optionally adjust the contrast level using `--contrast`:
```bash
# Increase contrast for accessibility or higher distinction (-1.0 to 1.0)
matugen image "/path/to/wallpaper.jpg" --mode dark --contrast 0.2
```

---

## Related Documentation

* [Hyprland Compositor](../hyprland/index.md): Window manager border theming and configuration modularity.
* [Hyprlock Screen Locker](../hyprland/hyprlock.md): Lockscreen surfaces and authentication colors.
* [Quickshell Control Center](../quickshell/index.md): Real-time wallpaper selector and QML theme integration.
* [Waybar Status Bar](waybar.md): Top status bar stylesheet imports and live reload signals.
* [Wofi Application Launcher](wofi.md): Material Design 3 launcher CSS imports.
* [Alacritty Terminal](../terminals/alacritty.md): Live terminal palette reload configuration.
* [Fastfetch Telemetry](fastfetch.md): Hardware display with terminal palette swatches.
