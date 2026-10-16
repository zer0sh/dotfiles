# Floating Launcher & Animated Wallpaper Carousel

Quickshell implements a floating bottom-center application launcher and animated wallpaper selector inspired by Caelestia Shell. The component is integrated directly with Wayland layershell, Matugen color extraction, and hardware-accelerated QML transitions.

---

## Architecture Overview

The system consists of two coordinated Quickshell modules:

1. **Floating Launcher (`modules/launcher/`):**
   * Placed on `WlrLayershell.layer: WlrLayer.Overlay`.
   * Horizontally centered at the bottom of the screen with a 28 px bottom margin.
   * Translucent dark surface with rounded corners (22 px radius), subtle border highlight, and outer glow.
   * Search input at the bottom with real-time mode detection:
     * **Application Mode (default):** Lists system desktop entries with official icons, titles, and descriptions.
     * **Command / Actions Mode (`>`):** Activated by typing `>` to expose system commands.
     * **Wallpaper Carousel (`>wallpaper` / `SUPER + W`):** Horizontal card carousel featuring 16:9 previews, active wallpaper glow, and a local file explorer.
2. **Desktop Background Engine (`modules/background/Background.qml`):**
   * Placed on `WlrLayershell.layer: WlrLayer.Background` on all connected displays (`Quickshell.screens`).
   * Implements a double-buffer (ping-pong) layer switching architecture, guaranteeing reliable consecutive wallpaper transitions without QML property binding degradation.
   * Manages smooth cross-image animations, replacing static background setters like `swaybg`.
   * Applies the "Zoom & Blur" (Emergence) transition:
     * Outgoing wallpaper scales from 1.0 to 1.15 while fading opacity from 1.0 to 0.0 in 750 ms (`Easing.InOutQuad`).
     * Incoming wallpaper scales from 0.88 to 1.0 while fading opacity from 0.0 to 1.0 in 750 ms (`Easing.InOutQuad`).
   * Triggers `apply-matugen.sh` asynchronously to regenerate system palettes across Hyprland, Waybar, Alacritty, and Quickshell.

---

## File Structure

```text
quickshell/
├── modules/
│   ├── background/
│   │   └── Background.qml           # Fullscreen background layer with Zoom & Blur transition
│   └── launcher/
│       ├── Launcher.qml             # Main overlay window, state machine, and search bar
│       ├── WallpaperCard.qml        # 16:9 wallpaper thumbnail card and browse button
│       ├── AppItem.qml              # Application list row delegate with icon and metadata
│       └── ActionItem.qml           # System action row delegate
└── scripts/
    ├── list-apps.py                 # Fast desktop entry parser (exports JSON)
    ├── browse-wallpaper.sh          # Zenity file picker integration
    └── resolve-icons.sh             # Desktop icon path resolver
```

---

## Operational Modes

### 1. Application Search Mode
When the search input is empty or contains standard text:
* Lists all installed `.desktop` applications discovered by `list-apps.py`.
* Shows application icon, title in bold, and comment / category description.
* Keyboard navigation: `Up` / `Down` arrows move selection, `Enter` executes the application and closes the launcher, `Escape` cancels.

### 2. Action / Command Mode (`>`)
Typing `>` filters available system commands:
* **Wallpaper Carousel:** Enters the wallpaper picker view.
* **Cycle Theme:** Cycles between Matugen, Cobalt Night, Amethyst, Arctic Mist, and Cyberpunk.
* **Light Mode / Dark Mode:** Switches Matugen generation mode.
* **Lock Screen:** Locks session using `hyprlock`.
* **Sleep / Suspend:** Suspends the machine to RAM (`systemctl suspend`).
* **Restart System / Shut Down:** Session reboot and power-off actions.

### 3. Wallpaper Carousel Mode
Typing `>wallpaper ` or pressing `SUPER + W` opens the horizontal carousel:
* Expanded floating card container (1080 px width, 330 px height) offering comfortable horizontal and vertical headroom.
* Displays 16:9 cards (224x214 px with 120 px thumbnail height) generated from `/home/zero/Pictures/walls/` and cached in `~/.cache/wallpapers/`.
* **Enhanced Hover & Focus Animations:**
  * Dynamic elevation: Cards lift upward by -10 px on mouse hover.
  * Elastic scale expansion: Scales to 1.10 using `Easing.OutBack` with 1.3 overshoot.
  * Internal parallax zoom: The 16:9 thumbnail subtly zooms to 1.08 within rounded clipping bounds.
  * Vibrant halo glow: Border widens to 2 px with primary color illumination and expanded glow margins.
* **Active Badge:** The currently active desktop wallpaper is highlighted with an "Active" badge and a focused double border.
* **Add Local File Card:** Positioned at the end of the carousel. Clicking or pressing `Enter` opens a native file dialog (`zenity`) to import external images, automatically caching thumbnails and applying the wallpaper.
* **Snappy Keyboard & Scroll Navigation:** `Left` / `Right` arrows instantly navigate adjacent wallpapers with 140 ms highlight transitions (`highlightMoveDuration: 140`), `WheelHandler` provides fluid scrolling without intercepting hover states, and `Enter` or mouse click applies the selected wallpaper with the Zoom & Blur transition.

---

## IPC Commands and Keybindings

The launcher and background engine expose IPC endpoints:

```bash
# Toggle application launcher
qs ipc call launcher toggle

# Open wallpaper carousel directly
qs ipc call launcher wallpaper

# Filter commands or text via IPC
qs ipc call launcher search ">"

# Set wallpaper programmatically with animated transition
qs ipc call wallpaper set "/path/to/image.png"

# Hide launcher
qs ipc call launcher hide
```

### Hyprland Integration (`~/.config/hypr/binds.conf`)

* `SUPER + Space`: Runs `~/.config/hypr/scripts/toggle-menu`, invoking `qs ipc call launcher toggle` with Wofi as fallback.
* `SUPER + W`: Invokes `qs ipc call launcher wallpaper` to present the wallpaper carousel.
