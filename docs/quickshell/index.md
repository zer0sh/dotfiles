# Quickshell & Control Center

Quickshell is the Wayland-native QML widget framework driving this desktop environment. It provides a One UI inspired control center featuring translucent cards, rounded pill toggles, and reactive sliders.

---

## Modules Overview

* **Control Center (`modules/controlcenter/`):**
  * Toggles for Wi-Fi, Bluetooth, DND, Airplane Mode, Caffeine, Power Profiles, Night Light, and Screen Shaders.
  * Interactive volume and brightness sliders.
  * Direct access to wallpaper changer and battery diagnostics.
* **Notifications & Toasts (`modules/notifications/`):**
  * Native DBus notification server (`org.freedesktop.Notifications`).
  * Top-center floating toast layer with smooth downward entrance animations.
  * Persistent notification drawer accessible via Waybar or keyboard shortcuts.
* **Clipboard Manager (`modules/clipboard/`):**
  * Visual history and search for text and images integrated with `cliphist`.
* **DeskClock & Calendar (`modules/deskclock/`, `modules/calendar/`):**
  * Ambient desktop clock surface and expandable calendar panel.
* **Mini Music Player (`modules/osd/MiniPlayer.qml`):**
  * Compact MPRIS playback controller triggered with `SUPER + M`.

---

## Validation and Live Reload

To validate QML syntax or restart Quickshell without crashing your Wayland session:

```bash
# Validate QML syntax without restarting
~/.config/quickshell/restart-quickshell.sh --validate

# Restart Quickshell live
~/.config/quickshell/restart-quickshell.sh
```
