# Kitty Configuration

Kitty is the default terminal emulator in this environment, bound to `SUPER + Return` through the `$terminal` variable in Hyprland and running the [Zsh Shell](zsh.md). Its configuration deliberately mirrors [Alacritty](alacritty.md): identical typography, padding, opacity and cursor behavior, with the color palette supplied by the [Matugen Dynamic Theming Engine](../apps/matugen.md).

---

## File Locations

* **Repository source:** `~/dotfiles/kitty/kitty.conf`
* **Target symlink:** `~/.config/kitty` -> `~/dotfiles/kitty`
* **Imported color palette:** `~/.config/themes/current/kitty.conf`
* **Matugen template:** `~/.config/matugen/templates/kitty.conf`

---

## Dynamic Theme Integration (Matugen)

Kitty does not define any static colors in its main configuration. It includes an externally generated palette file, keeping the same central-store architecture used by Alacritty:

```conf
include ~/.config/themes/current/kitty.conf
```

The palette template is adapted from the [kitty template of matugen-themes](https://github.com/InioX/matugen-themes#kitty) (MIT license) and maps Material Design 3 color roles onto the complete terminal palette: the 16 ANSI colors, cursor and selection, URL color, tab bar, border colors, marks, and the extended 256-color range consumed by prompt themes such as Starship.

### Live Update Workflow

1. Matugen processes the current desktop wallpaper or the manual theme selected via the [Quickshell Control Center](../quickshell/index.md).
2. It evaluates the template located at `~/.config/matugen/templates/kitty.conf` against the generated color roles.
3. The resulting palette is written to `~/.config/themes/current/kitty.conf`.
4. The template's `post_hook` (`pkill -SIGUSR1 kitty || true`) signals every running kitty instance, which reloads the configuration in place without interrupting active shell sessions.

Unlike Alacritty, kitty does not watch included files on its own. The `SIGUSR1` signal plays exactly the same role as Alacritty's `live_config_reload = true`. A manual reload is also available with `Ctrl + Shift + F5`.

---

## Visual Settings & Typography

```conf
window_padding_width 15
background_opacity 0.92

cursor_shape underline
cursor_blink_interval 0.5

font_family family="BlexMono Nerd Font" style="Bold"
bold_font family="BlexMono Nerd Font" style="Bold"
italic_font family="BlexMono Nerd Font" style="Bold Italic"
bold_italic_font family="BlexMono Nerd Font" style="Bold Italic"
font_size 11.0

shell_integration no-cursor
```

* **Padding:** `15` px on every edge, matching the `15 x 15` padding used by Alacritty and keeping clean breathing room against [Hyprland window borders](../hyprland/index.md).
* **Opacity:** `0.92`, identical to Alacritty, providing subtle background transparency that blends with Hyprland dual-layer blur while maintaining high contrast and readability.
* **Font:** `BlexMono Nerd Font` with the Bold weight used as the normal style through the `family=` / `style=` font specification, replicating Alacritty's `[font]` block. `font_size 11.0` keeps kitty visually aligned with Alacritty's default rendered size.
* **Cursor:** underlined shape with a `0.5 s` blink interval. `shell_integration no-cursor` prevents Zsh from overriding the cursor shape announced by shell integration.

### Parity with Alacritty

| Setting | Alacritty | Kitty |
| :--- | :--- | :--- |
| Palette source | `import` of `themes/current/alacritty.toml` | `include` of `themes/current/kitty.conf` |
| Live reload | `live_config_reload = true` | `post_hook`: `pkill -SIGUSR1 kitty` |
| Padding | `padding = { x = 15, y = 15 }` | `window_padding_width 15` |
| Opacity | `opacity = 0.92` | `background_opacity 0.92` |
| Cursor | `shape = "Underline"`, `blinking = "On"` | `cursor_shape underline`, `cursor_blink_interval 0.5` |
| Font | BlexMono Nerd Font, Bold / Bold Italic | `family=` / `style=` spec, `font_size 11.0` |

---

## Associated Keybindings

* `SUPER + Return` launches kitty through the `$terminal` variable defined in `~/.config/hypr/variables.conf`.
* Helper scripts such as `hypr/scripts/sudo-launcher` also spawn kitty directly.
* [Wofi](../apps/wofi.md) launches `.desktop` entries requiring a terminal through `term=kitty`.
* `Ctrl + Shift + F5` reloads the kitty configuration manually.

---

## Related Documentation

* [Alacritty Configuration](alacritty.md): Primary terminal whose visual settings this configuration mirrors.
* [Zsh Shell Configuration](zsh.md): Default login shell environment, lightweight plugins, and custom prompt styles.
* [Matugen Theming Engine](../apps/matugen.md): Dynamic generation of `kitty.conf` color tables and the `SIGUSR1` reload hook.
* [Hyprland Architecture](../hyprland/index.md): `$terminal` variable, compositor blur, and window rules.
* [Wofi Application Launcher](../apps/wofi.md): Menu runner used to launch kitty instances.
