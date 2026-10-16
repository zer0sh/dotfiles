# Quickshell & Control Center

Quickshell is the Wayland-native QML widget framework driving this desktop environment. It provides a One UI inspired control center featuring translucent cards, rounded pill toggles, and reactive sliders on top of the [Hyprland compositor](../hyprland/index.md).

---

## Modules Overview

* **Control Center (`modules/controlcenter/`):**
  * Toggles for Wi-Fi, Bluetooth, DND, Airplane Mode, Caffeine, Power Profiles, Night Light, and [Screen Shaders](../hyprland/shaders.md).
  * Interactive volume and brightness sliders synchronizing with PipeWire and `brightnessctl`.
  * Direct access to wallpaper changer and battery diagnostics.
  * Theme switching integrated with the [Matugen Dynamic Theming Engine](../apps/matugen.md).
* **Notifications & Toasts (`modules/notifications/`):**
  * Native DBus notification server (`org.freedesktop.Notifications`).
  * Top-center floating toast layer with smooth downward entrance animations.
  * Persistent notification drawer accessible via Waybar or keyboard shortcuts.
  * Full design parameters and easing curves detailed in the [Notifications & OSDs Guide](osd-notifications.md).
* **Clipboard Manager (`modules/clipboard/`):**
  * Visual history and search for text and images integrated with `cliphist`.
  * Keyboard access mapped via [Hyprland Keybindings](../hyprland/keybinds.md#quickshell-and-desktop-overlays).
* **DeskClock & Calendar (`modules/deskclock/`, `modules/calendar/`):**
  * Ambient desktop clock surface and expandable calendar panel with date navigation.
* **Mini Music Player (`modules/osd/MiniPlayer.qml`):**
  * Compact MPRIS playback controller triggered with `SUPER + M` as defined in [Hyprland Keybindings](../hyprland/keybinds.md#quickshell-and-desktop-overlays).
* **Application Launcher (`modules/launcher/`):**
  * Fast native application runner and app drawer complementing [Wofi Launcher](../apps/wofi.md).

---

## Dynamic Palette Integration

Quickshell widgets consume Material Design 3 tokens generated dynamically by [Matugen](../apps/matugen.md):

* **Token source:** `~/.config/themes/current/palette.json`
* **Theme loader:** `Theme.qml` loads colors reactively, allowing instantaneous UI repaints when wallpapers change without restarting the shell.
* **Semantic roles:** Surface containers, primary accents, text variants, and outline borders are mapped directly to QML elements.

---

## Validation and Live Reload

To validate QML syntax or restart Quickshell without crashing your Wayland session:

```bash
# Validate QML syntax without restarting
~/.config/quickshell/restart-quickshell.sh --validate

# Restart Quickshell live
~/.config/quickshell/restart-quickshell.sh
```

---

## Related Documentation

* [Notifications & OSD Dynamics](osd-notifications.md): Animation curves, screen positioning, and source maps for toasts and OSD popups.
* [Hyprland Architecture](../hyprland/index.md): Compositor startup hooks, autostart services, and display arrangements.
* [Hyprland Keybindings](../hyprland/keybinds.md): Global hotkeys for invoking Quickshell panels, toggles, and tools.
* [GLSL Screen Shaders](../hyprland/shaders.md): Shader pipeline controlled directly from the Control Center.
* [Matugen Theming Engine](../apps/matugen.md): Central theme generator populating `palette.json`.
* [Wofi Application Launcher](../apps/wofi.md): Material Design 3 runner running alongside Quickshell.
* [Alacritty Terminal](../terminals/alacritty.md): Main terminal sharing font and color styling.
