# Keyboard Shortcuts Overlay

The Shortcuts Overlay (`quickshell:shortcuts`) is a Wayland-native cheat sheet modal built into Quickshell. Triggered globally via `F1`, it provides an interactive, searchable reference of all active [Hyprland keybindings](../hyprland/keybinds.md) and system actions.

---

## Architecture & Visual Design

The module (`modules/shortcuts/ShortcutsOverlay.qml`) aligns with the One UI and Material Design 3 aesthetic established in the [Control Center](index.md):

* **Surface Geometry:** Centered modal container measuring 920x660 px with a 28 px corner radius (`Root.Theme.panelRadius`).
* **Glassmorphic Finish:** Translucent dark glass surface (`Qt.rgba(surface.r, surface.g, surface.b, 0.78)`) backed by hardware-accelerated Hyprland blur (`layerrule = blur on, ignore_alpha 0, match:namespace quickshell:.*`) and an outline border (`1.5 px`).
* **Backdrop Layer:** Full-screen darkened scrim (`Qt.rgba(0, 0, 0, 0.45)`) that dismisses the overlay on click.
* **Responsive 2-Column Grid:** Two-column card flow providing ample horizontal width for long descriptions and multi-key sequences.
* **Keycap Chip Rendering:** Key combinations are split into distinct rounded keycaps (e.g., `SUPER`, `SHIFT`, `R`) styled with primary accent tones and high-contrast labels.

---

## Core Features

### 1. Dynamic Keybind Parser

The overlay reads `~/.config/hypr/binds.conf` directly via a background `quickshell.io.Process` stream. Rather than dumping raw compositor dispatchers, the parser:

* Resolves Hyprland variable references (`$mainMod`, `$terminal`, `$fileManager`, `$menu`).
* Normalizes modifier combinations and translates hardware keys (`Return` to `Enter`, `Print` to `Print Screen`, audio and brightness XF86 symbols).
* Groups repetitive workspace transitions (`workspace 1..10`, `movetoworkspace 1..10`) and directional focus arrows into concise entries.
* Maps binds into categorized sets: **Applications**, **Windows**, **Workspaces**, and **System & Media**.

### 2. Live Search and Category Filtering

* **Real-time Filter:** Live search bar filtering instantly across key names, dispatchers, and localized descriptions.
* **Category Pills:** Quick-switch filter buttons:
  * **All (`all`):** Complete catalog of user and desktop actions.
  * **Applications (`apps`):** Terminal, file manager, app launcher, wallpaper selector, and utility launchers.
  * **Windows (`windows`):** Window kill, floating toggle, fullscreen, focus navigation, and mouse drag/resize.
  * **Workspaces (`workspaces`):** Workspace navigation and window routing.
  * **System (`system`):** Audio volume, monitor brightness, screenshots, screen recording, OCR, and GLSL shaders.

### 3. LayerShell and Navigation

* **Namespace:** `quickshell:shortcuts`
* **Layer:** `WlrLayer.Overlay` with `WlrKeyboardFocus.Exclusive`
* **Dismissal Actions:**
  * Pressing `F1` or `Escape` (handled by declarative QML `Shortcut` components).
  * Clicking the dedicated top-right circular close button.
  * Clicking the dark outer scrim.

---

## IPC Interface

The overlay exposes an IPC target callable from Hyprland keybindings or terminal scripts:

```bash
# Toggle visibility (mapped to F1 in ~/.config/hypr/binds.conf)
quickshell ipc call shortcuts toggle

# Open explicitly
quickshell ipc call shortcuts open

# Close explicitly
quickshell ipc call shortcuts close
```

---

## Related Documentation

* [Hyprland Keybindings Catalog](../hyprland/keybinds.md): Complete index of desktop shortcut combinations.
* [Control Center Architecture](index.md): Glassmorphic panel layout and design tokens.
* [GLSL Screen Shaders](../hyprland/shaders.md): Screen filters callable from shortcuts.
