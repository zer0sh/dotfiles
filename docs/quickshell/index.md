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
* **Notifications & Control Center Integration (`modules/controlcenter/`, `modules/notifications/`):**
  * Native DBus notification server (`org.freedesktop.Notifications`) managed by `NotificationService.qml`.
  * Top-center floating toast layer (`NotificationToastLayer.qml`) with smooth downward entrance animations.
  * Collapsible notifications card embedded directly inside the Control Center featuring the title `Notifications • ( # )`, rotating toggle chevron, quick "Clear all" action, empty placeholder state, and scrollable notification list.
  * Waybar notification bell triggers `qs ipc call notifications toggle`, opening the Control Center with the notifications card smoothly expanded.
  * Full design parameters and easing curves detailed in the [Notifications & OSDs Guide](osd-notifications.md).
* **Clipboard Manager (`modules/clipboard/`):**
  * Visual history and search for text and images integrated with `cliphist`.
  * Keyboard access mapped via [Hyprland Keybindings](../hyprland/keybinds.md#quickshell-and-desktop-overlays).
* **DeskClock & Calendar (`modules/deskclock/`, `modules/calendar/`):**
  * Ambient desktop clock surface and expandable calendar panel with date navigation.
* **Mini Music Player (`modules/osd/MiniPlayer.qml`):**
  * Compact MPRIS playback controller triggered with `SUPER + M` as defined in [Hyprland Keybindings](../hyprland/keybinds.md#quickshell-and-desktop-overlays).
* **Application Launcher & Theme Selector (`modules/launcher/`):**
  * Fast native application runner and app drawer complementing [Wofi Launcher](../apps/wofi.md).
  * Interactive theme carousel (`>theme` mode) displaying theme preview cards (`ThemeCard.qml`), active status badges, and an integrated top header bar with title and a quick **Light Mode / Dark Mode** switch.
  * Synchronized with Matugen and persisted in `~/.config/themes/current/mode`.

---

## Dynamic Palette & Glassmorphism Integration

Quickshell widgets consume Material Design 3 tokens generated dynamically by [Matugen](../apps/matugen.md):

* **Token source:** `~/.config/themes/current/palette.json`
* **Theme loader:** `Theme.qml` loads colors reactively, allowing instantaneous UI repaints when wallpapers or light/dark modes change without restarting the shell.
* **Centralized Glassmorphism:** Standardized transparency properties (`Root.Theme.glassPanel` with opacity `0.55` and `Root.Theme.glassCard` with opacity `0.85`) unified across the DeskClock widget, launcher floating cards, and notifications.
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
