# Keybindings

All keybindings are centralized in [`binds.conf`](file:///home/zero/.config/hypr/binds.conf). The primary modifier key is `SUPER` (`$mainMod`).

---

## Applications and System

| Shortcut | Action | Target / Command |
| :--- | :--- | :--- |
| `SUPER + Enter` | Open terminal | [`$terminal` (kitty)](../terminals/kitty.md) |
| `SUPER + E` | Open file manager | `nautilus` |
| `SUPER + Space` | Application launcher | `scripts/toggle-menu` ([Wofi Launcher](../apps/wofi.md)) |
| `SUPER + Q` | Close active window | `killactive` |
| `SUPER + SHIFT + R` | Reload Hyprland config | `hyprctl reload` |
| `SUPER + L` | Lock screen | [`hyprlock`](hyprlock.md) |
| `SUPER + P` | Display layout editor | `nwg-displays` |
| `SUPER + X` | Launch app as root | `scripts/sudo-launcher` |

---

## Screen Capture and Recording

| Shortcut | Action | Tool / Helper Script |
| :--- | :--- | :--- |
| `Print` | Fullscreen screenshot | `scripts/screenshot` (saves to disk + copies to clipboard) |
| `SUPER + S` | Capture selected area | `scripts/screenshot area` |
| `SUPER + SHIFT + O` | Optical Character Recognition (OCR) | `scripts/ocr` (extracts text to clipboard) |
| `SUPER + ALT + R` | Toggle screen recording | `scripts/record` (saves MP4 with audio) |

---

## Quickshell and Desktop Overlays

| Shortcut | Action | IPC Command | Reference |
| :--- | :--- | :--- | :--- |
| `CTRL + ALT + Del` | Power menu | `quickshell ipc call powermenu toggle` | [Control Center](../quickshell/index.md) |
| `SUPER + W` | Wallpaper picker | `quickshell ipc call wallpaper toggle` | [Matugen Integration](../apps/matugen.md) |
| `SUPER + M` | Mini music player | `quickshell ipc call miniplayer toggle` | [OSD & Mini Player](../quickshell/osd-notifications.md) |
| `F1` | Shortcut cheatsheet overlay | `quickshell ipc call shortcuts toggle` | [Control Center](../quickshell/index.md) |

---

## Screen Filters and Shaders

| Shortcut | Applied Shader | Helper Script | Reference |
| :--- | :--- | :--- | :--- |
| `SUPER + B` | Toggle active shader ON / OFF | `scripts/filter toggle` | [GLSL Shaders](shaders.md) |
| `SUPER + CTRL + 1` | Vintage Sepia | `scripts/filter sepia` | [GLSL Shaders](shaders.md) |
| `SUPER + CTRL + 2` | Black & White | `scripts/filter bw` | [GLSL Shaders](shaders.md) |
| `SUPER + CTRL + 3` | Film Noir | `scripts/filter noir` | [GLSL Shaders](shaders.md) |
| `SUPER + CTRL + 4` | Aged Vintage | `scripts/filter vintage` | [GLSL Shaders](shaders.md) |
| `SUPER + CTRL + 5` | Vivid Colors | `scripts/filter vivid` | [GLSL Shaders](shaders.md) |
| `SUPER + CTRL + 0` | Disable shaders | `scripts/filter off` | [GLSL Shaders](shaders.md) |

---

## Related Documentation

* [Hyprland Architecture](index.md): Modular setup, display configuration, and startup daemons.
* [GLSL Screen Shaders](shaders.md): Detailed visual descriptions of all compositor color filters.
* [Screen Locking & Idle](hyprlock.md): Hyprlock security, PAM authentication, and Hypridle power states.
* [Wofi Application Launcher](../apps/wofi.md): Material Design 3 launcher presets and customization.
* [Kitty Terminal](../terminals/kitty.md): Default terminal emulator, font choice, and palette reload.
* [Alacritty Terminal](../terminals/alacritty.md): Secondary terminal emulator sharing the same visual settings.
* [Quickshell Overview](../quickshell/index.md): Desktop control center and reactive Wayland widgets.
