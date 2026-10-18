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
     * **Command / Actions Mode (`/` or `>`):** Activated by typing `/` (or `>`)  to expose system commands.
     * **Wallpaper Carousel (`/wallpaper` / `SUPER + W`):** Horizontal card carousel featuring 16:9 previews, active wallpaper glow, and a local file explorer.
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
│       ├── ThemeCard.qml            # Theme palette preview card with Material 3 mockup
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
* **High-Contrast Selection Feedback:**
  * Active item receives a vibrant translucent primary tint (`rgba(primary, 0.22)`) and 1.5 px glowing primary border.
  * Vertical accent pill indicator on the left border.
  * Prominent `[ 󰌑 Enter ]` badge on the right edge.
  * Dynamic icon and title scale expansion.
* Keyboard navigation: `Up` / `Down` arrows move selection with automatic viewport positioning (`positionViewAtIndex`), `Enter` executes the application and closes the launcher, `Escape` cancels.

### 2. Action / Command Mode (`/` or `>`)
Typing `/` (or `>`) filters available system commands:
* **Wallpaper Carousel:** Enters the horizontal wallpaper picker carousel (`/wallpaper `).
* **Theme Carousel:** Enters the horizontal visual theme picker carousel (`/theme `).
* **Lock Screen:** Locks session using `hyprlock`.
* **Sleep / Suspend:** Suspends the machine to RAM (`systemctl suspend`).
* **Restart System / Shut Down:** Session reboot and power-off actions.

### 3. Wallpaper Carousel Mode
Typing `/wallpaper ` (or pressing `SUPER + W`) opens the horizontal carousel:
* Expanded floating card container (1080 px width, 340 px height, 24 px radius) offering generous horizontal and vertical headroom.
* **Caelestia Shell Containment & Edge Fade Overlays:**
  * Strict clipping (`clip: true`) enforced across the floating dock card, content viewport, and horizontal list view, eliminating lateral overflow beyond container boundaries.
  * Left and right 32 px horizontal gradient fade overlays that smoothly blend scrollable cards into the dark dock background without hard cutoffs.
* Displays 16:9 cards (224x214 px with 120 px thumbnail height) generated from `/home/zero/Pictures/walls/` and cached in `~/.cache/wallpapers/`.
* **Hover & Selection Styling:**
  * Dynamic elevation: Cards lift upward by -5 px on hover (-2 px on keyboard selection).
  * Smooth scale: Subtle 1.05 expansion on hover (1.03 on keyboard selection) with `Easing.OutCubic`.
  * Internal thumbnail zoom: 16:9 thumbnail expands to 1.05 within rounded bounds.
  * Vibrant halo glow: Border widens to 2 px with primary accent color and expanded glow margins.
* **Active Badge:** The currently active desktop wallpaper is highlighted with an "Active" badge and a focused double border.
* **Add Local File Card:** Positioned at the end of the carousel. Clicking or pressing `Enter` opens a native file dialog (`zenity`) to import external images, automatically caching thumbnails and applying the wallpaper.

### 4. Theme Carousel Mode
Typing `/theme ` or `/tema ` (also `>theme `), clicking "Theme" in the Control Center, or executing `qs ipc call launcher theme` opens the horizontal theme carousel:
* Reuses the same 1080x340 px floating container and smooth horizontal scroll architecture as the wallpaper carousel.
* **Visual Theme Cards (`ThemeCard.qml`):**
  * Displays 224x214 px cards with a dedicated 120 px preview container showcasing an interface mockup for each palette.
  * Preview includes a miniature header, active primary widget, slider with active track, accent chip, and 5 color swatches (`primary`, `primaryContainer`, `surfaceContainerHigh`, `connected`, `textPrimary`).
  * Palette colors resolve via explicit `Qt.color` conversion, ensuring accurate rendering across both static palettes and dynamic Matugen extractions.
  * An "Active" badge dynamically marks the currently applied theme.
* **Interactive Behavior:**
  * Selecting a card applies the theme instantly via `Theme.currentTheme`, persists it to `~/.config/quickshell/current-theme`, triggers `apply-theme.sh` or `apply-matugen.sh` across the system, and closes the launcher.
  * Full keyboard support with `Left` / `Right` navigation, `Enter` to apply, and text filtering (e.g. `>theme cobalt`).

---

## IPC Commands and Keybindings

The launcher and background engine expose IPC endpoints:

```bash
# Toggle application launcher
qs ipc call launcher toggle

# Open wallpaper carousel directly
qs ipc call launcher wallpaper

# Open theme carousel directly
qs ipc call launcher theme
qs ipc call themepicker show

# Navigate selection via IPC
qs ipc call launcher next
qs ipc call launcher prev
qs ipc call launcher activate

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
