# Quickshell & Control Center

Quickshell is the Wayland-native QML widget framework driving this desktop environment. It provides a One UI inspired control center featuring translucent cards, rounded pill toggles, and reactive sliders on top of the [Hyprland compositor](../hyprland/index.md).

---

## Modules Overview

* **Control Center (`modules/controlcenter/`):**
  * **Layout Architecture:** Balanced two-column grid layout featuring a left widgets column (Analog Clock, Weather, Media Player) and a right control matrix (4x3 quick toggle grid alongside vertical glassmorphic sliders).
  * **Analog Clock Widget (`AnalogClockWidget.qml`):** Canvas-based analog dial with dynamic hour and minute hands, digital time readout, and localized English weekday and calendar date.
  * **Weather Widget (`WeatherWidget.qml`):** Live atmospheric conditions, ambient temperature, location label, and relative humidity fetched via OpenWeather API in English.
  * **Vertical Sliders Card:** Frosted glassmorphic card housing vertical reactive sliders for PipeWire audio volume and `brightnessctl` display backlight.
  * **Quick Toggles (4x3 Grid):** Rounded pill buttons for Wi-Fi, Bluetooth, DND, Airplane Mode, Caffeine, Power Profiles, Night Light, Screen Shaders, Audio outputs, Dynamic Theming, Energy, and Wallpaper selection.
  * **Energy & Performance Dashboard (`BatterySection.qml`):** Dedicated hardware metrics subpage displaying charge percentage, discharge rates, full charge estimates, battery health state, power draw, charge cycles, and power profile presets (Power Saver, Balanced, Performance).
  * **Waybar Sync:** Seamless bidirectional state sync between quick toggles (Caffeine, Night Light, Shader) and top status bar indicators using POSIX signals.
* **Notifications & Toasts (`modules/notifications/`):**
  * Native DBus notification server (`org.freedesktop.Notifications`).
  * Top-center floating toast layer with smooth downward entrance animations.
  * Persistent notification drawer accessible via [Waybar](../apps/waybar.md) or keyboard shortcuts.
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
* [Waybar Status Bar](../apps/waybar.md): Top status bar shell integrating with Quickshell notification signals and launcher.
* [Hyprland Architecture](../hyprland/index.md): Compositor startup hooks, autostart services, and display arrangements.
* [Hyprland Keybindings](../hyprland/keybinds.md): Global hotkeys for invoking Quickshell panels, toggles, and tools.
* [GLSL Screen Shaders](../hyprland/shaders.md): Shader pipeline controlled directly from the Control Center.
* [Matugen Theming Engine](../apps/matugen.md): Central theme generator populating `palette.json`.
* [Wofi Application Launcher](../apps/wofi.md): Material Design 3 runner running alongside Quickshell.
* [Alacritty Terminal](../terminals/alacritty.md): Main terminal sharing font and color styling.
