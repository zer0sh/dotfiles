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
   ├── hyprtoolkit.conf --> read by hyprpolkitagent and Hyprland/QML apps (rendered to ~/.config/hypr/)
   ├── btop.theme       --> linked by ~/.config/btop/themes/matugen.theme
   ├── gtk-3.0.css     --> linked by ~/.config/gtk-3.0/gtk.css
   ├── gtk-4.0.css     --> linked by ~/.config/gtk-4.0/gtk.css
   ├── spicetify.ini   --> linked by ~/.config/spicetify/Themes/matugen/color.ini
   ├── steam.css       --> linked by ~/.local/share/Adwaita-for-Steam/custom/custom.css
   ├── palette.json    --> consumed by Quickshell Control Center & Widgets
   ├── matugen.vim     --> loaded by Vim via :colorscheme matugen
   └── vscode-colors / vscode-colors.json --> watched by the VS Code "Matugen Theme" extension (rendered to ~/.cache/matugen/)
    └── zen-userchrome.css / zen-usercontent.css --> rendered into <profile>/chrome/ and imported by userChrome.css / userContent.css
```

Note: the outputs rendered outside `~/.config/themes/current/` are the
exceptions to the central store. `hyprtoolkit.conf` goes to
`~/.config/hypr/hyprtoolkit.conf`, the VS Code outputs go to
`~/.cache/matugen/vscode-colors` and `~/.cache/matugen/vscode-colors.json`
because the `haikalllp.matugen-theme` extension watches those hardcoded paths,
and the Zen Browser outputs go to the profile `chrome/` folder because Firefox
forks only load stylesheets from the profile.

---

## Configuration (`config.toml`)

The engine behavior and output mappings are defined in `config.toml`:

```toml
# Matugen is the color generator; ~/.config/themes is the central theme store.

[config]
mode = "dark"
type = "scheme-vibrant"
source_color_index = 0

[templates.waybar]
input_path = "~/.config/matugen/templates/waybar.css"
output_path = "~/.config/themes/current/waybar.css"

[templates.wofi]
input_path = "~/.config/matugen/templates/wofi.css"
output_path = "~/.config/themes/current/wofi.css"

[templates.kitty]
input_path = "~/.config/matugen/templates/kitty.conf"
output_path = "~/.config/themes/current/kitty.conf"
post_hook = "pkill -SIGUSR1 kitty || true"

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

[templates.vim]
input_path = "~/.config/matugen/templates/matugen.vim"
output_path = "~/.config/themes/current/matugen.vim"

[templates.spicetify]
input_path = "~/.config/matugen/templates/spicetify.ini"
output_path = "~/.config/themes/current/spicetify.ini"

[templates.steam]
input_path = "~/.config/matugen/templates/steam.css"
output_path = "~/.config/themes/current/steam.css"
post_hook = 'cd "$HOME/.local/share/Adwaita-for-Steam" && python3 install.py --custom-css -t normal >/dev/null 2>&1 || true'

# VS Code (haikalllp.matugen-theme extension watches these paths)
[templates.vscode-raw]
input_path = "~/.config/matugen/templates/vscode-colors"
output_path = "~/.cache/matugen/vscode-colors"

[templates.vscode-json]
input_path = "~/.config/matugen/templates/vscode-colors.json"
output_path = "~/.cache/matugen/vscode-colors.json"

# Zen Browser (imported by <profile>/chrome/userChrome.css and userContent.css)
[templates.zen-userchrome]
input_path = "~/.config/matugen/templates/zen-userchrome.css"
output_path = "~/.zen/xbjonc67.Default Profile/chrome/zen-userChrome.css"

[templates.zen-usercontent]
input_path = "~/.config/matugen/templates/zen-usercontent.css"
output_path = "~/.zen/xbjonc67.Default Profile/chrome/zen-userContent.css"
```

The snippet above mirrors `~/dotfiles/matugen/config.toml` exactly. For the
full list of keys supported by matugen 4.x (`contrast`, `fallback_color`,
`prefer`, `caching`, `version_check`, `import_json_files`, `expr_prefix` /
`expr_postfix`, `[config.wallpaper]`, `[config.custom_colors]`), see the
[official example configuration](https://github.com/InioX/matugen/blob/main/example/config.toml)
and the [documentation site](https://iniox.github.io/).

---

## Consumer Applications and Reload Strategies

| Target Application | Destination File | Consumed Tokens | Reload Method |
| :--- | :--- | :--- | :--- |
| **[Quickshell](../quickshell/index.md)** | `themes/current/palette.json` | Surfaces, containers, primary accents, semantic states | Automatic filesystem watcher / panel restart |
| **[Waybar](waybar.md)** | `themes/current/waybar.css` | Background, text, accent, warning, critical, charging | `pkill -SIGUSR2 waybar` |
| **[Wofi](wofi.md)** | `themes/current/wofi.css` | Panel backdrop, input field, text, selection, outline | Next instance invocation |
| **[Alacritty](../terminals/alacritty.md)** | `themes/current/alacritty.toml` | Normal, bright, primary, cursor, and selection colors | Automatic live reload |
| **[Kitty](../terminals/kitty.md)** | `themes/current/kitty.conf` | ANSI 16 palette, extended 256-color range, URL color, tab bar, borders, marks | `post_hook`: `pkill -SIGUSR1 kitty` (live reload) |
| **[Hyprland](../hyprland/index.md)** | `themes/current/hyprland.conf` | `col.active_border`, `col.inactive_border` | `hyprctl reload` or `hyprctl keyword` |
| **[Hyprlock](../hyprland/hyprlock.md)** | `themes/current/hyprlock.conf` | Lockscreen text, ring accent, error and warning colors | Next screen lock event |
| **hyprpolkitagent / Hyprland QML apps** | `hypr/hyprtoolkit.conf` | Hyprtoolkit palette: background, base, text, alternate and highlight colors | Next application launch |
| **[btop](btop.md)** | `themes/current/btop.theme` | Box outlines, graphs, text, selection, gradient metrics | Next launch / live theme switch |
| **GNOME Classic (GTK 3)** | `themes/current/gtk-3.0.css` | Window, seamless headerbar, inputs, buttons, selections, `custom-dark`/`custom-light` base | Next app launch |
| **GNOME Modern (GTK 4 / Libadwaita)** | `themes/current/gtk-4.0.css` | Libadwaita named colors, seamless headerbar, soft navigation sidebar, hidden window controls | Next app launch |
| **Papirus Folders** | `themes/current/papirus-color` | Nearest folder palette (`colors_to_compare`) matching primary accent | Immediate post-hook (`papirus-folders -C`) |
| **Spicetify (Spotify)** | `themes/current/spicetify.ini` | Main, player, sidebar, cards, text, accents, buttons | `spicetify apply -n` in `apply-matugen.sh` + live Hyprland reload shortcut |
| **[Steam](steam.md)** | `themes/current/steam.css` | Adwaita CSS variables: accent, window_bg, headerbar, sidebar | `post_hook` running `install.py --custom-css -t normal`; restart the Steam client to display it |
| **[Vim](../terminals/vim.md)** | `themes/current/matugen.vim` | Editor highlights, syntax groups, NERDTree colors, airline statusline palette | `:colorscheme matugen` or new instance |
| **VS Code** (`haikalllp.matugen-theme`) | `~/.cache/matugen/vscode-colors` and `.json` | Full Material You palette (background, foreground, cursor, 16 accent colors) | Automatic via extension file watcher / `Matugen Theme: Update Theme` |
| **[Zen Browser](zen.md)** (`<profile>/chrome/`) | `zen-userChrome.css` and `zen-userContent.css` | Chrome UI: sidebar, tabs, toolbar, urlbar, panels; `about:` pages: links, buttons, inputs, cards | Full browser restart (profile stylesheets load at startup only) |


### Themed GTK Applications Suite

The generated stylesheets dynamically theme classic and modern GTK applications to match the active desktop palette, inspired by [Mitsugen](https://github.com/DimitrisMilonopoulos/mitsugen):

* **Ultra-Clean Headerbars**: Window controls (minimize, maximize, close buttons) are hidden via `gsettings set org.gnome.desktop.wm.preferences button-layout ":"` and GTK CSS, keeping titlebars distraction-free.
* **Unified Surface**: Headerbars blend seamlessly with `@window_bg_color`, allowing sidebars and view panes to extend smoothly from top to bottom without harsh division borders.
* **Refined Navigation & Breadcrumbs**: Nautilus navigation sidebars use soft rounded pills with accent translucency (`alpha(@accent_bg_color, 0.18)`), and pathbar breadcrumbs adopt rounded corners.
* **Modern GTK3 Foundation**: GTK3 applications consume the `custom-dark` / `custom-light` base themes (`adw-gtk3`), unifying classic and modern apps under a single Libadwaita design language.

### Papirus Folders Dynamic Theming

Papirus icon folders automatically adapt to the desktop wallpaper without requiring root privileges or `sudoers` modifications:

#### 1. The Name Collision Problem & User Namespace Solution
In modern Wayland and GTK 4 setups (such as Nautilus in GNOME 48), if an icon theme named `Papirus-Dark` exists in both `/usr/share/icons/` and `~/.local/share/icons/`, GTK 4 resolves system paths first, falling back to unmodifiable blue folders. 

To overcome this without requiring `sudo` on every wallpaper switch, the environment provisions dedicated user-space themes in `~/.local/share/icons/`:
* `Papirus-Matugen-Dark` (inherits `Papirus-Dark,Papirus,breeze-dark,hicolor`)
* `Papirus-Matugen-Light` (inherits `Papirus-Light,Papirus,breeze,hicolor`)

Because these theme names do not exist in `/usr/share/icons/`, GTK 4 is guaranteed to load the user's local instance.

#### 2. Helper Scripts Required

Two scripts manage this pipeline inside `~/dotfiles/scripts/`:

* **`scripts/papirus-folders`**: The official Papirus folder recoloring script bundled directly in the dotfiles repository and deployed to `~/.local/bin/papirus-folders`.
* **`scripts/setup-papirus-matugen.sh`**: One-time setup utility (executed automatically by `install.sh`) that:
  1. Installs the `papirus-folders` binary to `~/.local/bin/`.
  2. Copies system Papirus themes to `~/.local/share/icons/Papirus-Matugen-Dark` and `Papirus-Matugen-Light`.
  3. Rewrites their `index.theme` to update `Name` and configure `Inherits` fallback to the system package.
  4. Generates an initial icon cache via `gtk-update-icon-cache`.

To manually trigger or reinitialize the user icon themes:
```bash
~/dotfiles/scripts/setup-papirus-matugen.sh
```

#### 3. Matugen Configuration (`matugen/config.toml`)

Matugen's built-in `colors_to_compare` engine evaluates the wallpaper's primary accent against all 23 official Papirus folder palettes and executes `papirus-folders`:

```toml
[templates.papirus-folders]
input_path = "~/.config/matugen/templates/papirus-color"
output_path = "~/.config/themes/current/papirus-color"
colors_to_compare = [
    { name = "black",      color = "#4f4f4f" },
    { name = "blue",       color = "#5294e2" },
    { name = "bluegrey",   color = "#607d8b" },
    { name = "brown",      color = "#ae8e6c" },
    { name = "carmine",    color = "#a30002" },
    { name = "cyan",       color = "#00bcd4" },
    { name = "darkcyan",   color = "#45abb7" },
    { name = "deeporange", color = "#eb6637" },
    { name = "green",      color = "#87b158" },
    { name = "grey",       color = "#8e8e8e" },
    { name = "indigo",     color = "#5c6bc0" },
    { name = "magenta",    color = "#ca71df" },
    { name = "nordic",     color = "#81a1c1" },
    { name = "orange",     color = "#ee923a" },
    { name = "palebrown",  color = "#d1bfae" },
    { name = "paleorange", color = "#eeca8f" },
    { name = "pink",       color = "#f06292" },
    { name = "red",        color = "#e25252" },
    { name = "teal",       color = "#16a085" },
    { name = "violet",     color = "#7e57c2" },
    { name = "white",      color = "#e4e4e4" },
    { name = "yaru",       color = "#676767" },
    { name = "yellow",     color = "#f9bd30" },
]
compare_to = "{{ colors.primary.default.hex }}"
post_hook = "papirus-folders -t Papirus-Matugen-Dark -C {{ closest_color }} >/dev/null 2>&1 && papirus-folders -t Papirus-Matugen-Light -C {{ closest_color }} >/dev/null 2>&1 && papirus-folders -t Papirus-Matugen -C {{ closest_color }} >/dev/null 2>&1 || true"
index = 1
```

The template file `matugen/templates/papirus-color` simply stores:
```text
current={{colors.primary.default.hex_stripped}}
```

#### 4. Live Reloading in `apply-matugen.sh`

Whenever `apply-matugen.sh` runs:
1. It writes `gtk-icon-theme-name=Papirus-Matugen-Dark` (or `Papirus-Matugen-Light`) into both `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`.
2. Updates `gsettings set org.gnome.desktop.interface icon-theme`.
3. Runs Matugen, which switches the symlinks in `~/.local/share/icons/Papirus-Matugen-Dark/` to the nearest matching color.
4. Toggles `icon-theme` to `Adwaita` and back to force running GTK 4 apps (such as Nautilus) to immediately invalidate their icon cache without needing a session restart.

![Themed GTK Applications Suite](../assets/images/apps/gtk-suite.png)

### Material Bibata Dynamic Cursor Theming

The mouse cursor dynamically re-tones itself on every wallpaper switch to harmoniously match the Material Design 3 primary accent, integrating [Material Bibata Cursor](https://github.com/SakibShahariar/material-bibata-cursor) created by [Sakib Shahariar](https://github.com/SakibShahariar):

#### 1. Perceptual Palette Matching (CIEDE2000)

Rather than converting colors through distorted HSV color spaces, the system calculates perceptual distance using the CIEDE2000 Delta-E algorithm in CIELAB space via `themes/color_match.py`. It compares the active wallpaper's `primary` hex token against 28 curated M3 tonal pairs in `themes/bibata-themes.json` (plus Classic).

* **Dark Mode**: Activates the dark container body with saturated tonal border (e.g., `Bibata-Material-Lime`, `Bibata-Material-Teal`).
* **Light Mode**: Automatically routes to the matching tone-swapped variant with `-Light` suffix (e.g., `Bibata-Material-Lime-Light`), preserving high contrast standards (>= 4.5:1).

#### 2. Cross-Desktop Application Sync

When `themes/apply-matugen.sh` runs:
1. Resolves the optimal cursor theme name via `python3 themes/color_match.py <primary_hex> themes/bibata-themes.json`.
2. Persists the active theme name to `~/.config/themes/current/cursor-theme`.
3. Dispatches live cursor updates to Hyprland (`hyprctl setcursor <theme> 24`).
4. Updates GNOME / GTK settings via `gsettings set org.gnome.desktop.interface cursor-theme <theme>`.
5. Updates GTK configuration files (`~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini`).
6. Overwrites `~/.icons/default/index.theme` for legacy X11 / XCursor applications.

#### 3. Setup and Deployment

The setup utility `scripts/setup-bibata-matugen.sh` deploys the official pre-built `v1.5.0` assets directly to `~/.local/share/icons/` with symlinks in `~/.icons/`, verified during initial `./install.sh`.

```bash
~/dotfiles/scripts/setup-bibata-matugen.sh
```

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

## Orchestration: `apply-matugen.sh`

`~/dotfiles/themes/apply-matugen.sh` is the single entrypoint that regenerates
the whole palette. It is invoked by Quickshell when the wallpaper changes
(`modules/background/Background.qml`), by the theme picker in the Control
Center (`modules/controlcenter/ControlCenter.qml`), and manually from a shell.

Inputs, in order of precedence: the optional first argument, then the
`~/.config/themes/current/wallpaper` state file. The mode (dark/light) follows
the optional second argument, then `~/.config/themes/current/mode`, defaulting
to `dark`. The color scheme type (`scheme-vibrant`, `scheme-fruit-salad`, `scheme-monochrome`, etc.)
follows the optional third argument, then `~/.config/themes/current/scheme_type`, defaulting
to `scheme-vibrant`. All three state files are rewritten on every run.

The script executes:

1. `matugen image` with `--config ~/.config/matugen/config.toml`,
   `-t "$TYPE"`, `--contrast 0.2`, `--mode "$MODE"`, `--source-color-index 0`
   and `--quiet` (the index flag bypasses the interactive color picker).
2. `hyprctl reload` to re-read the generated border colors.
3. `pkill -SIGUSR2 waybar` to reload the status bar stylesheet.
4. Writes `matugen` to `~/.config/quickshell/current-theme` so Quickshell
   consumes `palette.json` instead of a static theme.
5. Sets `org.gnome.desktop.interface color-scheme` to `prefer-dark` or
   `prefer-light`, sets `icon-theme` (`Papirus-Dark` or `Papirus-Light`),
   enforces `button-layout ":"` to hide window controls, and toggles
   `gtk-theme` to force GTK stylesheets to re-read with `custom-dark` or `custom-light`.
6. Runs `spicetify apply -n` only when the active Spicetify theme is `matugen`.
7. Runs `~/.config/themes/update-wallpaper-cache.sh` to refresh wallpaper
   thumbnails.

No reload step is needed for Alacritty (automatic live reload), for VS Code
(the extension watches `~/.cache/matugen/`), or for the root symlinks created
by `sync-root-theme.sh` (they point at `themes/current/`). Zen Browser cannot
be reloaded programmatically either: the rendered `zen-userChrome.css` and
`zen-userContent.css` are picked up on the next full browser restart. Steam is
re-injected automatically by its `post_hook` on every render, but the client
must be restarted to display the refreshed palette. Similarly, Spicetify permanently
injects the updated `matugen` palette into Spotify via `spicetify apply -n`; if a Spotify
window is currently active in Hyprland, `apply-matugen.sh` automatically dispatches
a native `Ctrl + Shift + R` reload shortcut via `hyprctl dispatch sendshortcut` to reload
the interface live with the new colors without closing the client or stopping music playback.
Because Spotify runs through XWayland to bypass CEF Wayland GPU crashes, context menu blur
and shadow artifacts are eliminated using specialized compositor rules (see
[XWayland & Window Rules](../hyprland/xwayland.md)).

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

## Manual Installation: VS Code Theme Integration (Pilot)

Standalone instructions to add the VS Code theme integration to an existing
matugen installation without cloning the full dotfiles repository. This is the
pilot for the manual installation format used across this documentation.

All snippets are compatible with `bash` and `zsh`, use explicit paths only
(no glob patterns), and are safe to paste into an interactive shell.

### Files created or modified

| Action | Path | Notes |
| :--- | :--- | :--- |
| Create | `~/.config/matugen/templates/vscode-colors` | Raw color list template |
| Create | `~/.config/matugen/templates/vscode-colors.json` | JSON color template |
| Modify (backup first) | `~/.config/matugen/config.toml` | Registers both templates |
| Create | `~/.cache/matugen/vscode-colors` | Rendered by matugen |
| Create | `~/.cache/matugen/vscode-colors.json` | Rendered by matugen |

### Step 1: Validate prerequisites

Run the checks. Every line must report `OK` before continuing, except
`extension`: a missing extension here is expected, because Step 6 installs it:

```bash
command -v matugen >/dev/null 2>&1 && echo "matugen       : OK" || echo "matugen       : MISSING"
command -v code >/dev/null 2>&1 && echo "vscode cli    : OK" || echo "vscode cli    : MISSING"
command -v curl >/dev/null 2>&1 && echo "curl          : OK" || echo "curl          : MISSING"
test -d "$HOME/.config/matugen/templates" && echo "templates dir : OK" || echo "templates dir : MISSING"
test -f "$HOME/.config/matugen/config.toml" && echo "config.toml   : OK" || echo "config.toml   : MISSING"
code --list-extensions 2>/dev/null | grep -Fx "haikalllp.matugen-theme" >/dev/null && echo "extension     : OK" || echo "extension     : MISSING"
```

If a line reports `MISSING`:

* `matugen`: install it from <https://github.com/InioX/matugen>.
* `vscode cli`: install VS Code and make sure the `code` command is in `PATH`.
* `curl`: install it with your package manager (`apt install curl` on Debian).
* `templates dir`: create it with `mkdir -p "$HOME/.config/matugen/templates"`.
* `config.toml`: create an empty one with `touch "$HOME/.config/matugen/config.toml"`.
* `extension`: the `haikalllp.matugen-theme` theme extension is not installed
  yet; Step 6 installs it, so no action is needed here.

### Step 2: Back up the files that will be modified

The only existing file altered by this procedure is `config.toml`. The backup
name carries the exact date and time of the operation:

```bash
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"
cp -p "$HOME/.config/matugen/config.toml" "$HOME/.config/matugen/config.toml.$BACKUP_STAMP.bak"
echo "Backup created: $HOME/.config/matugen/config.toml.$BACKUP_STAMP.bak"
```

If template files from a previous attempt already exist, they are backed up
the same way before being replaced:

```bash
BACKUP_STAMP="$(date +%Y%m%d-%H%M%S)"
if test -f "$HOME/.config/matugen/templates/vscode-colors"; then
    cp -p "$HOME/.config/matugen/templates/vscode-colors" "$HOME/.config/matugen/templates/vscode-colors.$BACKUP_STAMP.bak"
fi
if test -f "$HOME/.config/matugen/templates/vscode-colors.json"; then
    cp -p "$HOME/.config/matugen/templates/vscode-colors.json" "$HOME/.config/matugen/templates/vscode-colors.json.$BACKUP_STAMP.bak"
fi
```

### Step 3: Create the template files

Download both templates directly from the repository:

```bash
mkdir -p "$HOME/.config/matugen/templates"
curl -fsSL -o "$HOME/.config/matugen/templates/vscode-colors" "https://raw.githubusercontent.com/zer0sh/dotfiles/main/matugen/templates/vscode-colors"
curl -fsSL -o "$HOME/.config/matugen/templates/vscode-colors.json" "https://raw.githubusercontent.com/zer0sh/dotfiles/main/matugen/templates/vscode-colors.json"
```

Alternatively, copy the file contents manually from the repository pages
([vscode-colors](https://github.com/zer0sh/dotfiles/blob/main/matugen/templates/vscode-colors),
[vscode-colors.json](https://github.com/zer0sh/dotfiles/blob/main/matugen/templates/vscode-colors.json))
into the destination paths shown above.

Confirm both files exist and are not empty:

```bash
test -s "$HOME/.config/matugen/templates/vscode-colors" && echo "vscode-colors      : OK" || echo "vscode-colors      : MISSING"
test -s "$HOME/.config/matugen/templates/vscode-colors.json" && echo "vscode-colors.json : OK" || echo "vscode-colors.json : MISSING"
```

### Step 4: Register the templates in `config.toml`

The following block is idempotent: it appends the sections only when they are
not already registered. The heredoc delimiter is quoted, so no variable or
shell expansion happens inside it:

```bash
if grep -q "^\[templates.vscode-raw\]" "$HOME/.config/matugen/config.toml"; then
    echo "Already registered in config.toml, nothing to do."
else
    cat >> "$HOME/.config/matugen/config.toml" <<'EOF'

# VS Code (haikalllp.matugen-theme extension watches these paths)
[templates.vscode-raw]
input_path = "~/.config/matugen/templates/vscode-colors"
output_path = "~/.cache/matugen/vscode-colors"

[templates.vscode-json]
input_path = "~/.config/matugen/templates/vscode-colors.json"
output_path = "~/.cache/matugen/vscode-colors.json"
EOF
    echo "Registered in config.toml."
fi
```

### Step 5: Generate the colors

Replace the wallpaper path with your own absolute path. The
`--source-color-index 0` flag disables the interactive color picker, so the
command also works from keybindings or non-interactive shells:

```bash
matugen image "/absolute/path/to/your-wallpaper.jpg" --mode dark --source-color-index 0
test -f "$HOME/.cache/matugen/vscode-colors" && echo "rendered colors : OK" || echo "rendered colors : MISSING"
```

### Step 6: Install the extension and activate the theme

```bash
code --install-extension haikalllp.matugen-theme
```

Then in VS Code press `Ctrl+K` `Ctrl+T` and select **Matugen** (or
**Matugen Bordered** for panels with border lines).

### Step 7: Verification

```bash
test -f "$HOME/.cache/matugen/vscode-colors" && echo "colors      : OK" || echo "colors      : MISSING"
code --list-extensions | grep -Fx "haikalllp.matugen-theme" >/dev/null && echo "extension   : OK" || echo "extension   : MISSING"
find "$HOME/.vscode/extensions" -maxdepth 2 -type f -name "matugen.json" -path "*matugen-theme*" 2>/dev/null | grep -q . && echo "theme file  : OK" || echo "theme file  : MISSING"
```

Note: the `-name` and `-path` values in the `find` command are `find`
predicates, not shell patterns, so they are never expanded by the shell.

### Troubleshooting

* **`themes/matugen.json` does not exist or VS Code reports it cannot load the
  theme:** the extension activated before the color files were generated, so
  its file watcher missed them. Open the Command Palette and run
  `Matugen Theme: Update Theme`, or reload the window with
  `Developer: Reload Window`.
* **Palette did not change after a wallpaper switch:** run
  `matugen image` again (Step 5) and check the Output panel of VS Code,
  channel `Matugen Theme`.
* **Restore the previous configuration:** copy the backup created in Step 2
  back over `config.toml` using the exact name printed by the backup command.

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
* [Zen Browser Theming](zen.md): Profile `userChrome.css` / `userContent.css` integration with a manual installation guide.
