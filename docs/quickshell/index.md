# Quickshell & Control Center

Quickshell is the Wayland-native QML widget framework driving this desktop environment. It provides a One UI inspired control center featuring translucent cards, rounded pill toggles, and reactive sliders on top of the [Hyprland compositor](../hyprland/index.md).

---

## Modules Overview

* **Control Center (`modules/controlcenter/`):**
  * **Dynamic Island Shelf Architecture:** Docked directly below Waybar (`shelfHeight: 36px`, `y: 0`, `anchors.rightMargin: 0`) with a borderless glass surface (`border.width: 0`, `alpha 0.80`) matching the top status bar.
  * **Concave Transition Fillet:** Hardware-accelerated `QtQuick.Shapes` inverted fillet (28 px radius) bridging Waybar's horizontal bottom edge with the panel's left vertical shoulder, creating a continuous molded Dynamic Island appearance.
  * **Instant & Clean Deployment:** Completely eliminates overshoot bouncing and clipped vertical resizing for instantaneous, responsive activation.
  * **Layout Architecture:** Balanced two-column grid layout featuring a left widgets column (Analog Clock, Weather, Media Player) and a right control matrix (4x3 quick toggle grid alongside vertical glassmorphic sliders).
  * **Analog Clock Widget (`AnalogClockWidget.qml`):** Canvas-based analog dial with dynamic hour and minute hands, digital time readout, and localized English weekday and calendar date.
  * **Weather Widget (`WeatherWidget.qml`):** Live atmospheric conditions, ambient temperature, location label, and relative humidity fetched via OpenWeather API in English.
  * **Vertical Sliders Card:** Frosted glassmorphic card housing vertical reactive sliders for PipeWire audio volume and `brightnessctl` display backlight.
  * **Quick Toggles (4x3 Grid):** Rounded pill buttons for Wi-Fi, Bluetooth, DND, Airplane Mode, Caffeine, Power Profiles, Night Light, Screen Shaders, Audio outputs, Dynamic Theming, Energy, and Wallpaper selection.
  * **Orbital Radar Submenus (`WifiSection.qml`, `BluetoothSection.qml`):**
    * **Wi-Fi Orbital Radar:** Central localhost host node with discovered networks revolving in concentric orbits. Orbital radius is dynamically mapped to signal strength (stronger signal orbits closer to the host). Features a fixed right-side telemetry card displaying active connection metrics (SSID, security protocol, local IP/CIDR, live dBm and transfer rates), fast instant caching, and a pause/resume animation button with state persisted in `radar_preferences.json`.
    * **Bluetooth Orbital Radar:** Central host node with paired and discovered devices in dynamic orbital paths. Includes an interactive device iconography picker (Nerd Font glyphs for mouse, keyboard, headphones, speaker, gamepad, and generic device) with persistent mapping in `bluetooth_icons.json`, fixed right-side connection telemetry card, and an independent pause/resume toggle.
  * **Energy & Performance Dashboard (`BatterySection.qml`):** Dedicated hardware metrics subpage displaying charge percentage, discharge rates, full charge estimates, battery health state, power draw, charge cycles, and power profile presets (Power Saver, Balanced, Performance).
  * **Waybar Sync:** Seamless bidirectional state sync between quick toggles (Caffeine, Night Light, Shader, Power Profiles) and top status bar indicators using POSIX signals (including `SIGRTMIN+11` for instantaneous power profile updates).
* **Notifications & Dynamic Island Toasts (`modules/controlcenter/`, `modules/notifications/`):**
  * Native DBus notification server (`org.freedesktop.Notifications`) managed by `NotificationService.qml`.
  * Top-center Dynamic Island toast layer (`NotificationToastLayer.qml`) docked flush with Waybar (`shelfHeight: 36px`), featuring dual concave transition fillets (28 px radius), flat top edges, and downward slide emergence animation.
  * Collapsible notifications card embedded directly inside the Control Center featuring the title `Notifications • ( # )`, rotating toggle chevron, quick "Clear all" action, empty placeholder state, and scrollable notification list.
  * Waybar notification bell triggers `qs ipc call notifications toggle`, opening the Control Center with the notifications card smoothly expanded.
  * Full design parameters and easing curves detailed in the [Notifications & OSDs Guide](osd-notifications.md).
* **Clipboard Manager (`modules/clipboard/`):**
  * **Dynamic Island Shelf Architecture:** Docked flush below Waybar (`shelfHeight: 36px`, `y: 0`, `anchors.rightMargin: 0`) with seamless 28 px concave transition fillet and continuous 2 px accent outline (`Root.Theme.primary`).
  * **Compact Geometry:** Scaled to 616 px width (30% narrower than the standard 880 px panel) for clean, unobtrusive clipboard history management.
  * **Unified Translucency:** Panel background with 0.85 opacity (`Root.Theme.panelBg`) and cards styled at 0.95 opacity (`Root.Theme.surfaceContainer`) matching the Notification Center design system.
  * **Functionality:** Real-time text history populated via `cliphist list`, instant re-copying via `cliphist decode <id> | wl-copy`, and quick pill button for wiping history.
  * **Triggering:** Accessible via Waybar quick action button or globally using `SUPER + V` (`qs ipc call clipboard toggle`). Detailed in [Hyprland Keybindings](../hyprland/keybinds.md#quickshell-and-desktop-overlays).
* **DeskClock & Calendar (`modules/deskclock/`, `modules/calendar/`):**
  * Ambient desktop clock surface and expandable calendar panel with date navigation.
* **Unified Music Player (`modules/launcher/`):**
  * Bottom-docked non-modal interactive MPRIS music controller integrated inside the launcher. Triggered globally with `SUPER + M` (`qs ipc call miniplayer toggle`) or by typing `/music`, featuring passthrough desktop click masking and full playback controls.
* **Application Launcher & Dynamic Island Carousel (`modules/launcher/`):**
  * Bottom-docked runner (`anchors.bottomMargin: 0`) with dual concave fillets (28 px radius) seamlessly emerging from the screen's bottom bezel.
  * Powers Application Drawer, Wallpaper Carousel, Shader Selector, Theme Carousel, and Gadget Manager. Detailed in the [Launcher & Wallpapers Guide](launcher-wallpapers.md).
* **Workspace Overview & Exposé (`modules/overview/`):**
  * Full-screen 2x5 grid displaying all 10 Hyprland workspaces simultaneously with proportional window layouts.
  * Drag-and-drop window relocation across workspaces, quick window kill, and spatial keyboard navigation.
  * Triggered globally with `SUPER + Tab` / `SUPER + SHIFT + Tab`. Detailed in the [Workspace Overview Guide](overview.md).
* **Keyboard Shortcuts Overlay (`modules/shortcuts/`):**
  * Wayland-native cheat sheet modal triggered via `F1` featuring live search, category pills, two-column card grid, and glassmorphic styling aligned with the Control Center. Detailed in the [Keyboard Shortcuts Guide](shortcuts-overlay.md).

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

* [Workspace Overview & Exposé](overview.md): 2x5 grid exposé, proportional window geometries, and drag-and-drop window relocation.
* [Keyboard Shortcuts Overlay](shortcuts-overlay.md): Wayland modal cheat sheet, category filtering, and live search.
* [Notifications & OSD Dynamics](osd-notifications.md): Animation curves, screen positioning, and source maps for toasts and OSD popups.
* [Waybar Status Bar](../apps/waybar.md): Top status bar shell integrating with Quickshell notification signals and launcher.
* [Hyprland Architecture](../hyprland/index.md): Compositor startup hooks, autostart services, and display arrangements.
* [Hyprland Keybindings](../hyprland/keybinds.md): Global hotkeys for invoking Quickshell panels, toggles, and tools.
* [GLSL Screen Shaders](../hyprland/shaders.md): Shader pipeline controlled directly from the Control Center.
* [Matugen Theming Engine](../apps/matugen.md): Central theme generator populating `palette.json`.
* [Wofi Application Launcher](../apps/wofi.md): Material Design 3 runner running alongside Quickshell.
* [Alacritty Terminal](../terminals/alacritty.md): Main terminal sharing font and color styling.
