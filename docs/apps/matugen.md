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
   ├── btop.theme       --> linked by ~/.config/btop/themes/matugen.theme
   ├── gtk-3.0.css     --> linked by ~/.config/gtk-3.0/gtk.css
   ├── gtk-4.0.css     --> linked by ~/.config/gtk-4.0/gtk.css
   ├── spicetify.ini   --> linked by ~/.config/spicetify/Themes/matugen/color.ini
   ├── steam.css       --> linked by ~/.config/AdwSteamGtk/custom.css
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

[templates.btop]
input_path = "~/.config/matugen/templates/btop.theme"
output_path = "~/.config/themes/current/btop.theme"

[templates.gtk3]
input_path = "~/.config/matugen/templates/gtk-3.0.css"
output_path = "~/.config/themes/current/gtk-3.0.css"

[templates.gtk4]
input_path = "~/.config/matugen/templates/gtk-4.0.css"
output_path = "~/.config/themes/current/gtk-4.0.css"

[templates.spicetify]
input_path = "~/.config/matugen/templates/spicetify.ini"
output_path = "~/.config/themes/current/spicetify.ini"

[templates.steam]
input_path = "~/.config/matugen/templates/steam.css"
output_path = "~/.config/themes/current/steam.css"
post_hook = "adwaita-steam-gtk -i >/dev/null 2>&1 || flatpak run io.github.Foldex.AdwSteamGtk -i >/dev/null 2>&1 || true"
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
| **[btop](btop.md)** | `themes/current/btop.theme` | Box outlines, graphs, text, selection, gradient metrics | Next launch / live theme switch |
| **GNOME Classic (GTK 3)** | `themes/current/gtk-3.0.css` | Window, headerbar, inputs, buttons, selection, accent | Next app launch |
| **GNOME Modern (GTK 4 / Libadwaita)** | `themes/current/gtk-4.0.css` | Libadwaita named colors: accent, window_bg, headerbar, cards | Next app launch |
| **Spicetify (Spotify)** | `themes/current/spicetify.ini` | Main, player, sidebar, cards, text, accents, buttons | `spicetify apply -n` / automated in `apply-matugen.sh` |
| **[Steam](steam.md)** | `themes/current/steam.css` | Adwaita CSS variables: accent, window_bg, headerbar, sidebar | `post_hook` with `adwaita-steam-gtk -i` |


### Themed GTK Applications Suite

The generated stylesheets dynamically theme classic and modern GTK applications to match the active desktop palette:

![Themed GTK Applications Suite](../assets/images/apps/gtk-suite.png)

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

# Generate palette in dark mode
matugen image "/path/to/wallpaper.jpg" --mode dark --source-color-index 0

# Generate palette in light mode
matugen image "/path/to/wallpaper.jpg" --mode light --source-color-index 0
```

### Centralized Theme Dispatcher (`apply-matugen.sh`)

The environment provides `~/.config/themes/apply-matugen.sh` to coordinate multi-component reloads and mode persistence:

```bash
# Apply with current wallpaper and specific mode
~/.config/themes/apply-matugen.sh "" light
~/.config/themes/apply-matugen.sh "" dark
```

Optionally adjust the contrast level using `--contrast`:
```bash
# Increase contrast for accessibility or higher distinction (-1.0 to 1.0)
matugen image "/path/to/wallpaper.jpg" --mode dark --contrast 0.2
```

---

## Privileged Applications Theming (sudo / root)

By default, applications executed with `sudo` (such as administrative tools, file managers, or system monitors) read configuration files from `/root/.config/` and do not inherit user-level CSS overrides.

To synchronize your active Matugen theme with the root user:

```bash
sudo ~/dotfiles/scripts/sync-root-theme.sh
```

### Mechanism and Persistence:
1. Creates `/root/.config/gtk-3.0/` and `/root/.config/gtk-4.0/`.
2. Configures `Adwaita-dark` preference in `/root/.config/gtk-3.0/settings.ini`.
3. Symlinks root GTK stylesheets directly to the user's central theme store:
   * `/root/.config/gtk-3.0/gtk.css` -> `~/.config/themes/current/gtk-3.0.css`
   * `/root/.config/gtk-4.0/gtk.css` -> `~/.config/themes/current/gtk-4.0.css`
4. Symlinks root btop monitor theme (`/root/.config/btop/themes/matugen.theme`).

Because these are live symlinks targeting `~/.config/themes/current/`, subsequent wallpaper or palette changes made via Quickshell will automatically reflect in root applications without re-executing the synchronization script.

### Synchronization & Cleanup Flags

The `sync-root-theme.sh` utility provides flags to manage synchronization or easily restore default themes:

| Flag | Privilege | Description |
| :--- | :--- | :--- |
| `--sync` (default) | `sudo` | Synchronize root GTK and btop themes from active user theme. |
| `--cleanup-user` | User | Revert user GTK3 and GTK4 stylesheets to system defaults. |
| `--cleanup-root` | `sudo` | Remove root theme symlinks and restore original settings. |
| `--cleanup-all` | `sudo` | Revert both user and root configurations to factory defaults. |

```bash
# Revert user theme only (no sudo required)
~/dotfiles/scripts/sync-root-theme.sh --cleanup-user

# Revert root theme only
sudo ~/dotfiles/scripts/sync-root-theme.sh --cleanup-root

# Revert both user and root to system defaults
sudo ~/dotfiles/scripts/sync-root-theme.sh --cleanup-all
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
* [Steam Client Theming](steam.md): Dynamic Adwaita-for-Steam custom stylesheet and post-hook injection.
